SET client_min_messages TO WARNING;

CREATE OR REPLACE FUNCTION pgapex.f_is_superuser(
  username VARCHAR
, password VARCHAR
)
RETURNS boolean AS $$
  SELECT EXISTS(
    SELECT 1
    FROM pg_catalog.pg_shadow
    WHERE usename = $1
      AND (passwd = 'md5' || md5($2 || $1)
        OR passwd IS NULL
      )
      AND usesuper = TRUE
      AND (valuntil IS NULL
        OR valuntil > current_timestamp
      )
  );
$$ LANGUAGE sql
  SECURITY DEFINER
  SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_user_exists(
  username VARCHAR
, password VARCHAR
)
RETURNS boolean AS $$
  SELECT EXISTS(
    SELECT 1
    FROM pg_catalog.pg_shadow
    WHERE usename = $1
      AND (passwd = 'md5' || md5($2 || $1)
        OR passwd IS NULL
      )
      AND (valuntil IS NULL
        OR valuntil > current_timestamp
      )
  );
$$ LANGUAGE sql
  SECURITY DEFINER
  SET search_path = pgapex, public, pg_temp;
--------------------------------
---------- APPLICATION ----------
--------------------------------

CREATE OR REPLACE FUNCTION pgapex.f_application_get_applications()
RETURNS json AS $$
  SELECT COALESCE(JSON_AGG(a), '[]')
  FROM (
    SELECT
      application_id AS id
    , 'application' AS type
    , json_build_object(
        'alias', alias
      , 'name', name
    ) AS attributes
    FROM pgapex.application
    ORDER BY name
  ) a
$$ LANGUAGE sql
  SECURITY DEFINER
  SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_application_get_application(
  i_id    pgapex.application.application_id%TYPE
)
  RETURNS json AS $$
SELECT
  json_build_object(
      'id', application_id
      , 'type', 'application'
      , 'attributes', json_build_object(
          'name', name
          , 'alias', alias
          , 'database', database_name
          , 'databaseUsername', database_username
      )
  )
FROM pgapex.application
WHERE application_id = i_id
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_application_get_application_authentication(
  i_id    pgapex.application.application_id%TYPE
)
  RETURNS json AS $$
  SELECT
  json_build_object(
    'id', application_id
  , 'type', 'application-authentication'
  , 'attributes', json_build_object(
      'authenticationScheme', authentication_scheme_id
    , 'authenticationFunction', json_build_object(
        'database', database_name
      , 'schema', authentication_function_schema_name
      , 'function', authentication_function_name
      )
    , 'loginPageTemplate', login_page_template_id
    )
  )
  FROM pgapex.application
  WHERE application_id = i_id
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_application_delete_application(
  i_id pgapex.application.application_id%TYPE
)
  RETURNS boolean AS $$
BEGIN
  DELETE FROM pgapex.application
  WHERE application_id = i_id;
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_application_application_may_have_an_alias(
  i_id    pgapex.application.application_id%TYPE
, v_alias pgapex.application.alias%TYPE
)
RETURNS boolean AS $$
DECLARE
  b_alias_already_exists BOOLEAN;
BEGIN
  IF i_id IS NULL THEN
    SELECT COUNT(1) = 0 INTO b_alias_already_exists FROM pgapex.application WHERE alias = v_alias;
  ELSE
    SELECT COUNT(1) = 0 INTO b_alias_already_exists FROM pgapex.application WHERE alias = v_alias AND application_id <> i_id;
  END IF;
  RETURN b_alias_already_exists;
END
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_application_application_may_have_a_name(
  i_id    pgapex.application.application_id%TYPE
, v_name  pgapex.application.name%TYPE
)
RETURNS boolean AS $$
DECLARE
  b_name_already_exists BOOLEAN;
BEGIN
  IF i_id IS NULL THEN
    SELECT COUNT(1) = 0 INTO b_name_already_exists FROM pgapex.application WHERE name = v_name;
  ELSE
    SELECT COUNT(1) = 0 INTO b_name_already_exists FROM pgapex.application WHERE name = v_name AND application_id <> i_id;
  END IF;
  RETURN b_name_already_exists;
END
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_application_save_application(
  i_id                 pgapex.application.application_id%TYPE
, v_name               pgapex.application.name%TYPE
, v_alias              pgapex.application.alias%TYPE
, v_database           pgapex.application.database_name%TYPE
, v_database_username  pgapex.application.database_username%TYPE
, v_database_password  pgapex.application.database_password%TYPE
)
RETURNS boolean AS $$
BEGIN
  IF pgapex.f_user_exists(v_database_username, v_database_password) = FALSE THEN
    RAISE EXCEPTION 'Application username and password do not match.';
  END IF;
  IF (v_alias ~* '.*[a-z].*') = FALSE OR (v_alias ~* '^\w*$') = FALSE THEN
    RAISE EXCEPTION 'Application alias must contain characters (included underscore) and may contain numbers.';
  END IF;
  IF pgapex.f_application_application_may_have_an_alias(i_id, v_alias) = FALSE THEN
    RAISE EXCEPTION 'Application alias is already taken.';
  END IF;
  IF i_id IS NULL THEN
    INSERT INTO pgapex.application (name, alias, database_name, database_username, database_password)
    VALUES (v_name, v_alias, v_database, v_database_username, v_database_password);
  ELSE
    UPDATE pgapex.application
    SET name = v_name
    ,   alias = v_alias
    ,   database_name = v_database
    ,   database_username = v_database_username
    ,   database_password = v_database_password
    WHERE application_id = i_id;
  END IF;
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_application_save_application_authentication(
  i_id                                  pgapex.application.application_id%TYPE
, v_authentication_scheme               pgapex.application.authentication_scheme_id%TYPE
, v_authentication_function_schema_name pgapex.application.authentication_function_schema_name%TYPE
, v_authentication_function_name        pgapex.application.authentication_function_name%TYPE
, i_login_page_template                 pgapex.application.login_page_template_id%TYPE
)
RETURNS boolean AS $$
BEGIN
  IF v_authentication_scheme = 'NO_AUTHENTICATION' THEN
    UPDATE pgapex.application
    SET authentication_scheme_id = v_authentication_scheme
      ,   authentication_function_schema_name = NULL
      ,   authentication_function_name = NULL
      ,   login_page_template_id = NULL
    WHERE application_id = i_id;
  ELSE
    UPDATE pgapex.application
    SET authentication_scheme_id = v_authentication_scheme
    ,   authentication_function_schema_name = v_authentication_function_schema_name
    ,   authentication_function_name = v_authentication_function_name
    ,   login_page_template_id = i_login_page_template
    WHERE application_id = i_id;
  END IF;
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = pgapex, public, pg_temp;

-------------------------------------
---------- DATABASE OBJECT ----------
-------------------------------------

CREATE OR REPLACE FUNCTION pgapex.f_database_object_get_databases()
RETURNS json AS $$
SELECT COALESCE(JSON_AGG(a), '[]')
FROM (
       SELECT
           database_name AS id
         , 'database' AS type
         , json_build_object(
               'name', database_name
           ) AS attributes
       FROM pgapex.database
       ORDER BY database_name
     ) a
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_database_object_get_authentication_functions(
  i_application_id pgapex.application.application_id%TYPE
)
RETURNS json AS $$
  WITH boolean_functions_with_two_parameters AS (
      SELECT f.database_name, f.schema_name, f.function_name, f.return_type, p.parameter_type
      FROM pgapex.application a
        LEFT JOIN pgapex.function f ON a.database_name = f.database_name
        LEFT JOIN pgapex.parameter p ON (a.database_name = p.database_name AND p.schema_name = f.schema_name AND p.function_name = f.function_name)
      WHERE f.return_type = 'bool'
        AND a.application_id = i_application_id
      GROUP BY f.database_name, f.schema_name, f.function_name, f.return_type, p.parameter_type
      HAVING MAX(p.ordinal_position) = 2
      ORDER BY f.database_name, f.schema_name, f.function_name
  )
  SELECT json_agg(
    json_build_object(
      'type', 'login-function'
    , 'attributes', json_build_object(
        'database', f.database_name
        , 'schema',   f.schema_name
        , 'function', f.function_name
      )
    )
  )
  FROM boolean_functions_with_two_parameters f
  WHERE f.parameter_type IN ('text', 'varchar')
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_database_object_get_views_with_columns(
  i_application_id pgapex.application.application_id%TYPE
)
RETURNS JSON AS $$
WITH views_with_columns AS (
    SELECT
      json_build_object(
            'id', vc.database_name || '.' || vc.schema_name || '.' || vc.view_name
          , 'type', 'view'
          , 'attributes', json_build_object(
                'schema', vc.schema_name
              , 'name', vc.view_name
              , 'columns', json_agg(
                  json_build_object(
                        'id', vc.database_name || '.' || vc.schema_name || '.' || vc.view_name || '.' || vc.column_name
                      , 'type', 'column'
                      , 'attributes', json_build_object(
                          'name', vc.column_name
                      )
                  )
                  ORDER BY vc.column_number::INT ASC
              )
          )
      ) AS vwc
    FROM pgapex.application a
      LEFT JOIN pgapex.view_column vc ON a.database_name = vc.database_name
    WHERE a.application_id = i_application_id
    GROUP BY vc.database_name, vc.schema_name, vc.view_name
    ORDER BY vc.schema_name ASC, vc.view_name ASC
)
SELECT
  COALESCE(json_agg(views_with_columns.vwc), '[]')
FROM views_with_columns;
$$ LANGUAGE SQL
SECURITY DEFINER
SET search_path = pgapex, PUBLIC, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_database_object_get_functions_with_parameters(
  i_application_id pgapex.application.application_id%TYPE
)
RETURNS JSON AS $$
WITH functions_with_parameters AS (
    SELECT
      json_build_object(
            'id', p.database_specific_name
          , 'type', 'function'
          , 'attributes', json_build_object(
                'schema', p.schema_name
              , 'name', p.function_name
              , 'parameters', json_agg(
                  json_build_object(
                        'id', p.database_name || '.' || p.schema_name || '.' || p.function_name || '.' || p.ordinal_position
                      , 'type', 'parameter'
                      , 'attributes', json_build_object(
                          'name', p.parameter_name
                        , 'argumentType', p.parameter_type
                        , 'ordinalPosition', p.ordinal_position
                      )
                  )
              )
          )
      ) AS fwp
    FROM pgapex.application a
    LEFT JOIN pgapex.parameter p ON a.database_name = p.database_name
    WHERE a.application_id = i_application_id
    GROUP BY p.database_specific_name, p.database_name, p.schema_name, p.function_name
    ORDER BY p.database_name, p.schema_name, p.function_name
)
SELECT
  COALESCE(json_agg(functions_with_parameters.fwp), '[]')
FROM functions_with_parameters;
$$ LANGUAGE SQL
SECURITY DEFINER
SET search_path = pgapex, PUBLIC, pg_temp;

------------------------------
---------- TEMPLATE ----------
------------------------------

CREATE OR REPLACE FUNCTION pgapex.f_template_get_page_templates(
  v_page_type pgapex.page_template.page_type_id%TYPE
)
RETURNS json AS $$
  SELECT COALESCE(JSON_AGG(a), '[]')
  FROM (
    SELECT
      t.template_id AS id
    , lower(v_page_type) || '-page-template' AS type
    , json_build_object(
        'name', t.name
    ) AS attributes
    FROM pgapex.page_template pt
    LEFT JOIN pgapex.template t ON pt.template_id = t.template_id
    WHERE pt.page_type_id = v_page_type
    ORDER BY t.name
  ) a
$$ LANGUAGE sql
  SECURITY DEFINER
  SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_template_get_region_templates()
  RETURNS json AS $$
SELECT COALESCE(JSON_AGG(a), '[]')
FROM (
       SELECT
           t.template_id AS id
         , 'region-template' AS type
         , json_build_object(
               'name', t.name
           ) AS attributes
       FROM pgapex.region_template rt
         LEFT JOIN pgapex.template t ON rt.template_id = t.template_id
       ORDER BY t.name
     ) a
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_template_get_navigation_templates()
  RETURNS json AS $$
SELECT COALESCE(JSON_AGG(a), '[]')
  FROM (
    SELECT
      t.template_id AS id
    , 'navigation-template' AS type
    , json_build_object(
        'name', t.name
    ) AS attributes
    FROM pgapex.navigation_template nt
    LEFT JOIN pgapex.template t ON nt.template_id = t.template_id
    ORDER BY t.name
  ) a
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_template_get_report_templates()
  RETURNS json AS $$
SELECT COALESCE(JSON_AGG(a), '[]')
  FROM (
    SELECT
      t.template_id AS id
    , 'report-template' AS type
    , json_build_object(
        'name', t.name
    ) AS attributes
    FROM pgapex.report_template rt
    LEFT JOIN pgapex.template t ON rt.template_id = t.template_id
    ORDER BY t.name
  ) a
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_template_get_report_link_templates()
  RETURNS json AS $$
SELECT COALESCE(JSON_AGG(a), '[]')
  FROM (
    SELECT
      t.template_id AS id
    , 'report-link-template' AS type
    , json_build_object(
        'name', t.name
    ) AS attributes
    FROM pgapex.report_link_template rlt
    LEFT JOIN pgapex.template t ON rlt.template_id = t.template_id
    ORDER BY t.name
  ) a
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_template_get_detailview_templates()
  RETURNS json AS $$
SELECT COALESCE(JSON_AGG(a), '[]')
  FROM (
    SELECT
      t.template_id AS id
    , 'detail-view-template' AS type
    , json_build_object(
        'name', t.name
    ) AS attributes
    FROM pgapex.detailview_template dvt
    LEFT JOIN pgapex.template t ON dvt.template_id = t.template_id
    ORDER BY t.name
  ) a
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_template_get_form_templates()
  RETURNS json AS $$
SELECT COALESCE(JSON_AGG(a), '[]')
  FROM (
    SELECT
      t.template_id AS id
    , 'form-template' AS type
    , json_build_object(
        'name', t.name
    ) AS attributes
    FROM pgapex.form_template ft
    LEFT JOIN pgapex.template t ON ft.template_id = t.template_id
    ORDER BY t.name
  ) a
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_template_get_tabularform_templates()
  RETURNS json AS $$
SELECT COALESCE(JSON_AGG(a), '[]')
  FROM (
    SELECT
      t.template_id AS id
    , 'tabularform-template' AS type
    , json_build_object(
        'name', t.name
    ) AS attributes
    FROM pgapex.tabularform_template tft
    LEFT JOIN pgapex.template t ON tft.template_id = t.template_id
    ORDER BY t.name
  ) a
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_template_get_button_templates()
  RETURNS json AS $$
SELECT COALESCE(JSON_AGG(a), '[]')
  FROM (
    SELECT
      t.template_id AS id
    , 'button-template' AS type
    , json_build_object(
        'name', t.name
    ) AS attributes
    FROM pgapex.button_template bt
    LEFT JOIN pgapex.template t ON bt.template_id = t.template_id
    ORDER BY t.name
  ) a
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_template_get_textarea_templates()
  RETURNS json AS $$
SELECT COALESCE(JSON_AGG(a), '[]')
  FROM (
    SELECT
      t.template_id AS id
    , 'textarea-template' AS type
    , json_build_object(
        'name', t.name
    ) AS attributes
    FROM pgapex.textarea_template tt
    LEFT JOIN pgapex.template t ON tt.template_id = t.template_id
    ORDER BY t.name
  ) a
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_template_get_drop_down_templates()
  RETURNS json AS $$
SELECT COALESCE(JSON_AGG(a), '[]')
  FROM (
    SELECT
      t.template_id AS id
    , 'drop-down-template' AS type
    , json_build_object(
        'name', t.name
    ) AS attributes
    FROM pgapex.drop_down_template ddt
    LEFT JOIN pgapex.template t ON ddt.template_id = t.template_id
    ORDER BY t.name
  ) a
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_template_get_combo_box_templates()
  RETURNS json AS $$
