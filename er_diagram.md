# TailorSync Database Schema & Entity Relationships (Text-Based)

This document describes the database schema, table structures, and relationships for the **TailorSync** application in a descriptive, text-based format.

---

## 1. core.business (Table: `businesses`)
Represents a tailoring shop or tenant.

* **Attributes:**
  * `id` (Integer, Primary Key) - Unique identifier for the business.
  * `name` (String, Not Null) - Name of the tailoring shop.
  * `address` (String, Nullable) - Business physical address.
  * `phone` (String, Nullable) - Business contact number.
* **Relationships:**
  * **One-to-Many** with `users` (A business has multiple staff/owners).
  * **One-to-Many** with `customers` (A business serves multiple registered customers).
  * **One-to-Many** with `measurement_templates` (A business can define its own measurement templates).

---

## 2. core.user (Table: `users`)
Represents users of the platform (owners, tailors, and staff).

* **Attributes:**
  * `id` (Integer, Primary Key) - Unique identifier for the user.
  * `email` (String, Unique, Index, Not Null) - User's login email.
  * `phone` (String, Nullable) - User's phone number.
  * `full_name` (String, Nullable) - User's full name.
  * `hashed_password` (String, Not Null) - Hashed password for authentication.
  * `is_active` (Boolean, Default: True, Not Null) - Active status of the user account.
  * `role` (Enum [OWNER, STAFF], Default: STAFF) - System role mapping privileges.
  * `business_id` (Integer, Foreign Key to `businesses.id`) - Associated business.
  * `created_at` (DateTime, Not Null) - Timestamp when user was created.
  * `updated_at` (DateTime, Not Null) - Timestamp when user details were last updated.
* **Relationships:**
  * **Many-to-One** with `businesses` (Many users belong to one business).
  * **One-to-Many** with `staff_assignments` (A tailor/staff is assigned to work on multiple orders).
  * **One-to-Many** with `notes` (A user can write multiple internal notes).

---

## 3. core.customer (Table: `customers`)
Represents clients registered under a business.

* **Attributes:**
  * `id` (Integer, Primary Key) - Unique identifier for the customer.
  * `business_id` (Integer, Foreign Key to `businesses.id`) - Associated business.
  * `name` (String, Not Null) - Customer's name.
  * `email` (String, Index, Nullable) - Customer's email.
  * `phone` (String, Index, Nullable) - Customer's phone number.
  * `notes` (Text, Nullable) - Custom general descriptions/notes about this customer.
  * `created_at` (DateTime) - Timestamp when customer profile was created.
* **Relationships:**
  * **Many-to-One** with `businesses` (Many customers are served by one business).
  * **One-to-Many** with `orders` (A customer can place multiple orders).
  * **One-to-Many** with `customer_measurements` (A customer has multiple dynamic measurement records).
  * **One-to-Many** with `measurements` (A customer has multiple legacy measurements).

---

## 4. core.order (Table: `orders`)
Represents a tailoring job order placed by a customer.

* **Attributes:**
  * `id` (Integer, Primary Key) - Unique identifier for the order.
  * `business_id` (Integer, Foreign Key to `businesses.id`) - Associated business.
  * `customer_id` (Integer, Foreign Key to `customers.id`) - Customer who placed the order.
  * `garment_type` (String, Not Null) - Category of garment (e.g., Shirt, Trouser, Suit).
  * `occasion` (String, Nullable) - Occasion the garment is intended for (e.g., Wedding, Casual).
  * `status` (Enum [Order Received, Cutting, Sewing, Fitting, Quality Check, Ready, Delivered], Default: Order Received) - Current processing state.
  * `priority` (Enum [Low, Medium, High], Default: Medium) - Priority level of the order.
  * `due_date` (DateTime, Nullable) - Scheduled delivery/fitting date.
  * `completed_at` (DateTime, Nullable) - Completion date.
  * `created_at` (DateTime, Default: Current UTC Time) - Order placement date.
  * `tailor_remarks` (String, Nullable) - Custom production notes from the tailor.
  * `customer_instructions` (String, Nullable) - Specific style guidelines or custom requests from the client.
