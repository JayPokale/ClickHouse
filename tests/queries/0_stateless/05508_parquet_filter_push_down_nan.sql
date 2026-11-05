-- Tags: no-fasttest, no-random-settings
-- no-fasttest: the Parquet format is not available in fast test builds

-- The min/max statistics of a Parquet row group or page leave out NaN. A comparison that is true for NaN
-- (`NOT (x < 5)`, `x != 1`) can therefore be true in a row group whose [min, max] fails it. Filter push down
-- must not drop such a row group, so the result must not depend on the setting.
-- Row groups of 3 rows: [1, NaN, 2], [NaN, NaN, NaN], [10, 20, 30], [1, 1, NaN].

set max_insert_threads = 1;
set engine_file_truncate_on_insert = 1;
set output_format_parquet_row_group_size = 3;

INSERT INTO FUNCTION file(currentDatabase() || '_05508.parquet', Parquet, 'x Float64, y Float32')
SELECT x, toFloat32(x) FROM (SELECT arrayJoin([1, nan, 2, nan, nan, nan, 10, 20, 30, 1, 1, nan]) AS x);

SELECT 'NOT (x < 5)',
    (SELECT count() FROM file(currentDatabase() || '_05508.parquet') WHERE NOT (x < 5)),
    (SELECT count() FROM file(currentDatabase() || '_05508.parquet') WHERE NOT (x < 5) SETTINGS input_format_parquet_filter_push_down = 0, input_format_parquet_page_filter_push_down = 0);
SELECT 'NOT (x <= 5)',
    (SELECT count() FROM file(currentDatabase() || '_05508.parquet') WHERE NOT (x <= 5)),
    (SELECT count() FROM file(currentDatabase() || '_05508.parquet') WHERE NOT (x <= 5) SETTINGS input_format_parquet_filter_push_down = 0, input_format_parquet_page_filter_push_down = 0);
SELECT 'NOT (y < 5)',
    (SELECT count() FROM file(currentDatabase() || '_05508.parquet') WHERE NOT (y < 5)),
    (SELECT count() FROM file(currentDatabase() || '_05508.parquet') WHERE NOT (y < 5) SETTINGS input_format_parquet_filter_push_down = 0, input_format_parquet_page_filter_push_down = 0);
SELECT 'x != 1',
    (SELECT count() FROM file(currentDatabase() || '_05508.parquet') WHERE x != 1),
    (SELECT count() FROM file(currentDatabase() || '_05508.parquet') WHERE x != 1 SETTINGS input_format_parquet_filter_push_down = 0, input_format_parquet_page_filter_push_down = 0);
SELECT 'x NOT IN (1, 2)',
    (SELECT count() FROM file(currentDatabase() || '_05508.parquet') WHERE x NOT IN (1, 2)),
    (SELECT count() FROM file(currentDatabase() || '_05508.parquet') WHERE x NOT IN (1, 2) SETTINGS input_format_parquet_filter_push_down = 0, input_format_parquet_page_filter_push_down = 0);
SELECT 'NOT (x > 5)',
    (SELECT count() FROM file(currentDatabase() || '_05508.parquet') WHERE NOT (x > 5)),
    (SELECT count() FROM file(currentDatabase() || '_05508.parquet') WHERE NOT (x > 5) SETTINGS input_format_parquet_filter_push_down = 0, input_format_parquet_page_filter_push_down = 0);
-- Comparisons that are false for NaN still prune row groups.
SELECT 'x >= 5',
    (SELECT count() FROM file(currentDatabase() || '_05508.parquet') WHERE x >= 5),
    (SELECT count() FROM file(currentDatabase() || '_05508.parquet') WHERE x >= 5 SETTINGS input_format_parquet_filter_push_down = 0, input_format_parquet_page_filter_push_down = 0);
