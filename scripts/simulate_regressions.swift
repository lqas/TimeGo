#!/usr/bin/env swift
import Foundation

// Standalone simulations of the regressions we fixed (no app launch required).

var failed = 0
func expect(_ cond: Bool, _ msg: String) {
    if cond {
        print("PASS  \(msg)")
    } else {
        failed += 1
        print("FAIL  \(msg)")
    }
}

// MARK: - Shared models (mirrors production logic)

func dayKey(for date: Date, calendar: Calendar = .current) -> String {
    let comps = calendar.dateComponents([.year, .month, .day], from: date)
    let year = comps.year ?? 0
    let month = comps.month ?? 0
    let day = comps.day ?? 0
    let mm = month < 10 ? "0\(month)" : "\(month)"
    let dd = day < 10 ? "0\(day)" : "\(day)"
    return "\(year)-\(mm)-\(dd)"
}

struct Gate {
    var wasOnCompany = false
    mutating func noteCleared() { wasOnCompany = false }
    mutating func shouldStart(onCompany: Bool, hasSessionToday: Bool) -> Bool {
        defer { wasOnCompany = onCompany }
        guard !hasSessionToday else { return false }
        return onCompany && !wasOnCompany
    }
}

// MARK: 1) Morning unlock recursion (the overnight quit)

print("\n== 1. Morning unlock / day-boundary recursion ==")

func simulateOldMorningUnlock() -> Int {
    var gate = Gate()
    var sessionDay: String? = dayKey(for: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
    var depth = 0
    var maxDepth = 0
    let today = dayKey(for: Date())

    func evaluate() {
        depth += 1
        maxDepth = max(maxDepth, depth)
        defer { depth -= 1 }
        if depth > 200 { return } // hard stop

        let hasToday = (sessionDay == today)
        if gate.shouldStart(onCompany: true, hasSessionToday: hasToday) {
            // OLD start(): clear stale session first (publishes nil).
            // noteCleared() resets the rising-edge gate, so the sync sink can
            // call evaluate → start again while still inside start().
            if let existing = sessionDay, existing != today {
                sessionDay = nil
                gate.noteCleared()
                evaluate() // sync re-enter like Combine sink
            }
            sessionDay = today
        }
    }

    evaluate()
    return maxDepth
}

func simulateNewMorningUnlock() -> (depth: Int, session: String?) {
    var gate = Gate()
    var sessionDay: String? = dayKey(for: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
    var depth = 0
    var maxDepth = 0
    let today = dayKey(for: Date())
    var deferred: [() -> Void] = []
    var evaluating = false

    func evaluate() {
        guard !evaluating else { return }
        evaluating = true
        defer { evaluating = false }

        depth += 1
        maxDepth = max(maxDepth, depth)
        defer { depth -= 1 }
        if depth > 200 { return }

        let hasToday = (sessionDay == today)
        if gate.shouldStart(onCompany: true, hasSessionToday: hasToday) {
            // NEW start(): atomic replace, no nil intermediate
            sessionDay = today
        }
    }

    // Midnight / wake reconcile clears yesterday
    if let existing = sessionDay, existing != today {
        sessionDay = nil
        gate.noteCleared()
        deferred.append { evaluate() } // deferred like Task { @MainActor in ... }
    }
    for job in deferred { job() }
    return (maxDepth, sessionDay)
}

let oldDepth = simulateOldMorningUnlock()
// Production crash was unbounded stack growth; this model shows the sync re-entry
// (depth >= 2) that Combine made fatal once gate.noteCleared() reset the edge.
expect(oldDepth >= 2, "old path re-enters evaluate during start (maxDepth=\(oldDepth))")

let neu = simulateNewMorningUnlock()
expect(neu.depth <= 2, "new path stays shallow (maxDepth=\(neu.depth))")
expect(neu.session == dayKey(for: Date()), "new path clocks in for today")
expect(neu.depth < oldDepth || neu.depth == 1,
       "new path is not deeper than old re-entry (new=\(neu.depth), old=\(oldDepth))")

// MARK: 2) OA URL default / migration

print("\n== 2. OA URL default removed ==")

struct OASettings: Codable {
    var companyOAURL: String = ""

    init(companyOAURL: String = "") {
        self.companyOAURL = companyOAURL
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let decodedOA = try c.decodeIfPresent(String.self, forKey: .companyOAURL)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if decodedOA == "https://i.mdpi.cn/team/attendance" {
            companyOAURL = ""
        } else {
            companyOAURL = decodedOA
        }
    }

    enum CodingKeys: String, CodingKey { case companyOAURL }
}

func decodeOA(_ json: String) throws -> OASettings {
    try JSONDecoder().decode(OASettings.self, from: Data(json.utf8))
}

expect(OASettings().companyOAURL.isEmpty, "fresh default OA URL is empty")
expect(try decodeOA(#"{"companyOAURL":"https://i.mdpi.cn/team/attendance"}"#).companyOAURL.isEmpty,
       "old built-in default is cleared on decode")
expect(try decodeOA(#"{}"#).companyOAURL.isEmpty, "missing OA key decodes to empty")
expect(try decodeOA(#"{"companyOAURL":"https://oa.example.com/x"}"#).companyOAURL
        == "https://oa.example.com/x",
       "custom OA URL is kept")

func makeURL(from raw: String) -> URL? {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    if let url = URL(string: trimmed), let scheme = url.scheme, !scheme.isEmpty { return url }
    return URL(string: "https://\(trimmed)")
}
expect(makeURL(from: "") == nil, "empty OA does not resolve to a URL (no menu button)")

// MARK: 3) Notification catch-up grace (no double fire at exact time)

print("\n== 3. Notification catch-up grace ==")

func shouldCatchUp(now: Date, fireAt: Date, alreadyNotified: Bool, grace: TimeInterval = 3) -> Bool {
    guard !alreadyNotified else { return false }
    return now >= fireAt.addingTimeInterval(grace)
}

let fire = Date()
expect(!shouldCatchUp(now: fire, fireAt: fire, alreadyNotified: false),
       "at exact fire time, catch-up does NOT post (avoids racing calendar trigger)")
expect(!shouldCatchUp(now: fire.addingTimeInterval(2), fireAt: fire, alreadyNotified: false),
       "within 3s grace, catch-up does not post")
expect(shouldCatchUp(now: fire.addingTimeInterval(3), fireAt: fire, alreadyNotified: false),
       "after grace, catch-up posts once for missed notification")
expect(!shouldCatchUp(now: fire.addingTimeInterval(10), fireAt: fire, alreadyNotified: true),
       "already notified → no second post")

// MARK: 4) Network gate rising edge

print("\n== 4. Network rising-edge gate ==")

var gate = Gate()
expect(gate.shouldStart(onCompany: true, hasSessionToday: false), "first join company → start")
expect(!gate.shouldStart(onCompany: true, hasSessionToday: false), "still on company → no second start")
gate.noteCleared()
expect(gate.shouldStart(onCompany: true, hasSessionToday: false), "after clear, rising edge works again")
expect(!gate.shouldStart(onCompany: true, hasSessionToday: true), "has session today → never start")

print(failed == 0 ? "\nAll simulations passed." : "\n\(failed) simulation(s) failed.")
exit(failed == 0 ? 0 : 1)
