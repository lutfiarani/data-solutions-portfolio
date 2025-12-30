# Workforce Absenteeism Analytics
**HR Analytics | Cross-Database Integration | Real-Time Attendance Tracking**

---

## Client Context

**Industry:** Manufacturing facilities  
**Workforce Scale:** 5,000+ employees across multiple departments  
**Challenge:** Real-time workforce availability for production planning

---

## The Business Problem

HR and production teams lacked critical workforce visibility:

- **How many workers available TODAY?** (Data only available day after)
- **Attendance rates by department** - Sewing and Assembly have different patterns
- **Resignation trends** - No early warning system for attrition spikes
- **Shift-specific availability** - Can't plan next shift without current data

**Business Impact:** 
- Production schedules assume certain workforce levels
- High absenteeism = understaffed lines = missed production targets
- Late resignation trend detection = inability to plan hiring proactively
- Overstaffing (hiring too many) or understaffing (missing targets) both costly

---

## The Solution

### Real-Time Workforce Availability System

Built cross-database integration bridging two separate systems:

### System Architecture

**Challenge:** HR data and attendance data lived in completely separate systems:
- **HR System:** Oracle database (employee master data, termination records)
- **Attendance System:** SQL Server database (daily clock-in/out records)

**Solution:** OPENQUERY to bridge databases and create unified workforce view

### Key Metrics Calculated

**Department-Level Tracking:**
- **Total Workforce:** Active employees per department (excluding terminated)
- **Present Today:** Employees who clocked in for current shift
- **Absent Today:** Total workforce - Present employees
- **Attendance Rate:** (Present / Total) × 100
- **Daily Resignations:** Terminations recorded today

**Calculation Logic:**
```
For each department (Sewing, Assembly):
  Total Employees = COUNT(employees WHERE termination IS NULL)
  Present = COUNT(employees WHERE attendance_status = 'PRESENT')
  Absent = Total - Present
  Attendance Rate = (Present / Total) × 100
  Resignation Today = COUNT(employees WHERE termination_date = TODAY)
```

### Shift-Specific Analysis

- Tracked attendance by shift (Shift 1, Shift 2, overtime)
- Enabled production planning: "Do we have enough sewers for afternoon shift?"
- Historical patterns revealed: Monday morning has higher absenteeism

### Trend Monitoring

- Daily inserts into historical table for trending
- Week-over-week attendance pattern analysis
- Resignation rate trending (early warning system)
- Seasonal pattern identification (holiday periods, etc.)

---

## Technical Implementation

### Cross-Database Querying (Oracle + SQL Server)

**The Technical Challenge:**
Two separate database systems required bridging without manual data exports.

**The Solution:**
```sql
INSERT INTO attendance_summary
SELECT * FROM OPENQUERY(HR_SYSTEM_ORACLE, '
  -- Oracle query runs on HR system
  SELECT employee_id, department, attendance_status
  FROM employees JOIN attendance
  WHERE date = TODAY
')
```

**Key Technical Details:**
- OPENQUERY allows SQL Server to execute queries on remote Oracle database
- Query runs entirely on Oracle side (faster than pulling all data then filtering)
- Results transferred to SQL Server only once
- Scheduled daily at shift start (6:00 AM)

### Handling Technical Challenges

**Time Zone Conversions:**
- Oracle and SQL Server handle dates differently
- TO_CHAR in Oracle vs. CONVERT in SQL Server
- Solution: Consistent date format (YYYYMMDD) across both systems

