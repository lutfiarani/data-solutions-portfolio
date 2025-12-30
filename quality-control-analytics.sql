/*
=================================================================================
QUALITY CONTROL ANALYTICS - DEFECT TRACKING & AQL COMPLIANCE
=================================================================================

BUSINESS CONTEXT:
This query provides comprehensive quality analytics for manufacturing operations:
- Identifies top defect types to prioritize corrective actions
- Tracks AQL (Acceptable Quality Limit) pass rates for export compliance
- Monitors country-specific order completion status
- Enables data-driven quality interventions

USE CASE:
Quality teams need instant visibility into:
1. Which defect types are most frequent (focus corrective action)
2. Which orders are passing/failing final inspection (shipping readiness)
3. Country-specific order fulfillment status (customer priorities)

TECHNICAL COMPLEXITY:
- Multi-source data integration (production, quality, export, master data)
- Statistical calculations (defect rates, pass rates)
- Complex CASE logic for status determination
- LEFT JOIN for handling orders without inspection results
- Subqueries for most recent inspection results

BUSINESS IMPACT:
- Reduced quality review meetings from 2 hours → 30 minutes
- Instant defect identification by type, line, shift
- Proactive quality interventions before shipment
- Prevented costly rejected shipments through early detection

=================================================================================
*/


-- =============================================================================
-- QUERY 1: TOP 3 DEFECT ANALYSIS
-- Identifies most frequent defect types to prioritize corrective actions
-- =============================================================================

SELECT TOP 3 
    -- Defect Information
    A.Defect_Code,
    B.Defect_Description,
    
    -- Defect Metrics
    SUM(CONVERT(NUMERIC, A.Good_Count)) AS Total_Defects,
    
    -- Context: Total Production (for defect rate calculation)
    (
        SELECT SUM(CONVERT(NUMERIC, Good_Count)) AS Total_Production
        FROM production_logs WITH (NOLOCK)
        WHERE Factory = 'A1'
            AND CONVERT(CHAR(8), Timestamp, 112) = '20210219'  -- Date parameter
            AND Production_Status = 'AE'  -- Assembly End
    ) AS Total_Production_Qty,
    
    -- Calculated Defect Rate (percentage)
    (
        SUM(CONVERT(NUMERIC, A.Good_Count)) * 100.0 / 
        (
            SELECT SUM(CONVERT(NUMERIC, Good_Count))
            FROM production_logs WITH (NOLOCK)
            WHERE Factory = 'A1'
                AND CONVERT(CHAR(8), Timestamp, 112) = '20210219'
                AND Production_Status = 'AE'
        )
    ) AS Defect_Rate_Percent

FROM quality_inspection_logs AS A WITH (NOLOCK)

-- Join with defect code master table for descriptions
JOIN defect_code_master AS B WITH (NOLOCK)
    ON A.Defect_Code = B.Code_ID
    AND B.Code_Group = 'QCODE'  -- Quality codes only

WHERE 
    CONVERT(CHAR(8), A.Timestamp, 112) = '20210219'  -- Analysis date
    AND A.Factory = 'A1'

GROUP BY 
    A.Defect_Code, 
    B.Defect_Description

ORDER BY 
    Total_Defects DESC;

/*
INTERPRETATION:
- Defect_Rate_Percent shows what % of production had this defect
- Top 3 defects typically account for 60-80% of quality issues (Pareto principle)
- Focus quality training and process improvements on these top defects
- Example: If "Stitching - Skipped Stitch" is #1, focus on sewing machine maintenance
*/


-- =============================================================================
-- QUERY 2: AQL PASS RATE TRACKING
-- Monitors final inspection pass rates for export compliance
-- =============================================================================

SELECT 
    -- Pass/Fail Counts (by Purchase Order)
    SUM(CASE WHEN Inspection_Result = 'Y' THEN 1 ELSE 0 END) AS Orders_Passed,
    SUM(CASE WHEN Inspection_Result <> 'Y' THEN 1 ELSE 0 END) AS Orders_Failed,
    
    -- Pass/Fail Volume (by Quantity - more meaningful for revenue)
    SUM(CASE WHEN Inspection_Result = 'Y' THEN Quantity ELSE 0 END) AS Volume_Passed,
    SUM(CASE WHEN Inspection_Result <> 'Y' THEN Quantity ELSE 0 END) AS Volume_Failed,
    
    -- Calculated Pass Rates
    (
        SUM(CASE WHEN Inspection_Result = 'Y' THEN 1 ELSE 0 END) * 100.0 / 
        COUNT(*)
    ) AS Order_Pass_Rate_Percent,
    
    (
        SUM(CASE WHEN Inspection_Result = 'Y' THEN Quantity ELSE 0 END) * 100.0 / 
        SUM(Quantity)
    ) AS Volume_Pass_Rate_Percent

