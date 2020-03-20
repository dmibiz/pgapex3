CREATE OR REPLACE FUNCTION pgapex.f_get_schema_meta_info(
  database VARCHAR
, username VARCHAR
, password VARCHAR
)
RETURNS TABLE (
  schema_name VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT res_schema_name
  FROM
  dblink(
    'dbname=' || database || ' user=' || username || ' password=' || password,
    'SELECT nspname FROM pg_catalog.pg_namespace ' ||
    'WHERE nspname NOT IN (''information_schema'', ''pg_catalog'') ' ||
    '  AND nspname NOT LIKE ''pg_toast%'' ' ||
    '  AND nspname NOT LIKE ''pg_temp%'''
  ) AS (
    res_schema_name VARCHAR
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN;
END
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_get_view_meta_info(
  database VARCHAR
, username VARCHAR
, password VARCHAR
)
RETURNS TABLE (
  schema_name VARCHAR
, view_name   VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    res_schema_name
  , res_view_name
  FROM
  dblink(
    'dbname=' || database || ' user=' || username || ' password=' || password,
    'SELECT n.nspname, c.relname ' ||
    'FROM pg_class c ' ||
    'LEFT JOIN pg_namespace n ON n.oid = c.relnamespace ' ||
    'WHERE c.relkind IN (''v'', ''m'') ' ||
    '  AND n.nspname NOT IN (''information_schema'', ''pg_catalog'') ' ||
    '  AND n.nspname NOT LIKE ''pg_toast%'' ' ||
    '  AND n.nspname NOT LIKE ''pg_temp%'''
  ) AS (
    res_schema_name VARCHAR
  , res_view_name VARCHAR
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN;
END
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_get_view_column_meta_info(
  database VARCHAR
, username VARCHAR
, password VARCHAR
)
RETURNS TABLE (
  schema_name   VARCHAR
, view_name     VARCHAR
, column_name   VARCHAR
, column_type   VARCHAR
, column_number VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    res_schema_name
  , res_view_name
  , res_column_name
  , res_column_type
  , res_column_number
  FROM
  dblink(
    'dbname=' || database || ' user=' || username || ' password=' || password,
    'SELECT n.nspname, c.relname, a.attname, t.typname, a.attnum ' ||
    'FROM pg_catalog.pg_class c ' ||
    'LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace ' ||
    'LEFT JOIN pg_catalog.pg_attribute a ON a.attrelid = c.oid ' ||
    'LEFT JOIN pg_catalog.pg_type t ON a.atttypid = t.oid ' ||
    'WHERE c.relkind IN (''v'', ''m'') ' ||
    '  AND n.nspname NOT IN (''information_schema'', ''pg_catalog'') ' ||
    '  AND n.nspname NOT LIKE ''pg_toast%'' ' ||
    '  AND n.nspname NOT LIKE ''pg_temp%'' ' ||
    '  AND a.attnum > 0 ' ||
    '  AND NOT a.attisdropped'
  ) AS (
    res_schema_name   VARCHAR
  , res_view_name     VARCHAR
  , res_column_name   VARCHAR
  , res_column_type   VARCHAR
  , res_column_number VARCHAR
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN;
END
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_get_function_meta_info(
  database VARCHAR
, username VARCHAR
, password VARCHAR
)
RETURNS TABLE (
  schema_name   VARCHAR
, function_name VARCHAR
, return_type   VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    res_schema_name
  , res_function_name
  , res_return_type
  FROM
  dblink(
    'dbname=' || database || ' user=' || username || ' password=' || password,
    'SELECT n.nspname, p.proname, t.typname ' ||
    'FROM pg_catalog.pg_proc p ' ||
    'LEFT JOIN pg_catalog.pg_namespace n ON p.pronamespace = n.oid ' ||
    'LEFT JOIN pg_catalog.pg_type t ON p.prorettype = t.oid ' ||
    'WHERE ' ||
    '    n.nspname NOT IN (''information_schema'', ''pg_catalog'') ' ||
    'AND n.nspname NOT LIKE ''pg_toast%'' ' ||
    'AND n.nspname NOT LIKE ''pg_temp%'''
  ) AS (
    res_schema_name   VARCHAR
  , res_function_name VARCHAR
  , res_return_type   VARCHAR
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN;
END
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_get_function_parameter_meta_info(
  database VARCHAR
, username VARCHAR
, password VARCHAR
)
RETURNS TABLE (
  specific_name    VARCHAR
, schema_name      VARCHAR
, function_name    VARCHAR
, parameter_name   VARCHAR
, ordinal_position INT
, parameter_type   VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    res_specific_name
  , res_schema_name
  , res_function_name
  , res_parameter_name
  , res_ordinal_position
  , res_parameter_type
  FROM
  dblink(
    'dbname=' || database || ' user=' || username || ' password=' || password,
    'SELECT r.specific_name, r.routine_schema, r.routine_name, p.parameter_name, p.ordinal_position, p.udt_name ' ||
    'FROM information_schema.routines r ' ||
    'JOIN information_schema.parameters p ON r.specific_name = p.specific_name ' ||
    'WHERE r.routine_type = ''FUNCTION'' ' ||
    '  AND r.routine_schema NOT IN (''pg_catalog'', ''information_schema'') ' ||
    '  AND r.routine_schema NOT LIKE ''pg_toast%'' ' ||
    '  AND r.routine_schema NOT LIKE ''pg_temp%'''
  ) AS (
    res_specific_name    VARCHAR
  , res_schema_name      VARCHAR
  , res_function_name    VARCHAR
  , res_parameter_name   VARCHAR
  , res_ordinal_position INT
  , res_parameter_type   VARCHAR
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN;
END
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_refresh_database_objects()
RETURNS void
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW pgapex.database;
  REFRESH MATERIALIZED VIEW pgapex.schema;
  REFRESH MATERIALIZED VIEW pgapex.function;
  REFRESH MATERIALIZED VIEW pgapex.parameter;
  REFRESH MATERIALIZED VIEW pgapex.view;
  REFRESH MATERIALIZED VIEW pgapex.view_column;
  REFRESH MATERIALIZED VIEW pgapex.data_type;
END
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = pgapex, public, pg_temp;