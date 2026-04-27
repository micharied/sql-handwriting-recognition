CREATE OR REPLACE TABLE raw_data AS
SELECT *
FROM (
        VALUES  (1, 1, 0.0::DECIMAL(8,4), 0.0::DECIMAL(8,4)),
                (2, 1, 1.0::DECIMAL(8,4), 1.0::DECIMAL(8,4)),
                (3, 1, 2.0::DECIMAL(8,4), 2.0::DECIMAL(8,4)),
                (4, 2, 5.0::DECIMAL(8,4), 5.0::DECIMAL(8,4)),
                (5, 2, 6.0::DECIMAL(8,4), 6.0::DECIMAL(8,4))
    ) AS seeded_raw_data(id, stroke_id, x, y);

.read macros/smoothing_macro.sql

SELECT *
FROM smoothing(1, 0.2);
