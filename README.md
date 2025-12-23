# DevX Diary Flutter MVP

A private, secure Flutter-based personal diary and life management application with journaling, mood tracking, habit building, and more.

## MVP Features Implemented

✅ **1. Authentication & User Access**
- Email/password login and signup via Firebase Auth
- Password reset via email
- Secure logout
- "Remember me" session persistence (auth state streams)

✅ **2. Diary / Journal Entries**
- Create, edit, and view diary entries
- Date picker for editable dates
- Mood selection (Happy, Sad, Angry, Calm, Neutral) with icons
- Optional tags (people, habits, themes)
- Chronological timeline view
- Calendar-based filtering (week/month view via TableCalendar)
- Search by title and tags

✅ **3. Mood Tracker (Integrated with Diary)**
- Mood assigned to each diary entry
- Visual mood icons and colors
- Mood history can be viewed via chronological list

✅ **4. Habit Tracker (Atomic Habits Style)**
- Create habits with name, frequency (daily/weekly), and start date
- One-tap daily completion
- Automatic streak calculation
- Simple check circle visual feedback
- Habits stored per user in Firestore

✅ **5. Daily Routine & Checklist**
- Per-day routine checklist with add, edit, complete, remove
- Reuse previous day's routine with one click
- Routine resets each day (stored by date key)

✅ **6. People Section (Memory & Relationship Tagging)**
- Maintain personal list of people with names and notes
- Tag people in diary entries
- View people timeline: all entries tagged with a specific person

✅ **7. Secure Password Vault (Basic MVP)**
- Local encryption via flutter_secure_storage
- Store website/app, username, password, and notes
- Add and edit credentials
- Searchable list (no sharing of sensitive data)

✅ **8. Reminders & Email Notifications**
- Create reminders with title, description, date, and time
- Calls Cloud Function to schedule email reminders (placeholder)
- Reminder status tracking

✅ **9. Google Drive Backup & Import**
- Export all user data to JSON and share via OS Share Sheet
- Data includes entries, habits, routines, people, reminders, vault
- Import stub (file_picker integration ready)
- Enables device migration and data recovery

✅ **10. UI / UX Design (Flutter MVP)**
- Clean, modern calming design with soft color palette (#6C84A7)
- Material 3 design
- Card-based UI for entries, habits, and routines
- Mobile-first layout optimized for one-handed use
- Smooth animations using Flutter's native capabilities
- Minimal distractions

## Project Structure

```
lib/
├── main.dart                 # Firebase init, auth-aware routing, theme
├── firebase_options.dart     # Firebase configuration (needs flutterfire configure)
├── pages/
│   ├── auth/
│   │   └── login_page.dart                # Combined login/signup form
│   ├── home/
│   │   └── home_page.dart                 # Bottom nav, main layout
│   ├── diary/
│   │   ├── diary_list_page.dart          # List, search, calendar filter
│   │   └── diary_editor_page.dart        # Create/edit entries
│   ├── habits/
│   │   └── habits_page.dart               # Create, complete, streak tracking
│   ├── routine/
│   │   └── routine_page.dart              # Daily checklist, reuse
│   ├── people/
│   │   └── people_page.dart               # Add people, view timeline
│   ├── vault/
│   │   └── vault_page.dart                # Secure password storage
│   ├── reminders/
│   │   └── reminders_page.dart            # Create reminders, call Cloud Function
│   └── settings/
│       └── settings_page.dart             # Backup, import, design info
└── utils/
    └── backup.dart                        # Export to JSON and share
```

## Backend Setup

### Firebase

1. Create a Firebase project at [firebase.google.com](https://firebase.google.com)
2. Enable Authentication (Email/Password)
3. Enable Cloud Firestore (set to test mode for initial development)
4. Enable Cloud Storage (for future expansion)
5. Create a Cloud Function for email reminders (optional, app will silently ignore if not present)

### Configure Firebase Credentials

Run in the project directory:
```bash
flutterfire configure
```

This will automatically configure `firebase_options.dart` for all platforms.

## Getting Started

### Prerequisites

- Flutter 3.0+
- Dart 3.0+
- Android Studio / Xcode (for iOS)
- Firebase account and project

### Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd devx_diary_flutter
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase (see Backend Setup above)

4. Run the app:
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web (after flutterfire configure for web)
flutter run -d chrome
```

## Database Structure (Firestore)

```
users/
├── {uid}/
│   ├── entries/
│   │   ├── {docId}
│   │   │   ├── title: string
│   │   │   ├── content: string
│   │   │   ├── mood: string (happy|sad|angry|calm|neutral)
│   │   │   ├── tags: array<string>
│   │   │   ├── date: timestamp
│   │   │   └── updatedAt: timestamp
│   ├── habits/
│   │   ├── {docId}
│   │   │   ├── name: string
│   │   │   ├── frequency: string (daily|weekly)
│   │   │   ├── startDate: timestamp
│   │   │   ├── completions: map<string, bool> (key: "yyyy-MM-dd")
│   │   │   └── createdAt: timestamp
│   ├── routines/
│   │   ├── {dateKey} ("yyyy-MM-dd")
│   │   │   └── tasks: array<{title: string, done: bool}>
│   ├── people/
│   │   ├── {docId}
│   │   │   ├── name: string
│   │   │   ├── notes: string
│   │   │   └── createdAt: timestamp
│   ├── reminders/
│   │   ├── {docId}
│   │   │   ├── title: string
│   │   │   ├── description: string
│   │   │   ├── scheduledAt: timestamp
│   │   │   ├── status: string (scheduled|sent|failed)
│   │   │   └── createdAt: timestamp
```

**Local Storage (flutter_secure_storage):**
- `vault_items`: JSON array of {name, username, password, notes}

## Development Notes

- **Authentication**: Uses Firebase Auth with email/password. Future versions can add Google Sign-In, Apple Sign-In.
- **Offline Support**: Firestore is configured with persistence enabled.
- **Encryption**: Password vault uses flutter_secure_storage (platform-native encryption).
- **Reminders**: Currently calls a Cloud Function. Implement a backend Cloud Function to handle email scheduling.
- **Backup**: Export uses share_plus to leverage OS-native share sheet (supports Google Drive, email, etc.).

## Future Enhancements

- Advanced mood analytics with charts
- Habit correlations with mood data
- Biometric unlock for vault
- Flutter Web and Desktop support (same backend)
- Integration with habit-tracking APIs
- Custom reminder notifications (local + push)
- Data migration between devices

## Architecture

The app uses:
- **Firebase** for authentication and real-time Firestore database
- **Provider** for simple state management
- **flutter_secure_storage** for encrypted local storage
- **table_calendar** for calendar-based filtering
- **share_plus** for backup export

## Testing

A basic widget test placeholder is included:
```bash
flutter test
```

## License

MIT License

---

**Built for personal reflection, emotional awareness, habit consistency, and long-term personal growth.**
