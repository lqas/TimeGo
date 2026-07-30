# TimeGo

**English** | [简体中文](./README.zh-CN.md)

A macOS menu bar helper for flexible work hours: start the timer when you arrive at the office, and get reminded when it’s time to leave.

Built for “arrive whenever, leave after you hit your target hours.” By default it suggests a leave time based on **8 hours of work + 1 hour lunch**, both adjustable in Settings.

**Requires macOS 14 or later.**


<img width="200" height="100%" alt="CleanShot 2026-07-22 at 16 29 29@2x" src="https://github.com/user-attachments/assets/b8391fc4-bf58-4e30-9a1c-463e3c6a3c5e" />
<img width="200" height="100%" alt="CleanShot 2026-07-22 at 16 29 48@2x" src="https://github.com/user-attachments/assets/0d56c118-d00a-4b3a-9d2f-a6e6092447be" />
<img width="200" height="100%" alt="CleanShot 2026-07-22 at 16 30 39@2x" src="https://github.com/user-attachments/assets/46407073-1c2e-47ec-ae40-021827b52fea" />
<img width="200" height="100%" alt="CleanShot 2026-07-22 at 16 32 05@2x" src="https://github.com/user-attachments/assets/4fce5eb3-df45-411e-b5ac-71208fb0f6d5" />

---

## Features

- Menu bar always shows **time remaining / overtime so far**
- **Auto start**: when you join the company Wi‑Fi or company IP, or when you unlock/wake the Mac (optional: only auto-start on the company network, so home unlocks don’t trigger it)
- **Manual control**: edit start time, set to now, or clear today
- **Notifications**: alert when target hours are done; optional early leave reminder (default 5 minutes before)
- **One-click company attendance / OA** (URL configurable in Settings)
- **Chinese / English**, follows system language by default
- Optional **launch at login**
- Data stays on your Mac only — nothing is uploaded

---

## Install

1. Download the latest `TimeGo-*.zip` from [Releases](../../releases) and unzip it  
2. Drag `TimeGo.app` into the Applications folder  
3. **First launch**: in Finder, **Control-click → Open**, then confirm Open  
   - If macOS still blocks it: System Settings → Privacy & Security → Open Anyway  
4. Use the app once the TimeGo icon appears in the menu bar  

> Don’t only double-click an unsigned app — macOS may block it. After one Control-click Open, normal launches work.

---

## First-time setup

1. Click the menu bar icon → **Settings**  
2. Turn on **Launch at Login** (if prompted: System Settings → General → Login Items → allow TimeGo)  
3. Enter your company **Wi‑Fi name** and/or **IP prefix** (or use “Fill current…” while at the office)  
4. Allow **Notifications** (needed for leave and early reminders)  
5. Matching by Wi‑Fi name may require **Location** permission; if you prefer not to grant it, IP prefix alone is enough  

You can also paste your OA / attendance URL in Settings; once set, the menu shows **Open Attendance**.

---

## Daily use

- **Auto**: after you join the company network (or unlock the Mac), timing usually starts by itself  
- **Manual**: tap “Start work now” in the panel, or type a start time  
- **Progress**: menu bar shows remaining time; after the target it shows overtime  
- **Edit time**: adjust hours and minutes under time correction (after the hour field, focus jumps to minutes)  
- **Attendance history**: tap **Open Attendance** to open your OA URL in the browser  
- **Leave reminders**: notify when hours are complete; with early reminder on, you’ll get an earlier ping too  

---

## Auto-start rules (short)

While you haven’t started timing today:

- Join a matching company Wi‑Fi or company IP → auto start  
- Wake / unlock → may also auto start (if a company network is configured, it usually requires you to already be on that network)  
- Launch the app while already on the company network → starts as well  

You can always edit the start time manually. After midnight, timing resets for the new day.

---

## Privacy

- Start time and settings stay on this Mac  
- Attendance or location data is never sent to a server  
- Location permission is only used to read the Wi‑Fi name (optional)  
- **Open Attendance** simply opens the URL you entered in the system browser  

---

## FAQ

**Can’t find the menu bar icon?**  
Check whether the right side of the menu bar is crowded; or open TimeGo from Applications. Enable launch at login in Settings so you don’t have to start it by hand every time.

**Didn’t auto-start?**  
Confirm company Wi‑Fi / IP is filled in and you’re actually on the company network; or start manually and correct the time.

**No notifications?**  
System Settings → Notifications → TimeGo → allow notifications, and in the app Settings confirm leave / early reminders are enabled.

**Won’t open the first time?**  
In Finder use **Control-click → Open**, not only a double-click. That’s normal for apps that aren’t App Store–notarized.