SELECT COALESCE(JSON_AGG(a), '[]')
  FROM (
    SELECT
      t.template_id AS id
    , 'combo-box-template' AS type
    , json_build_object(
        'name', t.name
    ) AS attributes
    FROM pgapex.combo_box_template cbt
    LEFT JOIN pgapex.template t ON cbt.template_id = t.template_id
    ORDER BY t.name
  ) a
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_template_get_calendar_templates()
  RETURNS json AS $$
SELECT COALESCE(JSON_AGG(a), '[]')
  FROM (
    SELECT
      t.template_id AS id
    , 'calendar-template' AS type
    , json_build_object(
        'name', t.name
    ) AS attributes
    FROM pgapex.calendar_template ct
    LEFT JOIN pgapex.template t ON ct.template_id = t.template_id
    ORDER BY t.name
  ) a
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_template_get_tabularform_button_templates()
  RETURNS json AS $$
SELECT COALESCE(JSON_AGG(a), '[]')
  FROM (
    SELECT
      t.template_id AS id
    , 'tabularform-button-template' AS type
    , json_build_object(
        'name', t.name
    ) AS attributes
    FROM pgapex.tabularform_button_template tfbt
    LEFT JOIN pgapex.template t ON tfbt.template_id = t.template_id
    ORDER BY t.name
  ) a
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_template_get_input_templates(
  v_input_template_type pgapex.input_template.input_template_type_id%TYPE
)
  RETURNS json AS $$
SELECT COALESCE(JSON_AGG(a), '[]')
  FROM (
    SELECT
      t.template_id AS id
    , lower(v_input_template_type) || '-input-template' AS type
    , json_build_object(
        'name', t.name
    ) AS attributes
    FROM pgapex.input_template it
    LEFT JOIN pgapex.template t ON it.template_id = t.template_id
    WHERE it.input_template_type_id = v_input_template_type
    ORDER BY t.name
  ) a
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

--------------------------
---------- PAGE ----------
--------------------------

CREATE OR REPLACE FUNCTION pgapex.f_page_get_pages(
  i_application_id pgapex.page.application_id%TYPE
)
RETURNS json AS $$
  SELECT COALESCE(JSON_AGG(a), '[]')
  FROM (
    SELECT
      page_id AS id
    , 'page' AS type
    , json_build_object(
        'title', title
      , 'alias', alias
      , 'isHomepage', is_homepage
      , 'isAuthenticationRequired', is_authentication_required
    ) AS attributes
    FROM pgapex.page
    WHERE application_id = i_application_id
    ORDER BY title, alias
  ) a
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_page_save_page(
  i_page_id                    pgapex.page.page_id%TYPE
, i_application_id             pgapex.page.application_id%TYPE
, i_template_id                pgapex.page.template_id%TYPE
, v_title                      pgapex.page.title%TYPE
, v_alias                      pgapex.page.alias%TYPE
, b_is_homepage                pgapex.page.is_homepage%TYPE
, b_is_authentication_required pgapex.page.is_authentication_required%TYPE
)
RETURNS boolean AS $$
DECLARE
  b_homepage_exists BOOLEAN;
BEGIN
  IF (v_alias ~* '.*[a-z].*') = FALSE OR (v_alias ~* '^\w*$') = FALSE THEN
    RAISE EXCEPTION 'Page alias must contain characters (included underscore) and may contain numbers.';
  END IF;
  IF b_is_homepage THEN
    UPDATE pgapex.page
    SET is_homepage = FALSE
    WHERE application_id = i_application_id;
  ELSE
    SELECT count(1) > 0 INTO b_homepage_exists
    FROM pgapex.page
    WHERE application_id = i_application_id
      AND is_homepage = TRUE
      AND page_id <> COALESCE(i_page_id, -1);
    IF b_homepage_exists = FALSE THEN
      b_is_homepage = TRUE;
    END IF;
  END IF;
  IF i_page_id IS NULL THEN
    INSERT INTO pgapex.page (application_id, template_id, title, alias, is_homepage, is_authentication_required)
    VALUES (i_application_id, i_template_id, v_title, v_alias, b_is_homepage, b_is_authentication_required);
  ELSE
    UPDATE pgapex.page
    SET application_id = i_application_id
    ,   template_id = i_template_id
    ,   title = v_title
    ,   alias = v_alias
    ,   is_homepage = b_is_homepage
    ,   is_authentication_required = b_is_authentication_required
    WHERE page_id = i_page_id;
  END IF;
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_page_get_page(
  i_page_id    pgapex.page.page_id%TYPE
)
RETURNS json AS $$
  SELECT
  json_build_object(
    'id', application_id
  , 'type', 'page'
  , 'attributes', json_build_object(
      'title', title
    , 'alias', alias
    , 'template', template_id
    , 'isHomepage', is_homepage
    , 'isAuthenticationRequired', is_authentication_required
    )
  )
  FROM pgapex.page
  WHERE page_id = i_page_id
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_page_delete_page(
  i_page_id pgapex.page.page_id%TYPE
)
RETURNS boolean AS $$
DECLARE
  b_homepage_exists BOOLEAN;
  i_application_id INT;
BEGIN
  SELECT application_id INTO i_application_id
  FROM pgapex.page WHERE page_id = i_page_id;

  DELETE FROM pgapex.page WHERE page_id = i_page_id;

  SELECT count(1) > 0 INTO b_homepage_exists
  FROM pgapex.page
  WHERE application_id = i_application_id
        AND is_homepage = TRUE;

  IF b_homepage_exists = FALSE THEN
    UPDATE pgapex.page
    SET is_homepage = TRUE
    WHERE page_id = (
      SELECT page_id FROM pgapex.page ORDER BY is_authentication_required ASC LIMIT 1
    );
  END IF;
  RETURN TRUE;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_page_page_may_have_an_alias(
  i_page_id        pgapex.page.page_id%TYPE
, i_application_id pgapex.page.application_id%TYPE
, v_alias          pgapex.page.alias%TYPE
)
RETURNS boolean AS $$
  SELECT NOT EXISTS (
    SELECT 1 FROM pgapex.page
    WHERE application_id = i_application_id
    AND alias = v_alias
    AND (
      CASE
        WHEN i_page_id IS NULL THEN TRUE
        ELSE page_id <> i_page_id
      END
    )
  );
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

--------------------------------
---------- NAVIGATION ----------
--------------------------------

CREATE OR REPLACE FUNCTION pgapex.f_navigation_get_navigations(
  i_application_id pgapex.navigation.application_id%TYPE
)
  RETURNS json AS $$
  SELECT COALESCE(JSON_AGG(a), '[]')
  FROM (
    SELECT
      navigation_id AS id
    , 'navigation' AS type
    , json_build_object(
        'name', name
    ) AS attributes
    FROM pgapex.navigation
    WHERE application_id = i_application_id
    ORDER BY name
  ) a
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_navigation_save_navigation(
  i_navigation_id  pgapex.navigation.navigation_id%TYPE
, i_application_id pgapex.navigation.application_id%TYPE
, v_name           pgapex.navigation.name%TYPE
)
RETURNS boolean AS $$
BEGIN
  IF i_navigation_id IS NULL THEN
    INSERT INTO pgapex.navigation (application_id, name) VALUES (i_application_id, v_name);
  ELSE
    UPDATE pgapex.navigation
    SET application_id = i_application_id
    ,   name = v_name
    WHERE navigation_id = i_navigation_id;
  END IF;
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_navigation_navigation_may_have_a_name(
    i_navigation_id  pgapex.navigation.navigation_id%TYPE
  , i_application_id pgapex.navigation.application_id%TYPE
  , v_name           pgapex.navigation.name%TYPE
)
  RETURNS boolean AS $$
DECLARE
  b_name_already_exists BOOLEAN;
BEGIN
  IF i_navigation_id IS NULL THEN
    SELECT COUNT(1) = 0 INTO b_name_already_exists
    FROM pgapex.navigation WHERE name = v_name AND application_id = i_application_id;
  ELSE
    SELECT COUNT(1) = 0 INTO b_name_already_exists
    FROM pgapex.navigation WHERE name = v_name AND application_id = i_application_id AND navigation_id <> i_navigation_id;
  END IF;
  RETURN b_name_already_exists;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_navigation_get_navigation(
  i_navigation_id    pgapex.navigation.navigation_id%TYPE
)
  RETURNS json AS $$
  SELECT
  json_build_object(
    'id', navigation_id
  , 'type', 'navigation'
  , 'attributes', json_build_object(
      'name', name
    )
  )
  FROM pgapex.navigation
  WHERE navigation_id = i_navigation_id
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_navigation_delete_navigation(
  i_navigation_id pgapex.navigation.navigation_id%TYPE
)
RETURNS boolean AS $$
BEGIN
  DELETE FROM pgapex.navigation WHERE navigation_id = i_navigation_id;
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_navigation_get_navigation_items(
  i_navigation_id pgapex.navigation_item.navigation_id%TYPE
)
RETURNS json AS $$
SELECT COALESCE(JSON_AGG(a), '[]')
FROM (
  SELECT
    ni.navigation_item_id AS id
  , 'navigation-item' AS type
  , json_build_object(
      'name', ni.name
    , 'parentNavigationItemId', ni.parent_navigation_item_id
    , 'sequence', ni.sequence
    , 'url', ni.url
    , 'page', (
        CASE
          WHEN ni.page_id IS NULL THEN NULL
          ELSE json_build_object(
              'id', ni.page_id
            , 'title', p.title
          )
        END
      )
    ) AS attributes
  FROM pgapex.navigation_item AS ni
  LEFT JOIN pgapex.page AS p ON ni.page_id = p.page_id
  WHERE ni.navigation_id = i_navigation_id
  ORDER BY ni.sequence, ni.name
) a
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_navigation_navigation_item_contains_cycle(
  i_navigation_item_id pgapex.navigation_item.navigation_item_id%TYPE
, i_parent_navigation_item_id pgapex.navigation_item.navigation_item_id%TYPE
)
RETURNS boolean AS $$
  SELECT EXISTS (
      WITH RECURSIVE navigation_item_search_graph(parent_id, path, has_cycle)
      AS (
        SELECT i_parent_navigation_item_id, ARRAY[i_navigation_item_id, i_parent_navigation_item_id], (i_navigation_item_id = i_parent_navigation_item_id)

        UNION ALL

        SELECT ni.parent_navigation_item_id, nisg.path || ni.parent_navigation_item_id, ni.parent_navigation_item_id = ANY(nisg.path)
        FROM navigation_item_search_graph nisg
        JOIN pgapex.navigation_item ni ON ni.navigation_item_id = nisg.parent_id
        WHERE NOT nisg.has_cycle
      )
      SELECT 1
      FROM navigation_item_search_graph
      WHERE has_cycle
      LIMIT 1
  );
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_navigation_navigation_item_may_have_a_sequence(
  i_navigation_item_id         pgapex.navigation_item.navigation_item_id%TYPE
, i_navigation_id              pgapex.navigation_item.navigation_id%TYPE
, i_parent_navigation_item_id  pgapex.navigation_item.parent_navigation_item_id%TYPE
, i_sequence                   pgapex.navigation_item.sequence%TYPE
)
RETURNS boolean AS $$
  SELECT NOT EXISTS(
    SELECT 1 FROM pgapex.navigation_item
    WHERE
      (CASE
        WHEN i_navigation_item_id IS NULL THEN TRUE
        ELSE navigation_item_id <> i_navigation_item_id
      END)
      AND navigation_id = i_navigation_id
      AND (
       CASE
         WHEN i_parent_navigation_item_id IS NULL THEN parent_navigation_item_id IS NULL
         ELSE parent_navigation_item_id = i_parent_navigation_item_id
       END)
      AND sequence = i_sequence
  );
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_navigation_navigation_item_may_refer_to_page(
  i_navigation_item_id pgapex.navigation_item.navigation_item_id%TYPE
, i_navigation_id      pgapex.navigation_item.navigation_id%TYPE
, i_page_id            pgapex.navigation_item.page_id%TYPE
)
RETURNS boolean AS $$
  SELECT NOT EXISTS(
    SELECT 1 FROM pgapex.navigation_item
    WHERE
      navigation_id = i_navigation_id
      AND (
       CASE
         WHEN i_page_id IS NULL THEN FALSE
         ELSE page_id = i_page_id
       END)
      AND (
       CASE
         WHEN i_navigation_item_id IS NULL THEN TRUE
         ELSE navigation_item_id <> i_navigation_item_id
       END)
  );
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_navigation_delete_navigation_item(
  i_navigation_item_id pgapex.navigation_item.navigation_item_id%TYPE
)
RETURNS boolean AS $$
BEGIN
  DELETE FROM pgapex.navigation_item WHERE navigation_item_id = i_navigation_item_id;
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_navigation_get_navigation_item(
  i_navigation_item_id pgapex.navigation_item.navigation_item_id%TYPE
)
RETURNS json AS $$
  SELECT
  json_build_object(
    'id', navigation_id
  , 'type', 'navigation-item'
  , 'attributes', json_build_object(
      'name', name
    , 'parentNavigationItemId', parent_navigation_item_id
    , 'sequence', sequence
    , 'page', page_id
    , 'url', url
    )
  )
  FROM pgapex.navigation_item
  WHERE navigation_item_id = i_navigation_item_id
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_navigation_save_navigation_item(
  i_navigation_item_id         pgapex.navigation_item.navigation_item_id%TYPE
, i_parent_navigation_item_id  pgapex.navigation_item.parent_navigation_item_id%TYPE
, i_navigation_id              pgapex.navigation_item.navigation_id%TYPE
, v_name                       pgapex.navigation_item.name%TYPE
, i_sequence                   pgapex.navigation_item.sequence%TYPE
, i_page_id                    pgapex.navigation_item.page_id%TYPE
, v_url                        pgapex.navigation_item.url%TYPE
)
RETURNS boolean AS $$
BEGIN
  IF i_navigation_item_id IS NULL THEN
    INSERT INTO pgapex.navigation_item (parent_navigation_item_id, navigation_id, name, sequence, page_id, url)
    VALUES (i_parent_navigation_item_id, i_navigation_id, v_name, i_sequence, i_page_id, v_url);
  ELSE
    UPDATE pgapex.navigation_item
    SET parent_navigation_item_id = i_parent_navigation_item_id
    ,   navigation_id = i_navigation_id
    ,   name = v_name
    ,   sequence = i_sequence
    ,   page_id = i_page_id
    ,   url = v_url
    WHERE navigation_item_id = i_navigation_item_id;
  END IF;
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------------------------
---------- REGION ----------
----------------------------

