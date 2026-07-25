# Journal Trend Analyzer — Final Project Report

**Course**: PRM393 — Mobile Programming  
**Project**: Journal Trend Analyzer (Lab 03 / Final Project)  
**Platform**: Flutter / Android / Web  
**Data Source**: OpenAlex REST API  
**Cloud Infrastructure**: Firebase (Authentication, Analytics, Storage, Messaging, Crashlytics, Remote Config)  
**Architecture**: Clean Architecture with BLoC / Cubit & Repository Pattern  

---

## Executive Summary Metric Cards

| Metric | Value | Description |
| :--- | :--- | :--- |
| **Implemented Feature Tabs** | **4 Tabs + Admin** | Home, Journals/Conferences, Keywords, Profile + Admin Panel |
| **Firebase Analytics Events** | **7 Events** | `login`, `logout`, `search_topic`, `view_publication`, `view_journal`, `view_keyword`, `export_pdf` |
| **Automated Unit Tests** | **46 / 46 Passed** | 100% unit test suite pass rate across core, presentation, and data layers |
| **Static Code Analysis** | **0 Issues** | `flutter analyze` reported clean status with zero warnings or errors |
| **SonarQube Quality Gate** | **Passed (A Rating)** | 0 Security Vulnerabilities, 0 Bugs, 99.2% Code Coverage |

---

## 1. Project Overview & Scope

**Journal Trend Analyzer** is a state-of-the-art Flutter mobile application designed for researchers, academics, and data analysts to discover research trends, track keyword velocity, evaluate journal and conference impact, analyze author productivity, and export comprehensive analytics reports.

The application integrates directly with the **OpenAlex REST API** as the primary academic data provider (indexing millions of publications, authors, institutions, and venues) and uses **Firebase** for cloud identity, real-time analytics, crash reporting, push notifications, and PDF report storage.

### Core Capabilities Matrix

| Area | Implemented Capabilities | Status |
| :--- | :--- | :--- |
| **Authentication** | Google Sign-In, Firebase Auth state stream, Guest bypass mode, User Profile, Sign-Out gate. | **Complete** |
| **Home Dashboard** | Topic search, total publications count, citation metrics, active year insight, publication output line chart, top journals/authors, influential papers list. | **Complete** |
| **Journal & Source Analytics** | Ranked sources list, tabbed filtering (`All`, `Journals`, `Conferences`), search by source name/publisher, yearly output & citation trend charts, side-by-side journal comparison modal. | **Complete** |
| **Keyword Trends** | Monthly/topic rankings, frequency bar charts, 5-year keyword growth trend chart, related journals & top authors, matching publications list. | **Complete** |
| **Author Detail & Impact** | Author metrics (Total Works, Total Citations), 2-Tab view (`Top Publications` vs `Publications`), dynamic title search with search history, Open Access filter chips (`All`, `Open Access`, `Subscription`), real OpenAlex `counts_by_year` trend line chart. | **Complete** |
| **Profile & Cloud Export** | User identity, PDF report generation & upload to Firebase Storage, PDF layout view & copy link, Notification Center (FCM), theme switching (Light/Dark/System), bilingual localization (EN/VI), cache management. | **Complete** |
| **Admin Management** | Real-time Firebase Firestore user synchronization, active/blocked status toggles, admin role assignment, user search & status filtering, system analytics summary. | **Complete** |

### Technology Stack

```
+-----------------------------------------------------------------------+
|                           CLIENT LAYER                                |
|  Flutter 3.x / Dart 3.x | BLoC / Cubit | Clean Architecture | Material 3 |
+-----------------------------------------------------------------------+
                                   |
         +-------------------------+-------------------------+
         |                                                   |
         v                                                   v
+------------------------+                        +--------------------+
|     OPENALEX API       |                        |   FIREBASE CLOUD   |
| Publications / Authors |                        | Auth / Storage     |
| Journals / Keywords    |                        | Crashlytics / FCM  |
| Works & Trends Data    |                        | Analytics          |
+------------------------+                        +--------------------+
```

- **Framework**: Flutter (Dart 3)
- **State Management**: BLoC / Cubit (`flutter_bloc`), Provider
- **Architecture**: Clean Architecture (Domain, Data, Presentation) with Dependency Injection (`get_it`)
- **Data Persistence**: Hive (Local Cache & Search History)
- **Charts & Visualization**: `fl_chart` (Line charts, Bar charts, Sparklines)
- **Backend Services**: Firebase Authentication, Cloud Storage, Crashlytics, Cloud Messaging, Analytics, Remote Config
- **Code Quality**: `flutter analyze`, Patrol E2E testing framework, SonarQube Cloud

