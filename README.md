# Flux

## 📱 App Name
**Flux**

## 🧩 Description
Flux is a mobile-first marketplace designed to connect skilled local service providers with clients in need.  
The app bridges the gap between freelancers and seekers by providing a secure platform for browsing portfolios, booking services, and handling payments, while empowering providers with professional profile management tools.

## 🔗 GitHub Repository
https://github.com/alialsaffarcodexals/Flux.git

---

## 👥 Group Members
- **Ali Alsaffar** (202301152) – Group Leader  
- **Faisal Alasfoor** (202304774)  
- **Ali Abdulla** (202300917)  
- **Ali Najaf** (202304083)  
- **Mohammed Taher** (202305225)  
- **Mohamed Alnooh** (202303672)  

---

## 🚀 Main Features

### **Feature 1: User Authentication & Dual-Role Management**
- **Developer:** Ali Alsaffar (202301152)  
- **Tester:** Faisal Alasfoor (202304774)  
- **Description:** Secure sign-up and login system that allows users to switch seamlessly between **Seeker** and **Provider** roles within a single account.

---

### **Feature 2: Verified Provider Profile & Skills Management**
- **Developer:** Ali Alsaffar (202301152)  
- **Tester:** Faisal Alasfoor (202304774)  
- **Description:** Providers can manage public profiles, add skills, and upload verification documents for admin review.

---

### **Feature 3: Portfolio Project Management**
- **Developer:** Mohamed Alnooh (202303672)  
- **Tester:** Ali Alsaffar (202301152)  
- **Description:** Providers can showcase their work by uploading project titles, descriptions, and images in a visual portfolio.

---

### **Feature 4: Service Request & Review Management**
- **Developer:** Mohamed Alnooh (202303672)  
- **Tester:** Ali Alsaffar (202301152)  
- **Description:** Seekers can track service requests (Pending, In Progress, Completed) and submit star ratings and reviews for completed services.

---

### **Feature 5: Admin Tools (Moderation & User Management)**
- **Developer:** Ali Abdulla (202300917)  
- **Tester:** Mohamed Alnooh (202303672)  
- **Description:** Admin dashboard for managing users (suspend/ban), moderating content, and managing service categories.

---

### **Feature 6: Activity & Notification Center**
- **Developer:** Ali Abdulla (202300917)  
- **Tester:** Mohamed Alnooh (202303672)  
- **Description:** Centralized hub displaying user activities, booking updates, and system notifications.

---

### **Feature 7: Booking & Scheduling Management**
- **Developer:** Faisal Alasfoor (202304774)  
- **Tester:** Ali Alsaffar (202301152)  
- **Description:** Users can request bookings by selecting available dates and times. Providers can accept or decline requests.  
Includes a **“My Bookings”** calendar view.

---

### **Feature 8: In-App Messaging**
- **Developer:** Faisal Alasfoor (202304774)  
- **Tester:** Ali Alsaffar (202301152)  
- **Description:** Real-time chat functionality enabling direct communication between Seekers and Providers.

---

### **Feature 9: Service Discovery & Search**
- **Developer:** Mohammed Taher (202305225)  
- **Tester:** Ali Najaf (202304083)  
- **Description:** Keyword search, category filtering, and sorting by **Price** or **Rating** to help users find suitable services.

---

### **Feature 10: Smart Recommendations**
- **Developer:** Mohammed Taher (202305225)  
- **Tester:** Ali Najaf (202304083)  
- **Description:** Personalized **“Recommended for You”** section based on user behavior and booking history.

---

### **Feature 11: History Tracking & Favorites**
- **Developer:** Ali Najaf (202304083)  
- **Tester:** Mohammed Taher (202305225)  
- **Description:** Allows users to view past services and save favorite providers for quick re-hiring.

---

### **Feature 12: Dispute Resolution Center**
- **Developer:** Ali Najaf (202304083)  
- **Tester:** Mohammed Taher (202305225)  
- **Description:** Reporting system that enables users to flag inappropriate behavior or service disputes for admin review.

---

## ✨ Extra Features
- **Availability Calendar with Conflict Management** (Ali Alsaffar)  
  Visual provider schedule using **CalendarKit**, with automatic conflict detection to prevent double bookings.

- **Service Package Builder** (Ali Alsaffar)  
  Allows providers to create fixed-price, ready-made service packages.

---

## 🎨 Design Changes & UI Updates

The following design and feature changes were applied after the initial project prototype and feature list, based on usability evaluation, implementation constraints, and time limitations.

---

## 🖥️ User Interface & Visual Design Changes

- **Home Screen Color Update:**  
  Adjusted the home page background colors to improve visual clarity and contrast while keeping the default black font for better readability.

- **Provider Profile Enhancement:**  
  Added a dedicated **“My Service Packages”** section to the Provider Profile to better organize and present provider offerings.

- **Profile Action Change:**  
  Replaced the **“Edit Public Profile”** button with **“Edit Profile Picture”** to better reflect the actual supported action.

- **Portfolio Button Logic Update:**  
  Changed the **Portfolio Edit** button to a **Delete** button to better align with the actual portfolio management logic.

---

## 🔁 Screen Flow & Navigation Changes

- **Booking Screen Flow Adjustment:**  
  Modified the booking screen flow due to the complexity of the original design, simplifying user interaction and reducing potential user confusion.

- **Services & Companies Information Page:**  
  The services and companies information page was simplified due to limited remaining development time.

---

## 🛠️ Admin Tools Design Changes

- **Skill Verification Enhancements:**  
  - Added a **Segmented Control** in the skill verification screen.  
  - Added a **description field** to provide clearer context during skill verification.

- **Category Management Improvements:**  
  Added functionality to **edit or delete categories** directly from the admin interface.

- **Reports Module Updates:**  
  - Added an additional segment to the segmented control in reports.  
  - Changed the **Alert button** functionality to better match the updated report workflow.

- **User Account Management Adjustments:**  
  - Removed the **status field** from user accounts, as there are no corresponding screens defined in the Figma design.  
  - Added a **Ban User** button to allow proper user moderation.

---

## ❓ Why These Changes Were Made

### **User Experience Improvements**
- To improve readability, simplify navigation, and reduce cognitive load.
- To align UI elements with actual functionality and user expectations.
- To create a clearer and more intuitive booking and profile management experience.

### **Technical & Implementation Constraints**
- Some features were adjusted due to platform limitations and implementation complexity.
- Firebase data structure and iOS implementation constraints required UI and flow simplifications.

### **Time Constraints**
- Certain screens and flows were simplified or adjusted due to limited remaining development time while ensuring core functionality was preserved.

---

## 📌 Summary

These design changes reflect an iterative development approach where the UI, screen flows, and admin tools were refined to balance usability, technical feasibility, and project time constraints while maintaining alignment with the project goals.



---

## 📦 Libraries & External Code
- **Firebase Firestore** – NoSQL database for users, services, bookings, and chats  
- **Firebase Authentication** – Secure login and registration  
- **CalendarKit** – Provider availability calendar UI  
- **IQKeyboardManager** – Automatic keyboard handling  
- **UIKit** – Core UI framework (Storyboard & Programmatic)

---

## ⚙️ Setup Instructions

### 1️⃣ Clone the Repository
```bash
git clone https://github.com/alialsaffarcodexals/Flux.git
cd Flux
