# ✂️ TailorSync

**TailorSync** is an AI-powered, unified business management platform designed specifically for tailoring shops. It modernizes traditional tailoring workflows by replacing scattered customer data, paper measurements, and manual tracking with a sleek mobile interface and an intelligent AI/ML predictive backend.

---

## 🌟 Key Features

* **Intelligent Measurement Prediction:** Dual AI engines (Microsoft Foundry and a custom `.joblib` Scikit-Learn ML Model) automatically predict missing garment measurements based on minimal inputs (e.g., predicting a full shirt's measurements from just height and weight).
* **Smart Fabric Estimation:** Accurately estimates the required fabric length depending on the chosen style, fit, occasion, and the customer's exact measurements.
* **Complete Order Lifecycle Management:** Seamlessly tracks orders from `Pending` → `In Progress` → `Ready` → `Delivered`.
* **Automated Customer Notifications:** Automatically triggers professional email notifications alerting the customer exactly when their garment is `Ready` for collection.
* **Staff Task Assignment:** Assign specific garments to specific tailors, complete with email notifications for new tasks.
* **Real-time Dashboard Statistics:** Instantly visualizes shop performance, pending orders, and active staff assignments.

---

## 🏗 System Architecture

TailorSync uses a modern, scalable client-server architecture:

### 1. Frontend (Mobile App)
* **Framework:** Flutter (Dart)
* **State Management:** Riverpod
* **Routing:** GoRouter
* **Networking:** Dio (REST API consumption)
* **UI/UX:** Premium, responsive design with dynamic scanning/ripple loading animations for AI processes.

### 2. Backend (REST API)
* **Framework:** Python FastAPI
* **Database:** PostgreSQL (with SQLAlchemy ORM and Alembic migrations)
* **AI/ML Layer:** 
  * `ml_service.py`: Local Scikit-Learn inference via `.joblib` models.
  * `foundry_client.py`: Microsoft Foundry AI integration via cloud LLMs.
* **Background Tasks:** Threading for non-blocking SMTP email delivery.

### 3. Cloud & Deployment
* **Hosting:** Azure App Service (Backend)
* **CI/CD:** GitHub Actions (for automated testing and deployment)

---

## 👥 The 6-Member Engineering Team

This project was built collaboratively by a highly specialized 6-member engineering team. Each member owned a distinct domain:

1. **Backend & Azure Integration Engineer:** Built the FastAPI architecture, endpoints, database ORM bridges, and managed the Azure App Service deployment.
2. **Flutter Frontend Engineer:** Developed the sleek mobile UI, state management (Riverpod), responsive layouts, and integrated the Dio REST client.
3. **Database & Data Engineer:** Designed the PostgreSQL schema, complex relational mapping (Customers → Orders → Measurements), and enforced data integrity.
4. **AI & Machine Learning Engineer:** Trained the custom `.joblib` ML models and engineered the complex prompt instructions for the Microsoft Foundry AI endpoints.
5. **Business Logic & Order Management Engineer:** Implemented the core tailoring workflow, staff assignment systems, dashboard statistic calculations, and email notification triggers.
6. **QA, Integration & DevOps Engineer:** Managed Git/GitHub workflows, CI/CD pipelines, integration testing, and ensured the Python backend and Flutter frontend communicated flawlessly.

---

## 🚀 Getting Started

### Prerequisites
* **Flutter SDK:** `>=3.0.0 <4.0.0`
* **Python:** `3.10+`
* **PostgreSQL:** `14+`

### Backend Setup (FastAPI)
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Set up the environment variables (`.env`):
   ```env
   DATABASE_URL=postgresql://user:password@localhost/tailorsync
   FOUNDRY_ENDPOINT=<your_azure_ai_endpoint>
   FOUNDRY_API_KEY=<your_azure_ai_key>
   SMTP_USERNAME=<your_email>
   SMTP_PASSWORD=<your_app_password>
   ```
4. Run the server:
   ```bash
   uvicorn app.main:app --reload
   ```

### Frontend Setup (Flutter)
1. Navigate to the frontend directory:
   ```bash
   cd frontend/flutter_app
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

---

## 📄 License
This university project is proprietary and built strictly for academic presentation purposes.