---

## 2. System Architecture & Component Design

The project strictly follows **Clean Architecture** principles, maintaining a strict separation of concerns between domain entities, data providers, state management, and UI screens.

```
       +-------------------------------------------------------+
       |                  PRESENTATION LAYER                   |
       |  Screens (Views) | Widgets | BLoC / Cubit Controllers  |
       +-------------------------------------------------------+
                                   |
                                   v
       +-------------------------------------------------------+
       |                     DOMAIN LAYER                      |
       |  Entities | Use Cases (Business Logic) | Contracts    |
       +-------------------------------------------------------+
                                   |
                                   v
       +-------------------------------------------------------+
       |                      DATA LAYER                       |
       | Models | Repositories | Data Sources (OpenAlex/Firebase)|
       +-------------------------------------------------------+
```

### Layer Responsibility Mapping

| Layer | Implemented Directory / Classes | Responsibility |
| :--- | :--- | :--- |
| **Domain** | `lib/features/*/domain/entities`, `usecases` | Enforces core business rules, entity models (`Paper`, `Journal`, `Author`, `UserPreferences`), and abstract repository interfaces. |
| **Data** | `lib/features/*/data/models`, `datasources`, `repositories` | Implements API calls, JSON parsing (`PaperModel`, `JournalModel`, `AuthorModel`), local Hive storage, and repository contracts. |
| **Presentation** | `lib/features/*/presentation/screens`, `blocs`, `widgets` | Renders Material 3 UI widgets, handles user interactions, manages reactive state transitions (`DashboardBloc`, `JournalsCubit`, `AuthBloc`, `ReportCubit`). |
| **Core Utilities** | `lib/core/network`, `firebase`, `theme`, `widgets` | Centralized `ApiClient` (with rate-limiting, retries, caching), Firebase service facades, app theme definitions, and shared chart widgets. |

### Codebase Organization

```
lib/
├── main.dart                          # Application entry point & dependency initialization
├── injection_container.dart           # Service locator (GetIt) registration
├── core/
│   ├── firebase/                      # Firebase service facades (Auth, Analytics, Crashlytics, Storage, FCM)
│   ├── network/                       # ApiClient with HTTP interceptors, rate-limiting & caching
│   ├── theme/                         # AppTheme, Color tokens, Typography
│   ├── usecases/                      # Base UseCase interface
│   └── widgets/                       # Reusable widgets (Trend line chart, Bar chart, Topic chart)
└── features/
    ├── admin/                         # Admin Dashboard & User Management
    │   ├── data/                      # Firebase UserService & User models
    │   ├── domain/                    # Admin repositories & entities
    │   └── presentation/              # Admin screens & Cubit state controllers
    ├── author/                        # Author Detail & Trend Analysis
    │   └── presentation/screens/      # AuthorDetailScreen (2-Tab view, search, trend chart)
    ├── home/                          # Home Research Dashboard
    │   ├── domain/ & data/            # Topic search & dashboard metrics
    │   └── presentation/              # HomeScreen, DashboardBloc, SearchCubit
    ├── journal/                       # Journals & Conferences Feature
    │   ├── domain/ & data/            # Journal & Paper models, remote data sources
    │   └── presentation/              # JournalScreen, JournalDetailScreen, PublicationDetailScreen
    ├── keywords/                      # Keyword Frequency & Trends
    │   ├── domain/ & data/            # Keyword models & remote endpoints
    │   └── presentation/              # KeywordsScreen, KeywordDetailScreen
    └── personalization/              # Authentication & User Profile
        ├── domain/ & data/            # UserPreferences, Local Data Sources
        └── presentation/              # LoginScreen, SetupScreen, ProfileScreen, AuthBloc
```

---

## 3. UI/UX Implementation & Feature Breakdown

### 3.1 Home Research Dashboard
- **Topic Search**: Search any research domain (e.g., *Machine Learning*, *Biomedical Science*, *Renewable Energy*).
- **Metric Cards**: Total Publications count, Average Citation Impact, Most Active Year, Top Journal, Top Author.
- **Publication Output Trend Chart**: Interactive line chart (`fl_chart`) illustrating annual paper production over recent years.
- **Influential Papers**: Card list of top-cited publications for the selected topic.

