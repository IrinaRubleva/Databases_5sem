WITH price_history AS (
    SELECT 
        p.ID_Product,
        pr.name_,
        pr.category,
        p.ID_Darkstore,
        d.address,
        p.valid_from,
        p.price_value,
        LAG(p.price_value) OVER (
            PARTITION BY p.ID_Product, p.ID_Darkstore 
            ORDER BY p.valid_from
        ) AS prev_price,
        LAG(p.valid_from) OVER (
            PARTITION BY p.ID_Product, p.ID_Darkstore 
            ORDER BY p.valid_from
        ) AS prev_valid_from
    FROM Price p
    JOIN Product pr ON pr.ID_Product = p.ID_Product
    JOIN DarkStore d ON d.ID_Darkstore = p.ID_Darkstore
    WHERE p.valid_from BETWEEN '2022-01-01' AND '2026-12-31'  --количество дней или часов
    
)
SELECT 
    ID_Product,
    name_,
    category,
    address,
    valid_from AS new_price_date,
    price_value AS curr_price,
    prev_price,
    ABS(price_value - prev_price) AS abs_change_price, -- абсолютное изменение
    (price_value - prev_price)/prev_price * 100 AS per_change_price, -- процентное изменение
    EXTRACT(DAY FROM (valid_from - prev_valid_from)) AS long_prev_period_day, -- длительность предыдущего периода
    CASE WHEN ABS((price_value - prev_price)/prev_price * 100) > 15 THEN true ELSE false END AS per_change-- изменение > 15%
FROM price_history
WHERE prev_price IS NOT NULL 
  AND price_value <> prev_price
ORDER BY ID_Product, ID_Darkstore, valid_from;