DROP TABLE IF EXISTS pgapex.view_column;
DROP TABLE IF EXISTS pgapex.view;
DROP TABLE IF EXISTS pgapex.parameter;
DROP TABLE IF EXISTS pgapex.function;
DROP TABLE IF EXISTS pgapex.data_type;
DROP TABLE IF EXISTS pgapex.schema;
DROP TABLE IF EXISTS pgapex.database;


CREATE MATERIALIZED VIEW pgapex.database AS
SELECT datname AS database_name
FROM pg_catalog.pg_database
WHERE datname NOT IN ('template0', 'template1');


CREATE MATERIALIZED VIEW pgapex.schema AS
SELECT DISTINCT
  a.database_name
, i.schema_name
FROM
  pgapex.application a
, pgapex.f_get_schema_meta_info(a.database_name, a.database_username, a.database_password) i;


CREATE MATERIALIZED VIEW pgapex.view AS
SELECT DISTINCT
  a.database_name
, i.schema_name
, i.view_name
FROM
  pgapex.application a
, pgapex.f_get_view_meta_info(a.database_name, a.database_username, a.database_password) i;


CREATE MATERIALIZED VIEW pgapex.view_column AS
SELECT DISTINCT
  a.database_name
, i.schema_name
, i.view_name
, i.column_name
, i.column_type
, i.column_number
FROM
  pgapex.application a
, pgapex.f_get_view_column_meta_info(a.database_name, a.database_username, a.database_password) i;


CREATE MATERIALIZED VIEW pgapex.function AS
SELECT DISTINCT
  a.database_name
, i.schema_name
, i.function_name
, i.return_type
FROM
  pgapex.application a
, pgapex.f_get_function_meta_info(a.database_name, a.database_username, a.database_password) i;


CREATE MATERIALIZED VIEW pgapex.parameter AS
SELECT DISTINCT
  a.database_name || '.' || i.specific_name AS database_specific_name
, a.database_name
, i.schema_name
, i.function_name
, i.parameter_name
, i.ordinal_position
, i.parameter_type
FROM
  pgapex.application a
, pgapex.f_get_function_parameter_meta_info(a.database_name, a.database_username, a.database_password) i;


CREATE MATERIALIZED VIEW pgapex.data_type (
  database_name
, schema_name
, data_type
) AS
SELECT DISTINCT database_name, schema_name, column_type FROM pgapex.view_column
UNION
SELECT DISTINCT database_name, schema_name, return_type FROM pgapex.function
UNION
SELECT DISTINCT database_name, schema_name, parameter_type FROM pgapex.parameter;