CREATE OR REPLACE FUNCTION pgapex.f_region_get_display_points_with_regions(
  i_page_id pgapex.page.page_id%TYPE
)
RETURNS json AS $$
  SELECT json_agg(json_build_object(
      'id', ptdp.page_template_display_point_id
    , 'type', 'page-template-display-point'
    , 'attributes', json_build_object(
          'displayPointName', ptdp.display_point_id
        , 'description', ptdp.description
        , 'regions', (
          SELECT coalesce(json_agg(json_build_object(
               'id', r.region_id
             , 'type', 'region'
             , 'attributes', json_build_object(
                   'name', r.name
                 , 'sequence', r.sequence
                 , 'isVisible', r.is_visible
                 , 'type', (
                   CASE
                     WHEN hr.region_id IS NOT NULL THEN 'HTML'
                     WHEN nr.region_id IS NOT NULL THEN 'NAVIGATION'
                     WHEN fr.region_id IS NOT NULL THEN 'FORM'
                     WHEN rr.region_id IS NOT NULL AND rr.unique_id IS NULL THEN 'REPORT'
                     WHEN rr.region_id IS NOT NULL AND rr.unique_id IS NOT NULL AND rr.form_page_id IS NOT NULL THEN 'REPORT-FOR-FORM'
                     WHEN rr.region_id IS NOT NULL AND rr.unique_id IS NOT NULL THEN 'REPORT-FOR-DETAIL-VIEW'
                     WHEN tfr.region_id IS NOT NULL THEN 'TABULAR-FORM'
                     WHEN dvr.region_id IS NOT NULL THEN 'DETAIL-VIEW'
                     ELSE 'UNKNOWN'
                   END
                 )
             )
           )), '[]')
          FROM pgapex.region r
            LEFT JOIN pgapex.html_region hr ON r.region_id = hr.region_id
            LEFT JOIN pgapex.navigation_region nr ON r.region_id = nr.region_id
            LEFT JOIN pgapex.form_region fr ON r.region_id = fr.region_id
            LEFT JOIN pgapex.report_region rr ON r.region_id = rr.region_id
            LEFT JOIN pgapex.tabularform_region tfr ON r.region_id = tfr.region_id
            LEFT JOIN pgapex.detailview_region dvr ON r.region_id = dvr.region_id
          WHERE r.page_template_display_point_id = ptdp.page_template_display_point_id
                AND r.page_id = p.page_id
        )
    )
  ))
  FROM pgapex.page p
    LEFT JOIN pgapex.page_template pt ON p.template_id = pt.template_id
    LEFT JOIN pgapex.page_template_display_point ptdp ON pt.template_id = ptdp.page_template_id
  WHERE p.page_id = i_page_id
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_get_region(
  i_region_id pgapex.region.region_id%TYPE
)
RETURNS json AS $$
DECLARE
  j_result JSON;
BEGIN
  IF (SELECT EXISTS (SELECT 1 FROM pgapex.html_region WHERE region_id = i_region_id)) = TRUE THEN
    SELECT pgapex.f_region_get_html_region(i_region_id) INTO j_result;
  ELSIF (SELECT EXISTS (SELECT 1 FROM pgapex.navigation_region WHERE region_id = i_region_id)) = TRUE THEN
    SELECT pgapex.f_region_get_navigation_region(i_region_id) INTO j_result;
  ELSIF (SELECT EXISTS (SELECT 1 FROM pgapex.report_region WHERE unique_id IS NULL AND region_id = i_region_id)) = TRUE THEN
    SELECT pgapex.f_region_get_report_region(i_region_id) INTO j_result;
  ELSIF (
    SELECT EXISTS (SELECT 1 FROM pgapex.report_region WHERE unique_id IS NOT NULL AND form_page_id IS NOT NULL AND region_id = i_region_id)
  ) = TRUE THEN
    SELECT pgapex.f_region_get_report_and_form_region_by_report_id(i_region_id) INTO j_result;
  ELSIF (SELECT EXISTS (SELECT 1 FROM pgapex.form_region WHERE region_id = i_region_id)) = TRUE THEN
    SELECT pgapex.f_region_get_form_region(i_region_id) INTO j_result;
  ELSIF (SELECT EXISTS (SELECT 1 FROM pgapex.tabularform_region WHERE region_id = i_region_id)) = TRUE THEN
    SELECT pgapex.f_region_get_tabularform_region(i_region_id) INTO j_result;
  ELSIF (
    SELECT EXISTS (SELECT 1 FROM pgapex.report_region rr LEFT JOIN pgapex.detailview_region dvr ON rr.region_id = dvr.report_region_id
		  WHERE rr.unique_id IS NOT NULL AND rr.region_id = i_region_id)
  ) = TRUE THEN
    SELECT pgapex.f_region_get_report_and_detailview_region_by_report_id(i_region_id) INTO j_result;
  ELSIF (
    SELECT EXISTS (SELECT 1 FROM pgapex.detailview_region dvr LEFT JOIN pgapex.report_region rr ON dvr.report_region_id = rr.region_id
		  WHERE rr.unique_id IS NOT NULL AND dvr.region_id = i_region_id)
  ) = TRUE THEN
    SELECT pgapex.f_region_get_report_and_detailview_region_by_detailview_id(i_region_id) INTO j_result;
  END IF;
  RETURN j_result;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_delete_region(
  i_region_id pgapex.region.region_id%TYPE
)
RETURNS boolean AS $$
BEGIN
  DELETE FROM pgapex.region WHERE region_id = i_region_id;
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_save_html_region(
    i_region_id                      pgapex.region.region_id%TYPE
  , i_page_id                        pgapex.region.page_id%TYPE
  , i_region_template_id             pgapex.region.template_id%TYPE
  , i_page_template_display_point_id pgapex.region.page_template_display_point_id%TYPE
  , v_name                           pgapex.region.name%TYPE
  , i_sequence                       pgapex.region.sequence%TYPE
  , b_is_visible                     pgapex.region.is_visible%TYPE
  , t_content                        pgapex.html_region.content%TYPE
)
  RETURNS boolean AS $$
DECLARE
  i_new_region_id INT;
BEGIN
  IF i_region_id IS NULL THEN
    SELECT nextval('pgapex.region_region_id_seq') INTO i_new_region_id;

    INSERT INTO pgapex.region (region_id, page_id, template_id, page_template_display_point_id, name, sequence, is_visible)
    VALUES (i_new_region_id, i_page_id, i_region_template_id, i_page_template_display_point_id, v_name, i_sequence, b_is_visible);

    INSERT INTO pgapex.html_region (region_id, content)
    VALUES (i_new_region_id, t_content);
  ELSE
    UPDATE pgapex.region
    SET page_id = i_page_id
    ,   template_id = i_region_template_id
    ,   page_template_display_point_id = i_page_template_display_point_id
    ,   name = v_name
    ,   sequence = i_sequence
    ,   is_visible = b_is_visible
    WHERE region_id = i_region_id;

    UPDATE pgapex.html_region
    SET content = t_content
    WHERE region_id = i_region_id;
  END IF;
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_get_html_region(
  i_region_id pgapex.region.region_id%TYPE
)
  RETURNS json AS $$
  SELECT
  json_build_object(
    'id', r.region_id
  , 'type', 'html-region'
  , 'attributes', json_build_object(
      'name', r.name
    , 'sequence', r.sequence
    , 'regionTemplate', r.template_id
    , 'isVisible', r.is_visible
    , 'content', hr.content
    )
  )
  FROM pgapex.region r
  LEFT JOIN pgapex.html_region hr ON r.region_id = hr.region_id
  WHERE r.region_id = i_region_id
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_save_navigation_region(
  i_region_id                      pgapex.region.region_id%TYPE
, i_page_id                        pgapex.region.page_id%TYPE
, i_region_template_id             pgapex.region.template_id%TYPE
, i_page_template_display_point_id pgapex.region.page_template_display_point_id%TYPE
, v_name                           pgapex.region.name%TYPE
, i_sequence                       pgapex.region.sequence%TYPE
, b_is_visible                     pgapex.region.is_visible%TYPE
, i_navigation_type_id             pgapex.navigation_region.navigation_type_id%TYPE
, i_navigation_id                  pgapex.navigation_region.navigation_id%TYPE
, i_navigation_template_id         pgapex.navigation_region.template_id%TYPE
, b_repeat_last_level              pgapex.navigation_region.repeat_last_level%TYPE
)
  RETURNS boolean AS $$
DECLARE
  i_new_region_id INT;
BEGIN
  IF i_region_id IS NULL THEN
    SELECT nextval('pgapex.region_region_id_seq') INTO i_new_region_id;

    INSERT INTO pgapex.region (region_id, page_id, template_id, page_template_display_point_id, name, sequence, is_visible)
    VALUES (i_new_region_id, i_page_id, i_region_template_id, i_page_template_display_point_id, v_name, i_sequence, b_is_visible);

    INSERT INTO pgapex.navigation_region (region_id, navigation_type_id, navigation_id, template_id, repeat_last_level)
    VALUES (i_new_region_id, i_navigation_type_id, i_navigation_id, i_navigation_template_id, b_repeat_last_level);
  ELSE
    UPDATE pgapex.region
    SET page_id = i_page_id
    ,   template_id = i_region_template_id
    ,   page_template_display_point_id = i_page_template_display_point_id
    ,   name = v_name
    ,   sequence = i_sequence
    ,   is_visible = b_is_visible
    WHERE region_id = i_region_id;

    UPDATE pgapex.navigation_region
    SET navigation_type_id = i_navigation_type_id
      , navigation_id = i_navigation_id
      , template_id = i_navigation_template_id
      , repeat_last_level = b_repeat_last_level
    WHERE region_id = i_region_id;
  END IF;
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_get_navigation_region(
  i_region_id pgapex.region.region_id%TYPE
)
  RETURNS json AS $$
  SELECT
  json_build_object(
    'id', r.region_id
  , 'type', 'navigation-region'
  , 'attributes', json_build_object(
      'name', r.name
    , 'sequence', r.sequence
    , 'regionTemplate', r.template_id
    , 'isVisible', r.is_visible

    , 'navigationTemplate', nr.template_id
    , 'navigationType', nr.navigation_type_id
    , 'navigation', nr.navigation_id
    , 'repeatLastLevel', nr.repeat_last_level
    )
  )
  FROM pgapex.region r
  LEFT JOIN pgapex.navigation_region nr ON r.region_id = nr.region_id
  WHERE r.region_id = i_region_id
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_save_report_region(
    i_region_id                      pgapex.region.region_id%TYPE
  , i_page_id                        pgapex.region.page_id%TYPE
  , i_region_template_id             pgapex.region.template_id%TYPE
  , i_page_template_display_point_id pgapex.region.page_template_display_point_id%TYPE
  , v_name                           pgapex.region.name%TYPE
  , i_sequence                       pgapex.region.sequence%TYPE
  , b_is_visible                     pgapex.region.is_visible%TYPE
  , i_report_template_id             pgapex.report_region.template_id%TYPE
  , v_schema_name                    pgapex.report_region.schema_name%TYPE
  , v_view_name                      pgapex.report_region.view_name%TYPE
  , i_items_per_page                 pgapex.report_region.items_per_page%TYPE
  , b_show_header                    pgapex.report_region.show_header%TYPE
  , i_unique_id                      pgapex.report_region.unique_id%TYPE
  , i_link_template_id               pgapex.report_region.link_template_id%TYPE
  , v_pagination_query_parameter     pgapex.page_item.name%TYPE
  , b_include_create_entity_button   pgapex.report_region.include_create_entity_button%TYPE
  , v_create_entity_button_label     pgapex.report_region.create_entity_button_label%TYPE
  , i_create_entity_page_id          pgapex.report_region.create_entity_page_id%TYPE
  , i_form_page_id                   pgapex.report_region.form_page_id%TYPE
)
  RETURNS int AS $$
DECLARE
  i_new_region_id INT;
BEGIN
  IF i_region_id IS NULL THEN
    SELECT nextval('pgapex.region_region_id_seq') INTO i_new_region_id;

    INSERT INTO pgapex.region (region_id, page_id, template_id, page_template_display_point_id, name, sequence, is_visible)
    VALUES (i_new_region_id, i_page_id, i_region_template_id, i_page_template_display_point_id, v_name, i_sequence, b_is_visible);

    INSERT INTO pgapex.report_region (region_id, template_id, schema_name, view_name, items_per_page, show_header, unique_id, link_template_id, include_create_entity_button, create_entity_button_label, create_entity_page_id, form_page_id)
    VALUES (i_new_region_id, i_report_template_id, v_schema_name, v_view_name, i_items_per_page, b_show_header, i_unique_id, i_link_template_id, b_include_create_entity_button, v_create_entity_button_label, i_create_entity_page_id, i_form_page_id);

    INSERT INTO pgapex.page_item (page_id, region_id, name) VALUES (i_page_id, i_new_region_id, v_pagination_query_parameter);
    RETURN i_new_region_id;
  ELSE
    UPDATE pgapex.region
    SET page_id = i_page_id
    ,   template_id = i_region_template_id
    ,   page_template_display_point_id = i_page_template_display_point_id
    ,   name = v_name
    ,   sequence = i_sequence
    ,   is_visible = b_is_visible
    WHERE region_id = i_region_id;

    UPDATE pgapex.report_region
    SET template_id = i_report_template_id
      , schema_name = v_schema_name
      , view_name = v_view_name
      , items_per_page = i_items_per_page
      , show_header = b_show_header
      , unique_id = i_unique_id
      , link_template_id = i_link_template_id
      , include_create_entity_button = b_include_create_entity_button
      , create_entity_button_label = v_create_entity_button_label
      , create_entity_page_id = i_create_entity_page_id
      , form_page_id = i_form_page_id
    WHERE region_id = i_region_id;

    UPDATE pgapex.page_item
    SET name = v_pagination_query_parameter
    WHERE page_id = i_page_id
      AND region_id = i_region_id;
    RETURN i_region_id;
  END IF;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_delete_report_region_columns(
  i_region_id pgapex.region.region_id%TYPE
)
  RETURNS boolean AS $$
BEGIN
  DELETE FROM pgapex.report_column WHERE region_id = i_region_id;
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_create_report_region_column(
    i_region_id             pgapex.report_column.region_id%TYPE
  , v_view_column_name      pgapex.report_column.view_column_name%TYPE
  , v_heading               pgapex.report_column.heading%TYPE
  , i_sequence              pgapex.report_column.sequence%TYPE
  , b_is_text_escaped       pgapex.report_column.is_text_escaped%TYPE
)
  RETURNS boolean AS $$
DECLARE
  i_new_report_column_id INT;
BEGIN
  SELECT nextval('pgapex.report_column_report_column_id_seq') INTO i_new_report_column_id;
  INSERT INTO pgapex.report_column (report_column_id, region_id, report_column_type_id, view_column_name, heading, sequence, is_text_escaped)
    VALUES (i_new_report_column_id, i_region_id, 'COLUMN', v_view_column_name, v_heading, i_sequence, b_is_text_escaped);
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_create_report_region_link(
    i_region_id             pgapex.report_column.region_id%TYPE
  , v_heading               pgapex.report_column.heading%TYPE
  , i_sequence              pgapex.report_column.sequence%TYPE
  , b_is_text_escaped       pgapex.report_column.is_text_escaped%TYPE
  , v_url                   pgapex.report_column_link.url%TYPE
  , v_link_text             pgapex.report_column_link.link_text%TYPE
  , v_attributes            pgapex.report_column_link.attributes%TYPE
)
  RETURNS boolean AS $$
DECLARE
  i_new_report_column_id INT;
