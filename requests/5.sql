WITH batch_state AS(
    SELECT v.ID_Vendor,
        v.name_,
        b.ID_Batch,
        b.ID_Product,
        b.init_quantity, 
        EXTRACT(DAY FROM expiration_date - acceptance_date)  AS dur_life  --для "среднее число дней от приёмки партии до окончания срока годности"
    FROM Batch b
    JOIN Vendor v ON v.ID_Vendor = b.ID_Vendor
    WHERE acceptance_date BETWEEN '2026-01-01' AND '2026-12-01'
),
writesoff AS (
    SELECT 
        b.ID_Vendor,
        SUM(w.quantity) AS writesoff_qty
    FROM WriteOff w
    JOIN Batch b ON w.ID_Batch = b.ID_Batch
    --"объём списаний по причинам истечения срока годности или порчи"
    WHERE w.reason IN ('Expirated', 'Damaged') 
    AND b.acceptance_date >= '2026-01-01' AND b.acceptance_date <  '2026-12-02' 
    GROUP BY b.ID_Vendor
), 
used_prod AS(
    SELECT 
        b.ID_Vendor,
        COUNT(DISTINCT b.ID_Batch) AS cnt_used_batches
    FROM Batch b
    JOIN ActualFulfillment af ON b.ID_Batch = af.ID_Batch  
    WHERE b.acceptance_date >= '2026-01-01' AND b.acceptance_date < '2026-12-02'
    GROUP BY b.ID_Vendor
),
vendors AS(
    SELECT 
        bs.ID_Vendor,
        bs.name_,
        COUNT(*) AS cnt_batches,  --количество принятых партий
        COUNT(DISTINCT bs.ID_Product) AS cnt_products, --количество различных поставляемых товаров
        SUM(bs.init_quantity) AS total_init_qty, --суммарный первоначальный объём
        COALESCE(w.writesoff_qty, 0) AS writesoff_qty, --объём списаний
        ROUND(COALESCE(w.writesoff_qty, 0)::numeric / NULLIF(SUM(bs.init_quantity), 0) * 100, 2) AS writesoff_per,   --долю списанного объёма
        COALESCE(ub.cnt_used_batches, 0) AS cnt_used_batches,
        ROUND(AVG(bs.dur_life), 2)  AS avg_dur_life   --cреднее число дней от приёмки партии до окончания срока годности
        FROM batch_state bs
        LEFT JOIN writesoff w ON bs.ID_Vendor = w.ID_Vendor
        LEFT JOIN used_prod ub ON bs.ID_Vendor = ub.ID_Vendor
        GROUP BY bs.ID_Vendor, bs.name_, w.writesoff_qty, ub.cnt_used_batches
        HAVING COUNT(*) >= 5
)
SELECT 
    ID_Vendor,
    name_,
    cnt_batches,
    cnt_products,
    total_init_qty,
    writesoff_qty,
    writesoff_per,
    cnt_used_batches,
    avg_dur_life,
    
    ROW_NUMBER() OVER (ORDER BY writesoff_per) AS rating_place,
    NTILE(4) over(ORDER BY writesoff_per) AS qual_gr
FROM vendors
ORDER BY rating_place;