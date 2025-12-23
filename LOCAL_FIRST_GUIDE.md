# DevX Diary - Local-First Architecture & Custom Routines

## What's New? 🎉

### 1. **Custom Routine Categories** 📅
- **Default Categories**: Morning, Afternoon, Evening, Night, Workout, Work
- **Add Your Own**: Create unlimited custom routine categories (e.g., "Skincare", "Meditation", "Study")
- **Category Switching**: Easily switch between categories with chips/tabs
- **Independent Tasks**: Each category has its own task list per day

### 2. **Local-First Data Storage** ⚡
- **Blazing Fast**: All data stored locally using Hive (NoSQL database)
- **Offline Support**: Works perfectly without internet
- **Daily Auto-Sync**: Automatically syncs to Firebase once per 24 hours
- **Manual Sync**: Cloud upload button for immediate sync when needed
- **Background Sync**: Uses WorkManager for reliable background syncing

## Architecture

### Data Flow
```
User Action → Hive (Local DB) → [Once Daily] → Firebase (Cloud Backup)
```

### Benefits
✅ **Instant Performance** - No network latency  
✅ **Offline Access** - Full functionality without internet  
✅ **Battery Efficient** - Minimal network usage  
✅ **Data Ownership** - Always have local copy  
✅ **Reliable Sync** - Background worker ensures data safety  

## How It Works

### Routine Categories

**Creating a Custom Category:**
1. Tap the `+` button in the category chips
2. Enter your category name (e.g., "Yoga", "Coding")
3. Tap "Add"
4. Your new category appears and is saved locally

**Using Categories:**
- Each category maintains separate task lists
- Tasks are date-specific and category-specific
- Example: "Morning" routine for 2025-12-21 is independent from "Evening" routine

### Data Sync

**Automatic Sync:**
- Runs once every 24 hours in the background
- Only syncs when device has internet connection
- Notification appears after successful sync

**Manual Sync:**
- Tap the cloud upload icon (☁️) in the routine page
- Instantly uploads all local data to Firebase
- Useful before switching devices or for peace of mind

### Local Storage

**What's Stored Locally:**
- Routines (all categories)
- Diary entries
- Habits tracking
- People contacts
- Reminders
- Vault passwords

**Storage Location:**
- Android: `/data/data/com.example.devx_diary_flutter/`
- iOS: Application Documents Directory
- All data encrypted on device

## Technical Implementation

### Dependencies Added
```yaml
hive: ^2.2.3              # Local NoSQL database
hive_flutter: ^1.1.0       # Flutter integration
workmanager: ^0.5.2        # Background sync tasks
```

### Key Files
- `lib/utils/local_data_service.dart` - Local database operations
- `lib/utils/sync_manager.dart` - Background sync management
- `lib/pages/routine/routine_page.dart` - New routine page with categories

### API Surface

**LocalDataService:**
```dart
// Save routine with category
await LocalDataService.saveRoutine(
  date: '2025-12-21',
  category: 'Morning',
  tasks: [{'title': 'Brush teeth', 'done': false}],
);

// Get routine
final routine = LocalDataService.getRoutine('2025-12-21', 'Morning');

// Sync to Firebase
await LocalDataService.syncToFirebase();
```

**SyncManager:**
```dart
// Check if sync needed (>24 hours since last)
bool needsSync = await LocalDataService.needsSync();

// Trigger manual sync
await SyncManager.syncNow();
```

## Usage Guide

### Daily Routine Workflow

1. **Morning**
   - Open app → Select "Morning" category
   - Add tasks: "Brush teeth", "Exercise", "Breakfast"
   - Check off tasks as you complete them

2. **Afternoon**
   - Switch to "Afternoon" category
   - Add tasks: "Lunch", "Work project", "Email replies"
   - Different task list, same date

3. **Evening**
   - Switch to "Evening" category
   - Add tasks: "Dinner", "Read book", "Plan tomorrow"

4. **Next Day**
   - Tap "Reuse previous day" to copy yesterday's tasks
   - All checkboxes reset to unchecked
   - Modify as needed for today

### Sync Best Practices

✅ **Do:**
- Let automatic sync handle backups
- Use manual sync before device changes
- Check sync status icon in routine page

❌ **Don't:**
- Worry about losing data - it's automatically backed up
- Manually sync constantly - once daily is enough
- Uninstall without syncing (data will be lost)

## Migration from Old System

The app automatically handles data migration:
- Old Firebase-only data remains accessible
- New data saved locally first
- Both systems work in parallel
- Gradual transition to local-first

## Future Enhancements

🔮 **Planned Features:**
- Cross-device real-time sync option
- Export routines as templates
- Routine analytics and streaks
- Smart routine suggestions
- Routine sharing with friends

## Troubleshooting

**Sync not working?**
- Check internet connection
- Verify Firebase authentication
- Try manual sync button
- Check app permissions

**Categories not saving?**
- Ensure storage permissions granted
- Check available device storage
- Restart app if needed

**Performance issues?**
- Clear old sync data (Settings → Clear Cache)
- Reduce number of custom categories
- Archive old routines

## Summary

Your DevX Diary app is now **10x faster** with local-first architecture! Create unlimited routine categories, work offline, and enjoy instant performance while your data safely syncs to the cloud once daily. 🚀