* **Relationships:**
  * **Many-to-One** with `customers` (Many orders belong to one customer).
  * **One-to-Many** with `customer_measurements` (An order is tied to multiple dynamic customer measurements).
  * **One-to-Many** with `measurements` (An order can link to legacy measurement tables).
  * **One-to-Many** with `staff_assignments` (An order is assigned to staff members for roles like cutting/sewing).
  * **One-to-Many** with `notes` (An order can have internal comments).
  * **One-to-Many** with `ai_predictions` (An order can have associated AI prediction history).
  * **One-to-Many** with `fabric_estimations` (Fabric length requirements calculated for this order).
  * **One-to-Many** with `fabric_recommendations` (AI fabric recommendations generated for the order).

---

## 5. measurement.customer_measurement (Table: `customer_measurements`)
Holds individual values for dynamic measurements.

* **Attributes:**
  * `id` (Integer, Primary Key) - Unique identifier.
  * `customer_id` (Integer, Foreign Key to `customers.id`, Not Null) - Target customer.
  * `order_id` (Integer, Foreign Key to `orders.id`, Nullable) - Optional link to a specific order.
  * `field_id` (Integer, Foreign Key to `measurement_fields.id`, Not Null) - Associated template field.
  * `value` (Float, Nullable) - Measured numeric size (e.g., length, width).
  * `recorded_at` (DateTime, Default: Current UTC Time)
* **Relationships:**
  * **Many-to-One** with `customers` (Many measurements belong to one customer).
  * **Many-to-One** with `orders` (Many measurements can be linked to one order).
  * **Many-to-One** with `measurement_fields` (A measurement maps back to a schema definition).

---

## 6. measurement.measurement (Table: `measurements`)
Legacy table holding static core body measurements.

* **Attributes:**
  * `id` (Integer, Primary Key)
  * `customer_id` (Integer, Foreign Key to `customers.id`, Not Null) - Target customer.
  * `order_id` (Integer, Foreign Key to `orders.id`, Nullable) - Associated order.
  * `height` (Float) - Height in cm.
  * `weight` (Float) - Weight in kg.
  * `chest` (Float) - Chest size in cm.
  * `waist` (Float) - Waist size in cm.
  * `hip` (Float) - Hip size in cm.
  * `shoulder` (Float) - Shoulder width in cm.
  * `sleeve_length` (Float) - Sleeve length in cm.
  * `inseam` (Float) - Inseam length in cm.
  * `predicted_fields` (JSON, Default: Empty list) - Logs which dimensions were inferred using AI vs manual.
  * `recorded_at` (DateTime, Default: Current UTC Time)
* **Relationships:**
  * **Many-to-One** with `customers`.
  * **Many-to-One** with `orders`.

---

## 7. measurement.measurement_template (Table: `measurement_templates`)
Allows businesses to define dynamic size categories (e.g., custom sizes for "Shirts", "Suits").

* **Attributes:**
  * `id` (Integer, Primary Key)
  * `business_id` (Integer, Foreign Key to `businesses.id`, Nullable) - Associated business. Null represents global templates.
  * `category_name` (String, Index, Not Null) - Category label (e.g., "Shirts", "Trousers").
  * `display_order` (Integer, Default: 0) - Ordering sorting position.
* **Relationships:**
  * **Many-to-One** with `businesses` (Many templates can be registered for a business).
  * **One-to-Many** with `measurement_fields` (A template includes multiple size fields; cascades on delete).

---

## 8. measurement.measurement_field (Table: `measurement_fields`)
Specific measurement points inside a dynamic template.

