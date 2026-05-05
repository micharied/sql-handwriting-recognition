WITH RECURSIVE
raw_data(id, stroke_id, x, y) AS (
    VALUES  (1, 1, 0.0::DECIMAL(8,4), 0.0::DECIMAL(8,4)),
            (2, 1, 1.0::DECIMAL(8,4), 1.0::DECIMAL(8,4)),
            (3, 1, 2.0::DECIMAL(8,4), 2.0::DECIMAL(8,4)),
            (4, 2, 5.0::DECIMAL(8,4), 5.0::DECIMAL(8,4)),
            (5, 2, 6.0::DECIMAL(8,4), 6.0::DECIMAL(8,4))
),
smoothing_phase(id, stroke_id, x, y) AS (
    SELECT id,
        stroke_id,
        x,
        y
    FROM raw_data
    WHERE id = (
            SELECT MIN(id)
            FROM raw_data
            WHERE stroke_id = 1
        )
    UNION ALL
    SELECT r.id,
        r.stroke_id,
        factor*s.x + (1 - factor) * r.x AS sx,
        factor*s.y + (1 - factor) * r.y AS sy   
    FROM raw_data r
        JOIN smoothing_phase s ON r.id = s.id + 1
    WHERE r.stroke_id = 1
),
thinning_phase(id, stroke_id, x, y) AS (
    SELECT id, stroke_id, x, y
    FROM smoothing_phase
)
SELECT *
FROM thinning_phase
ORDER BY stroke_id;
