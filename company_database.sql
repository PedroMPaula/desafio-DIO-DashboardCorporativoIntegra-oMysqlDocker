-- ============================================================
-- BASE DE DADOS COMPANY - Desafio Power BI (sem Azure)
-- Usar com MySQL local ou Docker
-- ============================================================

CREATE DATABASE IF NOT EXISTS company_db;
USE company_db;
-- ============================================================
-- TABELA: employee
-- ============================================================
DROP TABLE IF EXISTS works_on;
DROP TABLE IF EXISTS dependent;
DROP TABLE IF EXISTS dept_locations;
DROP TABLE IF EXISTS project;
DROP TABLE IF EXISTS department;
DROP TABLE IF EXISTS employee;

CREATE TABLE employee (
    Fname       VARCHAR(15)    NOT NULL,
    Minit       CHAR(1),
    Lname       VARCHAR(15)    NOT NULL,
    Ssn         CHAR(9)        NOT NULL,
    Bdate       DATE,
    Address     VARCHAR(30),
    Sex         CHAR(1),
    Salary      DECIMAL(10,2),
    Super_ssn   CHAR(9),
    Dno         INT            NOT NULL,
    CONSTRAINT empPK PRIMARY KEY (Ssn)
);

-- ============================================================
-- TABELA: department
-- ============================================================
CREATE TABLE department (
    Dname           VARCHAR(15)   NOT NULL,
    Dnumber         INT           NOT NULL,
    Mgr_ssn         CHAR(9)       NOT NULL,
    Mgr_start_date  DATE,
    CONSTRAINT deptPK PRIMARY KEY (Dnumber),
    CONSTRAINT deptSK UNIQUE (Dname)
);

-- ============================================================
-- TABELA: dept_locations
-- ============================================================
CREATE TABLE dept_locations (
    Dnumber     INT           NOT NULL,
    Dlocation   VARCHAR(15)   NOT NULL,
    CONSTRAINT dept_locPK PRIMARY KEY (Dnumber, Dlocation)
);

-- ============================================================
-- TABELA: project
-- ============================================================
CREATE TABLE project (
    Pname       VARCHAR(15)   NOT NULL,
    Pnumber     INT           NOT NULL,
    Plocation   VARCHAR(15),
    Dnum        INT           NOT NULL,
    CONSTRAINT projPK PRIMARY KEY (Pnumber),
    CONSTRAINT projSK UNIQUE (Pname)
);

-- ============================================================
-- TABELA: works_on
-- ============================================================
CREATE TABLE works_on (
    Essn    CHAR(9)       NOT NULL,
    Pno     INT           NOT NULL,
    Hours   DECIMAL(3,1)  NOT NULL,
    CONSTRAINT works_onPK PRIMARY KEY (Essn, Pno)
);

-- ============================================================
-- TABELA: dependent
-- ============================================================
CREATE TABLE dependent (
    Essn            CHAR(9)       NOT NULL,
    Dependent_name  VARCHAR(15)   NOT NULL,
    Sex             CHAR(1),
    Bdate           DATE,
    Relationship    VARCHAR(8),
    CONSTRAINT dependentPK PRIMARY KEY (Essn, Dependent_name)
);

-- ============================================================
-- INSERÇÃO DE DADOS
-- ============================================================

-- Employees (inserir antes de FK constraints)
INSERT INTO employee VALUES
('John',  'B', 'Smith',   '123456789', '1965-01-09', '731 Fondren, Houston TX', 'M', 30000.00, '333445555', 5),
('Franklin', 'T', 'Wong',  '333445555', '1975-12-08', '638 Voss, Houston TX',   'M', 40000.00, '888665555', 5),
('Alicia', 'J', 'Zelaya', '999887777', '1988-07-19', '3321 Castle, Spring TX', 'F', 25000.00, '987654321', 4),
('Jennifer', 'S', 'Wallace', '987654321', '1971-06-20', '291 Berry, Bellaire TX', 'F', 43000.00, '888665555', 4),
('Ramesh', 'K', 'Narayan', '666884444', '1982-09-15', '975 Fire Oak, Humble TX', 'M', 38000.00, '333445555', 5),
('Joyce',  'A', 'English', '453453453', '1992-07-31', '5631 Rice, Houston TX',  'F', 25000.00, '333445555', 5),
('Ahmad',  'V', 'Jabbar',  '987987987', '1989-03-29', '980 Dallas, Houston TX', 'M', 25000.00, '987654321', 4),
('James',  'E', 'Borg',    '888665555', '1967-11-10', '450 Stone, Houston TX',  'M', 55000.00, NULL,        1);