BEGIN
  SELECT nextval('pgapex.report_column_report_column_id_seq') INTO i_new_report_column_id;
  INSERT INTO pgapex.report_column (report_column_id, region_id, report_column_type_id, heading, sequence, is_text_escaped)
    VALUES (i_new_report_column_id, i_region_id, 'LINK', v_heading, i_sequence, b_is_text_escaped);
  INSERT INTO pgapex.report_column_link (report_column_id, url, link_text, attributes)
    VALUES (i_new_report_column_id, v_url, v_link_text, v_attributes);
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_get_report_region(
  i_region_id pgapex.region.region_id%TYPE
)
  RETURNS json AS $$
  SELECT
    json_build_object(
          'id', r.region_id
        , 'type', 'report-region'
        , 'attributes', json_build_object(
              'name', r.name
            , 'sequence', r.sequence
            , 'regionTemplate', r.template_id
            , 'isVisible', r.is_visible

            , 'reportTemplate', rr.template_id
            , 'schemaName', rr.schema_name
            , 'viewName', rr.view_name
            , 'showHeader', rr.show_header
            , 'itemsPerPage', rr.items_per_page
            , 'paginationQueryParameter', pi.name
            , 'includeEntityCreateButton', rr.include_create_entity_button
            , 'reportColumns', json_agg(
                CASE
                WHEN rcl.report_column_link_id IS NULL THEN
                  json_build_object(
                        'id', rc.report_column_id
                      , 'type', 'report-column'
                      , 'attributes', json_build_object(
                          'type', 'COLUMN'
                          , 'isTextEscaped', rc.is_text_escaped
                          , 'heading', rc.heading
                          , 'sequence', rc.sequence
                          , 'column', rc.view_column_name
                      )
                  )
                ELSE
                  json_build_object(
                        'id', rc.report_column_id
                      , 'type', 'report-link'
                      , 'attributes', json_build_object(
                            'type', 'LINK'
                          , 'isTextEscaped', rc.is_text_escaped
                          , 'heading', rc.heading
                          , 'sequence', rc.sequence
                          , 'linkUrl', rcl.url
                          , 'linkText', rcl.link_text
                          , 'linkAttributes', rcl.attributes
                      )
                  )
                END
                ORDER BY rc.sequence ASC
            )
        )
    )
  FROM pgapex.region r
    LEFT JOIN pgapex.report_region rr ON r.region_id = rr.region_id
    LEFT JOIN pgapex.page_item pi ON pi.region_id = rr.region_id
    LEFT JOIN pgapex.report_column rc ON rc.region_id = rr.region_id
    LEFT JOIN pgapex.report_column_link rcl ON rcl.report_column_id = rc.report_column_id
  WHERE r.region_id = i_region_id
  GROUP BY r.region_id, r.name, r.sequence, r.template_id, r.is_visible,
    rr.template_id, rr.schema_name, rr.view_name, rr.show_header,
    rr.items_per_page, rr.include_create_entity_button, pi.name
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_save_tabularform_region(
    i_region_id                      pgapex.region.region_id%TYPE
  , i_page_id                        pgapex.region.page_id%TYPE
  , i_region_template_id             pgapex.region.template_id%TYPE
  , i_page_template_display_point_id pgapex.region.page_template_display_point_id%TYPE
  , v_name                           pgapex.region.name%TYPE
  , i_sequence                       pgapex.region.sequence%TYPE
  , b_is_visible                     pgapex.region.is_visible%TYPE
  , i_tabularform_template_id        pgapex.tabularform_region.template_id%TYPE
  , v_schema_name                    pgapex.tabularform_region.schema_name%TYPE
  , v_view_name                      pgapex.tabularform_region.view_name%TYPE
  , i_items_per_page                 pgapex.tabularform_region.items_per_page%TYPE
  , b_show_header                    pgapex.tabularform_region.show_header%TYPE
  , v_unique_id                      pgapex.tabularform_region.unique_id%TYPE
  , v_xmin_view_column               pgapex.tabularform_region.xmin_view_column%TYPE
  , v_pagination_query_parameter     pgapex.page_item.name%TYPE
)
  RETURNS int AS $$
DECLARE
  i_new_region_id INT;
BEGIN
  IF i_region_id IS NULL THEN
    SELECT nextval('pgapex.region_region_id_seq') INTO i_new_region_id;

    INSERT INTO pgapex.region (region_id, page_id, template_id, page_template_display_point_id, name, sequence, is_visible)
    VALUES (i_new_region_id, i_page_id, i_region_template_id, i_page_template_display_point_id, v_name, i_sequence, b_is_visible);

    INSERT INTO pgapex.tabularform_region (region_id, template_id, schema_name, view_name, items_per_page, show_header, unique_id, xmin_view_column)
    VALUES (i_new_region_id, i_tabularform_template_id, v_schema_name, v_view_name, i_items_per_page, b_show_header, v_unique_id, v_xmin_view_column);

    INSERT INTO pgapex.page_item (page_id, tabularform_region_id, name) VALUES (i_page_id, i_new_region_id, v_pagination_query_parameter);

    RETURN i_new_region_id;
  ELSE
    UPDATE pgapex.region
    SET page_id = i_page_id
    ,   template_id = i_region_template_id
    ,   page_template_display_point_id = i_page_template_display_point_id
    ,   name = v_name
    ,   sequence = i_sequence
    ,   is_visible = b_is_visible
    WHERE region_id = i_region_id;

    UPDATE pgapex.tabularform_region
    SET template_id = i_tabularform_template_id
      , schema_name = v_schema_name
      , view_name = v_view_name
      , items_per_page = i_items_per_page
      , show_header = b_show_header
      , unique_id = v_unique_id
      , xmin_view_column = v_xmin_view_column
    WHERE region_id = i_region_id;

    UPDATE pgapex.page_item
    SET name = v_pagination_query_parameter
    WHERE page_id = i_page_id
      AND tabularform_region_id = i_region_id;
    RETURN i_region_id;
  END IF;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_create_tabularform_region_column(
    i_region_id             pgapex.tabularform_column.region_id%TYPE
  , v_view_column_name      pgapex.tabularform_column.view_column_name%TYPE
  , v_heading               pgapex.tabularform_column.heading%TYPE
  , i_sequence              pgapex.tabularform_column.sequence%TYPE
  , b_is_text_escaped       pgapex.tabularform_column.is_text_escaped%TYPE
)
  RETURNS boolean AS $$
DECLARE
  i_new_tabularform_column_id INT;
BEGIN
  SELECT nextval('pgapex.tabularform_column_tabularform_column_id_seq') INTO i_new_tabularform_column_id;
  INSERT INTO pgapex.tabularform_column (tabularform_column_id, region_id, tabularform_column_type_id, view_column_name, heading, sequence, is_text_escaped)
    VALUES (i_new_tabularform_column_id, i_region_id, 'COLUMN', v_view_column_name, v_heading, i_sequence, b_is_text_escaped);
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_create_tabularform_region_link(
    i_region_id             pgapex.tabularform_column.region_id%TYPE
  , v_heading               pgapex.tabularform_column.heading%TYPE
  , i_sequence              pgapex.tabularform_column.sequence%TYPE
  , b_is_text_escaped       pgapex.tabularform_column.is_text_escaped%TYPE
  , v_url                   pgapex.tabularform_column_link.url%TYPE
  , v_link_text             pgapex.tabularform_column_link.link_text%TYPE
  , v_attributes            pgapex.tabularform_column_link.attributes%TYPE
)
  RETURNS boolean AS $$
DECLARE
  i_new_tabularform_column_id INT;
BEGIN
  SELECT nextval('pgapex.tabularform_column_tabularform_column_id_seq') INTO i_new_tabularform_column_id;
  INSERT INTO pgapex.tabularform_column (tabularform_column_id, region_id, tabularform_column_type_id, heading, sequence, is_text_escaped)
    VALUES (i_new_tabularform_column_id, i_region_id, 'LINK', v_heading, i_sequence, b_is_text_escaped);
  INSERT INTO pgapex.tabularform_column_link (tabularform_column_id, url, link_text, attributes)
    VALUES (i_new_tabularform_column_id, v_url, v_link_text, v_attributes);
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_delete_tabularform_region_columns(
  i_region_id pgapex.region.region_id%TYPE
)
  RETURNS boolean AS $$
BEGIN
  DELETE FROM pgapex.tabularform_column WHERE region_id = i_region_id;
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_create_tabularform_region_function(
    i_region_id           INT
  , i_button_template_id  INT
  , v_function_schema     VARCHAR ( 64 )
  , v_function_name       VARCHAR ( 64 )
  , v_button_label        VARCHAR ( 255 )
  , i_sequence            INT
  , v_success_message     VARCHAR ( 255 )
  , v_error_message       VARCHAR ( 255 )
  , b_app_user            BOOLEAN
  , b_xmin_parameter      BOOLEAN
)
  RETURNS boolean AS $$
DECLARE
  i_tabularform_function_id INT;
BEGIN
  SELECT nextval('pgapex.tabularform_function_tabularform_function_id_seq') INTO i_tabularform_function_id;
  INSERT INTO pgapex.tabularform_function (tabularform_function_id, region_id, button_template_id, schema_name, function_name, button_label,
   sequence, success_message, error_message, app_user, xmin_parameter)
  VALUES (i_tabularform_function_id, i_region_id, i_button_template_id, v_function_schema, v_function_name, v_button_label, i_sequence,
  v_success_message, v_error_message, b_app_user, b_xmin_parameter);

  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_delete_tabularform_region_functions(
  i_region_id pgapex.region.region_id%TYPE
)
  RETURNS boolean AS $$
  BEGIN
    DELETE FROM pgapex.tabularform_function WHERE region_id = i_region_id;
    RETURN FOUND;
  END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_delete_tabularform_functions(
    i_region_id     INT
)
  RETURNS boolean AS $$
BEGIN
  DELETE FROM pgapex.tabularform_function WHERE region_id = i_region_id;

  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_save_detailview_region(
    i_region_id                      pgapex.region.region_id%TYPE
  , i_page_id                        pgapex.region.page_id%TYPE
  , i_region_template_id             pgapex.region.template_id%TYPE
  , i_page_template_display_point_id pgapex.region.page_template_display_point_id%TYPE
  , v_name                           pgapex.region.name%TYPE
  , i_sequence                       pgapex.region.sequence%TYPE
  , b_is_visible                     pgapex.region.is_visible%TYPE
  , i_report_region_id               pgapex.detailview_region.report_region_id%TYPE
  , i_detailview_template_id         pgapex.detailview_region.template_id%TYPE
  , v_schema_name                    pgapex.detailview_region.schema_name%TYPE
  , v_view_name                      pgapex.detailview_region.view_name%TYPE
  , v_unique_id                      pgapex.detailview_region.unique_id%TYPE
)
  RETURNS int AS $$
DECLARE
  i_new_region_id INT;
BEGIN
  IF i_region_id IS NULL THEN
    SELECT nextval('pgapex.region_region_id_seq') INTO i_new_region_id;

    INSERT INTO pgapex.region (region_id, page_id, template_id, page_template_display_point_id, name, sequence, is_visible)
    VALUES (i_new_region_id, i_page_id, i_region_template_id, i_page_template_display_point_id, v_name, i_sequence, b_is_visible);

    INSERT INTO pgapex.detailview_region (region_id, report_region_id, template_id, schema_name, view_name, unique_id)
    VALUES (i_new_region_id, i_report_region_id, i_detailview_template_id, v_schema_name, v_view_name, v_unique_id);

    RETURN i_new_region_id;
  ELSE
    UPDATE pgapex.region
    SET page_id = i_page_id
    ,   template_id = i_region_template_id
    ,   page_template_display_point_id = i_page_template_display_point_id
    ,   name = v_name
    ,   sequence = i_sequence
    ,   is_visible = b_is_visible
    WHERE region_id = i_region_id;

    UPDATE pgapex.detailview_region
    SET report_region_id = i_report_region_id
    ,   template_id = i_detailview_template_id
    ,   schema_name = v_schema_name
    ,   view_name = v_view_name
    ,   unique_id = v_unique_id
    WHERE region_id = i_region_id;

    RETURN i_region_id;
  END IF;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_create_detailview_region_column(
    i_region_id             pgapex.detailview_column.region_id%TYPE
  , v_view_column_name      pgapex.detailview_column.view_column_name%TYPE
  , v_heading               pgapex.detailview_column.heading%TYPE
  , i_sequence              pgapex.detailview_column.sequence%TYPE
  , b_is_text_escaped       pgapex.detailview_column.is_text_escaped%TYPE
)
  RETURNS boolean AS $$
DECLARE
  i_new_detailview_column_id INT;
BEGIN
  SELECT nextval('pgapex.detailview_column_detailview_column_id_seq') INTO i_new_detailview_column_id;
  INSERT INTO pgapex.detailview_column (detailview_column_id, detailview_column_type_id, region_id, view_column_name, heading, sequence, is_text_escaped)
    VALUES (i_new_detailview_column_id, 'COLUMN', i_region_id, v_view_column_name, v_heading, i_sequence, b_is_text_escaped);
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_create_detailview_region_link(
    i_region_id             pgapex.detailview_column.region_id%TYPE
  , v_heading               pgapex.detailview_column.heading%TYPE
  , i_sequence              pgapex.detailview_column.sequence%TYPE
  , b_is_text_escaped       pgapex.detailview_column.is_text_escaped%TYPE
  , v_url                   pgapex.detailview_column_link.url%TYPE
  , v_link_text             pgapex.detailview_column_link.link_text%TYPE
  , v_attributes            pgapex.detailview_column_link.attributes%TYPE
)
  RETURNS boolean AS $$
DECLARE
  i_new_detailview_column_id INT;
BEGIN
  SELECT nextval('pgapex.detailview_column_detailview_column_id_seq') INTO i_new_detailview_column_id;
  INSERT INTO pgapex.detailview_column (detailview_column_id, region_id, detailview_column_type_id, heading, sequence, is_text_escaped)
    VALUES (i_new_detailview_column_id, i_region_id, 'LINK', v_heading, i_sequence, b_is_text_escaped);
  INSERT INTO pgapex.detailview_column_link (detailview_column_id, url, link_text, attributes)
    VALUES (i_new_detailview_column_id, v_url, v_link_text, v_attributes);
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_delete_detailview_region_columns(
  i_region_id pgapex.region.region_id%TYPE
)
  RETURNS boolean AS $$
BEGIN
  DELETE FROM pgapex.detailview_column WHERE region_id = i_region_id;
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_delete_form_pre_fill_and_form_field(
  i_region_id pgapex.region.region_id%TYPE
)
  RETURNS boolean AS $$
DECLARE
  i_form_pre_fill_id INT;
BEGIN
  SELECT form_pre_fill_id INTO i_form_pre_fill_id FROM pgapex.form_region WHERE region_id = i_region_id;
  IF i_form_pre_fill_id IS NOT NULL THEN
    DELETE FROM pgapex.form_pre_fill WHERE form_pre_fill_id = i_form_pre_fill_id;
  END IF;
  DELETE FROM pgapex.form_field WHERE region_id = i_region_id;
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_delete_subform_field(
  i_subregion_id pgapex.subregion.subregion_id%TYPE
)
  RETURNS boolean AS $$
BEGIN
  DELETE FROM pgapex.form_field WHERE subregion_id = i_subregion_id;
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_save_form_region(
    i_region_id                      pgapex.region.region_id%TYPE
  , i_page_id                        pgapex.region.page_id%TYPE
  , i_region_template_id             pgapex.region.template_id%TYPE
  , i_page_template_display_point_id pgapex.region.page_template_display_point_id%TYPE
  , v_name                           pgapex.region.name%TYPE
  , i_sequence                       pgapex.region.sequence%TYPE
  , b_is_visible                     pgapex.region.is_visible%TYPE
  , i_form_pre_fill_id               pgapex.form_region.form_pre_fill_id%TYPE
  , i_form_template_id               pgapex.form_region.template_id%TYPE
  , i_button_template_id             pgapex.form_region.button_template_id%TYPE
  , v_schema_name                    pgapex.form_region.schema_name%TYPE
  , v_function_name                  pgapex.form_region.function_name%TYPE
  , v_button_label                   pgapex.form_region.button_label%TYPE
  , v_success_message                pgapex.form_region.success_message%TYPE
  , v_error_message                  pgapex.form_region.error_message%TYPE
  , v_redirect_url                   pgapex.form_region.redirect_url%TYPE
)
  RETURNS int AS $$
DECLARE
  i_new_region_id INT;