* **Attributes:**
  * `id` (Integer, Primary Key)
  * `template_id` (Integer, Foreign Key to `measurement_templates.id`, Not Null) - Parent template.
  * `field_name` (String, Not Null) - e.g., "Chest", "Sleeve Length", "Waist".
  * `unit` (String, Default: "cm") - Unit of measure.
  * `is_required` (Boolean, Default: True) - Validation constraint.
  * `placeholder` (String, Nullable) - Input placeholder text.
  * `display_order` (Integer, Default: 0)
* **Relationships:**
  * **Many-to-One** with `measurement_templates` (Many fields belong to one template).
  * **One-to-Many** with `customer_measurements` (A field config has many customer measurements).

---

## 9. core.staff_assignment (Table: `staff_assignments`)
Maps users (tailors/staff) to specific orders they need to process.

* **Attributes:**
  * `id` (Integer, Primary Key)
  * `order_id` (Integer, Foreign Key to `orders.id`) - Associated order.
  * `staff_id` (Integer, Foreign Key to `users.id`) - Staff member assigned.
  * `role` (String) - Action role (e.g., "Cutter", "Stitcher", "Fitter").
  * `assigned_at` (DateTime, Default: Current UTC Time)
* **Relationships:**
  * **Many-to-One** with `orders` (An order can have multiple staff assigned to different roles).
  * **Many-to-One** with `users` (A staff member can have multiple assignments).

---

## 10. core.note (Table: `notes`)
Comments and internal discussion notes for orders.

* **Attributes:**
  * `id` (Integer, Primary Key)
  * `order_id` (Integer, Foreign Key to `orders.id`) - The order context.
  * `created_by` (Integer, Foreign Key to `users.id`) - Staff/Owner authoring the note.
  * `content` (Text) - Markdown/Plain-text message.
  * `created_at` (DateTime, Default: Current UTC Time)
* **Relationships:**
  * **Many-to-One** with `orders` (Many notes belong to one order).
  * **Many-to-One** with `users` (Many notes are written by one staff author).

---

## 11. ai.ai_prediction (Table: `ai_predictions`)
History of prediction requests sent to AI models.

* **Attributes:**
  * `id` (Integer, Primary Key)
  * `order_id` (Integer, Foreign Key to `orders.id`, Nullable) - Order context.
  * `input` (JSON) - Features input (e.g., height, weight).
  * `output` (JSON) - Predictions output (e.g., estimated body parameters).
  * `model_name` (String) - Identifier of the AI model.
  * `created_at` (DateTime, Default: Current UTC Time)
* **Relationships:**
  * **Many-to-One** with `orders`.

---

## 12. ai.fabric_catalog (Table: `fabric_catalog`)
Reference catalog list for fabric types.

* **Attributes:**
  * `id` (Integer, Primary Key)
  * `name` (String, Not Null) - Fabric brand/material name (e.g., premium cotton).
  * `fabric_type` (String, Not Null) - Material type (e.g., Cotton, Silk, Linen, Wool).
  * `characteristics` (JSON) - List of descriptive qualities (e.g., `["Breathable", "Lightweight"]`).
  * `suitability` (JSON) - Recommended garment usage (e.g., `["Casual", "Summer", "Shirts"]`).

---

## 13. ai.fabric_estimation (Table: `fabric_estimations`)
Holds calculations for length of fabric required for specific orders.

* **Attributes:**
  * `id` (Integer, Primary Key)
  * `order_id` (Integer, Foreign Key to `orders.id`) - Connected order.
  * `garment_type` (String) - Type of garment requested.
  * `required_length_m` (Float) - Total length estimate in meters.
  * `details` (String) - Detail comments about calculations.
* **Relationships:**
  * **Many-to-One** with `orders`.

---

## 14. ai.fabric_recommendation (Table: `fabric_recommendations`)
AI-suggested fabric details matching custom orders.

* **Attributes:**
  * `id` (Integer, Primary Key)
  * `order_id` (Integer, Foreign Key to `orders.id`, Nullable) - Target order.
  * `recommendations` (JSON) - Recommendation listing properties.
* **Relationships:**
  * **Many-to-One** with `orders`.
