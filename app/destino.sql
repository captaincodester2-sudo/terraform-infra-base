CREATE TABLE resultados (
    window_start TIMESTAMP_LTZ(3),
    window_end TIMESTAMP_LTZ(3),
    sensor_id VARCHAR(20),
    avg_temperature DOUBLE,
    avg_air_quality_index DOUBLE,
    mediciones BIGINT
) WITH (
    'connector' = 'print'
)