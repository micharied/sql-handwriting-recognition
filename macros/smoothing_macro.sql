CREATE OR REPLACE MACRO smoothing(stroke_id_param, factor) AS TABLE WITH RECURSIVE smoothed AS (
        SELECT id,
            stroke_id,
            x,
            y
        FROM raw_data
        WHERE stroke_id = stroke_id_param
            AND id = (
                SELECT MIN(id)
                FROM raw_data
                WHERE stroke_id = stroke_id_param
            )
        UNION ALL
        SELECT r.id,
            r.stroke_id,
            factor*s.x + (1 - factor) * r.x AS sx,
            factor*s.y + (1 - factor) * r.y AS sy
        FROM raw_data r
            JOIN smoothed s ON r.id = s.id + 1
        WHERE r.stroke_id = stroke_id_param
    )
SELECT *
FROM smoothed
ORDER BY id;