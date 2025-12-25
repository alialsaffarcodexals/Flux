Markdown

# Flux - Local Skills Exchange Platform (iOS)

Welcome to the official repository for **Flux**. This document outlines our project structure, architecture, and team responsibilities. Please read this carefully to ensure we all code in the same direction.

---

## 🏗 Project Architecture: MVVM (Model-View-ViewModel)

To keep our code clean and scalable, we are moving away from standard MVC to **MVVM**. This prevents "Massive View Controllers" and makes testing easier.

### 1. Model (The Data)
* **Location:** `Flux/Models`
* **What is it?** Simple Swift `structs` that define our data (e.g., `User`, `Service`).
* **Rule:** No logic, no UI code. Just data.

### 2. View (The UI)
* **Location:** `Storyboards` and `ViewControllers` inside `Features`.
* **What is it?** The visual elements.
* **Rule:** The ViewController should be "dumb". It only handles UI events (button taps, updating labels). It **never** talks to Firebase directly. It asks the ViewModel to do the work.

### 3. ViewModel (The Brains)
* **Location:** `ViewModels` inside `Features`.
* **What is it?** The logic layer.
* **Rule:** This is where you write functions like `performLogin()`, `fetchServices()`, or `calculateTotal()`. It talks to the **Services** (Backend) and updates the View.

---

## 📂 Project Directory Structure

We have organized the app by **Feature**, not by file type. This allows every member to work in their own folder without causing conflicts.

