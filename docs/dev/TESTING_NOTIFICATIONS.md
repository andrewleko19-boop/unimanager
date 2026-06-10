# Push Notifications Testing Guide

## Prerequisites

- ✅ App version: v1.0.0
- ✅ Service Worker: v1.0.0 (cache version matches)
- ✅ Browser: Chrome/Firefox with Notification API support

---

## Test Cases

### Test 1: Permission Request Modal

**Steps:**

1. Open Settings tab → Notifications section
2. Click "Enable" button
3. **Expected:** Modal appears with "Allow Notifications" message
4. **Bilingual:** Check RTL layout in Arabic mode

**Result:** ******\_\_\_******

---

### Test 2: Grant Permission

**Steps:**

1. From Test 1, click "Allow" button
2. **Expected:**
   - Modal closes
   - Toast shows "Notifications enabled"
   - Settings shows "🗸 Enabled" (green checkmark)

**Result:** ******\_\_\_******

---

### Test 3: 24-Hour Task Warning ⏰

**Steps:**

1. Create task with deadline **exactly 23 hours** from now
2. Wait 15-30 seconds (notification check runs every 15 min)
3. **Expected:** Notification: "🔴 [Task Name] — due in less than 24 hours!"

**Result:** ******\_\_\_******

---

### Test 4: 1-Hour Task Warning 🔴

**Steps:**

1. Create task with deadline **exactly 59 minutes** from now
2. Wait for next check cycle (≤15 min)
3. **Expected:** Notification: "🔴 [Task Name] — due in less than 1 hour!"

**Result:** ******\_\_\_******

---

### Test 5: 2-Day Exam Warning ⚠️ (NEW)

**Steps:**

1. Create exam with date **exactly in 2 days**
2. Wait for notification check (≤15 min)
3. **Expected:** Notification: "⚠️ [Subject] exam in 2 days!"

**Result:** ******\_\_\_******

---

### Test 6: 1-Day Exam Warning (Tomorrow)

**Steps:**

1. Modify exam date to **tomorrow same time**
2. Wait for next check cycle (≤15 min)
3. **Expected:** Notification: "⚠️ [Subject] exam tomorrow!"

**Result:** ******\_\_\_******

---

### Test 7: Few Hours Before Exam 🚨 (NEW)

**Steps:**

1. Create exam with date **3 hours** from now
2. Wait for notification check
3. **Expected:** Notification: "🚨 [Subject] exam in a few hours!" (with requireInteraction:true)

**Result:** ******\_\_\_******

---

### Test 8: No Duplicate Notifications

**Steps:**

1. Wait 15+ minutes with same exam present
2. Check browser console (F12)
3. **Expected:**
   - Notification appears **only once**
   - localStorage key `e2_{examId}`, `e1_{examId}`, `eh_{examId}` prevent duplicates

**Result:** ******\_\_\_******

---

### Test 9: Service Worker Push Event (Advanced)

**Steps:**

1. Open DevTools → Application → Service Workers
2. Verify `sw.js` is active and running
3. Check Network tab for `supabase...` requests (Realtime API)
4. **Expected:** SW handles push events without errors

**Result:** ******\_\_\_******

---

### Test 10: RTL Language Support

**Steps:**

1. Settings → Language → العربية
2. Create Arabic subject exam
3. Wait for notification
4. **Expected:**
   - Notification text appears in Arabic ✓
   - Settings modal shows RTL layout ✓

**Result:** ******\_\_\_******

---

## Debug Commands (Console)

```javascript
// Check notification permission
Notification.permission; // Should return "granted"

// Manually trigger deadline check
checkDeadlines();

// View tracked notifications
JSON.parse(localStorage.getItem("unimanager_notified"));

// View Service Worker status
navigator.serviceWorker.controller; // Should exist

// Clear notification tracking (to re-trigger test)
localStorage.removeItem("unimanager_notified");

// Force notification
new Notification("Test", { body: "Testing notifications" });
```

---

## Known Limitations (v1.0.0)

- ⚠️ Push subscriptions use placeholder VAPID key (`AAAAG3xsHnkAAAAA`)
  - To enable server-sent push: Add real VAPID key from Supabase
  - For now: Notifications work via client-side deadline checks
- ⚠️ Notification check runs every 15 minutes (not real-time)
- ⚠️ Some browsers may require user interaction before notifications display

---

## Next Steps (v1.1+)

- [ ] Replace VAPID key with Supabase Edge Function
- [ ] Add `state.examsNotifEnabled` preference toggle
- [ ] Real-time push from Supabase Realtime API
- [ ] Notification persistence in IndexedDB
- [ ] Click handler to navigate to relevant exam/task

---

## Success Criteria

✅ All 10 tests pass
✅ No console errors
✅ Notifications appear within 15-60 seconds of deadline
✅ No duplicate notifications for same deadline
✅ RTL layout works for Arabic notifications