-- Departments
INSERT INTO department VALUES
('Headquarters', 1, '888665555', '1981-06-19'),
('Administration', 4, '987654321', '1995-01-01'),
('Research', 5, '333445555', '1988-05-22');

-- FK constraints depois dos dados (evita erro circular)
ALTER TABLE employee ADD CONSTRAINT empFK FOREIGN KEY (Super_ssn) REFERENCES employee(Ssn)        ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE employee ADD CONSTRAINT empDeptFK FOREIGN KEY (Dno)   REFERENCES department(Dnumber)  ON UPDATE CASCADE;
ALTER TABLE department ADD CONSTRAINT deptMgrFK FOREIGN KEY (Mgr_ssn) REFERENCES employee(Ssn)    ON UPDATE CASCADE;

-- Dept_locations
INSERT INTO dept_locations VALUES
(1, 'Houston'),
(4, 'Stafford'),
(5, 'Bellaire'),
(5, 'Sugarland'),
(5, 'Houston');

ALTER TABLE dept_locations ADD CONSTRAINT dept_loc_deptFK FOREIGN KEY (Dnumber) REFERENCES department(Dnumber) ON UPDATE CASCADE;

-- Projects
INSERT INTO project VALUES
('ProductX',  1, 'Bellaire',  5),
('ProductY',  2, 'Sugarland', 5),
('ProductZ',  3, 'Houston',   5),
('Computerization', 10, 'Stafford', 4),
('Reorganization',  20, 'Houston',  1),
('Newbenefits',     30, 'Stafford', 4);

ALTER TABLE project ADD CONSTRAINT projDeptFK FOREIGN KEY (Dnum) REFERENCES department(Dnumber) ON UPDATE CASCADE;

-- Works_on
INSERT INTO works_on VALUES
('123456789',  1, 32.5),
('123456789',  2, 7.5),
('666884444',  3, 40.0),
('453453453',  1, 20.0),
('453453453',  2, 20.0),
('333445555',  2, 10.0),
('333445555',  3, 10.0),
('333445555', 10, 10.0),
('333445555', 20, 10.0),
('999887777', 30, 30.0),
('999887777', 10, 10.0),
('987987987', 10, 35.0),
('987987987', 30,  5.0),
('987654321', 30, 20.0),
('987654321', 20, 15.0),
('888665555', 20, NULL);

ALTER TABLE works_on ADD CONSTRAINT works_onEmpFK  FOREIGN KEY (Essn) REFERENCES employee(Ssn)  ON UPDATE CASCADE;
ALTER TABLE works_on ADD CONSTRAINT works_onProjFK FOREIGN KEY (Pno)  REFERENCES project(Pnumber) ON UPDATE CASCADE;

-- Dependents
INSERT INTO dependent VALUES
('333445555', 'Alice',   'F', '1986-04-05', 'Daughter'),
('333445555', 'Theodore','M', '1983-10-25', 'Son'),
('333445555', 'Joy',     'F', '1978-05-03', 'Spouse'),
('987654321', 'Abner',   'M', '1942-02-28', 'Spouse'),
('123456789', 'Michael', 'M', '1988-01-04', 'Son'),
('123456789', 'Alice',   'F', '1988-12-30', 'Daughter'),
('123456789', 'Elizabeth','F','1967-05-05', 'Spouse');

ALTER TABLE dependent ADD CONSTRAINT dependentEmpFK FOREIGN KEY (Essn) REFERENCES employee(Ssn) ON UPDATE CASCADE;

-- ============================================================
-- QUERY PARA JUNÇÃO EMPLOYEE + GERENTE (requisito do desafio)
-- ============================================================
-- Esta query une cada colaborador com o nome do seu gerente:
-- SELECT 
--   CONCAT(e.Fname, ' ', e.Lname) AS Employee_Name,
--   e.Ssn,
--   e.Salary,
--   e.Dno,
--   CONCAT(m.Fname, ' ', m.Lname) AS Manager_Name,
--   m.Ssn AS Manager_Ssn
-- FROM employee e
-- LEFT JOIN employee m ON e.Super_ssn = m.Ssn;

SHOW TABLES;
SELECT 'Database company_db criada com sucesso!' AS status;
