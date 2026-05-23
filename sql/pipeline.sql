SET VARIABLE smoothing_factor = 0.65;
SET VARIABLE thinning_threshold = 0.22;

WITH RECURSIVE
smoothing_phase(pos, x, y) AS (
    SELECT pos,
        x,
        y
    FROM raw_data
    WHERE pos = 1
    UNION ALL
    SELECT r.pos,
        getvariable('smoothing_factor')*s.x + (1 - getvariable('smoothing_factor')) * r.x AS sx,
        getvariable('smoothing_factor')*s.y + (1 - getvariable('smoothing_factor')) * r.y AS sy
    FROM raw_data r
        JOIN smoothing_phase s ON r.pos = s.pos + 1
),
thinning_scan(pos, x, y) AS (
    SELECT pos, x, y
    FROM smoothing_phase
    WHERE pos = 1
    UNION ALL
    SELECT next_keep.pos, next_keep.x, next_keep.y
    FROM thinning_scan ts
    CROSS JOIN LATERAL (
        SELECT pos, x, y
        FROM smoothing_phase
        WHERE pos > ts.pos
          AND sqrt((x - ts.x)^2 + (y - ts.y)^2) > getvariable('thinning_threshold')
        ORDER BY pos
        LIMIT 1
    ) next_keep
),
curvature_directions_calc(pos, x, y, direction) AS (
    SELECT
        pos,
        x,
        y,
        CASE
            WHEN ABS(x - LAG(x) OVER w) >= ABS(y - LAG(y) OVER w)
            THEN CASE WHEN x >= LAG(x) OVER w THEN 'right' ELSE 'left' END
            ELSE CASE WHEN y >= LAG(y) OVER w THEN 'up' ELSE 'down' END
        END AS direction
    FROM thinning_scan
    WINDOW w AS (ORDER BY pos)
),
curvature_cleanup(pos, x, y, direction) AS (
    SELECT pos, x, y, direction
    FROM (
        SELECT
            pos,
            x,
            y,
            direction,
            LAG(direction) OVER (ORDER BY pos) AS prev_direction
        FROM curvature_directions_calc
        WHERE direction IS NOT NULL
    ) t
    WHERE direction IS DISTINCT FROM prev_direction
),
directions_16_calc(pos, x, y, direction) AS (
    SELECT
        pos,
        x,
        y,
        CAST(((ATAN2(y - LAG(y) OVER w2, x - LAG(x) OVER w2) * 180 / PI() + 360 + 11.25) % 360) / 22.5 AS INTEGER) AS direction
    FROM thinning_scan
    WINDOW w2 AS (ORDER BY pos)
),
corners(pos, x, y) AS (
    SELECT pos, x, y
    FROM directions_16_calc
    WHERE direction IS NOT NULL
    WINDOW w3 AS (ORDER BY pos)
    QUALIFY
        LEAST(ABS(LEAD(direction, 1) OVER w3 - LAG(direction, 1) OVER w3),
              16 - ABS(LEAD(direction, 1) OVER w3 - LAG(direction, 1) OVER w3)) >= 4
        AND LAG(direction, 1) OVER w3 = LAG(direction, 2) OVER w3
        AND LEAD(direction, 1) OVER w3 = LEAD(direction, 2) OVER w3
)
SELECT *
FROM corners 
ORDER BY pos
LIMIT 30;
