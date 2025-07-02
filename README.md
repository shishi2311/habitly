
# 📱 Habitly - Habit Tracking Application

Habitly is a modern habit tracking application designed to help users build and maintain positive daily habits. Built with **Flutter** and **Firebase**, it provides a clean, intuitive interface for tracking habits, maintaining streaks, and building consistency. The app targets individuals looking to develop better habits through simple, effective tracking and motivation.

---

## 🚀 Core Features

### 🔐 Authentication (Firebase Auth)
- Email/password and Google Sign-in
- Secure session and user data management

### ✅ Habit Management
- Create, edit, delete habits
- Set daily duration
- Track completion status and daily streaks

### 🔥 Streak Tracking
- Daily streak calculation
- Auto-reset on missed days
- Visual streak indicators and statistics

---

## 🛠️ Technical Architecture

### 📱 Frontend (Flutter)
- **Screens:** Home, Auth, Add/Edit Habit
- **State Management:** `Provider` with `ChangeNotifier`

### ☁️ Backend (Firebase)
- Firebase Auth with Google integration
- Cloud Firestore for habit data

**Firestore Structure:**
```

users/
└── {userId}/
└── habits/
└── {habitId}/
├── name
├── durationMinutes
├── streak
├── lastCompleted
└── createdAt

```

---

## 🔒 Security
- Firebase Security Rules
- Per-user data isolation
- Validation and safe reads/writes

---

## 💡 User Experience
- Clean, minimalist UI
- Easy habit creation & management
- Visual feedback for actions
- Motivating streak system

---

## 📈 Development Status

### ✅ Implemented
- Firebase Auth
- Habit CRUD
- Streak tracking
- Local persistence
- Real-time updates

### 🧩 Planned Features
- Habit categories
- Reminder notifications
- Stats dashboard
- Progress sharing
- Dark mode

---

## 🧾 Firestore Schema

### 👤 Users
```

users/{userId} {
email: string,
displayName: string,
createdAt: timestamp
}

```

### 📋 Habits
```

habits/{habitId} {
name: string,
durationMinutes: number,
streak: number,
lastCompleted: timestamp,
createdAt: timestamp,
updatedAt: timestamp
}

````

---

## 📦 Technical Dependencies
- Flutter SDK
- Firebase Core & Auth
- Cloud Firestore
- Google Sign-In
- Provider (State Management)

---

## ⚠️ Risks and Mitigations
| Risk                  | Mitigation                                  |
|-----------------------|----------------------------------------------|
| Data loss             | Error handling + Firestore backup            |
| Auth limitations      | Multi-provider support (Google/email)        |
| Performance           | Optimized queries, local cache               |
| Offline support       | Firestore’s built-in persistence             |

---

## 🧪 Development Environment
- VS Code
- Flutter DevTools
- Firebase CLI
- Android Emulator / iOS Simulator

---

## 🛠️ Getting Started

```bash
git clone https://github.com/shishi2311/habitly.git
cd habitly
flutter pub get
flutterfire configure
flutter run
````

---


