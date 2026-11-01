WITH order_pick_state AS(
    SELECT 
        DATE(op.completed_at) AS pick_date,
        COUNT(*) AS cnt_picking,
        AVG(EXTRACT(MINUTE FROM (op.completed_at - o.created_at)) 
            + EXTRACT(HOUR FROM (op.completed_at - o.created_at)) * 60 
            + EXTRACT(DAY FROM (op.completed_at - o.created_at)) * 1440 )
            AS avg_time_min,
        COALESCE(SUM(af.actual_quantity), 0) AS total_units,
        d.ID_Darkstore,
        d.address

        FROM orderpicking op
        JOIN actualfulfillment af ON op.ID_OrderPicking = af.ID_OrderPicking
        JOIN orders o ON op.ID_Order = o.ID_Order      
        JOIN darkstore d ON o.ID_Darkstore = d.ID_Darkstore
        WHERE o.created_at BETWEEN '2025-01-01' AND '2026-09-01' AND op.status = 'Completed'
        GROUP BY DATE(op.completed_at), d.ID_Darkstore, pick_date
)
SELECT 
    AVG(avg_time_min) OVER(PARTITION BY ID_Darkstore ORDER BY pick_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7_days,
    SUM(cnt_picking) OVER(PARTITION BY ID_Darkstore ORDER BY pick_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_sum_7_days,
    pick_date,
    ID_Darkstore,
    address,
    cnt_picking,
    avg_time_min,
    total_units
FROM order_pick_state
ORDER BY ID_Darkstore, pick_date;