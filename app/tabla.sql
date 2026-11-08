CREATE TABLE sensores (
    sensor_num INT,
    sensor_id AS CONCAT('sensor-0', CAST(sensor_num AS STRING)),
    temperature DOUBLE,
    humidity DOUBLE,
    air_quality_index DOUBLE,
    event_time TIMESTAMP_LTZ(3),
    WATERMARK FOR event_time AS event_time - INTERVAL '10' SECOND
) WITH (
    'connector' = 'datagen',
    'rows-per-second' = '5',

    'fields.temperature.min' = '10',
    'fields.temperature.max' = '35',

    'fields.humidity.min' = '30',
    'fields.humidity.max' = '90',

    'fields.air_quality_index.min' = '0',
    'fields.air_quality_index.max' = '300',

    'fields.sensor_num.min' = '1',
    'fields.sensor_num.max' = '5'
)