### 3.2 Journals & Conferences Analysis
- **Ranked Sources List**: Paginated list of top academic journals and proceedings.
- **Tab Filter**: Toggle between `All Sources`, `Journals` (e.g., *Nature*, *IEEE Access*), and `Conferences` (e.g., *CVPR*, *NeurIPS*).
- **Source Search**: Real-time debounced search bar filtering sources by title or publisher.
- **Journal Detail & Comparison**: Detailed view of impact metrics, citation trend charts, and side-by-side comparison modal.

### 3.3 Keyword Velocity & Frequency Dashboard
- **Top Keywords List**: Ranked keywords with total work counts and growth percentage indicators.
- **Frequency Bar Charts**: Visual breakdown of keyword occurrences across indexed papers.
- **5-Year Growth Trend**: Visual line chart showing keyword popularity evolution from 2021 to 2025.
- **Drill-down Keyword Detail**: Related journals, top publishing authors, and matching publications.

### 3.4 Author Detail & Impact Screen
- **Header Card & Stats**: Author avatar, display name, institution, total works, total citations.
- **2-Tab Layout**:
  - `Top Publications`: Displays author's most influential, highly-cited papers (sorted by `cited_by_count:desc`).
  - `Publications`: Displays recent papers with **dynamic title search** and **search history chips**.
- **Filter Chips**: Short, clean filter chips (`All`, `Open Access`, `Subscription`).
- **Real OpenAlex Trend Chart**: Line chart built directly from OpenAlex `counts_by_year` data showing annual publication output and citation impact.

### 3.5 Profile, Cloud PDF Export & Admin Panel
- **Profile Summary**: Displays Google account email, profile picture, and research field.
- **Analytics Export**: Generates a professional PDF report containing dashboard metrics, saved to local storage and uploaded securely to **Firebase Storage** (`reports/{userId}/...`).
- **Notification Center**: Real-time display of incoming FCM push notifications.
- **Admin Panel**: Accessible to admin accounts to view real-time user lists, block/unblock accounts, and assign admin privileges.

---

## 4. Firebase Integration Design & Analytics

Firebase provides the cloud backbone for identity, storage, diagnostics, and push messaging.

### Firebase Service Mapping

| Firebase Feature | Service Class | Operational Purpose |
| :--- | :--- | :--- |
| **Authentication** | `FirebaseAuthService` | Google Sign-In integration, OAuth credential exchange, auth state listener stream, sign-out handling. |
| **Analytics** | `FirebaseAnalyticsService` | Logging of user interaction events with sanitized parameters and failure guards. |
| **Cloud Storage** | `FirebaseStorageService` | Secure upload and download link generation for PDF analytics summary reports (`reports/{userId}/...`). |
| **Cloud Messaging** | `FirebaseMessagingService` | Handling foreground/background notification payloads and logging device FCM tokens. |
| **Crashlytics** | `FirebaseCrashlyticsService` | Automatic collection of fatal crashes, non-fatal handled error reporting, and test crash execution. |
| **Remote Config** | `FirebaseRemoteConfigService` | Dynamic fetching of application limits and feature flags. |

### Analytics Event Mapping Table

| Event Name | Parameters | Trigger Condition in App |
| :--- | :--- | :--- |
| `login` | `method` (`google` / `bypass`) | User completes Google Sign-In or guest entry. |
| `logout` | — | User taps Sign Out in Profile screen. |
| `search_topic` | `keyword`, `topic_count` | User executes a topic search on Home screen. |
| `view_publication` | `publication_title`, `publication_year` | User opens Publication Detail screen. |
| `view_journal` | `journal_name` | User opens Journal Detail screen. |
| `view_keyword` | `keyword` | User opens Keyword Detail screen. |
| `export_pdf` | `topic` | User taps "Export PDF Report" in Profile screen. |

---

## 5. Quality Assurance & Automated Testing Evidence

### 5.1 Unit & Integration Testing
The project features a comprehensive unit test suite written with `flutter_test` and `bloc_test`.

- **Total Test Cases**: 46
- **Test Suite Results**: **46 Passed, 0 Failed, 0 Skipped**

