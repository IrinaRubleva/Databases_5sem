WITH order_issues AS(
    SELECT
    --позиция заказа без созданного резерва
    CASE WHEN o.status IN ('Confirmed', 'Assembling', 'Ready', 'Delivering', 'Delivered') 
    THEN (
        SELECT COUNT(*)
        FROM orderposition op
        WHERE op.ID_Order = o.ID_Order 
            AND NOT EXISTS(
                SELECT 1
                FROM reserve r
                WHERE r.ID_OrderPosition = op.ID_OrderPosition
            )
    ) ELSE 0 
    END AS cnt_pos_without_reserve,

    --завершённая сборка без фактически зафиксированных партий товара
    CASE WHEN NOT EXISTS (
        SELECT 1 
        FROM OrderPicking op
        JOIN ActualFulfillment af ON af.ID_OrderPicking = op.ID_OrderPicking
        WHERE op.ID_Order = o.ID_Order
    ) AND EXISTS (
        SELECT 1 FROM OrderPicking opick 
        WHERE opick.ID_Order = o.ID_Order AND opick.status = 'Completed'
    )   THEN 1 ELSE 0 
    END AS cnt_pos_no_fulfillment,

    --заказ в статусе доставки без созданной записи доставки
    CASE WHEN NOT EXISTS(
        SELECT 1
        FROM orderdelivery od 
        WHERE od.ID_Order = o.ID_Order
    ) AND o.status IN ('Delivering', 'Delivered')
    THEN 1 ELSE 0 
    END AS cnt_pos_no_delivery,


    --доставленный заказ без успешной операции окончательного списания оплаты
    CASE WHEN o.status = 'Delivered' 
        AND NOT EXISTS(
            SELECT 1
            FROM transactions t
            WHERE t.ID_Order = o.ID_Order 
                AND t.operation_type = 'Capture' AND t.status = 'Success'
        ) THEN 1 ELSE 0 
    END AS cnt_pos_no_transaction,

    (SELECT COUNT(*) 
    FROM orderposition op 
    WHERE op.ID_Order = o.ID_Order) AS cnt_pos,
    o.ID_Order,
    o.ID_Darkstore,
    o.created_at,
    o.status

    FROM orders o
    WHERE o.created_at >= NOW() - INTERVAL '30 days'
)
SELECT ID_Order,
    ID_Darkstore,
    created_at,
    status,
    cnt_pos,
    cnt_pos_without_reserve,
    cnt_pos_no_delivery,
    cnt_pos_no_fulfillment,
    cnt_pos_no_transaction
FROM order_issues
WHERE cnt_pos_without_reserve > 0 
   OR cnt_pos_no_delivery = 1 
   OR cnt_pos_no_fulfillment = 1 
   OR cnt_pos_no_transaction = 1
ORDER BY created_at DESC;