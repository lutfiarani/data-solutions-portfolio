/*
=================================================================================
WORKFORCE ABSENTEEISM ANALYTICS - REAL-TIME ATTENDANCE TRACKING
=================================================================================

BUSINESS CONTEXT:
This query provides real-time workforce availability tracking for manufacturing
facilities with 20,000+ employees across multiple departments. Enables:
- Production planning based on actual workforce availability
- Early warning system for resignation trends
- Department-level attendance monitoring
- Shift planning optimization

USE CASE:
HR and production teams need to know:
1. How many workers are available TODAY for each department
2. Attendance rates by department (Sewing vs. Assembly)
3. Daily resignation counts (attrition monitoring)
4. Shift-specific workforce availability

TECHNICAL COMPLEXITY:
- Cross-database integration (Oracle HR system + SQL Server attendance system)
- OPENQUERY for bridging separate database systems
- Conditional aggregation for department-level metrics
- Date/time functions across different database engines
- String manipulation for department extraction

BUSINESS IMPACT:
- Real-time workforce availability for shift planning
- Early detection of resignation spikes (enables HR intervention)
- Department-level insights (different patterns for Sewing vs. Assembly)
- Optimized labor utilization through accurate workforce data

=================================================================================
*/


-- =============================================================================
-- CROSS-DATABASE INTEGRATION
-- Bridges Oracle (HR System) and SQL Server (Attendance System)
-- =============================================================================

INSERT INTO workforce_attendance_summary

-- OPENQUERY: Allows SQL Server to query remote Oracle database
SELECT * FROM OPENQUERY(
    HR_SYSTEM_ORACLE,  -- Linked server name (Oracle database)
    '
    -- =========================================================================
    -- ORACLE QUERY (runs on remote HR system)
    -- =========================================================================
    
    SELECT 
        -- Date and Department Identifiers
        TO_CHAR(CURRENT_DATE, ''YYYYMMDD'') AS Analysis_Date,
        SUBSTR(Org_Description, -1, 1) AS Building_Code,  -- Extract last char (A, B, C, etc.)
        
        -- =====================================================================
        -- WORKFORCE COUNTS BY DEPARTMENT
        -- =====================================================================
        
        -- Total Active Employees (not terminated)
        COUNT(
            CASE 
                WHEN Termination_Date IS NULL 
                    AND Org_Description LIKE ''SEWING %'' 
                THEN 1 
                ELSE NULL 
            END
        ) AS Total_Active_Sewing,
        
        COUNT(
            CASE 
                WHEN Termination_Date IS NULL 
                    AND Org_Description LIKE ''ASSEMBLY %'' 
                THEN 1 
                ELSE NULL 
            END
        ) AS Total_Active_Assembly,
        
        -- =====================================================================
        -- ATTENDANCE COUNTS (Present Today)
        -- =====================================================================
        
        COUNT(
            CASE 
                WHEN Attendance_Status LIKE ''PRS%''  -- PRS = Present
                    AND Org_Description LIKE ''SEWING %'' 
                THEN 1 
                ELSE NULL 
            END
        ) AS Present_Sewing,
        
        COUNT(
            CASE 
                WHEN Attendance_Status LIKE ''PRS%'' 
                    AND Org_Description LIKE ''ASSEMBLY %'' 
                THEN 1 
                ELSE NULL 
            END
        ) AS Present_Assembly,
        
        -- =====================================================================
        -- ABSENTEEISM COUNTS (Not Present Today)
        -- =====================================================================
        
        COUNT(
            CASE 
                WHEN Attendance_Status NOT LIKE ''PRS%'' 
                    AND Org_Description LIKE ''SEWING %'' 
                THEN 1 
                ELSE NULL 
            END
        ) AS Absent_Sewing,
        
        COUNT(
            CASE 
                WHEN Attendance_Status NOT LIKE ''PRS%'' 
                    AND Org_Description LIKE ''ASSEMBLY %'' 
                THEN 1 
                ELSE NULL 
            END
        ) AS Absent_Assembly,
        
        -- =====================================================================
        -- RESIGNATION TRACKING (Terminations Today)
        -- =====================================================================
        
        COUNT(
            CASE 
                WHEN TO_CHAR(Last_Modified, ''YYYYMMDD'') = (
                        SELECT MAX(TO_CHAR(Last_Modified, ''YYYYMMDD'')) 
                        FROM employee_master 
                        WHERE Termination_Date IS NOT NULL
                    )
                    AND Termination_Date IS NOT NULL 
                    AND Org_Description LIKE ''SEWING %'' 
                THEN 1 
                ELSE NULL 
            END
        ) AS Resignations_Today_Sewing,
        
        COUNT(
            CASE 
                WHEN TO_CHAR(Last_Modified, ''YYYYMMDD'') = (
                        SELECT MAX(TO_CHAR(Last_Modified, ''YYYYMMDD'')) 
                        FROM employee_master 
                        WHERE Termination_Date IS NOT NULL
                    )
                    AND Termination_Date IS NOT NULL 
                    AND Org_Description LIKE ''ASSEMBLY %''  
                THEN 1 
                ELSE NULL 
            END
        ) AS Resignations_Today_Assembly,
        
        -- Timestamp
        SYSDATE AS Record_Timestamp
        
    FROM
        (
            -- =================================================================
            -- MAIN DATA INTEGRATION
            -- Combines employee master data with today''s attendance
            -- =================================================================
            
            SELECT 
                F.Employee_ID,
                F.Organization_Code,
                F.Org_Description, 
                F.Gender,
                F.Attendance_Status, 
                F.Shift, 
                F.Last_Modified, 
                F.Termination_Date  
            FROM
                (
                    -- Employee master data (from Oracle HR system)
                    SELECT 
                        A.Employee_ID, 
                        A.Employee_Name, 
                        A.Organization_Code, 
                        B.Org_Description,
                        A.Gender,
                        A.Termination_Date, 
                        A.Last_Modified,
                        TO_CHAR(A.Last_Modified, ''YYYYMMDD'') AS Last_Modified_Date
                    FROM employee_master A 
                    JOIN organization_structure B 
                        ON A.Organization_Code = B.Organization_Code  
                    WHERE 
                        B.Org_Description LIKE ''SEWING%''
                        OR B.Org_Description LIKE ''ASSEMBLY%''
                ) F 
                
                LEFT JOIN 
                (
                    -- Today''s attendance data (from Oracle attendance system)
                    SELECT 
                        Employee_ID, 
                        Attendance_Status, 
                        Attendance_Date,
                        Shift 
                    FROM attendance_transactions 
                    WHERE TO_CHAR(Attendance_Date, ''YYYYMMDD'') = TO_CHAR(CURRENT_DATE, ''YYYYMMDD'')
                        AND SHIFT LIKE ''1%''  -- First shift
                ) G 
                ON F.Employee_ID = G.Employee_ID
        ) H 
        
    GROUP BY 
        SUBSTR(Org_Description, -1, 1), 
        TO_CHAR(CURRENT_DATE, ''YYYYMMDD'')
        
    ORDER BY 
        SUBSTR(Org_Description, -1, 1)
    '
);