BEGIN
  IF i_region_id IS NULL THEN
    SELECT nextval('pgapex.region_region_id_seq') INTO i_new_region_id;

    INSERT INTO pgapex.region (region_id, page_id, template_id, page_template_display_point_id, name, sequence, is_visible)
    VALUES (i_new_region_id, i_page_id, i_region_template_id, i_page_template_display_point_id, v_name, i_sequence, b_is_visible);

    INSERT INTO pgapex.form_region (region_id, form_pre_fill_id, template_id, button_template_id, schema_name, function_name, button_label, success_message, error_message, redirect_url)
    VALUES (i_new_region_id, i_form_pre_fill_id, i_form_template_id, i_button_template_id, v_schema_name, v_function_name, v_button_label, v_success_message, v_error_message, v_redirect_url);

    RETURN i_new_region_id;
  ELSE
    UPDATE pgapex.region
    SET page_id = i_page_id
    ,   template_id = i_region_template_id
    ,   page_template_display_point_id = i_page_template_display_point_id
    ,   name = v_name
    ,   sequence = i_sequence
    ,   is_visible = b_is_visible
    WHERE region_id = i_region_id;

    UPDATE pgapex.form_region
    SET form_pre_fill_id   = i_form_pre_fill_id
      , template_id        = i_form_template_id
      , button_template_id = i_button_template_id
      , schema_name        = v_schema_name
      , function_name      = v_function_name
      , button_label       = v_button_label
      , success_message    = v_success_message
      , error_message      = v_error_message
      , redirect_url       = v_redirect_url
    WHERE region_id = i_region_id;
    RETURN i_region_id;
  END IF;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_save_form_pre_fill(
    v_schema_name pgapex.form_pre_fill.schema_name%TYPE
  , v_view_name   pgapex.form_pre_fill.view_name%TYPE
)
  RETURNS int AS $$
DECLARE
  i_new_form_pre_fill_id INT;
BEGIN
  SELECT nextval('pgapex.form_pre_fill_form_pre_fill_id_seq') INTO i_new_form_pre_fill_id;
  INSERT INTO pgapex.form_pre_fill (form_pre_fill_id, schema_name, view_name)
  VALUES (i_new_form_pre_fill_id, v_schema_name, v_view_name);
  RETURN i_new_form_pre_fill_id;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_save_fetch_row_condition(
    i_form_pre_fill_id pgapex.fetch_row_condition.form_pre_fill_id%TYPE
  , i_region_id        pgapex.region.region_id%TYPE
  , v_url_parameter    pgapex.page_item.name%TYPE
  , v_view_column_name pgapex.fetch_row_condition.view_column_name%TYPE
)
RETURNS void AS $$
  INSERT INTO pgapex.fetch_row_condition (form_pre_fill_id, url_parameter_id, view_column_name)
  VALUES (i_form_pre_fill_id, (
    SELECT pi.page_item_id
    FROM pgapex.region r
    LEFT JOIN pgapex.page_item pi ON pi.page_id = r.page_id
    WHERE r.region_id = i_region_id
      AND pi.name = v_url_parameter
  ), v_view_column_name);
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_save_form_field(
    i_region_id                           pgapex.form_field.region_id%TYPE
  , v_field_type_id                       pgapex.form_field.field_type_id%TYPE
  , i_list_of_values_id                   pgapex.form_field.list_of_values_id%TYPE
  , i_form_field_template_id              pgapex.template.template_id%TYPE
  , v_field_pre_fill_view_column_name     pgapex.form_field.field_pre_fill_view_column_name%TYPE
  , v_form_element_name                   pgapex.page_item.name%TYPE
  , v_label                               pgapex.form_field.label%TYPE
  , i_sequence                            pgapex.form_field.sequence%TYPE
  , b_is_mandatory                        pgapex.form_field.is_mandatory%TYPE
  , b_is_visible                          pgapex.form_field.is_visible%TYPE
  , b_is_read_only                        pgapex.form_field.is_read_only%TYPE
  , b_wysiwyg_editor                      pgapex.form_field.wysiwyg_editor%TYPE
  , v_default_value                       pgapex.form_field.default_value%TYPE
  , v_help_text                           pgapex.form_field.help_text%TYPE
  , v_function_parameter_type             pgapex.form_field.function_parameter_type%TYPE
  , v_function_parameter_ordinal_position pgapex.form_field.function_parameter_ordinal_position%TYPE
)
RETURNS int AS $$
DECLARE
  i_new_form_field_id INT;
  i_page_id INT;
BEGIN
  SELECT nextval('pgapex.form_field_form_field_id_seq') INTO i_new_form_field_id;
  SELECT page_id INTO i_page_id FROM pgapex.region WHERE region_id = i_region_id;

  INSERT INTO pgapex.form_field (form_field_id, region_id, field_type_id, list_of_values_id, input_template_id, drop_down_template_id, textarea_template_id,
                                 combo_box_template_id, calendar_template_id,
                                 field_pre_fill_view_column_name, label, sequence, is_mandatory, is_visible, is_read_only, wysiwyg_editor, default_value, help_text,
                                 function_parameter_type, function_parameter_ordinal_position
  )
  VALUES (i_new_form_field_id, i_region_id, v_field_type_id, i_list_of_values_id, (
    CASE
      WHEN v_field_type_id IN ('TEXT', 'PASSWORD', 'RADIO', 'CHECKBOX') THEN i_form_field_template_id
      ELSE NULL
    END
  ), (
    CASE
    WHEN v_field_type_id = 'DROP_DOWN' THEN i_form_field_template_id
    ELSE NULL
    END
  ), (
    CASE
    WHEN v_field_type_id = 'TEXTAREA' THEN i_form_field_template_id
    ELSE NULL
    END
  ), (
    CASE
    WHEN v_field_type_id = 'COMBO_BOX' THEN i_form_field_template_id
    ELSE NULL
    END
  ), (
    CASE
    WHEN v_field_type_id = 'CALENDAR' THEN i_form_field_template_id
    ELSE NULL
    END
  ),
  v_field_pre_fill_view_column_name, v_label, i_sequence, b_is_mandatory, b_is_visible, b_is_read_only, b_wysiwyg_editor, v_default_value, v_help_text,
  v_function_parameter_type, v_function_parameter_ordinal_position);

  INSERT INTO pgapex.page_item (page_id, form_field_id, name) VALUES (i_page_id, i_new_form_field_id, v_form_element_name);
  RETURN i_new_form_field_id;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_save_subform_field(
    i_subregion_id                        pgapex.form_field.subregion_id%TYPE
  , v_field_type_id                       pgapex.form_field.field_type_id%TYPE
  , i_list_of_values_id                   pgapex.form_field.list_of_values_id%TYPE
  , i_form_field_template_id              pgapex.template.template_id%TYPE
  , v_field_pre_fill_view_column_name     pgapex.form_field.field_pre_fill_view_column_name%TYPE
  , v_form_element_name                   pgapex.page_item.name%TYPE
  , v_label                               pgapex.form_field.label%TYPE
  , i_sequence                            pgapex.form_field.sequence%TYPE
  , b_is_mandatory                        pgapex.form_field.is_mandatory%TYPE
  , b_is_visible                          pgapex.form_field.is_visible%TYPE
  , b_is_read_only                        pgapex.form_field.is_read_only%TYPE
  , b_wysiwyg_editor                      pgapex.form_field.wysiwyg_editor%TYPE
  , v_default_value                       pgapex.form_field.default_value%TYPE
  , v_help_text                           pgapex.form_field.help_text%TYPE
  , v_function_parameter_type             pgapex.form_field.function_parameter_type%TYPE
  , v_function_parameter_ordinal_position pgapex.form_field.function_parameter_ordinal_position%TYPE
)
RETURNS int AS $$
DECLARE
  i_new_form_field_id INT;
  i_page_id INT;
BEGIN
  SELECT nextval('pgapex.form_field_form_field_id_seq') INTO i_new_form_field_id;

  SELECT r.page_id INTO i_page_id FROM pgapex.region r
  LEFT JOIN pgapex.subregion sr ON sr.parent_region_id = r.region_id
  WHERE sr.subregion_id = i_subregion_id;

  INSERT INTO pgapex.form_field (form_field_id, subregion_id, field_type_id, list_of_values_id, input_template_id, drop_down_template_id, textarea_template_id,
                                 combo_box_template_id, calendar_template_id,
                                 field_pre_fill_view_column_name, label, sequence, is_mandatory, is_visible, is_read_only, wysiwyg_editor, default_value, help_text,
                                 function_parameter_type, function_parameter_ordinal_position
  )
  VALUES (i_new_form_field_id, i_subregion_id, v_field_type_id, i_list_of_values_id, (
    CASE
      WHEN v_field_type_id IN ('TEXT', 'PASSWORD', 'RADIO', 'CHECKBOX') THEN i_form_field_template_id
      ELSE NULL
    END
  ), (
    CASE
    WHEN v_field_type_id = 'DROP_DOWN' THEN i_form_field_template_id
    ELSE NULL
    END
  ), (
    CASE
    WHEN v_field_type_id = 'TEXTAREA' THEN i_form_field_template_id
    ELSE NULL
    END
  ), (
    CASE
    WHEN v_field_type_id = 'COMBO_BOX' THEN i_form_field_template_id
    ELSE NULL
    END
  ), (
    CASE
    WHEN v_field_type_id = 'CALENDAR' THEN i_form_field_template_id
    ELSE NULL
    END
  ),
  v_field_pre_fill_view_column_name, v_label, i_sequence, b_is_mandatory, b_is_visible, b_is_read_only, b_wysiwyg_editor, v_default_value, v_help_text,
  v_function_parameter_type, v_function_parameter_ordinal_position);

  INSERT INTO pgapex.page_item (page_id, form_field_id, name) VALUES (i_page_id, i_new_form_field_id, v_form_element_name);

  RETURN i_new_form_field_id;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_save_list_of_values(
  v_value_view_column_name pgapex.list_of_values.value_view_column_name%TYPE
, v_label_view_column_name pgapex.list_of_values.label_view_column_name%TYPE
, v_view_name              pgapex.list_of_values.view_name%TYPE
, v_schema_name            pgapex.list_of_values.schema_name%TYPE
)
  RETURNS int AS $$
DECLARE
  i_new_list_of_values_id INT;
BEGIN
  SELECT nextval('pgapex.list_of_values_list_of_values_id_seq') INTO i_new_list_of_values_id;
  INSERT INTO pgapex.list_of_values (list_of_values_id, value_view_column_name, label_view_column_name, view_name, schema_name)
  VALUES (i_new_list_of_values_id, v_value_view_column_name, v_label_view_column_name, v_view_name, v_schema_name);
  RETURN i_new_list_of_values_id;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_save_calendar_format(
  i_form_field_id pgapex.calendar_format.form_field_id%TYPE,
  v_calendar_format pgapex.calendar_format.calendar_format%TYPE
)
  RETURNS void AS $$
BEGIN
  INSERT INTO pgapex.calendar_format (form_field_id, calendar_format) VALUES (i_form_field_id, v_calendar_format);
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_save_report_subregion(
    i_subregion_id                   pgapex.subregion.subregion_id%TYPE
  , i_subregion_template_id          pgapex.subregion.template_id%TYPE
  , v_name                           pgapex.subregion.name%TYPE
  , i_sequence                       pgapex.subregion.sequence%TYPE
  , b_is_visible                     pgapex.subregion.is_visible%TYPE
  , v_query_parameter                pgapex.subregion.query_parameter%TYPE
  , i_parent_region_id               pgapex.subregion.parent_region_id%TYPE
  , i_report_template_id             pgapex.report_region.template_id%TYPE
  , v_schema_name                    pgapex.report_region.schema_name%TYPE
  , v_view_name                      pgapex.report_region.view_name%TYPE
  , i_items_per_page                 pgapex.report_region.items_per_page%TYPE
  , b_show_header                    pgapex.report_region.show_header%TYPE
  , i_unique_id                      pgapex.report_region.unique_id%TYPE
)
  RETURNS int AS $$
DECLARE
  i_new_subregion_id INT;
BEGIN
  SELECT nextval('pgapex.subregion_subregion_id_seq') INTO i_new_subregion_id;

    INSERT INTO pgapex.subregion (subregion_id, template_id, name, is_visible, query_parameter, parent_region_id, sequence)
    VALUES (i_new_subregion_id, i_subregion_template_id, v_name, b_is_visible, v_query_parameter, i_parent_region_id, i_sequence);

    INSERT INTO pgapex.report_region (subregion_id, template_id, schema_name, view_name, items_per_page, show_header, unique_id)
    VALUES (i_new_subregion_id, i_report_template_id, v_schema_name, v_view_name, i_items_per_page, b_show_header, i_unique_id);

    RETURN i_new_subregion_id;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_save_form_subregion(
    i_subregion_id                   pgapex.subregion.subregion_id%TYPE
  , i_subregion_template_id          pgapex.subregion.template_id%TYPE
  , v_name                           pgapex.subregion.name%TYPE
  , i_sequence                       pgapex.subregion.sequence%TYPE
  , b_is_visible                     pgapex.subregion.is_visible%TYPE
  , v_query_parameter                pgapex.subregion.query_parameter%TYPE
  , i_parent_region_id               pgapex.subregion.parent_region_id%TYPE
  , i_form_template_id               pgapex.form_region.template_id%TYPE
  , v_function_name                  pgapex.form_region.function_name%TYPE
  , i_submit_button_template_id      pgapex.button_template.template_id%TYPE
  , v_schema_name                    pgapex.form_region.schema_name%TYPE
  , v_button_label                   pgapex.form_region.button_label%TYPE
  , v_success_message                pgapex.form_region.success_message%TYPE
  , v_error_message                  pgapex.form_region.error_message%TYPE
)
  RETURNS int AS $$
DECLARE
  i_new_subregion_id INT;
  i_new_form_region_id INT;
BEGIN
  SELECT nextval('pgapex.subregion_subregion_id_seq') INTO i_new_subregion_id;
  SELECT nextval('pgapex.region_region_id_seq') INTO i_new_form_region_id;
    INSERT INTO pgapex.subregion (subregion_id, template_id, name, is_visible, query_parameter, parent_region_id, sequence)
    VALUES (i_new_subregion_id, i_subregion_template_id, v_name, b_is_visible, v_query_parameter, i_parent_region_id, i_sequence);

    INSERT INTO pgapex.form_region(region_id, subregion_id, template_id, button_template_id, schema_name, function_name, button_label,
    success_message, error_message)
    VALUES (i_new_form_region_id, i_new_subregion_id, i_form_template_id, i_submit_button_template_id, v_schema_name, v_function_name, v_button_label, v_success_message, v_error_message);

    RETURN i_new_subregion_id;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_save_tabularform_subregion(
    i_subregion_id                   pgapex.subregion.subregion_id%TYPE
  , i_subregion_template_id          pgapex.subregion.template_id%TYPE
  , v_name                           pgapex.subregion.name%TYPE
  , i_sequence                       pgapex.subregion.sequence%TYPE
  , b_is_visible                     pgapex.subregion.is_visible%TYPE
  , i_parent_region_id               pgapex.subregion.parent_region_id%TYPE
  , i_tabularform_template_id        pgapex.tabularform_subregion.template_id%TYPE
  , v_schema_name                    pgapex.tabularform_subregion.schema_name%TYPE
  , v_view_name                      pgapex.tabularform_subregion.view_name%TYPE
  , b_include_linked_page            pgapex.tabularform_subregion.include_linked_page%TYPE
  , i_linked_page_id                 pgapex.tabularform_subregion.linked_page_id%TYPE
  , v_linked_page_unique_id          pgapex.tabularform_subregion.linked_page_unique_id%TYPE
)
  RETURNS int AS $$
DECLARE
  i_new_subregion_id INT;
