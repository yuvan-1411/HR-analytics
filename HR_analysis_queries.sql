-- Query-1 Identify which departments are losing staff.

CREATE or REPLACE VIEW attrition_by_dept as 
SELECT 
    Department,
    COUNT(*) AS Total_Employees,
    SUM(Termd) AS Total_Terminated,
    ROUND((SUM(Termd) * 100.0 / COUNT(*)), 2) AS Attrition_Rate_Percent,
    ROUND(AVG(Salary), 2) AS Average_Salary,
    ROUND(AVG(EmpSatisfaction), 2) AS Avg_Satisfaction_Score,
    ROUND(AVG(Absences), 1) AS Avg_Absences
FROM hrdataset_v14
GROUP BY Department
ORDER BY Attrition_Rate_Percent DESC;

-- Query-2 Determine which recruitment channels provide the most satisfied workers.

CREATE VIEW recruitment_source AS
SELECT 
    Department, -- Added this to enable syncing
    RecruitmentSource,
    COUNT(*) AS Hires_Count,
    ROUND(AVG(Salary), 2) AS Avg_Salary,
    ROUND(AVG(EmpSatisfaction), 2) AS Avg_Satisfaction,
    ROUND(AVG(Absences), 1) AS Avg_Absences
FROM hrdataset_v14
GROUP BY Department, RecruitmentSource;

-- Query-3 Identify managers who might need leadership training based on team satisfaction.

create or replace view manager_scorecard as
SELECT 
    ManagerName,
    Department,
    COUNT(*) AS Team_Size,
    SUM(Termd) AS Terminatins,
    ROUND(AVG(EmpSatisfaction), 2) AS Team_Satisfaction,
    -- This calculates the percentage of the team that has a "Fully Meets" or "Exceeds" performance score
    ROUND(SUM(CASE WHEN PerformanceScore IN ('Fully Meets', 'Exceeds') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS High_Performance_Rate
FROM hrdataset_v14
GROUP BY ManagerName, Department
HAVING Team_Size > 5 -- Focusing on managers with significant team sizes
ORDER BY Team_Satisfaction ASC,
High_Performance_Rate DESC;

-- Query 4: Pay Equity & Representation Audit

CREATE VIEW pay_equity AS
WITH CompanyMetrics AS (
    SELECT AVG(Salary) AS Global_Avg_Salary FROM hrdataset_v14
)
SELECT 
    Department, -- Added this column
    RaceDesc, 
    Sex, 
    COUNT(*) AS Employee_Count,
    ROUND(AVG(Salary), 2) AS Group_Avg_Salary,
    ROUND(AVG(Salary) - (SELECT Global_Avg_Salary FROM CompanyMetrics), 2) AS Diff_From_Global_Avg,
    ROUND(((AVG(Salary) - (SELECT Global_Avg_Salary FROM CompanyMetrics)) / (SELECT Global_Avg_Salary FROM CompanyMetrics)) * 100, 2) AS Percent_Variance,
    ROUND(AVG(EmpSatisfaction), 2) AS Group_Satisfaction
FROM hrdataset_v14
GROUP BY Department, RaceDesc, Sex -- Added Department here
HAVING Employee_Count >= 1;

-- Query 5: Star Analysis

create view star_employees as
WITH DeptAverages AS (
    SELECT 
        Employee_Name,
        Department,
        Position,
        Salary,
        PerformanceScore,
        EmpSatisfaction,
        ROUND(AVG(Salary) OVER(PARTITION BY Department), 2) AS Dept_Avg_Salary
    FROM hrdataset_v14
)
SELECT * FROM DeptAverages
WHERE (PerformanceScore = 'Exceeds' AND Salary < Dept_Avg_Salary)
   OR (PerformanceScore = 'Fully Meets' AND EmpSatisfaction < 3)
ORDER BY PerformanceScore DESC, Salary ASC;

-- bridge view

CREATE VIEW dim_department AS
SELECT DISTINCT Department FROM hrdataset_v14;

CREATE VIEW dim_sex AS
SELECT DISTINCT Sex FROM hrdataset_v14;

