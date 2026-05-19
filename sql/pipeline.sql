SET VARIABLE smoothing_factor = 0.8;
SET VARIABLE thinning_threshold = 0.20;

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
thinning_scan(pos, x, y, last_keep_x, last_keep_y, keep_point) AS (
    SELECT pos,
        x,
        y,
        x AS last_keep_x,
        y AS last_keep_y,
        TRUE AS keep_point
    FROM smoothing_phase
    WHERE pos = 1
    UNION ALL
    SELECT s.pos,
        s.x,
        s.y,
        CASE WHEN sqrt((s.x - t.last_keep_x)^2 + (s.y - t.last_keep_y)^2) > getvariable('thinning_threshold')
            THEN s.x ELSE t.last_keep_x
        END AS last_keep_x,
        CASE WHEN sqrt((s.x - t.last_keep_x)^2 + (s.y - t.last_keep_y)^2) > getvariable('thinning_threshold')
            THEN s.y ELSE t.last_keep_y
        END AS last_keep_y,
        sqrt((s.x - t.last_keep_x)^2 + (s.y - t.last_keep_y)^2) > getvariable('thinning_threshold') AS keep_point
    FROM thinning_scan t
    JOIN smoothing_phase s
        ON s.pos = t.pos + 1
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
    WHERE keep_point
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
)
SELECT *
FROM curvature_cleanup
ORDER BY pos;
