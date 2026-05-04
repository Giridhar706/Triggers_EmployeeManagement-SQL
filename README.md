# SQL Triggers Case Study – Employee Management

## 📌 Overview

This project demonstrates the use of SQL Server triggers to enforce business rules, maintain data integrity, and track audit logs automatically.

The solution is based on a real-world scenario where an organization needs to validate employee data and track all changes without relying on application-level logic.

---

## 🧱 Database Structure

### Tables:

* **Employees** → Stores employee details
* **Departments** → Stores department information
* **EmployeeAudit** → Stores audit logs for all operations

---

## ⚙️ Trigger Implementations

### 🔹 T1 + T7: Insert Validation (Merged)

* Prevent salary less than 30000
* Ensure valid DeptID exists

### 🔹 T2: Audit Insert

* Logs new employee insertions

### 🔹 T3: Update Restriction

* Prevent salary reduction greater than 20%

### 🔹 T4: Audit Update

* Logs old and new salary values

### 🔹 T5: Delete Restriction

* Prevent deletion of employees from IT department

### 🔹 T6: Audit Delete

* Logs deleted employee records

---

## 🚀 Features

* Ensures **data integrity**
* Implements **real-time validation**
* Provides **automatic audit tracking**
* Safe to run multiple times (uses DROP + CREATE)

---

## 🧪 Test Cases

Optional test queries are included at the bottom of the script to verify:

* Valid and invalid inserts
* Salary update constraints
* Delete restrictions
* Audit logging

---

## 🛠️ Tech Stack

* SQL Server
* T-SQL
* Triggers

---

## 💡 Key Learning

Triggers help move business logic closer to the database, ensuring consistency and reducing dependency on application code.

---

## 👩‍💻 Author

Giridhar Gopal
