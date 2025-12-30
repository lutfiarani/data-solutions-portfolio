# Quality Control Analytics
**Statistical Analysis | Defect Tracking | AQL Compliance Monitoring**

---

## Client Context

**Industry:** Global footwear manufacturing  
**Quality Scope:** Export compliance for international brands (Adidas, Nike, etc.)  
**Challenge:** Fast defect identification and AQL pass rate tracking

---

## The Business Problem

The quality team faced critical visibility gaps:

- **2-hour weekly quality meetings** reviewing static Excel reports
- **Delayed defect identification** - issues discovered days after occurrence
- **No visibility into defect trends** by type, line, or shift
- **Manual AQL tracking** for export compliance (time-consuming and error-prone)
- **Difficulty isolating root causes** without granular data

**Business Impact:** Quality issues discovered late result in:
- Rejected shipments (customer penalties, damaged reputation)
- Expensive rework (wasted labor and materials)
- Risk of losing major accounts
- Last-minute scrambles to fix issues before shipping

---

## The Solution

### Multi-Dimensional Quality Analytics System

Built automated quality tracking system addressing three critical areas:

### 1. Top Defect Analysis (Pareto Principle)

**Automated daily identification** of top 3 defect types:
- Queries quality inspection logs for all defect codes
- Aggregates defect counts by type and description
- Calculates defect rate vs. total production
- Ranks defects by frequency and business impact

**Business Logic:**
```
Defect Rate = (Total Defects of Type / Total Production) × 100
```

**Key Insight:** Top 3 defects typically account for 60-80% of quality issues (Pareto principle). Focus corrective action where it matters most.

### 2. AQL Pass Rate Tracking

**Automated monitoring** of Acceptable Quality Limit compliance:
- Tracks inspection results at PO (Purchase Order) level
- Handles multiple inspection attempts (uses most recent result)
- Calculates both order-level and volume-weighted pass rates
- Separates by result: Passed, Hold, Reject

**Metrics Tracked:**
- **Order Pass Rate:** % of POs passing inspection (management KPI)
- **Volume Pass Rate:** % of total pairs passing (financial impact measure)
- **Release Volume:** Actual pairs cleared for shipment

**Why Volume Matters More:** One large order failing (50,000 pairs) has far more business impact than 10 small orders failing (500 pairs each).

### 3. Country-Specific Order Tracking

**High-priority customer monitoring:**
- Tracks order completion for key markets (China, USA, Europe)
- Cell-level production status (which lines working on which orders)
- Assembly completion verification
- Real-time status: Complete vs. In Progress

**Use Case:** When China order #12345 is 85% complete two days before shipping deadline, system flags it for production priority.

---

## Technical Implementation

### Complex SQL Architecture

**Data Integration:**
- Production logs (actual output data)
- Quality inspection logs (defect records)
- Export schedule (what needs to ship when)
- Code master tables (defect type descriptions)
- PO master data (order details and customer info)

**Advanced SQL Techniques:**
- **LEFT JOIN** to handle orders without inspection results yet
- **Subqueries** to find most recent inspection per PO (orders may be inspected multiple times)
- **CASE statements** for complex status logic
- **Window functions** for ranking and trending
- **Conditional aggregation** for department/line-level breakdown

### Statistical Methods

- Defect rate calculations (defects per 1,000 pairs)
- Pass rate percentages with volume weighting
- Trend analysis (day-over-day, week-over-week comparisons)
- Categorical analysis (defect types, locations, shifts, time-of-day)

---

## Tools & Technologies

- **Database:** SQL Server for data querying and aggregation
- **Analysis:** Statistical calculations, trend identification
- **Visualization:** Power BI dashboards, automated reports
- **Alerting:** Email notifications for threshold breaches

---

## Results & Impact

✅ **Reduced quality review meetings from 2 hours → 30 minutes**  
✅ **Instant defect identification** by line, shift, and type (no more waiting for reports)  
✅ **Real-time AQL compliance tracking** for export orders  
✅ **Proactive interventions** - spot systemic issues before they become major problems  
✅ **Data-driven corrective actions** - know exactly where to focus improvement efforts  

---

## Business Value & ROI

### Quality Issues Are Expensive:

**Cost of One Rejected Shipment:**
- Wasted labor: 10,000+ pairs × labor cost
- Wasted materials: Raw materials for rejected units
- Rework costs: Re-inspect, repair, or remake
- Customer penalties: Late delivery fees
- Relationship damage: Risk of losing future orders

### This System Paid for Itself:

**Example:** System caught a systemic stitching defect at 10 AM on a production line making 5,000 pairs for a major customer shipment. 

**Without this system:** Defect discovered at final inspection (end of day). Entire batch rejected. Cost: ~$50,000 in rework + customer penalty.

**With this system:** Defect caught early, line stopped immediately. Only 500 pairs affected. Cost: ~$2,500 in rework.

**Savings:** $47,500 on one incident. System paid for itself in the first month.

---

## Dashboard Metrics (Typical Daily View)

### Top Section - Defect Focus
- Top 3 defects today with defect rates
- Trend vs. yesterday/last week
- **Action Item:** Focus quality training on #1 defect

### Middle Section - AQL Compliance
- Today's pass rate (target: >95%)
- Volume passed (ready to ship)
- Failed orders needing attention
- **Action Item:** Review failed orders, decide on rework vs. negotiate with customer

### Bottom Section - Order Status
- High-priority customer orders completion %
- Orders at risk of missing shipment
- **Action Item:** Reallocate resources to at-risk orders

### Executive Summary Example:
> "Today: 94% AQL pass rate (target 95%). Top defect: Stitching - Skipped Stitch (2.3% of production). China Order #12345 at 85% completion - needs focus to meet Friday shipment."

---

## Key Insights

**Most Important Finding:** Speed matters more than perfection in quality data. Getting 90% accurate data in 1 minute is better than 100% accurate data in 1 day.

**Practical Application:** This analytics framework works for any manufacturing operation tracking:
- Product defects or failures
- Inspection pass/fail rates
- Customer-specific quality requirements
- Root cause analysis by location, time, or operator

---

## Technical Challenges Overcome

1. **Multiple Inspections Per Order**
   - Challenge: Orders may be inspected 2-3 times, need most recent result
   - Solution: Subquery with MAX(timestamp) to identify latest inspection

2. **Missing Inspection Data**
   - Challenge: Some orders scheduled to ship but not yet inspected
   - Solution: LEFT JOIN preserves all scheduled orders, shows NULL for missing results

3. **Volume-Weighted Calculations**
   - Challenge: Simple pass rate doesn't reflect business impact
   - Solution: Calculate both PO count pass rate AND volume-weighted pass rate

---

**Project Duration:** 2 months (design, development, testing)  
**Ongoing Maintenance:** Automated stored procedures, minimal manual intervention  
**Users:** Quality managers, production planners, shipping coordinators

---

[**View SQL Query**](../sql-queries/quality-control-analytics.sql)

*Note: SQL queries sanitized to remove company-specific information while preserving analytical logic and statistical methods.*