BEGIN
  SELECT nextval('pgapex.subregion_subregion_id_seq') INTO i_new_subregion_id;

  INSERT INTO pgapex.subregion (subregion_id, template_id, name, is_visible, parent_region_id, sequence)
  VALUES (i_new_subregion_id, i_subregion_template_id, v_name, b_is_visible, i_parent_region_id, i_sequence);

  INSERT INTO pgapex.tabularform_subregion (subregion_id, template_id, schema_name, view_name, include_linked_page, linked_page_id, linked_page_unique_id)
  VALUES (i_new_subregion_id, i_tabularform_template_id, v_schema_name, v_view_name, b_include_linked_page, i_linked_page_id, v_linked_page_unique_id);

  RETURN i_new_subregion_id;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_save_tabular_subform_function(
    i_subregion_id        pgapex.subregion.subregion_id%TYPE
  , i_button_template_id  pgapex.tabularform_function.button_template_id%TYPE
  , v_schema_name         pgapex.tabularform_function.schema_name%TYPE
  , v_function_name       pgapex.tabularform_function.function_name%TYPE
  , v_button_label        pgapex.tabularform_function.button_label%TYPE
  , i_sequence            pgapex.tabularform_function.sequence%TYPE
  , v_success_message     pgapex.tabularform_function.success_message%TYPE
  , v_error_message       pgapex.tabularform_function.error_message%TYPE
)
  RETURNS int as $$
DECLARE
  i_new_tabular_subform_function_id INT;
BEGIN
  SELECT nextval('pgapex.tabular_subform_function_tabular_subform_function_id_seq') INTO i_new_tabular_subform_function_id;

  INSERT INTO pgapex.tabular_subform_function (tabular_subform_function_id, subregion_id, button_template_id, schema_name, function_name, button_label, sequence, success_message, error_message)
  VALUES (i_new_tabular_subform_function_id, i_subregion_id, i_button_template_id, v_schema_name, v_function_name, v_button_label, i_sequence, v_success_message, v_error_message);

  RETURN i_new_tabular_subform_function_id;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_delete_tabular_subform_functions(
  i_subregion_id pgapex.subregion.subregion_id%TYPE
)
  RETURNS boolean as $$
BEGIN
  DELETE FROM pgapex.tabular_subform_function
  WHERE subregion_id = i_subregion_id;

  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_save_tabular_subform_linked_column(
    i_subregion_id                     pgapex.subregion.subregion_id%TYPE
  , v_parent_form_prefill_column_name  pgapex.tabular_subform_linked_column.parent_form_prefill_column_name%TYPE
  , v_tabular_subform_view_column_name pgapex.tabular_subform_linked_column.tabular_subform_view_column_name%TYPE
)
  RETURNS int as $$
DECLARE
  i_new_tabular_subform_linked_column_id INT;
BEGIN
  SELECT nextval('pgapex.tabular_subform_linked_column_tabular_subform_linked_column_seq') INTO i_new_tabular_subform_linked_column_id;

  INSERT INTO pgapex.tabular_subform_linked_column (tabular_subform_linked_column_id, subregion_id, parent_form_prefill_column_name, tabular_subform_view_column_name)
  VALUES (i_new_tabular_subform_linked_column_id, i_subregion_id, v_parent_form_prefill_column_name, v_tabular_subform_view_column_name);

  RETURN i_new_tabular_subform_linked_column_id;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_delete_tabular_subform_linked_columns(
  i_subregion_id pgapex.subregion.subregion_id%TYPE
)
  RETURNS boolean as $$
BEGIN
  DELETE FROM pgapex.tabular_subform_linked_column
  WHERE subregion_id = i_subregion_id;

  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_save_tabular_subform_function_argument(
    i_tabular_subform_function_id         pgapex.tabular_subform_function.tabular_subform_function_id%TYPE
  , i_subregion_id                        pgapex.subregion.subregion_id%TYPE
  , v_function_parameter_type             pgapex.tabular_subform_function_argument.function_parameter_type%TYPE
  , i_function_parameter_ordinal_position pgapex.tabular_subform_function_argument.function_parameter_ordinal_position%TYPE
  , v_tabular_subform_view_column_name    pgapex.tabular_subform_function_argument.tabular_subform_view_column_name%TYPE
)
  RETURNS int as $$
DECLARE
  i_new_tabular_subform_function_argument_id INT;
BEGIN
  SELECT nextval('pgapex.tabular_subform_function_argu_tabular_subform_function_argu_seq') INTO i_new_tabular_subform_function_argument_id;

  INSERT INTO pgapex.tabular_subform_function_argument (tabular_subform_function_argument_id, tabular_subform_function_id, subregion_id, function_parameter_type, function_parameter_ordinal_position, tabular_subform_view_column_name)
  VALUES (i_new_tabular_subform_function_argument_id, i_tabular_subform_function_id, i_subregion_id, v_function_parameter_type, i_function_parameter_ordinal_position, v_tabular_subform_view_column_name);
  
  RETURN i_new_tabular_subform_function_argument_id;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_delete_tabular_subform_function_argument(
  i_subregion_id pgapex.subregion.subregion_id%TYPE
)
  RETURNS boolean as $$
BEGIN
  DELETE FROM pgapex.tabular_subform_function_argument
  WHERE subregion_id = i_subregion_id;

  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_delete_tabularform_subregion_columns(
  i_subregion_id pgapex.subregion.subregion_id%TYPE
)
  RETURNS boolean AS $$
BEGIN
  DELETE FROM pgapex.tabularform_column WHERE subregion_id = i_subregion_id;
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_create_tabularform_subregion_column(
    i_subregion_id          pgapex.tabularform_column.subregion_id%TYPE
  , v_view_column_name      pgapex.tabularform_column.view_column_name%TYPE
  , v_heading               pgapex.tabularform_column.heading%TYPE
  , i_sequence              pgapex.tabularform_column.sequence%TYPE
  , b_is_text_escaped       pgapex.tabularform_column.is_text_escaped%TYPE
)
  RETURNS boolean AS $$
DECLARE
  i_new_tabularform_column_id INT;
BEGIN
  SELECT nextval('pgapex.tabularform_column_tabularform_column_id_seq') INTO i_new_tabularform_column_id;
  INSERT INTO pgapex.tabularform_column (tabularform_column_id, subregion_id, tabularform_column_type_id, view_column_name, heading, sequence, is_text_escaped)
    VALUES (i_new_tabularform_column_id, i_subregion_id, 'COLUMN', v_view_column_name, v_heading, i_sequence, b_is_text_escaped);
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_create_tabularform_subregion_link(
    i_subregion_id          pgapex.tabularform_column.subregion_id%TYPE
  , v_heading               pgapex.tabularform_column.heading%TYPE
  , i_sequence              pgapex.tabularform_column.sequence%TYPE
  , b_is_text_escaped       pgapex.tabularform_column.is_text_escaped%TYPE
  , v_url                   pgapex.tabularform_column_link.url%TYPE
  , v_link_text             pgapex.tabularform_column_link.link_text%TYPE
  , v_attributes            pgapex.tabularform_column_link.attributes%TYPE
)
  RETURNS boolean AS $$
DECLARE
  i_new_tabularform_column_id INT;
BEGIN
  SELECT nextval('pgapex.tabularform_column_tabularform_column_id_seq') INTO i_new_tabularform_column_id;
  INSERT INTO pgapex.tabularform_column (tabularform_column_id, subregion_id, tabularform_column_type_id, heading, sequence, is_text_escaped)
    VALUES (i_new_tabularform_column_id, i_subregion_id, 'LINK', v_heading, i_sequence, b_is_text_escaped);
  INSERT INTO pgapex.tabularform_column_link (tabularform_column_id, url, link_text, attributes)
    VALUES (i_new_tabularform_column_id, v_url, v_link_text, v_attributes);
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_subregion_delete_subregion(
  i_parent_region_id  pgapex.subregion.parent_region_id%TYPE
)
  RETURNS boolean AS $$
BEGIN
  DELETE FROM pgapex.subregion WHERE parent_region_id = i_parent_region_id;
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_subregion_delete_report_subregion_columns(
  i_subregion_id pgapex.subregion.subregion_id%TYPE
)
  RETURNS boolean AS $$
BEGIN
  DELETE FROM pgapex.report_column WHERE subregion_id = i_subregion_id;
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_subregion_create_report_subregion_column(
    i_subregion_id          pgapex.report_column.subregion_id%TYPE
  , v_view_column_name      pgapex.report_column.view_column_name%TYPE
  , v_heading               pgapex.report_column.heading%TYPE
  , i_sequence              pgapex.report_column.sequence%TYPE
  , b_is_text_escaped       pgapex.report_column.is_text_escaped%TYPE
)
  RETURNS boolean AS $$
DECLARE
  i_new_report_column_id INT;
BEGIN
  SELECT nextval('pgapex.report_column_report_column_id_seq') INTO i_new_report_column_id;
  INSERT INTO pgapex.report_column (report_column_id, subregion_id, report_column_type_id, view_column_name, heading, sequence, is_text_escaped)
    VALUES (i_new_report_column_id, i_subregion_id, 'COLUMN', v_view_column_name, v_heading, i_sequence, b_is_text_escaped);
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_subregion_create_report_subregion_link(
    i_subregion_id          pgapex.report_column.subregion_id%TYPE
  , v_heading               pgapex.report_column.heading%TYPE
  , i_sequence              pgapex.report_column.sequence%TYPE
  , b_is_text_escaped       pgapex.report_column.is_text_escaped%TYPE
  , v_url                   pgapex.report_column_link.url%TYPE
  , v_link_text             pgapex.report_column_link.link_text%TYPE
  , v_attributes            pgapex.report_column_link.attributes%TYPE
)
  RETURNS boolean AS $$
DECLARE
  i_new_report_column_id INT;
BEGIN
  SELECT nextval('pgapex.report_column_report_column_id_seq') INTO i_new_report_column_id;
  INSERT INTO pgapex.report_column (report_column_id, subregion_id, report_column_type_id, heading, sequence, is_text_escaped)
    VALUES (i_new_report_column_id, i_subregion_id, 'LINK', v_heading, i_sequence, b_is_text_escaped);
  INSERT INTO pgapex.report_column_link (report_column_id, url, link_text, attributes)
    VALUES (i_new_report_column_id, v_url, v_link_text, v_attributes);
  RETURN FOUND;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_get_form_region(
  i_region_id pgapex.region.region_id%TYPE
)
  RETURNS json AS $$
  SELECT
    json_build_object(
          'id', r.region_id
        , 'type', 'form-region'
        , 'attributes', json_build_object(
              'name', r.name
            , 'sequence', r.sequence
            , 'regionTemplate', r.template_id
            , 'isVisible', r.is_visible

            , 'formTemplate', fr.template_id
            , 'buttonTemplate', fr.button_template_id
            , 'buttonLabel', fr.button_label
            , 'successMessage', fr.success_message
            , 'errorMessage', fr.error_message
            , 'redirectUrl', fr.redirect_url
            , 'function', json_build_object(
                'type', 'function'
              , 'attributes', json_build_object(
                  'schema', fr.schema_name
                , 'name', fr.function_name
                )
              )
            , 'formPreFill', (fr.form_pre_fill_id IS NOT NULL)
            , 'formPreFillView', json_build_object(
                'id', fpf.form_pre_fill_id
              , 'type', 'form-pre-fill'
              , 'attributes', json_build_object(
                  'schema', fpf.schema_name
                , 'name', fpf.view_name
                )
              )
            , 'formPreFillColumns', (SELECT json_agg(json_build_object(
                                       'value', pi.name
                                     , 'column', json_build_object(
                                         'type', 'view-column'
                                       , 'attributes', json_build_object(
                                           'name', vc.column_name
                                         )
                                       )
                                     ) ORDER BY vc.column_number::INT ASC)
                                     FROM pgapex.view_column vc
                                     LEFT JOIN pgapex.fetch_row_condition frc ON (vc.column_name = frc.view_column_name AND frc.form_pre_fill_id = fpf.form_pre_fill_id)
                                     LEFT JOIN pgapex.page_item pi ON pi.page_item_id = frc.url_parameter_id
                                     WHERE vc.database_name = a.database_name
                                           AND vc.schema_name = fpf.schema_name
                                           AND vc.view_name = fpf.view_name)
            , 'functionParameters', (SELECT json_agg(ff_agg.ff_obj) FROM (
                                    SELECT json_build_object(
                                      'fieldType', ff.field_type_id
                                    , 'fieldTemplate', COALESCE(ff.input_template_id, ff.drop_down_template_id, ff.textarea_template_id, ff.combo_box_template_id, ff.calendar_template_id)
                                    , 'label', ff.label
                                    , 'inputName', pi.name
                                    , 'sequence', ff.sequence
                                    , 'isMandatory', ff.is_mandatory
                                    , 'isVisible', ff.is_visible
                                    , 'isReadOnly', ff.is_read_only
                                    , 'wysiwygEditor', ff.wysiwyg_editor
                                    , 'wysiwygMenuBar', wes.menu_bar
                                    , 'wysiwygStatusBar', wes.status_bar
                                    , 'wysiwygSpellCheck', wes.browser_spellcheck
                                    , 'defaultValue', ff.default_value
                                    , 'helpText', ff.help_text
                                    , 'attributes', json_build_object(
                                        'name', par.parameter_name
                                      , 'argumentType', ff.function_parameter_type
                                      , 'ordinalPosition', ff.function_parameter_ordinal_position
                                      )
                                    , 'preFillColumn', ff.field_pre_fill_view_column_name
                                    , 'listOfValuesView', json_build_object(
                                        'attributes', json_build_object(
                                          'schema', lov.schema_name
                                        , 'name', lov.view_name
                                        , 'columns', (SELECT json_agg(lov_cols.c) FROM (SELECT json_build_object(
                                            'attributes', json_build_object(
                                              'name', lov_vc.column_name
                                            )
                                          ) c FROM pgapex.view_column lov_vc
                                            WHERE lov_vc.database_name = a.database_name
                                              AND lov_vc.schema_name = lov.schema_name
                                              AND lov_vc.view_name = lov.view_name
                                          ) lov_cols)
                                        )
                                      )
                                    , 'listOfValuesValue', json_build_object(
                                        'attributes', json_build_object(
                                          'name', lov.value_view_column_name
                                        )
                                      )
                                    , 'listOfValuesLabel', json_build_object(
                                        'attributes', json_build_object(
                                          'name', lov.label_view_column_name
                                        )
                                      )
                                    , 'calendarFormat', cf.calendar_format
                                    , 'width', COALESCE(ffs.width, 100)
                                    , 'widthUnit', COALESCE(suw.size_unit_name, '%')
                                    , 'height', ffs.height
                                    , 'heightUnit', COALESCE(suh.size_unit_name, 'px')
                                    ) ff_obj
                                    FROM pgapex.form_field ff
                                    LEFT JOIN pgapex.page_item pi ON pi.form_field_id = ff.form_field_id
                                    LEFT JOIN pgapex.list_of_values lov ON lov.list_of_values_id = ff.list_of_values_id
                                    LEFT JOIN pgapex.calendar_format cf ON cf.form_field_id = ff.form_field_id
                                    LEFT JOIN pgapex.form_field_size ffs ON ffs.form_field_id = ff.form_field_id
                                    LEFT JOIN pgapex.size_unit suw ON suw.size_unit_id = ffs.width_unit_id
                                    LEFT JOIN pgapex.size_unit suh ON suh.size_unit_id = ffs.height_unit_id
                                    LEFT JOIN pgapex.wysiwyg_editor_settings wes ON wes.form_field_id = ff.form_field_id
                                    LEFT JOIN pgapex.parameter par ON (par.database_name = a.database_name AND par.schema_name = fr.schema_name AND par.function_name = fr.function_name AND par.parameter_type = ff.function_parameter_type AND par.ordinal_position = ff.function_parameter_ordinal_position)
                                    WHERE ff.region_id = r.region_id
                                    ORDER BY ff.function_parameter_ordinal_position) ff_agg
              )
            , 'subRegions', coalesce((SELECT json_agg(row_to_json(s)->'value') FROM (SELECT value FROM jsonb_array_elements(pgapex.f_region_get_form_subregions(i_region_id)::jsonb || pgapex.f_region_get_tabularform_subregions(i_region_id)::jsonb)
                            ORDER BY value->'sequence') AS s), '[]'::json)
        )
    )
  FROM pgapex.region r
    LEFT JOIN pgapex.form_region fr ON r.region_id = fr.region_id
    LEFT JOIN pgapex.form_pre_fill fpf ON fpf.form_pre_fill_id = fr.form_pre_fill_id
    LEFT JOIN pgapex.page p ON p.page_id = r.page_id
    LEFT JOIN pgapex.application a ON a.application_id = p.application_id
  WHERE r.region_id = i_region_id
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_get_tabularform_region(
  i_region_id pgapex.region.region_id%TYPE
)
  RETURNS json AS $$
  SELECT
  json_build_object(
    'id', r.region_id,
    'type', 'tabularform-region',
    'attributes', json_build_object(
      'name', r.name,
      'sequence', r.sequence,
      'regionTemplate', r.template_id,
      'isVisible', r.is_visible,
      'tabularFormTemplate', tfr.template_id,
      'viewSchema', tfr.schema_name,
      'viewName', tfr.view_name,
      'itemsPerPage', tfr.items_per_page,
      'showHeader', tfr.show_header,
      'uniqueId', tfr.unique_id,
      'xminViewColumn', tfr.xmin_view_column,
      'paginationQueryParameter', pi.name,
      'tabularFormButtons', (
        SELECT json_agg(
          json_build_object(
            'id', tff.tabularform_function_id,
            'buttonTemplateId', tff.button_template_id,
            'sequence', tff.sequence,
            'label', tff.button_label,
            'function', json_build_object(
              'attributes', json_build_object(
                  'schema', tff.schema_name,
                  'name', tff.function_name
              )
            ),
            'successMessage', tff.success_message,
            'errorMessage', tff.error_message,
            'appUserParameter', tff.app_user,
            'xminParameter', tff.xmin_parameter
          )
          ORDER BY tff.sequence ASC
        )
        FROM pgapex.tabularform_function tff
        WHERE tff.region_id = r.region_id
	    ),
		  'tabularFormColumns', json_agg(
        CASE
        WHEN tfcl.tabularform_column_link_id IS NULL THEN json_build_object(
          'id', tfc.tabularform_column_id,
          'type', 'tabularform-column',
          'attributes', json_build_object(
            'type', 'COLUMN',
            'column', tfc.view_column_name,
            'heading', tfc.heading,
            'sequence', tfc.sequence,
            'isTextEscaped', tfc.is_text_escaped
          )
        )
        ELSE json_build_object(
          'id', tfc.tabularform_column_id,
          'type', 'tabularform-link',
          'attributes', json_build_object(
            'type', 'LINK',
            'heading', tfc.heading,
            'sequence', tfc.sequence,
            'isTextEscaped', tfc.is_text_escaped,
            'linkUrl', tfcl.url,
            'linkText', tfcl.link_text,
            'linkAttributes', tfcl.attributes
          )
        )
        END
        ORDER BY tfc.sequence ASC
		  )
	  )
  )
  FROM pgapex.region r
    LEFT JOIN pgapex.tabularform_region tfr ON r.region_id = tfr.region_id
    LEFT JOIN pgapex.page_item pi ON r.region_id = pi.tabularform_region_id
    LEFT JOIN pgapex.tabularform_column tfc ON r.region_id = tfc.region_id
    LEFT JOIN pgapex.tabularform_column_link tfcl ON tfcl.tabularform_column_id = tfc.tabularform_column_id
  WHERE r.region_id = i_region_id
  GROUP BY r.region_id, r.name, r.sequence, r.template_id, r.is_visible, pi.name,
    tfr.template_id, tfr.schema_name, tfr.view_name, tfr.items_per_page, tfr.show_header, tfr.unique_id, tfr.xmin_view_column;

