CREATE TABLE sensores (
    sensor_id VARCHAR(20),
    temperature DOUBLE,
    humidity DOUBLE,
    air_quality_index DOUBLE,
    event_time TIMESTAMP_LTZ(3),
    WATERMARK FOR event_time AS event_time - INTERVAL '10' SECOND
) WITH (
    'connector' = 'kinesis',
    'stream.arn' = '{stream_arn}',
    'aws.region' = '{region}',
    'source.init.position' = '{init_position}',
    'format' = 'json',
    'json.timestamp-format.standard' = 'ISO-8601'
)