**NULL Handling:**
- Employees without attendance records yet (e.g., haven't clocked in)
- LEFT JOIN preserves all employees, shows NULL for no attendance
- CASE statements handle NULL gracefully in calculations

**Department Extraction:**
- Organization description contains building code at end ("SEWING A", "ASSEMBLY B")
- SUBSTR function extracts last character for department grouping

---

## Tools & Technologies

- **Databases:** SQL Server + Oracle (linked server configuration)
- **Integration:** OPENQUERY for cross-database bridging
- **Automation:** Scheduled jobs via SQL Server Agent
- **Visualization:** Power BI dashboards, mobile app for managers

---

## Results & Impact

✅ **Real-time workforce availability** for shift planning (know at 6 AM who's available today)  
✅ **Department-level insights** - Sewing and Assembly have different attendance patterns  
✅ **Early warning for resignation trends** - HR can intervene before attrition spike  
✅ **Shift planning optimization** - know exactly how many workers to expect  
✅ **Data-driven HR interventions** - identify departments with chronic absenteeism  

---

## Business Value

### Workforce = Largest Cost & Most Critical Resource

**Production Planning:**
- If sewing department is 10% short-staffed, adjust daily targets accordingly
- Prevent setting unrealistic targets that demoralize workers
- Allocate orders to lines with better workforce availability

**HR Interventions:**
- If Assembly sees resignation spike, investigate working conditions immediately
- Early detection enables retention interventions (stay bonuses, transfers, etc.)
- Plan hiring pipeline based on attrition trends

**Cost Savings:**
- Better workforce planning = optimal labor utilization
- Reduced overtime costs (don't overcompensate for absenteeism with expensive OT)
- Reduced understaffing costs (don't miss production targets)

---

## Real-World Example

### Problem Discovered:
System showed Assembly department had **22% absenteeism every Monday** (normal: 8%)

### Investigation:
- Workers missed late Friday payday (bank closes 3 PM, shift ends 4 PM)
- Weekend financial stress led to Monday absences
- Workers couldn't pay for transportation on Monday morning

### Solution:
- Changed payday from Friday 4 PM to Thursday 2 PM
- Workers could access money before weekend

### Results:
- Monday absenteeism dropped from 22% → 8%
- Production targets became predictable again
- Worker satisfaction improved (fewer financial stress issues)

**This workforce data enabled data-driven HR policy changes with measurable business impact.**

---

## Dashboard Metrics (Typical Morning View)

### Today's Workforce Status by Department

| Department | Total Active | Present | Absent | Attendance Rate |
|------------|--------------|---------|---------|-----------------|
| Sewing A   | 850          | 782     | 68      | 92%             |
| Sewing B   | 820          | 795     | 25      | 97%             |
| Assembly A | 650          | 585     | 65      | 90%             |
| Assembly B | 670          | 642     | 28      | 96%             |

### Alert Conditions:
- 🔴 Attendance rate <85% (critical staffing issue)
- 🟡 Attendance rate 85-90% (monitor closely)
- 🟢 Attendance rate >90% (normal)

### Resignation Trending:
- Today: 8 resignations (normal range: 5-10)
- 7-day average: 7.2 resignations
- Status: ✅ Normal

---

## Key Insights

**Most Important Finding:** Different departments have different attendance patterns. Sewing typically has higher absenteeism on Mondays (physically demanding work). Assembly has higher turnover (more repetitive tasks).

**One-size-fits-all HR policies don't work.** This data enables department-specific interventions.

**Reusable Framework:** While built for manufacturing, this architecture works for any organization tracking:
- Employee attendance across multiple locations/departments
- Resignation/attrition trends
- Shift-based workforce planning
- Cross-system HR data integration

---

## Technical Challenges Overcome

1. **Linked Server Configuration**
   - Challenge: Configure SQL Server to talk to Oracle database
   - Solution: Installed Oracle OLE DB provider, configured linked server with credentials

2. **Query Performance**
   - Challenge: 5,000+ employee records processed daily
   - Solution: Query runs on Oracle side (OPENQUERY), only results transferred

3. **Character Set Differences**
   - Challenge: Oracle UTF-8 vs. SQL Server character encoding
   - Solution: Explicit CAST to VARCHAR in OPENQUERY for consistency

---

**Project Duration:** 6 weeks (infrastructure setup, query development, testing)  
**Ongoing Maintenance:** Automated daily execution, minimal manual intervention  
**Users:** Production planners, HR team, facility managers

---

[**View SQL Query**](../sql-queries/workforce-absenteeism-analytics.sql)

*Note: SQL query sanitized to remove company-specific table names while preserving cross-database integration logic and business calculations.*
