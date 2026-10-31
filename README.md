# My Sadhna (मेरी साधना) 📿

> **A modern, responsive Flutter application designed for devotees to track daily Vaishnava sadhana, calculate Sukriti Points (SP), and maintain spiritual accountability within Bhakti Vriksha circles.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)](https://supabase.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-orange)](#)

---

## 🌟 Key Features

### 📿 Sadhana & Daily Logging
- **Japa Meditation Tracking**: Log completed daily rounds with automatic Sukriti Point allocation.
- **Study & Hearing (Shravanam & Kirtanam)**: Record time dedicated to Srila Prabhupada's books, lectures, and devotional katha.
- **Brahma-muhurta & Sleep Tracking**: Quick one-tap morning wake-up and bedtime logging.
- **Shloka Memorization Tracker**: Log memorized verses for additional spiritual points.
- **Streak Freeze Pass**: Maintain spiritual streaks during travel, pilgrimage, or illness.

### 📊 Analytics & Progress
- **Nistha Spiritual Growth Trend**: 4-week moving comparison to analyze consistency against prior performance.
- **Monthly Sadhana Heatmap**: Visual calendar grid highlighting full, partial, and missed sadhana days.
- **Bhakti Wrapped**: Summary of total holy names chanted, reading hours, and longest active streaks.
- **Monthly PDF Export**: Download and print monthly sadhana cards for personal records or preacher review.

### 🏛️ Preacher Console & Mentorship
- **Circle Management**: Counselees are mapped to assigned counselors/preachers.
- **Direct Calling & WhatsApp Integration**: Preachers can call or message devotees directly from the console.
- **Inactivity Alerts**: Highlights devotees who have missed logs for 3+ consecutive days.
- **Monthly Reviews & Notes**: Preachers can leave monthly spiritual guidance notes that appear directly on the devotee's dashboard.

### 🏆 Community Standings
- **Dynamic Leaderboards**: Filter by **Weekly** or **Monthly** top rankings.
- **Scope Filters**: Toggle between **All Circles** (community-wide) and **My Circle** (specific counselor group).
- **Custom Sacred Emblems**: Devotees can select custom sacred tilak and avatar badges (`📿`, `🌱`, `🔥`, `👑`, `🪷`, `🦚`, `☀️`, `🕊️`).

### ⚡ Reliability & Deployment
- **Offline Auto-Sync**: Logs entries locally when offline using `shared_preferences` and flushes them automatically via `connectivity_plus` upon network restoration.
- **Dual Authentication**: Password-based login alongside One-Tap Google OAuth with mandatory profile completion (DOB, phone, counselor, profession).
- **In-App Updater**: Built-in update prompt that directs Android APK users to the latest release hosted on Vercel.

---

## 🛠️ Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend / Database**: Supabase (PostgreSQL, Auth, Storage)
- **State & Local Storage**: `shared_preferences`, `connectivity_plus`
- **Typography & UI**: `google_fonts` (Cinzel, Outfit), `flutter_animate`
- **PDF Generation**: `pdf`, `printing`
- **Hosting**: Vercel (Web Application & APK distribution)

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.13.7` or later
- Dart SDK
- Supabase Account & Project
- Android Studio / VS Code with Flutter extensions

### 1. Clone the Repository

    git clone https://github.com/<your-username>/my_sadhna.git
    cd my_sadhna

### 2. Install Dependencies

    flutter pub get

### 3. Supabase Configuration

Set up your Supabase project credentials in `lib/main.dart`:

    await Supabase.initialize(
      url: 'YOUR_SUPABASE_PROJECT_URL',
      anonKey: 'YOUR_SUPABASE_ANON_KEY',
    );

Ensure your Supabase project has the required tables:
- `profiles`
- `sadhana_entries`
- `preachers`
- `counselor_notes`
- `app_config`

### 4. Run Locally

    # Run on Chrome
    flutter run -d chrome

    # Run on connected Android device
    flutter run -d android

---

## 📦 Building for Production

### Android Release APK

    # Generate split-per-ABI APKs for minimal download size (~25MB)
    flutter build apk --split-per-abi

    # The release binary is generated at:
    # build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

### Web Release

    flutter build web --release

---

## 📁 Project Structure

    my_sadhna/
    ├── android/               # Native Android configurations
    ├── lib/
    │   └── main.dart          # Core application (Auth, Dashboards, Preacher Console)
    ├── web/
    │   ├── downloads/         # Static release APK storage for in-app downloads
    │   └── index.html         # Web entry point
    ├── pubspec.yaml           # App dependencies & versioning
    └── README.md              # Project documentation

---

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).