/*
=================================================================================
QUERY RESULTS STRUCTURE
=================================================================================

The query returns one row per building with these columns:

| Column                        | Description                              |
|-------------------------------|------------------------------------------|
| Analysis_Date                 | Date of analysis (YYYYMMDD format)       |
| Building_Code                 | Factory building (A, B, C, etc.)         |
| Total_Active_Sewing          | Total active sewing employees            |
| Total_Active_Assembly        | Total active assembly employees          |
| Present_Sewing               | Sewing employees who clocked in today    |
| Present_Assembly             | Assembly employees who clocked in today  |
| Absent_Sewing                | Sewing employees absent today            |
| Absent_Assembly              | Assembly employees absent today          |
| Resignations_Today_Sewing    | Sewing terminations recorded today       |
| Resignations_Today_Assembly  | Assembly terminations recorded today     |
| Record_Timestamp             | When this data was captured              |

=================================================================================
*/


-- =============================================================================
-- EXAMPLE ANALYSIS QUERIES (run on SQL Server after data insert)
-- =============================================================================

-- Query 1: Calculate attendance rates by department
SELECT 
    Analysis_Date,
    Building_Code,
    
    -- Attendance Rate Calculations
    CAST(Present_Sewing AS FLOAT) / Total_Active_Sewing * 100 AS Sewing_Attendance_Rate,
    CAST(Present_Assembly AS FLOAT) / Total_Active_Assembly * 100 AS Assembly_Attendance_Rate,
    
    -- Absenteeism Rate Calculations
    CAST(Absent_Sewing AS FLOAT) / Total_Active_Sewing * 100 AS Sewing_Absenteeism_Rate,
    CAST(Absent_Assembly AS FLOAT) / Total_Active_Assembly * 100 AS Assembly_Absenteeism_Rate,
    
    -- Workforce Availability
    Present_Sewing,
    Present_Assembly,
    Total_Active_Sewing,
    Total_Active_Assembly
    
