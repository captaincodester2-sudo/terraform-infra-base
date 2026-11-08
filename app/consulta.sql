INSERT INTO resultados
SELECT
    window_start,
    window_end,
    sensor_id,
    AVG(temperature) AS avg_temperature,
    AVG(air_quality_index) AS avg_air_quality_index,
    COUNT(*) AS mediciones
FROM TABLE(
    TUMBLE(
        TABLE sensores,
        DESCRIPTOR(event_time),
        INTERVAL '1' MINUTE
    )
)
GROUP BY window_start, window_end, sensor_id;