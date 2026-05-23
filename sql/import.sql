DROP TABLE IF EXISTS raw_data;

CREATE TABLE IF NOT EXISTS raw_data (
    pos INTEGER PRIMARY KEY,
    x DECIMAL(8, 4) NOT NULL,
    y DECIMAL(8, 4) NOT NULL
);

DROP SEQUENCE IF EXISTS raw_data_pos_seq;
CREATE SEQUENCE raw_data_pos_seq START 1;

INSERT INTO raw_data (pos, x, y)
SELECT nextval('raw_data_pos_seq') AS pos,
    x,
    y
FROM read_json_auto('sql/Z_2.json');