```text
Flux
├── 📂 App (System Files)
│   ├── AppDelegate.swift          // App launch lifecycle
│   ├── SceneDelegate.swift        // Window & Scene management
│
├── 📂 Resources (Assets & Config)
│   ├── Assets.xcassets            // All Images, Colors, and Icons
│   ├── LaunchScreen.storyboard    // The Splash Screen
│   ├── Info.plist                 // App Permissions (Camera, Location)
│   └── GoogleService-Info.plist   // Firebase Configuration File
│
├── 📂 Models (Data Layer - Shared by Everyone)
│   ├── User.swift                 // [All] ID, Role, Name, Bio struct
│   ├── Service.swift              // [Mohammed Taher] Title, Price, Category
│   ├── Booking.swift              // [Faisal Alasfoor] Date, Status, IDs
│   ├── Project.swift              // [Mohamed Alnooh] Portfolio Item struct
│   ├── Review.swift               // [Mohamed Alnooh] Rating & Comment
│   ├── Report.swift               // [Ali Abdulla] Dispute details
│   └── Notification.swift         // [Ali Abdulla] Alert details
│
├── 📂 Services (Backend Managers - The "Heavy Lifters")
│   ├── AuthManager.swift          // Handles Login, Sign Up, Sign Out
│   ├── FirestoreManager.swift     // General Database Reading/Writing
│   ├── StorageManager.swift       // Handles Image Uploading to Storage
│   └── AdminService.swift         // Special Admin-only database functions
│
├── 📂 Features (The Main Application Screens)
│   │
│   │   // ─── GROUP 1: Identity & Access ───
│   ├── 📂 Authentication (Feature 1)
│   │   ├── 📂 Storyboards
│   │   │   └── Auth.storyboard           // Welcome, Login, Sign Up UI
│   │   ├── 📂 ViewControllers
│   │   │   ├── WelcomeViewController.swift
│   │   │   ├── LoginViewController.swift
│   │   │   ├── RoleSelectionViewController.swift
│   │   │   └── SignUpViewController.swift
│   │   └── 📂 ViewModels
│   │       └── AuthViewModel.swift       // Logic: Calls AuthManager
│   │
│   ├── 📂 AccountSettings (Feature 1 Extended)
│   │   ├── 📂 Storyboards
│   │   │   └── Settings.storyboard       // Change Email/Pass/Phone UI
│   │   ├── 📂 ViewControllers
│   │   │   ├── SettingsMainViewController.swift
│   │   │   ├── ChangeEmailViewController.swift
│   │   │   └── ChangePhoneViewController.swift
│   │   └── 📂 ViewModels
│   │       └── SettingsViewModel.swift
│   │
│   │   // ─── GROUP 2: Provider Specifics ───
│   ├── 📂 ProviderProfile (Feature 2)
│   │   ├── 📂 Storyboards
│   │   │   └── ProviderProfile.storyboard // Bio, Stats, Verification Status
│   │   ├── 📂 ViewControllers
│   │   │   ├── ProviderMainProfileVC.swift
│   │   │   ├── ManageSkillsViewController.swift
│   │   │   └── AddSkillViewController.swift
│   │   └── 📂 ViewModels
│   │       └── ProviderProfileViewModel.swift
│   │
│   ├── 📂 Portfolio (Feature 3)
│   │   ├── 📂 Storyboards
│   │   │   └── Portfolio.storyboard      // Grid of previous work
│   │   ├── 📂 ViewControllers
│   │   │   ├── PortfolioListViewController.swift
│   │   │   └── AddProjectViewController.swift
│   │   └── 📂 ViewModels
│   │       └── PortfolioViewModel.swift
│   │
│   │   // ─── GROUP 3: Discovery (Seeker Side) ───
│   ├── 📂 HomeDiscovery (Feature 9 & 10)
│   │   ├── 📂 Storyboards
│   │   │   └── Home.storyboard           // Search, Filters, Smart Recs
│   │   ├── 📂 ViewControllers
│   │   │   ├── HomeFeedViewController.swift
│   │   │   ├── FilterModalViewController.swift
│   │   │   └── ServiceDetailsViewController.swift // The "Gig" Page
│   │   └── 📂 ViewModels
│   │       ├── HomeViewModel.swift
│   │       └── ServiceDetailsViewModel.swift
│   │
│   │   // ─── GROUP 4: Actions & Operations ───
│   ├── 📂 BookingFlow (Feature 7)
│   │   ├── 📂 Storyboards
│   │   │   └── Booking.storyboard        // Calendar & Confirmation
│   │   ├── 📂 ViewControllers
│   │   │   ├── RequestBookingViewController.swift
│   │   │   └── BookingConfirmationVC.swift
│   │   └── 📂 ViewModels
│   │       └── BookingViewModel.swift
│   │
│   ├── 📂 MyRequests (Feature 4)
│   │   ├── 📂 Storyboards
│   │   │   └── Requests.storyboard       // Tabs: Pending, Progress, Done
│   │   ├── 📂 ViewControllers
│   │   │   ├── SeekerRequestListVC.swift
│   │   │   ├── LeaveReviewViewController.swift
│   │   │   └── ReviewSubmittedViewController.swift
│   │   └── 📂 ViewModels
│   │       └── RequestListViewModel.swift
│   │
│   ├── 📂 Messaging (Feature 8)
│   │   ├── 📂 Storyboards
│   │   │   └── Chat.storyboard           // Chat List & Chat Room
│   │   ├── 📂 ViewControllers
│   │   │   ├── ChatListViewController.swift
│   │   │   └── ChatRoomViewController.swift
│   │   └── 📂 ViewModels
│   │       └── ChatViewModel.swift
│   │
│   │   // ─── GROUP 5: User Records & Safety ───
│   ├── 📂 HistoryAndFavorites (Feature 11)
│   │   ├── 📂 Storyboards
│   │   │   └── History.storyboard        // Past bookings list
│   │   ├── 📂 ViewControllers
│   │   │   ├── ServiceHistoryViewController.swift
│   │   │   └── FavoritesViewController.swift
│   │   └── 📂 ViewModels
│   │       └── HistoryViewModel.swift
│   │
│   ├── 📂 SupportCenter (Feature 12)
│   │   ├── 📂 Storyboards
│   │   │   └── Dispute.storyboard        // Reporting forms
│   │   ├── 📂 ViewControllers
│   │   │   ├── ReportUserViewController.swift
│   │   └── 📂 ViewModels
│   │       └── ReportViewModel.swift
│   │
│   │   // ─── GROUP 6: Administration ───
│   ├── 📂 AdminDashboard (Feature 5)
│   │   ├── 📂 Storyboards
│   │   │   └── Admin.storyboard          // Ban users, Manage Categories
│   │   ├── 📂 ViewControllers
│   │   │   ├── AdminHomeViewController.swift
│   │   │   ├── UserManagementViewController.swift
│   │   │   └── CategoryManagerViewController.swift
│   │   └── 📂 ViewModels
│   │       └── AdminViewModel.swift
│   │
│   └── 📂 Notifications (Feature 6)
│       ├── 📂 Storyboards
│       │   └── Activity.storyboard       // Notification List
│       ├── 📂 ViewControllers
│       │   └── NotificationCenterViewController.swift
│       └── 📂 ViewModels
│           └── NotificationViewModel.swift
│
└── 📂 Utilities (Helpers - The "Tools")
    ├── Extensions.swift           // Custom code (e.g., Round Buttons)
    ├── Constants.swift            // Shared colors, API Keys, Strings
    └── Validator.swift            // Email/Password validation logic
👥 Team Assignments & Responsibilities
Each member owns specific folders. Do not touch another member's folder without communicating first.

👤 Ali Alsaffar (Team Lead)

Feature 1: User Authentication. Login, Sign Up, Role Selection (Seeker/Provider).


Feature 1 (Extended): Account Management. Changing Email, Password, and Phone Number.


Feature 2: Provider Profile. Managing Skills, Verification Status, and Bio.


Folders: Authentication, AccountSettings, ProviderProfile.

👤 Mohamed Alnooh

Feature 3: Portfolio Management. Uploading project images, titles, and descriptions.



Feature 4: Requests & Reviews. Tracking service status (Pending/In-Progress/Completed) and leaving reviews.


Folders: Portfolio, MyRequests.

👤 Mohammed Taher

Feature 9: Service Discovery. Search bar, Categories, Filtering (Price/Distance).



Feature 10: Smart Recommendations. The "Recommended for you" strip and featured services.



Shared Responsibility: ServiceDetailsViewController (The page that shows gig details).

Folders: HomeDiscovery.

👤 Faisal Alasfoor

Feature 7: Booking Management. The calendar picker, selecting time slots, and confirming the booking request.



Feature 8: In-App Messaging. Chat interface between Seeker and Provider.


Folders: BookingFlow, Messaging.

👤 Ali Abdulla

Feature 5: Admin Tools. User Management (Ban/Suspend), Category Management (Add/Edit Categories), Moderation.



Feature 6: Notification Center. Activity feed and system alerts.


Folders: AdminDashboard, Notifications.

👤 Ali Najaf

Feature 11: History & Favorites. Viewing past services and saving favorite providers.



Feature 12: Dispute Resolution. Reporting users/providers for violations.


Folders: HistoryAndFavorites, SupportCenter.

⚠️ Important Workflow Rules
Branching: Always create a branch for your feature.

git checkout -b feature/your-feature-name

No Logic in ViewControllers: If you are writing a Firebase call inside a ViewController, STOP. Move it to the ViewModel.

UI Updates: All UI updates must happen on the Main Thread.

Conflicts: If you touch Assets.xcassets or project.pbxproj, communicate with the team before pushing.

Let's build Flux! 🚀