$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_get_report_subregions(
  i_region_id pgapex.detailview_region.region_id%TYPE
)
RETURNS json AS $$
DECLARE
  j_result        JSON;
BEGIN
  SELECT json_agg((row_to_json(a)->>'json_build_object')::json) INTO j_result FROM (SELECT
    json_build_object(
      'type', 'SUBREPORT',
      'subRegionId', sr.subregion_id,
      'parentRegionId', sr.parent_region_id,
      'name', sr.name,
      'sequence', sr.sequence,
      'paginationQueryParameter', sr.query_parameter,
      'reportTemplate', rr.template_id,
      'viewSchema', rr.schema_name,
      'viewName', rr.view_name,
      'showHeader', rr.show_header,
      'itemsPerPage', rr.items_per_page,
      'linkedColumn', rr.unique_id,
      'columns', json_agg(
        CASE
        WHEN rcl.report_column_link_id IS NULL THEN
          json_build_object(
            'id', rc.report_column_id,
            'type', 'report-column',
            'attributes', json_build_object(
              'type', 'COLUMN',
              'isTextEscaped', rc.is_text_escaped,
              'heading', rc.heading,
              'sequence', rc.sequence,
              'column', rc.view_column_name
            )
          )
        ELSE
          json_build_object(
            'id', rc.report_column_id,
            'type', 'report-link',
            'attributes', json_build_object(
              'type', 'LINK',
              'isTextEscaped', rc.is_text_escaped,
              'heading', rc.heading,
              'sequence', rc.sequence,
              'linkUrl', rcl.url,
              'linkText', rcl.link_text,
              'linkAttributes', rcl.attributes
            )
          )
        END
      )
    )
  FROM pgapex.subregion sr
    LEFT JOIN pgapex.report_region rr ON sr.subregion_id = rr.subregion_id
	  LEFT JOIN pgapex.detailview_region dvr ON sr.parent_region_id = dvr.region_id
    LEFT JOIN pgapex.report_column rc ON rc.subregion_id = rr.subregion_id
    LEFT JOIN pgapex.report_column_link rcl ON rcl.report_column_id = rc.report_column_id
  WHERE dvr.region_id = i_region_id
  GROUP BY sr.name, sr.subregion_id, sr.sequence, sr.query_parameter,
    rr.template_id, rr.schema_name, rr.view_name, rr.show_header, rr.items_per_page, rr.unique_id
  ORDER BY sr.sequence ASC
    ) AS a;

  IF j_result IS NOT NULL THEN
    RETURN j_result;
  ELSE
    RETURN ('[]')::json;
  END IF;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_get_form_subregions(
  i_region_id pgapex.form_region.region_id%TYPE
)
RETURNS json AS $$
DECLARE
  j_result        JSON;
BEGIN
  SELECT json_agg((row_to_json(a)->>'json_build_object')::json) INTO j_result FROM (SELECT
    json_build_object(
      'type', 'SUBFORM',
      'subRegionId', sr.subregion_id,
      'parentRegionId', sr.parent_region_id,
      'name', sr.name,
      'sequence', sr.sequence,
      'formTemplate', fr.template_id,
      'formSubmitButtonTemplate', fr.button_template_id,
      'schema', fr.schema_name,
      'function', json_build_object(
                'type', 'function'
              , 'attributes', json_build_object(
                  'schema', fr.schema_name
                , 'name', fr.function_name
                )
      ),
      'functionParameters', (SELECT json_agg(ff_agg.ff_obj) FROM (
                                    SELECT json_build_object(
                                      'fieldType', ff.field_type_id
                                    , 'fieldTemplate', COALESCE(ff.input_template_id, ff.drop_down_template_id, ff.textarea_template_id, ff.combo_box_template_id, ff.calendar_template_id)
                                    , 'label', ff.label
                                    , 'inputName', pi.name
                                    , 'sequence', ff.sequence
                                    , 'isMandatory', ff.is_mandatory
                                    , 'isVisible', ff.is_visible
                                    , 'isReadOnly', ff.is_read_only
                                    , 'wysiwygEditor', ff.wysiwyg_editor
                                    , 'wysiwygMenuBar', wes.menu_bar
                                    , 'wysiwygStatusBar', wes.status_bar
                                    , 'wysiwygSpellCheck', wes.browser_spellcheck
                                    , 'defaultValue', ff.default_value
                                    , 'helpText', ff.help_text
                                    , 'attributes', json_build_object(
                                        'name', par.parameter_name
                                      , 'argumentType', ff.function_parameter_type
                                      , 'ordinalPosition', ff.function_parameter_ordinal_position
                                      )
                                    , 'preFillColumn', ff.field_pre_fill_view_column_name
                                    , 'listOfValuesView', json_build_object(
                                        'attributes', json_build_object(
                                          'schema', lov.schema_name
                                        , 'name', lov.view_name
                                        , 'columns', (SELECT json_agg(lov_cols.c) FROM (SELECT json_build_object(
                                            'attributes', json_build_object(
                                              'name', lov_vc.column_name
                                            )
                                          ) c FROM pgapex.view_column lov_vc
                                            WHERE lov_vc.database_name = app.database_name
                                              AND lov_vc.schema_name = lov.schema_name
                                              AND lov_vc.view_name = lov.view_name
                                          ) lov_cols)
                                        )
                                      )
                                    , 'listOfValuesValue', json_build_object(
                                        'attributes', json_build_object(
                                          'name', lov.value_view_column_name
                                        )
                                      )
                                    , 'listOfValuesLabel', json_build_object(
                                        'attributes', json_build_object(
                                          'name', lov.label_view_column_name
                                        )
                                      )
                                    , 'calendarFormat', cf.calendar_format
                                    , 'width', COALESCE(ffs.width, 100)
                                    , 'widthUnit', COALESCE(suw.size_unit_name, '%')
                                    , 'height', ffs.height
                                    , 'heightUnit', COALESCE(suh.size_unit_name, 'px')
                                    ) ff_obj
                                    FROM pgapex.form_field ff
                                    LEFT JOIN pgapex.page_item pi ON pi.form_field_id = ff.form_field_id
                                    LEFT JOIN pgapex.list_of_values lov ON lov.list_of_values_id = ff.list_of_values_id
                                    LEFT JOIN pgapex.calendar_format cf ON cf.form_field_id = ff.form_field_id
                                    LEFT JOIN pgapex.form_field_size ffs ON ffs.form_field_id = ff.form_field_id
                                    LEFT JOIN pgapex.size_unit suw ON suw.size_unit_id = ffs.width_unit_id
                                    LEFT JOIN pgapex.size_unit suh ON suh.size_unit_id = ffs.height_unit_id
                                    LEFT JOIN pgapex.wysiwyg_editor_settings wes ON wes.form_field_id = ff.form_field_id
                                    LEFT JOIN pgapex.parameter par ON (par.database_name = app.database_name AND par.schema_name = fr.schema_name AND par.function_name = fr.function_name AND par.parameter_type = ff.function_parameter_type AND par.ordinal_position = ff.function_parameter_ordinal_position)
                                    WHERE ff.subregion_id = sr.subregion_id
                                    ORDER BY ff.function_parameter_ordinal_position) ff_agg
              ),
      'buttonLabel', fr.button_label,
      'successMessage', fr.success_message,
      'errorMessage', fr.error_message
    )
  FROM pgapex.subregion sr
    INNER JOIN pgapex.form_region fr ON sr.subregion_id = fr.subregion_id
	  LEFT JOIN pgapex.form_field ff ON fr.subregion_id = ff.subregion_id
    LEFT JOIN pgapex.form_region pfr ON pfr.region_id = sr.parent_region_id
    LEFT JOIN pgapex.region r ON r.region_id = pfr.region_id
    LEFT JOIN pgapex.page p ON p.page_id = r.page_id
    LEFT JOIN pgapex.application app ON app.application_id = p.application_id
  WHERE sr.parent_region_id = i_region_id
  GROUP BY sr.name, sr.subregion_id, sr.sequence, sr.query_parameter,
    fr.template_id, fr.schema_name, fr.button_template_id, fr.function_name, fr.button_label, fr.success_message, fr.error_message,
    app.database_name, r.region_id
    ) AS a;

  IF j_result IS NOT NULL THEN
    RETURN j_result;
  ELSE
    RETURN ('[]')::json;
  END IF;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_get_tabularform_subregions(
  i_region_id pgapex.form_region.region_id%TYPE
)
RETURNS json AS $$
DECLARE
  j_result        JSON;
BEGIN
  SELECT json_agg((row_to_json(a)->>'json_build_object')::json) INTO j_result FROM (SELECT
    json_build_object(
      'type', 'TABULAR_SUBFORM',
      'subRegionId', sr.subregion_id,
      'parentRegionId', sr.parent_region_id,
      'name', sr.name,
      'sequence', sr.sequence,
      'paginationQueryParameter', sr.query_parameter,
      'viewName', tsr.view_name,
      'viewSchema', tsr.schema_name,
      'includeLinkedPage', tsr.include_linked_page,
      'linkedPageId', tsr.linked_page_id,
      'linkedPageUniqueId', tsr.linked_page_unique_id,
      'buttons', (SELECT json_agg(
          json_build_object(
            'sequence', tsf.sequence,
            'successMessage', tsf.success_message,
            'errorMessage', tsf.error_message,
            'label', tsf.button_label,
            'buttonTemplateId', tsf.button_template_id,
            'function', json_build_object(
              'type', 'function',
              'attributes', json_build_object(
                'schema', tsf.schema_name,
                'name', tsf.function_name,
                'parameters', (SELECT json_agg(
                    json_build_object(
                      'type', 'parameter',
                      'attributes', json_build_object(
                        'name', par.parameter_name,
                        'argumentType', tsfa.function_parameter_type,
                        'ordinalPosition', tsfa.function_parameter_ordinal_position
                      ),
                      'viewColumnForValue', tsfa.tabular_subform_view_column_name
                    )
                    ORDER BY tsfa.function_parameter_ordinal_position
                  )
                  FROM pgapex.tabular_subform_function_argument tsfa
                  LEFT JOIN pgapex.parameter par ON (par.database_name = app.database_name AND par.schema_name = tsf.schema_name AND par.function_name = tsf.function_name AND par.parameter_type = tsfa.function_parameter_type AND par.ordinal_position = tsfa.function_parameter_ordinal_position)
                  WHERE tsfa.tabular_subform_function_id = tsf.tabular_subform_function_id
                )
              )
            )
          )
          ORDER BY tsf.sequence ASC
        )
        FROM pgapex.tabular_subform_function tsf
        WHERE tsf.subregion_id = tsr.subregion_id
      ),
      'linkedColumns', (SELECT json_object_agg(
        tslc.parent_form_prefill_column_name,
        tslc.tabular_subform_view_column_name)
        FROM pgapex.tabular_subform_linked_column tslc
        WHERE tslc.subregion_id = tsr.subregion_id),
      'formColumns', json_agg(
        CASE
        WHEN tfcl.tabularform_column_link_id IS NULL THEN json_build_object(
          'id', tfc.tabularform_column_id,
          'type', 'tabularform-column',
          'attributes', json_build_object(
            'type', 'COLUMN',
            'column', tfc.view_column_name,
            'heading', tfc.heading,
            'sequence', tfc.sequence,
            'isTextEscaped', tfc.is_text_escaped
          )
        )
        ELSE json_build_object(
          'id', tfc.tabularform_column_id,
          'type', 'tabularform-link',
          'attributes', json_build_object(
            'type', 'LINK',
            'heading', tfc.heading,
            'sequence', tfc.sequence,
            'isTextEscaped', tfc.is_text_escaped,
            'linkUrl', tfcl.url,
            'linkText', tfcl.link_text,
            'linkAttributes', tfcl.attributes
          )
        )
        END
        ORDER BY tfc.sequence
		  )
    )
    FROM pgapex.subregion sr
      INNER JOIN pgapex.tabularform_subregion tsr ON sr.subregion_id = tsr.subregion_id
      LEFT JOIN pgapex.tabularform_column tfc ON sr.subregion_id = tfc.subregion_id
      LEFT JOIN pgapex.tabularform_column_link tfcl ON tfcl.tabularform_column_id = tfc.tabularform_column_id
      LEFT JOIN pgapex.form_region pfr ON sr.parent_region_id = pfr.region_id
      LEFT JOIN pgapex.region r ON r.region_id = pfr.region_id
      LEFT JOIN pgapex.page p ON p.page_id = r.page_id
      LEFT JOIN pgapex.application app ON app.application_id = p.application_id
    WHERE sr.parent_region_id = i_region_id
    GROUP BY sr.name, sr.subregion_id, sr.sequence, sr.query_parameter, tsr.view_name, tsr.schema_name, app.database_name, r.region_id,
             tsr.subregion_id

    ) AS a;

    IF j_result IS NOT NULL THEN
      RETURN j_result;
    ELSE
      RETURN ('[]')::json;
    END IF;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_get_detailview_region_id_by_report_region_id(
  i_region_id INT
)
RETURNS INT AS $$
DECLARE
  i_detailview_region_id  INT;
