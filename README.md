# ✂️ TailorSync - Comprehensive Project Report

<div align="center">
  <h3>An AI-Powered Unified Business Management Platform for the Tailoring Industry</h3>
  <p><i>A Final Year University Software Engineering Project</i></p>
</div>

---

## 📖 Table of Contents
1. [Executive Summary & Problem Statement](#1-executive-summary--problem-statement)
2. [The Solution: TailorSync](#2-the-solution-tailorsync)
3. [System Architecture](#3-system-architecture)
4. [Technology Stack](#4-technology-stack)
5. [The Dual AI & Machine Learning Engine](#5-the-dual-ai--machine-learning-engine)
6. [Core Modules & Features](#6-core-modules--features)
7. [Database Schema & Architecture](#7-database-schema--architecture)
8. [UI/UX & Design Philosophy](#8-uiux--design-philosophy)
9. [Setup & Installation Instructions](#9-setup--installation-instructions)
10. [License & Academic Integrity](#10-license--academic-integrity)

---

## 1. Executive Summary & Problem Statement

### The Problem
The traditional tailoring industry operates heavily on manual, paper-based processes. Customer measurements are recorded in physical ledgers, order statuses are tracked mentally or via chaotic whiteboards, and estimating fabric requirements relies entirely on individual tailor experience. This leads to:
* **Lost or misplaced customer data** and measurements.
* **Inaccurate fabric estimations** leading to material waste or shortages.
* **Inefficient workflow tracking** causing delayed orders and unhappy customers.
* **Lack of business insights** regarding shop performance and staff productivity.

### The Objective
To digitize, streamline, and intelligently enhance the tailoring lifecycle through an integrated mobile application and cloud-based AI backend, allowing tailor shop owners and staff to manage their business seamlessly from any device.

---

## 2. The Solution: TailorSync

**TailorSync** is a unified business management platform that completely modernizes the tailoring workflow. It serves as a central hub for customer CRM, order tracking, staff task assignment, and intelligent predictions. 

By integrating **Machine Learning** and **Cloud AI**, TailorSync can accurately predict a customer's full measurement profile based on minimal data (e.g., height and weight) and intelligently estimate the exact fabric yardage required for specific garment styles, significantly reducing human error and waste.

---

## 3. System Architecture

TailorSync employs a modern, scalable, and decoupled **Client-Server Architecture**.

* **Presentation Layer (Frontend):** A cross-platform Flutter application providing a responsive, native-like experience for both shop owners and staff.
* **Application Layer (Backend):** A high-performance Python FastAPI REST API that handles business logic, data validation, authentication, and orchestrates calls to external AI services.
* **Data Layer:** A relational PostgreSQL database ensuring ACID compliance and data integrity across complex Customer ↔ Order ↔ Measurement relationships.
* **AI/ML Layer:** A hybrid predictive engine utilizing both local `.joblib` Scikit-Learn models and cloud-based Microsoft Foundry LLMs.
* **Infrastructure:** Cloud-hosted on Azure App Services with continuous integration via GitHub Actions.

---

## 4. Technology Stack

### Frontend
* **Framework:** Flutter (Dart)
* **State Management:** Riverpod (Predictable, compile-safe state)
* **Routing:** GoRouter (Declarative URL-based navigation)
* **Networking:** Dio (Advanced HTTP client with interceptors)
* **Design System:** Custom glassmorphism UI with Google Fonts (Outfit, Inter)

### Backend
* **Framework:** Python FastAPI (Asynchronous, highly concurrent)
* **Database ORM:** SQLAlchemy (Declarative data models)
* **Migrations:** Alembic
* **Security:** JWT (JSON Web Tokens), Passlib (Bcrypt hashing)
* **Validation:** Pydantic

### AI & Machine Learning
* **Cloud AI:** Microsoft Foundry (Azure OpenAI/LLM endpoints)
* **Local ML:** Scikit-Learn (KMeans clustering, Joblib model serialization)
* **Data Processing:** Pandas, NumPy

### Infrastructure & DevOps
* **Database Hosting:** PostgreSQL
* **Backend Hosting:** Microsoft Azure App Service
* **Version Control:** Git & GitHub
* **CI/CD:** GitHub Actions

---

## 5. The Dual AI & Machine Learning Engine

TailorSync stands out by utilizing a **Dual-Engine Predictive Architecture** to handle measurement and fabric predictions.

### Engine 1: Microsoft Foundry (Cloud AI)
* **Use Case:** General, highly contextual predictions and natural language understanding.
* **Implementation:** The FastAPI backend securely communicates with Microsoft Foundry via REST. By injecting a tailored "System Prompt" alongside specific garment context, the AI accurately estimates measurements and fabric requirements based on global tailoring standards.
* **Handling:** Responses are parsed via advanced Regex processing to extract clean JSON, ensuring the Flutter frontend never crashes on malformed AI text.

### Engine 2: Custom Machine Learning (Local ML)
* **Use Case:** Strictly restricted, highly accurate predictions based purely on historical local data.
* **Implementation:** Utilizing `MeasurementPredictor` (`measurement_predictor.py`), the system loads pre-trained `.joblib` models using Scikit-Learn.
* **Algorithm:** Feature engineering transforms partial measurements (e.g., Height + Shoulder) into a NumPy array, which is then processed through an imputation/regression model (e.g., KMeans/RandomForest) to accurately predict the remaining missing variables based on the shop's actual historical tailoring dataset.

---

## 6. Core Modules & Features

1. **Dashboard & Analytics:** Real-time visibility into active orders, pending orders, completed orders, and staff workload.
2. **New Order Wizard:** A seamless, multi-step Flutter form capturing Customer Info → Garment Type → AI Measurements → Fabric Preferences.
3. **AI Recommendations:** Instantly fills in missing measurements based on AI predictions, saving the tailor immense time.
4. **Task Assignment:** Shop owners can assign specific garments to specific staff members (e.g., assigning a shirt to "Tailor A" and trousers to "Tailor B").
5. **Automated Notifications:** When a staff member updates a garment status to "Ready", the backend automatically fires an email to the customer using SMTP.
6. **Dynamic Editing:** AI predictions can be manually overridden via a custom bottom-sheet UI.

---

## 7. Database Schema & Architecture

The system utilizes a heavily normalized relational database to prevent data anomalies:
* **Users Table:** Handles both `OWNER` and `STAFF` roles with RBAC (Role-Based Access Control).
* **Customers Table:** Stores contact information and historical preferences.
* **Orders Table:** The central aggregate root tracking status, priority, due dates, and assigning foreign keys to Customers.
* **Measurements Table:** A dynamic key-value storage system allowing flexible measurements for different garment types (e.g., Shirts vs. Trousers) without requiring database schema alterations.
* **Staff Assignments Table:** A many-to-many resolution table linking `Users(STAFF)` to specific `Orders`.

---

## 8. UI/UX & Design Philosophy

The application rejects standard, boring material templates in favor of a **Premium, Modern Aesthetic**:
* **Animations:** Features custom "scanning" and "pulsing ripple" animations during AI loading states to provide visual feedback and delight the user.
* **Typography:** Uses Google's `Outfit` (for bold headers) and `Inter` (for highly readable body text).
* **Color Palette:** Deep Indigo and Teal gradients are used to differentiate between Cloud AI and Custom ML operations, reinforcing the brand identity.
* **Navigation:** Employs a persistent Bottom Navigation Bar combined with robust stack-based routing for sub-screens.

---

## 9. Setup & Installation Instructions

### Prerequisites
* **Flutter SDK:** `>=3.0.0`
* **Python:** `>=3.10`
* **PostgreSQL:** `>=14.0`

### Backend Initialization (FastAPI)
1. Clone the repository and navigate to the backend:
   ```bash
   cd backend
   ```
2. Create a virtual environment and install dependencies:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```
3. Configure the environment variables in a `.env` file:
   ```env
   DATABASE_URL=postgresql://postgres:password@localhost/tailorsync
   FOUNDRY_ENDPOINT=https://your-microsoft-foundry-endpoint.com
   FOUNDRY_API_KEY=your_secure_api_key
   SMTP_SERVER=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USERNAME=your_business_email@gmail.com
   SMTP_PASSWORD=your_app_specific_password
   ```
4. Run database migrations:
   ```bash
   alembic upgrade head
   ```
5. Start the API server:
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```

### Frontend Initialization (Flutter)
1. Navigate to the frontend directory:
   ```bash
   cd frontend/flutter_app
   ```
2. Fetch Dart packages:
   ```bash
   flutter pub get
   ```
3. Run the application on an emulator or physical device:
   ```bash
   flutter run
   ```
*(Note: Ensure the `API_BASE_URL` in the Flutter configuration points to your local machine's IP address if testing on a physical device, rather than `localhost`).*

---

## 10. License & Academic Integrity

This software system was developed as a Third Year University Project. All source code, machine learning models, and architectural designs are proprietary to the student engineering team. 

**Academic Declaration:** We hereby declare that this project is our own original work. Where external libraries, open-source frameworks, or cloud APIs have been utilized, they have been properly cited and implemented according to their respective open-source licenses.