FROM 
    (
        -- Subquery: Get today's export schedule
        SELECT 
            PO_Number, 
            Quantity 
        FROM export_schedule WITH (NOLOCK)
        WHERE Export_Date = CONVERT(CHAR(10), GETDATE(), 120)  -- Today's shipments
    ) AS A

    LEFT JOIN 
    (
        -- Subquery: Get most recent inspection result per PO
        -- (Orders may be inspected multiple times - we want latest result)
        SELECT 
            T.PO_Number, 
            T.Inspection_Result, 
            R.Most_Recent_Time
        FROM 
            (
                -- Find most recent inspection timestamp per PO
                SELECT 
                    PO_Number, 
                    MAX(Timestamp) AS Most_Recent_Time
                FROM quality_aql_data_log WITH (NOLOCK)
                GROUP BY PO_Number
            ) R
        INNER JOIN quality_aql_data_log T WITH (NOLOCK)
            ON T.PO_Number = R.PO_Number 
            AND T.Timestamp = R.Most_Recent_Time
    ) AS B
    ON A.PO_Number = B.PO_Number;

/*
INTERPRETATION:
- Order_Pass_Rate: % of POs that passed inspection (management KPI)
- Volume_Pass_Rate: % of total pairs that passed (financial impact)
- Volume_Pass_Rate is typically more important - one large order matters more
- Target: >95% pass rate for most customers
- Failed orders require rework or negotiation with customer

BUSINESS IMPACT:
- Daily tracking prevents last-minute shipment surprises
- Early warning allows time for corrective action
- Ties quality performance to shipment readiness
*/


-- =============================================================================
-- QUERY 3: COUNTRY-SPECIFIC ORDER STATUS (CHINA EXAMPLE)
-- Monitors order completion for high-priority customers
-- =============================================================================

SELECT 
    A.Sales_Order_Number,
    C.Line_Code,
    
    -- Order Quantities
    SUM(C.Lot_Quantity) AS Target_Quantity,
    SUM(C.Assembly_End_Quantity) AS Completed_Quantity,
    
    -- Customer Information
    B.Country,
    
    -- Completion Status
    CASE 
        WHEN SUM(C.Lot_Quantity) = SUM(C.Assembly_End_Quantity) 
            THEN 'Complete'
        ELSE 'In Progress'
    END AS Order_Status

FROM
    (
        -- Subquery: Get current load plan (scheduled shipments)
        SELECT DISTINCT(Sales_Order_Number) 
        FROM load_plan WITH (NOLOCK)
        WHERE Plan_Version IN (
            SELECT MAX(Plan_Version) 
            FROM load_plan WITH (NOLOCK)
        )
        AND Building_Code = 'A'  -- Factory A
    ) AS A

    -- Join with shipping mark info (customer details)
    JOIN shipping_mark_info AS B WITH (NOLOCK)
        ON A.Sales_Order_Number = B.PO_Number

    -- Join with production history (actual production)
    JOIN production_history AS C WITH (NOLOCK)
        ON A.Sales_Order_Number = C.PO_Number

WHERE 
    B.Country = 'CHINA'  -- Filter for China orders (can parameterize)

GROUP BY 
    A.Sales_Order_Number, 
    B.Country, 
    C.Line_Code;

/*
INTERPRETATION:
- Shows which China orders are complete vs. still in production
- Helps prioritize production lines to meet critical shipment deadlines
- Can be modified for any country/customer by changing WHERE clause

USAGE:
- Run daily to track progress on high-priority orders
- Alert when order completion falls behind schedule
- Coordinate with planning team on resource allocation
*/


-- =============================================================================
-- COMBINED DASHBOARD METRICS (TYPICAL DAILY SUMMARY)
-- =============================================================================

/*
The above three queries are typically combined in a dashboard showing:

1. TOP SECTION - Defect Focus
   - Top 3 defects today with defect rates
   - Trend vs. yesterday/last week
   - Action: Focus training on #1 defect

2. MIDDLE SECTION - AQL Compliance
   - Today's pass rate (target: >95%)
   - Volume passed (ready to ship)
   - Failed orders needing attention
   - Action: Review failed orders, decide on rework vs. negotiate

3. BOTTOM SECTION - Order Status
   - High-priority customer orders completion %
   - Orders at risk of missing shipment
   - Action: Reallocate resources to at-risk orders

TYPICAL EXECUTIVE SUMMARY:
"Today: 94% AQL pass rate (target 95%). Top defect: Stitching (2.3% of production).
 China Order #12345 at 85% completion - needs focus to meet Friday shipment."
*/


-- =============================================================================
-- NOTES FOR IMPLEMENTATION
-- =============================================================================

/*
1. PERFORMANCE OPTIMIZATION:
   - Index on: PO_Number, Timestamp, Factory, Defect_Code
   - WITH (NOLOCK) for real-time reporting
   - Query execution: <1 second for typical daily volume

2. DATA REFRESH:
   - Run every 15-30 minutes during production hours
   - Stored procedure with date parameters
   - Results cached in summary tables for dashboard

3. ALERTING RULES:
   - Alert if any defect exceeds 3% of production
   - Alert if AQL pass rate drops below 93%
   - Alert if high-priority order completion < 80% two days before shipment

4. TYPICAL USERS:
   - Quality Manager: Defect analysis for corrective action
   - Shipping Coordinator: AQL pass rate for shipment readiness
   - Production Planner: Order status for resource allocation

5. INTEGRATION:
   - Feeds Power BI dashboard updated every 30 minutes
   - Email alerts for threshold breaches
   - Mobile app for quality managers (view on shop floor)
*/