BEGIN
  SELECT dvr.region_id INTO i_detailview_region_id FROM pgapex.detailview_region dvr
  INNER JOIN pgapex.report_region rr ON dvr.report_region_id = rr.region_id
  WHERE rr.region_id = i_region_id;

  RETURN i_detailview_region_id;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_get_report_and_form_region_by_report_id(
  i_region_id pgapex.region.region_id%TYPE
)
  RETURNS json AS $$
  SELECT json_build_object(
    'viewSchema', rr.schema_name,
    'viewName', rr.view_name,
    'uniqueId', rr.unique_id,
    'reportRegionId', rr.region_id,
    'reportName', (SELECT name FROM pgapex.region WHERE region_id = rr.region_id),
    'reportSequence', (SELECT sequence FROM pgapex.region WHERE region_id = rr.region_id),
    'reportRegionTemplate', (SELECT template_id FROM pgapex.region WHERE region_id = rr.region_id),
    'reportIsVisible', (SELECT is_visible FROM pgapex.region WHERE region_id = rr.region_id),
    'reportTemplate', rr.link_template_id,
    'reportShowHeader', rr.show_header,
    'reportItemsPerPage', rr.items_per_page,
    'reportPaginationQueryParameter', pi.name,
    'reportIncludeEntityCreateButton', rr.include_create_entity_button,
    'reportCreateEntityButtonLabel', rr.create_entity_button_label,
    'reportCreateEntityPageId', rr.create_entity_page_id,
    'formPageId', rr.form_page_id,
    'reportPageId', (SELECT page_id FROM pgapex.region WHERE region_id = rr.region_id),
    'reportColumns', (
		  SELECT json_agg(
		  CASE
      WHEN rcl.report_column_link_id IS NULL THEN json_build_object(
        'id', rc.report_column_id,
        'type', 'report-column',
        'attributes', json_build_object(
          'type', 'COLUMN',
          'column', rc.view_column_name,
          'heading', rc.heading,
          'sequence', rc.sequence,
          'isTextEscaped', rc.is_text_escaped
          )
        )
      ELSE json_build_object(
        'id', rc.report_column_id,
        'type', 'report-link',
        'attributes', json_build_object(
          'type', 'LINK',
          'heading', rc.heading,
          'sequence', rc.sequence,
          'isTextEscaped', rc.is_text_escaped,
          'linkUrl', rcl.url,
          'linkText', rcl.link_text,
          'linkAttributes', rcl.attributes
          )
        )
      END
      ORDER BY rc.sequence ASC
	    )
      FROM pgapex.report_column rc
        LEFT JOIN pgapex.report_column_link rcl ON rc.report_column_id = rcl.report_column_id
      WHERE rc.region_id = rr.region_id
	  ),
	  'subRegions', (SELECT pgapex.f_region_get_report_subregions(
	    (SELECT pgapex.f_region_get_detailview_region_id_by_report_region_id(i_region_id)))
	  ),
	  'pageTemplateDisplayPointId', r.page_template_display_point_id
  )
  FROM pgapex.region r
    LEFT JOIN pgapex.report_region rr ON r.region_id = rr.region_id
    LEFT JOIN pgapex.page_item pi ON pi.region_id = rr.region_id
  WHERE r.region_id = i_region_id;

$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_get_report_and_detailview_region_by_report_id(
  i_region_id pgapex.region.region_id%TYPE
)
  RETURNS json AS $$
  SELECT json_build_object(
    'viewSchema', rr.schema_name,
    'viewName', rr.view_name,
    'uniqueId', rr.unique_id,
    'reportRegionId', rr.region_id,
    'reportName', (SELECT name FROM pgapex.region WHERE region_id = rr.region_id),
    'reportSequence', (SELECT sequence FROM pgapex.region WHERE region_id = rr.region_id),
    'reportRegionTemplate', (SELECT template_id FROM pgapex.region WHERE region_id = rr.region_id),
    'reportIsVisible', (SELECT is_visible FROM pgapex.region WHERE region_id = rr.region_id),
    'reportTemplate', rr.link_template_id,
    'reportShowHeader', rr.show_header,
    'reportItemsPerPage', rr.items_per_page,
    'reportPaginationQueryParameter', pi.name,
    'reportIncludeEntityCreateButton', rr.include_create_entity_button,
    'reportCreateEntityButtonLabel', rr.create_entity_button_label,
    'reportCreateEntityPageId', rr.create_entity_page_id,
    'reportPageId', (SELECT page_id FROM pgapex.region WHERE region_id = rr.region_id),
    'detailViewRegionId', dvr.region_id,
    'detailViewName', (SELECT name FROM pgapex.region WHERE region_id = dvr.region_id),
    'detailViewSequence', (SELECT sequence FROM pgapex.region WHERE region_id = dvr.region_id),
    'detailViewRegionTemplate', (SELECT template_id FROM pgapex.region WHERE region_id = dvr.region_id),
    'detailViewIsVisible', (SELECT is_visible FROM pgapex.region WHERE region_id = dvr.region_id),
    'detailViewTemplate', dvr.template_id,
    'detailViewPageId', (SELECT page_id FROM pgapex.region WHERE region_id = dvr.region_id),
    'reportColumns', (
		  SELECT json_agg(
		  CASE
      WHEN rcl.report_column_link_id IS NULL THEN json_build_object(
        'id', rc.report_column_id,
        'type', 'report-column',
        'attributes', json_build_object(
          'type', 'COLUMN',
          'column', rc.view_column_name,
          'heading', rc.heading,
          'sequence', rc.sequence,
          'isTextEscaped', rc.is_text_escaped
          )
        )
      ELSE json_build_object(
        'id', rc.report_column_id,
        'type', 'report-link',
        'attributes', json_build_object(
          'type', 'LINK',
          'heading', rc.heading,
          'sequence', rc.sequence,
          'isTextEscaped', rc.is_text_escaped,
          'linkUrl', rcl.url,
          'linkText', rcl.link_text,
          'linkAttributes', rcl.attributes
          )
        )
      END
      ORDER BY rc.sequence ASC
	    )
      FROM pgapex.report_column rc
        LEFT JOIN pgapex.report_column_link rcl ON rc.report_column_id = rcl.report_column_id
      WHERE rc.region_id = rr.region_id
	  ),
	  'detailViewColumns', (
		  SELECT json_agg(
		  CASE
      WHEN dvcl.detailview_column_link_id IS NULL THEN json_build_object(
        'id', dvc.detailview_column_id,
        'type', 'detailview-column',
        'attributes', json_build_object(
          'type', 'COLUMN',
          'column', dvc.view_column_name,
          'heading', dvc.heading,
          'sequence', dvc.sequence,
          'isTextEscaped', dvc.is_text_escaped
          )
        )
      ELSE json_build_object(
        'id', dvc.detailview_column_id,
        'type', 'detailview-link',
        'attributes', json_build_object(
          'type', 'LINK',
          'heading', dvc.heading,
          'sequence', dvc.sequence,
          'isTextEscaped', dvc.is_text_escaped,
          'linkUrl', dvcl.url,
          'linkText', dvcl.link_text,
          'linkAttributes', dvcl.attributes
          )
        )
      END
      ORDER BY dvc.sequence ASC
	    )
      FROM pgapex.detailview_column dvc
        LEFT JOIN pgapex.detailview_column_link dvcl ON dvc.detailview_column_id = dvcl.detailview_column_id
      WHERE dvc.region_id = dvr.region_id
	  ),
	  'subRegions', (SELECT pgapex.f_region_get_report_subregions(
	    (SELECT pgapex.f_region_get_detailview_region_id_by_report_region_id(i_region_id)))
	  ),
	  'pageTemplateDisplayPointId', r.page_template_display_point_id
  )
  FROM pgapex.region r
    LEFT JOIN pgapex.report_region rr ON r.region_id = rr.region_id
    LEFT JOIN pgapex.page_item pi ON pi.region_id = rr.region_id
    LEFT JOIN pgapex.detailview_region dvr ON dvr.report_region_id = rr.region_id
  WHERE r.region_id = i_region_id;

$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_get_report_and_detailview_region_by_detailview_id(
  i_region_id pgapex.region.region_id%TYPE
)
  RETURNS json AS $$
  SELECT json_build_object(
    'viewSchema', dvr.schema_name,
    'viewName', dvr.view_name,
    'uniqueId', dvr.unique_id,
    'reportRegionId', rr.region_id,
    'reportName', (SELECT name FROM pgapex.region WHERE region_id = rr.region_id),
    'reportSequence', (SELECT sequence FROM pgapex.region WHERE region_id = rr.region_id),
    'reportRegionTemplate', (SELECT template_id FROM pgapex.region WHERE region_id = rr.region_id),
    'reportIsVisible', (SELECT is_visible FROM pgapex.region WHERE region_id = rr.region_id),
    'reportTemplate', rr.link_template_id,
    'reportShowHeader', rr.show_header,
    'reportItemsPerPage', rr.items_per_page,
    'reportPaginationQueryParameter', pi.name,
    'reportIncludeEntityCreateButton', rr.include_create_entity_button,
    'reportCreateEntityButtonLabel', rr.create_entity_button_label,
    'reportCreateEntityPageId', rr.create_entity_page_id,
    'reportPageId', (SELECT page_id FROM pgapex.region WHERE region_id = rr.region_id),
    'detailViewRegionId', dvr.region_id,
    'detailViewName', (SELECT name FROM pgapex.region WHERE region_id = dvr.region_id),
    'detailViewSequence', (SELECT sequence FROM pgapex.region WHERE region_id = dvr.region_id),
    'detailViewRegionTemplate', (SELECT template_id FROM pgapex.region WHERE region_id = dvr.region_id),
    'detailViewIsVisible', (SELECT is_visible FROM pgapex.region WHERE region_id = dvr.region_id),
    'detailViewTemplate', dvr.template_id,
    'detailViewPageId', (SELECT page_id FROM pgapex.region WHERE region_id = dvr.region_id),
    'reportColumns', (
		  SELECT json_agg(
		  CASE
      WHEN rcl.report_column_link_id IS NULL THEN json_build_object(
        'id', rc.report_column_id,
        'type', 'report-column',
        'attributes', json_build_object(
          'type', 'COLUMN',
          'column', rc.view_column_name,
          'heading', rc.heading,
          'sequence', rc.sequence,
          'isTextEscaped', rc.is_text_escaped
          )
        )
      ELSE json_build_object(
        'id', rc.report_column_id,
        'type', 'report-link',
        'attributes', json_build_object(
          'type', 'LINK',
          'heading', rc.heading,
          'sequence', rc.sequence,
          'isTextEscaped', rc.is_text_escaped,
          'linkUrl', rcl.url,
          'linkText', rcl.link_text,
          'linkAttributes', rcl.attributes
          )
        )
      END
      ORDER BY rc.sequence ASC
	    )
      FROM pgapex.report_column rc
        LEFT JOIN pgapex.report_column_link rcl ON rc.report_column_id = rcl.report_column_id
      WHERE rc.region_id = rr.region_id
	  ),
	  'detailViewColumns', (
		  SELECT json_agg(
		  CASE
      WHEN dvcl.detailview_column_link_id IS NULL THEN json_build_object(
        'id', dvc.detailview_column_id,
        'type', 'detailview-column',
        'attributes', json_build_object(
          'type', 'COLUMN',
          'column', dvc.view_column_name,
          'heading', dvc.heading,
          'sequence', dvc.sequence,
          'isTextEscaped', dvc.is_text_escaped
          )
        )
      ELSE json_build_object(
        'id', dvc.detailview_column_id,
        'type', 'detailview-link',
        'attributes', json_build_object(
          'type', 'LINK',
          'heading', dvc.heading,
          'sequence', dvc.sequence,
          'isTextEscaped', dvc.is_text_escaped,
          'linkUrl', dvcl.url,
          'linkText', dvcl.link_text,
          'linkAttributes', dvcl.attributes
          )
        )
      END
      ORDER BY dvc.sequence ASC
	    )
      FROM pgapex.detailview_column dvc
        LEFT JOIN pgapex.detailview_column_link dvcl ON dvc.detailview_column_id = dvcl.detailview_column_id
      WHERE dvc.region_id = dvr.region_id
	  ),
	  'subRegions', (SELECT pgapex.f_region_get_report_subregions(i_region_id)),
	  'pageTemplateDisplayPointId', r.page_template_display_point_id
  )
  FROM pgapex.region r
    LEFT JOIN pgapex.detailview_region dvr ON r.region_id = dvr.region_id
    LEFT JOIN pgapex.report_region rr ON rr.region_id = dvr.report_region_id
    LEFT JOIN pgapex.page_item pi ON pi.region_id = rr.region_id
  WHERE r.region_id = i_region_id;

$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_region_may_have_a_sequence(
    i_region_id                      pgapex.region.region_id%TYPE
  , i_page_id                        pgapex.region.page_id%TYPE
  , i_page_template_display_point_id pgapex.region.page_template_display_point_id%TYPE
  , i_sequence                       pgapex.region.sequence%TYPE
)
RETURNS boolean AS $$
  SELECT NOT EXISTS(
    SELECT 1 FROM pgapex.region
    WHERE page_id = i_page_id
      AND sequence = i_sequence
      AND page_template_display_point_id = i_page_template_display_point_id
      AND (
        CASE
          WHEN i_region_id IS NULL THEN TRUE
          ELSE region_id <> i_region_id
        END)
  );
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_region_save_form_field_size(
    i_form_field_id pgapex.form_field_size.form_field_id%TYPE
  , d_width         pgapex.form_field_size.width%TYPE
  , v_width_unit    pgapex.size_unit.size_unit_name%TYPE
  , d_height        pgapex.form_field_size.height%TYPE
  , v_height_unit   pgapex.size_unit.size_unit_name%TYPE
)
RETURNS void AS $$
BEGIN
  INSERT INTO pgapex.form_field_size(form_field_id, width, width_unit_id, height, height_unit_id)
  VALUES (
    i_form_field_id, 
    d_width, 
    (SELECT size_unit_id FROM pgapex.size_unit WHERE size_unit_name = v_width_unit), 
    d_height, 
    (SELECT size_unit_id FROM pgapex.size_unit WHERE size_unit_name = v_height_unit));
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

CREATE OR REPLACE FUNCTION pgapex.f_region_save_wysiwyg_editor_settings(
    i_form_field_id       pgapex.wysiwyg_editor_settings.form_field_id%TYPE
  , b_menu_bar            pgapex.wysiwyg_editor_settings.menu_bar%TYPE
  , b_status_bar          pgapex.wysiwyg_editor_settings.status_bar%TYPE
  , b_browser_spellcheck  pgapex.wysiwyg_editor_settings.browser_spellcheck%TYPE
)
RETURNS void AS $$
  INSERT INTO pgapex.wysiwyg_editor_settings (form_field_id, menu_bar, status_bar, browser_spellcheck)
  VALUES (i_form_field_id, b_menu_bar, b_status_bar, b_browser_spellcheck);
$$ LANGUAGE SQL
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;