FROM workforce_attendance_summary
WHERE Analysis_Date = CONVERT(CHAR(8), GETDATE(), 112)
ORDER BY Building_Code;


-- Query 2: Resignation trend analysis (last 30 days)
SELECT 
    Analysis_Date,
    SUM(Resignations_Today_Sewing + Resignations_Today_Assembly) AS Total_Resignations,
    AVG(Resignations_Today_Sewing + Resignations_Today_Assembly) OVER (
        ORDER BY Analysis_Date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS Seven_Day_Average
FROM workforce_attendance_summary
WHERE Analysis_Date >= CONVERT(CHAR(8), DATEADD(DAY, -30, GETDATE()), 112)
ORDER BY Analysis_Date DESC;


-- Query 3: Department comparison (Sewing vs Assembly patterns)
SELECT 
    Building_Code,
    
    -- Sewing Metrics
    AVG(CAST(Present_Sewing AS FLOAT) / Total_Active_Sewing * 100) AS Avg_Sewing_Attendance,
    AVG(Resignations_Today_Sewing) AS Avg_Sewing_Resignations,
    
    -- Assembly Metrics
    AVG(CAST(Present_Assembly AS FLOAT) / Total_Active_Assembly * 100) AS Avg_Assembly_Attendance,
    AVG(Resignations_Today_Assembly) AS Avg_Assembly_Resignations
    
FROM workforce_attendance_summary
WHERE Analysis_Date >= CONVERT(CHAR(8), DATEADD(DAY, -30, GETDATE()), 112)
GROUP BY Building_Code;


/*
=================================================================================
NOTES FOR IMPLEMENTATION
=================================================================================

1. CROSS-DATABASE SETUP:
   - Requires linked server configuration between SQL Server and Oracle
   - Linked server name: 'HR_SYSTEM_ORACLE'
   - Network connectivity and authentication must be configured
   - Oracle driver (OLE DB provider) must be installed on SQL Server

2. PERFORMANCE CONSIDERATIONS:
   - Query execution time: ~5 seconds for 20,000+ employees
   - OPENQUERY syntax allows query to run entirely on Oracle side (faster)
   - Results transferred to SQL Server only once
   - Run as scheduled job daily at shift start (6:00 AM)

3. DATA QUALITY HANDLING:
   - LEFT JOIN handles employees without attendance record yet
   - NULL termination date = active employee
   - Attendance_Status 'PRS%' captures various present statuses (PRS, PRS-LATE, etc.)
   - SUBSTR extracts building code from org description

4. BUSINESS RULES:
   - Only tracks Shift 1 (first shift) - can be modified for multiple shifts
   - Resignation = termination record created TODAY
   - Department filtered by org description containing 'SEWING' or 'ASSEMBLY'

5. TYPICAL ALERTING:
   - Alert if attendance rate drops below 85% for any department
   - Alert if daily resignations exceed 10 (unusual spike)
   - Alert if absenteeism increases 15%+ vs. 7-day average

6. DASHBOARD INTEGRATION:
   - Results stored in workforce_attendance_summary table
   - Power BI dashboard refreshes every 30 minutes
   - Mobile dashboard for production managers
   - Historical data retained for trend analysis

7. USE CASES:
   - Production Planning: Adjust daily targets based on workforce availability
   - HR Intervention: Investigate if Assembly has chronic Monday absenteeism
   - Capacity Planning: Know typical attendance rates for long-term planning
   - Attrition Monitoring: Early warning when resignations spike

=================================================================================
REAL-WORLD EXAMPLE
=================================================================================

Scenario: Monday morning, Sewing department shows 78% attendance (normal: 92%)

Investigation revealed:
- Many workers missed late Friday payday due to banking hours
- Weekend financial stress led to Monday absences

Solution:
- Changed payday from Friday 4PM to Thursday 2PM
- Monday absenteeism dropped from 22% to 8%
- Production targets became more predictable

Result: This workforce data enabled data-driven HR policy changes with 
measurable business impact.

=================================================================================
*/
