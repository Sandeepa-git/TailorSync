# ✂️ TailorSync - Comprehensive User Manual

Welcome to **TailorSync**, the ultimate AI-powered business management platform designed specifically for the tailoring industry. This comprehensive manual covers every module of the platform, from initial setup and customer management to advanced AI predictions, dynamic measurements, and workflow tracking.

---

## Table of Contents
1. [Getting Started & Authentication](#1-getting-started--authentication)
2. [Dashboard & Analytics](#2-dashboard--analytics)
3. [Customer Management](#3-customer-management)
4. [Measurement Templates (Dynamic Sizing)](#4-measurement-templates-dynamic-sizing)
5. [Creating a New Order (Wizard)](#5-creating-a-new-order-wizard)
6. [AI Predictions & Fabric Intelligence](#6-ai-predictions--fabric-intelligence)
7. [Order Management & Workflow](#7-order-management--workflow)
8. [Task Assignment (Staff & Tailors)](#8-task-assignment-staff--tailors)
9. [Automated Notifications](#9-automated-notifications)
10. [Pattern Viewer](#10-pattern-viewer)
11. [Profile & Settings](#11-profile--settings)

---

## 1. Getting Started & Authentication

TailorSync supports multiple users per tailor shop, divided into **Owners** (full administrative access) and **Staff** (task-specific access).

### 1.1 Create Account (Shop Setup)
If you are setting up TailorSync for your business for the first time:
- On the welcome screen, tap **"Create Account"** or **"Sign Up"**.
- Enter your **Shop Name**, **Owner Name**, **Email**, **Contact Number**, and a **Secure Password**.
- This registers your business and sets you up automatically as the **Owner**.

> **[Insert Screenshot 1: Create Account Registration Form]**

### 1.2 Login & Role Access
- Enter your registered email and password on the **Login Screen**.
- The system automatically detects your role (`OWNER` or `STAFF`) and customizes the user interface accordingly. Staff members will see a streamlined view focused on their tasks.

> **[Insert Screenshot 2: Login Screen]**

---

## 2. Dashboard & Analytics

The Dashboard is your command center, providing real-time insights into your shop's daily operations.

- **Key Metrics:** Instantly view counts for Active Orders, Pending Orders, and Completed Orders.
- **Staff Workload:** Owners can see how many tasks are currently assigned to each staff member to balance the workload.
- **Recent Activity:** A quick-access list of the most recently updated orders requiring attention.

> **[Insert Screenshot 3: Main Dashboard with Analytics and Metrics]**

---

## 3. Customer Management

Maintain a secure, digital ledger of all your clients, ensuring you never lose a measurement book or contact detail again.

### 3.1 Adding a Customer
- Navigate to the **Customers** tab from the main menu.
- Tap the **"Add Customer"** button.
- Fill in the **Name**, **Email**, and **Phone Number**. You can also add specific **Notes** about their general preferences.
- Save to add them to your centralized database.

> **[Insert Screenshot 4: Add New Customer Form]**

### 3.2 Viewing Customer History
- Tap on any customer profile in your directory to view their contact information, past orders, preferred fabrics, and historical measurements.

> **[Insert Screenshot 5: Customer Profile & Order History View]**

---

## 4. Measurement Templates (Dynamic Sizing)

TailorSync abandons rigid measurement fields. Instead, it allows you to define custom measurement templates depending on the exact garment.

- **Managing Templates:** Owners can create unlimited templates for different categories (e.g., "Men's Shirt", "Women's 3-Piece Suit").
- **Adding Fields:** Inside a template, you can add specific measurement fields (e.g., "Sleeve Length", "Chest", "Inseam", "Neck") and set the required units (cm or inches).
- When taking measurements for a new order, the app will dynamically load the correct template configuration.

> **[Insert Screenshot 6: Measurement Template Builder]**

---

## 5. Creating a New Order (Wizard)

The New Order Wizard is a streamlined, multi-step process designed to record complex customer requests quickly and accurately.

### Step 1: Select Customer
Search for and select an existing customer from your directory to link the order to their profile.

> **[Insert Screenshot 7: New Order Wizard - Select Customer Screen]**

### Step 2: Order Details
- **Garment Type:** Select the type of garment (e.g., Shirt, Trouser, Suit).
- **Occasion:** Define the event intended for the garment (e.g., Wedding, Formal, Casual).
- **Priority:** Set the production priority level (Low, Medium, High).
- **Due Date:** Select the expected delivery or fitting date via the calendar.

> **[Insert Screenshot 8: New Order Wizard - Order Details Form]**

### Step 3: Record Measurements
- The app automatically loads the specific measurement template for the selected Garment Type.
- You can manually enter values, or use the **AI Prediction** feature to speed up the process (see Section 6).

> **[Insert Screenshot 9: New Order Wizard - Measurement Entry Screen]**

---

## 6. AI Predictions & Fabric Intelligence

TailorSync features a powerful Dual-Engine AI system (utilizing both Cloud LLMs and Local Machine Learning) to dramatically speed up order creation and reduce errors.

### 6.1 AI Measurement Prediction
Save immense time by letting the AI predict a full measurement profile based on minimal inputs (such as Height and Weight).
- Enter basic physical details and tap the **"Predict Measurements"** button.
- The AI will intelligently fill the remaining empty fields instantly. You can always manually adjust or override any predicted values if they need fine-tuning.

> **[Insert Screenshot 10: AI Measurement Prediction in Action (showing auto-filled data)]**

### 6.2 Fabric Estimation
Based on the customer's size and the specific garment type chosen, the AI automatically calculates the exact **required fabric length (in meters)**. This prevents under-ordering and minimizes material waste.

### 6.3 Fabric Recommendations
The AI acts as a digital consultant, suggesting optimal fabric types from the catalog (e.g., Premium Cotton, Linen, Wool) based on the garment style, seasonality, and the specified occasion.

> **[Insert Screenshot 11: AI Fabric Estimation and AI Fabric Recommendations Screen]**

---

## 7. Order Management & Workflow

Track the precise lifecycle of every garment as it moves through your workshop.

### 7.1 Status Tracking
Orders transition through a highly detailed workflow pipeline:
`Order Received` ➔ `Cutting` ➔ `Sewing` ➔ `Fitting` ➔ `Quality Check` ➔ `Ready` ➔ `Delivered`

- Tap on an order to update its current status.
- Add **Tailor Remarks** (internal production notes) or **Customer Instructions** (specific style requests from the client, such as "French Cuffs").

> **[Insert Screenshot 12: Order Status Update and Details Screen]**

### 7.2 Internal Notes
Staff and Owners can leave collaborative, time-stamped notes on an order (e.g., "Customer called to change collar style before cutting"), keeping everyone aligned.

---

## 8. Task Assignment (Staff & Tailors)

Distribute work efficiently among your tailoring team to maximize productivity.

### 8.1 Assigning Roles (For Owners)
Owners can assign specific staff members to distinct production roles on a single order. For example:
- **Tailor A:** Assigned to the "Cutting" phase.
- **Tailor B:** Assigned to the "Sewing/Stitching" phase.

> **[Insert Screenshot 13: Staff Assignment Interface showing role distribution]**

### 8.2 Staff Task List (For Tailors)
Staff members have a specialized **Tasks** view on their app. This screen shows *only* the specific garments and roles assigned to them, ensuring they stay focused on their immediate production queue without getting overwhelmed.

> **[Insert Screenshot 14: Staff Personalized Task Queue]**

---

## 9. Automated Notifications

TailorSync eliminates the need to manually call or text customers when their clothes are finished, improving customer service and saving time.
- When a staff member updates an order's status to **`Ready`**, the system automatically dispatches a professionally formatted email to the customer notifying them that their garment is ready for pickup or fitting.
- The Order History log permanently records when the notification was successfully sent.

> **[Insert Screenshot 15: Automated Email Notification Status in Order History]**

---

## 10. Pattern Viewer

*(Advanced Feature)* TailorSync provides a digital interface for tailors to view specific pattern guidelines or structural designs related to the selected garment type. This modernizes the cutting phase and reduces reliance on easily lost physical paper patterns.

> **[Insert Screenshot 16: Digital Pattern Viewer Interface]**

---

## 11. Profile & Settings

Manage your personal account, business profile, and application preferences.
- **Account:** Update your Full Name, Phone Number, and securely reset your Password.
- **Business Details (Owners only):** Update the shop's physical address and primary contact info.
- **UI Themes:** Toggle between visual themes (e.g., Dark Mode vs. Light Mode) to suit your workshop's lighting conditions.

> **[Insert Screenshot 17: Profile and System Settings Screen]**

---

*Thank you for choosing TailorSync to modernize your tailoring business!*
