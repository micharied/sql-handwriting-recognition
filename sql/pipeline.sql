SET VARIABLE smoothing_factor = 0.8;
SET VARIABLE thinning_threshold = 2;

CREATE OR REPLACE TEMPORARY MACRO cell_of(px, py, min_x, min_y, w, h) AS
    LEAST(FLOOR((px - min_x) / NULLIF(w, 0) * 4), 3)::INTEGER * 4
    + LEAST(FLOOR((py - min_y) / NULLIF(h, 0) * 4), 3)::INTEGER;

CREATE OR REPLACE TABLE character_direction_rules AS
SELECT * FROM (VALUES
    ('2', ['up', 'right', 'down', 'right']),
    ('5', ['left', 'down', 'right', 'down']),
    ('A', ['up', 'down', 'up', 'left']),
    ('B', ['up', 'right', 'down', 'left']),
    ('C', ['left', 'down', 'right']),
    ('D', ['up', 'right', 'down', 'left']),
    ('E', ['left', 'down', 'right', 'left']),
    ('F', ['left', 'down', 'right', 'left']),
    ('G', ['left', 'down', 'right', 'up', 'left']),
    ('H', ['down', 'up', 'right', 'up', 'down']),
    ('I', ['down']),
    ('K', ['down', 'up', 'right', 'up']),
    ('L', ['down', 'right']),
    ('M', ['up', 'down', 'up', 'down']),
    ('N', ['up', 'down', 'up']),
    ('O', ['left', 'down', 'right', 'up']),
    ('P', ['up', 'right', 'down', 'left']),
    ('Z', ['right', 'down', 'right'])
) AS t(char, prefix);

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
curvatures(pos, x, y, direction) AS (
    SELECT pos, x, y, direction
    FROM (
        SELECT
            pos,
            x,
            y,
            CASE
                WHEN LAG(x) OVER w IS NULL THEN NULL
                WHEN ABS(x - LAG(x) OVER w) >= ABS(y - LAG(y) OVER w)
                THEN CASE WHEN x >= LAG(x) OVER w THEN 'right' ELSE 'left' END
                ELSE CASE WHEN y >= LAG(y) OVER w THEN 'up' ELSE 'down' END
            END AS direction
        FROM thinning_scan
        WINDOW w AS (ORDER BY pos)
    )
    QUALIFY direction IS DISTINCT FROM LAG(direction) OVER (ORDER BY pos)
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
),
first_directions AS (
    SELECT list(direction ORDER BY pos) AS dirs
    FROM curvatures
),
character_recognition AS (
    SELECT DISTINCT cdr.char
    FROM first_directions fd
    CROSS JOIN character_direction_rules cdr
    WHERE
        fd.dirs[1:len(cdr.prefix)] = cdr.prefix
)
SELECT * FROM character_recognition;
