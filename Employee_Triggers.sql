
-- Drop tables if exist
IF OBJECT_ID('EmployeeAudit', 'U') IS NOT NULL DROP TABLE EmployeeAudit;
IF OBJECT_ID('Employees', 'U') IS NOT NULL DROP TABLE Employees;
IF OBJECT_ID('Departments', 'U') IS NOT NULL DROP TABLE Departments;

-- Create Departments table
CREATE TABLE Departments (
    DeptID INT PRIMARY KEY,
    DeptName VARCHAR(50)
);

-- Create Employees table
CREATE TABLE Employees (
    EmpID INT PRIMARY KEY,
    EmpName VARCHAR(50),
    Salary INT,
    DeptID INT
);

-- Create Audit Table
CREATE TABLE EmployeeAudit (
   AuditID INT IDENTITY(1,1) PRIMARY KEY,
   EmpID INT,
   ActionType VARCHAR(10),
   OldSalary INT,
   NewSalary INT,
   ActionDate DATETIME DEFAULT GETDATE()
);

-- Insert sample departments
INSERT INTO Departments VALUES 
(1, 'HR'),
(2, 'IT'),
(3, 'Sales');

 /* T1 + T7 MERGED (INSTEAD OF INSERT)
   - Prevent salary < 30000
   - Validate DeptID exists */

IF OBJECT_ID('trg_InsertValidation', 'TR') IS NOT NULL
DROP TRIGGER trg_InsertValidation;
GO

CREATE TRIGGER trg_InsertValidation
ON Employees
INSTEAD OF INSERT
AS
BEGIN
    -- Salary validation
    IF EXISTS (SELECT 1 FROM inserted WHERE Salary < 30000)
    BEGIN
        PRINT 'Insert rejected: Salary must be >= 30000';
        RETURN;
    END

    -- Department validation
    IF EXISTS (
        SELECT 1
        FROM inserted i
        LEFT JOIN Departments d ON i.DeptID = d.DeptID
        WHERE d.DeptID IS NULL
    )
    BEGIN
        PRINT 'Insert rejected: Invalid DeptID';
        RETURN;
    END

    -- Insert valid records
    INSERT INTO Employees (EmpID, EmpName, Salary, DeptID)
    SELECT EmpID, EmpName, Salary, DeptID FROM inserted;
END;
GO

-- T2: Log insert (AFTER INSERT)

IF OBJECT_ID('trg_T2_AuditInsert', 'TR') IS NOT NULL
DROP TRIGGER trg_T2_AuditInsert;
GO

CREATE TRIGGER trg_T2_AuditInsert
ON Employees
AFTER INSERT
AS
BEGIN
    INSERT INTO EmployeeAudit (EmpID, ActionType, NewSalary)
    SELECT EmpID, 'INSERT', Salary FROM inserted;
END;
GO

-- T3: Prevent salary drop > 20% (INSTEAD OF UPDATE)

IF OBJECT_ID('trg_T3_PreventSalaryDrop', 'TR') IS NOT NULL
DROP TRIGGER trg_T3_PreventSalaryDrop;
GO

CREATE TRIGGER trg_T3_PreventSalaryDrop
ON Employees
INSTEAD OF UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN deleted d ON i.EmpID = d.EmpID
        WHERE i.Salary < d.Salary * 0.8
    )
    BEGIN
        PRINT 'Update rejected: Salary reduction > 20% not allowed';
        RETURN;
    END

    UPDATE e
    SET 
        e.EmpName = i.EmpName,
        e.Salary = i.Salary,
        e.DeptID = i.DeptID
    FROM Employees e
    JOIN inserted i ON e.EmpID = i.EmpID;
END;
GO

-- T4: Log salary updates (AFTER UPDATE)

IF OBJECT_ID('trg_T4_LogSalaryUpdate', 'TR') IS NOT NULL
DROP TRIGGER trg_T4_LogSalaryUpdate;
GO

CREATE TRIGGER trg_T4_LogSalaryUpdate
ON Employees
AFTER UPDATE
AS
BEGIN
    INSERT INTO EmployeeAudit (EmpID, ActionType, OldSalary, NewSalary)
    SELECT d.EmpID, 'UPDATE', d.Salary, i.Salary
    FROM inserted i
    JOIN deleted d ON i.EmpID = d.EmpID;
END;
GO

-- T5: Prevent deletion from IT department (INSTEAD OF DELETE)

IF OBJECT_ID('trg_T5_PreventITDelete', 'TR') IS NOT NULL
DROP TRIGGER trg_T5_PreventITDelete;
GO

CREATE TRIGGER trg_T5_PreventITDelete
ON Employees
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM deleted d
        JOIN Departments dept ON d.DeptID = dept.DeptID
        WHERE dept.DeptName = 'IT'
    )
    BEGIN
        PRINT 'Delete blocked: Cannot delete IT employees';
        RETURN;
    END

    DELETE FROM Employees
    WHERE EmpID IN (SELECT EmpID FROM deleted);
END;
GO

-- T6: Log deletion (AFTER DELETE)

IF OBJECT_ID('trg_T6_LogDelete', 'TR') IS NOT NULL
DROP TRIGGER trg_T6_LogDelete;
GO

CREATE TRIGGER trg_T6_LogDelete
ON Employees
AFTER DELETE
AS
BEGIN
    INSERT INTO EmployeeAudit (EmpID, ActionType, OldSalary)
    SELECT EmpID, 'DELETE', Salary FROM deleted;
END;
GO

-- TEST CASES (OPTIONAL)

-- Valid insert
INSERT INTO Employees VALUES (1, 'Aman', 40000, 1);

-- Invalid salary
INSERT INTO Employees VALUES (2, 'Ravi', 20000, 1);

-- Invalid department
INSERT INTO Employees VALUES (3, 'Neha', 50000, 99);

-- Valid update
UPDATE Employees SET Salary = 38000 WHERE EmpID = 1;

-- Invalid update (>20% drop)
UPDATE Employees SET Salary = 20000 WHERE EmpID = 1;

-- Delete non-IT employee
DELETE FROM Employees WHERE EmpID = 1;

-- Check audit table
SELECT * FROM EmployeeAudit;