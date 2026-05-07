CREATE TABLE IF NOT EXISTS raw_data (
    id INTEGER PRIMARY KEY,
    stroke_id INTEGER NOT NULL,
    x DECIMAL(8, 4) NOT NULL,
    y DECIMAL(8, 4) NOT NULL
);

CREATE SEQUENCE IF NOT EXISTS raw_data_id_seq START 1;

CREATE SEQUENCE IF NOT EXISTS stroke_id_seq START 1;


WITH stroke AS (
    SELECT nextval('stroke_id_seq') AS stroke_id
)
INSERT INTO raw_data (id, stroke_id, x, y)
SELECT nextval('raw_data_id_seq') AS id,
    stroke.stroke_id,
    x,
    y
FROM read_json_auto('sql/import.json'), stroke;

SELECT max(stroke_id) FROM raw_data;