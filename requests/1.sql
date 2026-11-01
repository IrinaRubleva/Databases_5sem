WITH order_states AS(
    SELECT 
        o.ID_Darkstore,
        o.ID_Order,
        o.final_amount,
        o.status,
        EXTRACT(MINUTE FROM (op.completed_at - o.created_at)) 
        + EXTRACT(HOUR FROM (op.completed_at - o.created_at)) * 60 
        + EXTRACT(DAY FROM (op.completed_at - o.created_at)) * 1440 
        AS diff_in_minutes,
        CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END AS order_cancelled,
        CASE WHEN EXISTS (
            SELECT 1
            FROM orderposition op
            JOIN SubstitutionOffer so ON op.ID_OrderPosition = so.ID_OrderPosition
            JOIN SubstitutionDecision sd ON so.ID_SubstitutionOffer = sd.ID_SubstitutionOffer
            WHERE op.ID_Order = o.ID_Order AND sd.decision_type = 'Accept'
        ) THEN 1 ELSE 0 END AS orders_sub,      --ассепнули замену
        CASE WHEN EXISTS (
            SELECT 1 FROM OrderPosition op 
            WHERE op.ID_Order = o.ID_Order AND op.status = 'Substituted'
            ) THEN 1 ELSE 0 END AS offer_sub    --предложили змену 
    FROM orders o 
    LEFT JOIN OrderPicking op ON o.ID_Order = op.ID_Order
    WHERE o.created_at BETWEEN '2025-01-01' AND '2026-09-01'
),
darkstore_states AS (
    SELECT ID_Darkstore,
        COUNT(*) AS cnt_rows,
        SUM(orders_sub) AS cnt_orders_sub,
        SUM(order_cancelled) AS cnt_order_cancelled,
        AVG(final_amount) AS avg_amount,
        AVG(diff_in_minutes) AS avg_time,

        SUM(offer_sub) AS cnt_offered_sub,
        SUM(orders_sub) AS cnt_accepted_sub,
        SUM(order_cancelled) AS cnt_cancelled,
        SUM(offer_sub)::float8 / COUNT(*) * 100 AS sub_dl,
        SUM(order_cancelled)::float8 / COUNT(*) * 100 AS cancel_dl,
        SUM
            (CASE WHEN (offer_sub = 1 OR order_cancelled = 1) THEN 1 ELSE 0 END)::float8 / COUNT(*) AS problems

    FROM order_states
    GROUP BY ID_Darkstore
)
SELECT *
FROM darkstore_states
WHERE cnt_rows >= 20 
    --AND (cnt_orders_sub::float8 /cnt_rows) > 0.10
ORDER BY problems DESC;