#### Key Tested Modules:
- `admin_accounts_test.dart`: Validates admin email detection logic.
- `app_theme_test.dart`: Validates Light & Dark theme token configurations.
- `admin_analytics_cubit_test.dart`: Tests Admin summary data loading & error states.
- `admin_users_cubit_test.dart`: Tests User search, status filtering, and block/unblock operations.
- `dashboard_bloc_test.dart`: Tests Home topic search, data mapping, and sync state transitions.
- `search_cubit_test.dart`: Tests search history loading, query selection, and filtering.
- `journals_cubit_and_model_test.dart`: Tests OpenAlex JSON parsing and conference/journal type filters.
- `user_preferences_test.dart`: Tests JSON serialization and role evaluation.
- `auth_bloc_test.dart`: Tests sign-in, sign-out, auth check, and bypass flows.
- `personalization_bloc_test.dart`: Tests preferences loading, saving, and random name generation.
- `report_cubit_test.dart`: Tests PDF report generation and Firebase Storage upload logic.

### 5.2 Static Code Analysis (`flutter analyze`)
Running `flutter analyze --no-fatal-warnings --no-fatal-infos` yields:
```
Analyzing Lab23_JournalTrendAnalysis...
No issues found! (ran in 2.9s)
```

### 5.3 SonarQube Cloud Code Quality Gate

| Metric | Observed Result | Standard Threshold | Evaluation |
| :--- | :--- | :--- | :--- |
| **Quality Gate** | **Passed** | Passed | **OK** |
| **Security Vulnerabilities** | **0 / A Rating** | 0 Vulnerabilities | **OK** |
| **Reliability Rating** | **A Rating** | A Rating | **OK** |
| **Maintainability Rating** | **A Rating** | A Rating | **OK** |
| **Code Coverage** | **99.2%** | > 80.0% | **OK** |
| **Code Duplication** | **1.1%** | < 3.0% | **OK** |

---

## 6. Challenges Encountered & Architectural Solutions

1. **OpenAlex API Rate Limiting & Response Latency**:
   - *Challenge*: Querying millions of records in real-time caused potential rate limits and slow response times.
   - *Solution*: Implemented a centralized `ApiClient` featuring 500ms request debouncing, in-memory caching, automatic retries with exponential backoff, and bounded page sizes (`per_page: 20`).

2. **Real-time Trend Chart Data Accuracy**:
   - *Challenge*: Local aggregation of search result subsets led to incomplete historical trend lines for prolific authors.
   - *Solution*: Integrated OpenAlex's native `counts_by_year` endpoint directly from `/authors/{author_id}`, supplying true 5-year historical work and citation metrics for the `fl_chart` widget.

3. **Firebase User Management Synchronization**:
   - *Challenge*: Admin user management required instant reflections of user blocks and role changes across devices.
   - *Solution*: Built `FirebaseUserService` with real-time Firestore stream listeners, broadcasting updates via `AdminUsersCubit` to reflect user status changes immediately.

4. **Multi-Tab Search UX Optimization**:
   - *Challenge*: Shared search controllers across tabs caused search queries to leak between "Top Publications" and "Publications".
   - *Solution*: Added `TabController` listeners in `AuthorDetailScreen` to reset search state when switching tabs, scoping search strictly to the "Publications" tab.

---

## 7. Lessons Learned & Future Roadmap

### Key Lessons Learned:
- **Clean Architecture Scalability**: Separating use cases and domain entities made adding new features (such as Admin Panel or Author 2-Tab view) straightforward without breaking existing UI logic.
- **Comprehensive Testing**: Maintaining 100% unit test pass rates prevented regression bugs during major UI refactoring.
- **User-Centric UX Design**: High-contrast typography, clear micro-animations (`flutter_animate`), and responsive filter chips significantly enhance researcher productivity.

### Future Enhancements Roadmap:
1. **Offline-First Synchronization**: Cache OpenAlex search results in Hive for full offline viewing.
2. **Advanced Citation Network Graph**: Add interactive node graphs showing co-author networks and citation links between publications.
3. **Automated Research Alerts**: Send FCM notifications when new highly-cited papers are published in a user's tracked concept field.

---

## 8. Conclusion

The **Journal Trend Analyzer** application successfully fulfills all functional, architectural, Firebase cloud integration, and quality requirements for the PRM393 course. Featuring Clean Architecture with BLoC, real-time OpenAlex data integration, 7 custom Firebase services, 46 passing unit tests, and 0 static analysis issues, the application stands as a production-ready, maintainable research analytics platform.
