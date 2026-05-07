WITH RECURSIVE
smoothing_phase(id, stroke_id, x, y) AS (
    SELECT id,
        stroke_id,
        x,
        y
    FROM raw_data
    WHERE id = (
            SELECT MIN(id)
            FROM raw_data
            WHERE stroke_id = 186
        )
    UNION ALL
    SELECT r.id,
        r.stroke_id,
        0.8*s.x + (1 - 0.8) * r.x AS sx,
        0.8*s.y + (1 - 0.8) * r.y AS sy   
    FROM raw_data r
        JOIN smoothing_phase s ON r.id = s.id + 1
),
thinning_scan(stroke_id, id, x, y, last_keep_x, last_keep_y, keep_point) AS (
    SELECT stroke_id,
        id,
        x,
        y,
        x AS last_keep_x,
        y AS last_keep_y,
        TRUE AS keep_point
    FROM smoothing_phase
    WHERE id IN (SELECT MIN(id) FROM smoothing_phase GROUP BY stroke_id)
    UNION ALL
    SELECT s.stroke_id,
        s.id,
        s.x,
        s.y,
        CASE
            WHEN ABS(s.x - t.last_keep_x) >= 0.20::DECIMAL(8,4)
                OR ABS(s.y - t.last_keep_y) >= 0.20::DECIMAL(8,4) THEN s.x
            ELSE t.last_keep_x
        END AS last_keep_x,
        CASE
            WHEN ABS(s.x - t.last_keep_x) >= 0.20::DECIMAL(8,4)
                OR ABS(s.y - t.last_keep_y) >= 0.20::DECIMAL(8,4) THEN s.y
            ELSE t.last_keep_y
        END AS last_keep_y,
        ABS(s.x - t.last_keep_x) >= 0.20::DECIMAL(8,4)
            OR ABS(s.y - t.last_keep_y) >= 0.20::DECIMAL(8,4) AS keep_point
    FROM thinning_scan t
    JOIN smoothing_phase s
        ON s.stroke_id = t.stroke_id
        AND s.id = t.id + 1
),
thinning_phase(id, stroke_id, x, y) AS (
    SELECT id,
        stroke_id,
        x,
        y
    FROM thinning_scan
    WHERE keep_point
),
curvature_directions_calc(id, stroke_id, x, y, direction) AS (
    SELECT
        id,
        stroke_id,
        x,
        y,
        CASE
            WHEN ABS(x - LAG(x) OVER w) >= ABS(y - LAG(y) OVER w)
            THEN CASE WHEN x >= LAG(x) OVER w THEN 'right' ELSE 'left' END
            ELSE CASE WHEN y >= LAG(y) OVER w THEN 'up' ELSE 'down' END
        END AS direction
    FROM thinning_phase
    WINDOW w AS (PARTITION BY stroke_id ORDER BY id)
),
curvature_cleanup(id, stroke_id, x, y, direction) AS (
    SELECT id, stroke_id, x, y, direction
    FROM (
        SELECT
            id,
            stroke_id,
            x,
            y,
            direction,
            LAG(direction) OVER (PARTITION BY stroke_id ORDER BY id) AS prev_direction
        FROM curvature_directions_calc
        WHERE direction IS NOT NULL
    ) t
    WHERE direction IS DISTINCT FROM prev_direction
)
SELECT *
FROM curvature_cleanup
ORDER BY stroke_id, id;
