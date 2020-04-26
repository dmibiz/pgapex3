CREATE TYPE pgapex.t_navigation_item_with_level AS (
    navigation_item_id        INT
  , parent_navigation_item_id INT
  , sequence                  INT
  , name                      VARCHAR
  , page_id                   INT
  , url                       VARCHAR
  , level                     INT
);

CREATE TYPE pgapex.t_report_column_with_link AS (
    view_column_name VARCHAR
  , heading          VARCHAR
  , sequence         INT
  , is_text_escaped  BOOLEAN
  , url              VARCHAR
  , link_text        VARCHAR
  , attributes       VARCHAR
);

CREATE TYPE pgapex.t_tabularform_column_with_link AS (
    view_column_name VARCHAR
  , heading          VARCHAR
  , sequence         INT
  , is_text_escaped  BOOLEAN
  , url              VARCHAR
  , link_text        VARCHAR
  , attributes       VARCHAR
);

CREATE TYPE pgapex.t_column_with_link AS (
    view_column_name VARCHAR
  , heading          VARCHAR
  , sequence         INT
  , is_text_escaped  BOOLEAN
  , url              VARCHAR
  , link_text        VARCHAR
  , attributes       VARCHAR
);

CREATE TYPE pgapex.t_tabularform_button AS (
    tabularform_function_id VARCHAR,
    button_label VARCHAR,
    template VARCHAR
);

CREATE TYPE pgapex.t_tabular_subform_button AS (
  tabular_subform_function_id VARCHAR,
  button_label VARCHAR,
  template VARCHAR
);

CREATE OR REPLACE FUNCTION pgapex.f_app_query_page(
  v_application_root VARCHAR
, v_application_id   VARCHAR
, v_page_id          VARCHAR
, v_method           VARCHAR
, j_headers          JSONB
, j_get_params       JSONB
, j_post_params      JSONB
)
  RETURNS JSON AS $$
DECLARE
  j_response       JSON;
  t_response_body  TEXT;
  i_application_id INT;
  i_page_id        INT;
BEGIN
  PERFORM pgapex.f_app_create_temp_tables();
  SELECT pgapex.f_app_get_application_id(v_application_id) INTO i_application_id;

  IF i_application_id IS NULL THEN
    SELECT pgapex.f_app_error('Application does not exist: ' || v_application_id) INTO t_response_body;
    SELECT pgapex.f_app_create_response(t_response_body) INTO j_response;
    RETURN j_response;
  END IF;
  
  PERFORM pgapex.f_app_open_session(v_application_root, i_application_id, j_headers);

  SELECT pgapex.f_app_get_page_id(i_application_id, v_page_id) INTO i_page_id;

  IF i_page_id IS NULL THEN
    SELECT page_id INTO i_page_id FROM pgapex.page WHERE application_id = i_application_id AND is_homepage = true;
    IF i_page_id IS NULL THEN
      SELECT pgapex.f_app_error('Application does not have any pages') INTO t_response_body;
      SELECT pgapex.f_app_create_response(t_response_body) INTO j_response;
      RETURN j_response;
    ELSE
      PERFORM pgapex.f_app_set_header('location', v_application_root || '/app/' || v_application_id || '/' || i_page_id);
      SELECT pgapex.f_app_create_response('') INTO j_response;
      RETURN j_response;
    END IF;
  END IF;

  PERFORM pgapex.f_app_add_setting('application_root', v_application_root);
  PERFORM pgapex.f_app_add_setting('application_id', i_application_id::varchar);
  PERFORM pgapex.f_app_add_setting('page_id', i_page_id::varchar);
  BEGIN
    PERFORM pgapex.f_app_dblink_connect(i_application_id);
    PERFORM pgapex.f_app_parse_operation(i_application_id, i_page_id, v_method, j_headers, j_get_params, j_post_params);
    SELECT pgapex.f_app_create_page(i_application_id, i_page_id, j_get_params, j_post_params) INTO t_response_body;
  EXCEPTION
    WHEN OTHERS THEN
      SELECT pgapex.f_app_error('System error: ' || SQLERRM) INTO t_response_body;
  END;
  PERFORM pgapex.f_app_dblink_disconnect();
  SELECT pgapex.f_app_create_response(t_response_body) INTO j_response;
  BEGIN
  IF j_response->'headers'->>'location' IS NULL THEN
    IF f_app_session_read('success_message') IS NOT NULL THEN
      PERFORM f_app_session_delete('success_message');
    END IF;
    IF f_app_session_read('error_message') IS NOT NULL THEN
      PERFORM f_app_session_delete('error_message');
    END IF;
  END IF;
  EXCEPTION
    WHEN OTHERS THEN
      SELECT pgapex.f_app_error('System error: ' || SQLERRM) INTO t_response_body;
      SELECT pgapex.f_app_create_response(t_response_body) INTO j_response;
  END;

  RETURN j_response;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_logout(
    v_application_root VARCHAR
  , v_application_id   VARCHAR
  , j_headers          JSONB
)
  RETURNS JSON AS $$
DECLARE
  j_response       JSON;
  t_response_body  TEXT;
  i_application_id INT;
BEGIN
  PERFORM pgapex.f_app_create_temp_tables();
  SELECT pgapex.f_app_get_application_id(v_application_id) INTO i_application_id;

  IF i_application_id IS NULL THEN
    SELECT pgapex.f_app_error('Application does not exist: ' || v_application_id) INTO t_response_body;
    SELECT pgapex.f_app_create_response(t_response_body) INTO j_response;
    RETURN j_response;
  END IF;

  PERFORM pgapex.f_app_open_session(v_application_root, i_application_id, j_headers);
  DELETE FROM pgapex.session WHERE session_id = f_app_get_session_id();

  PERFORM pgapex.f_app_set_header('location', v_application_root || '/app/' || v_application_id);
  SELECT pgapex.f_app_create_response('') INTO j_response;
  RETURN j_response;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_create_temp_tables()
RETURNS void AS $$
BEGIN
  CREATE TEMP TABLE IF NOT EXISTS temp_headers (
      transaction_id INT          NOT NULL
    , field_name     VARCHAR(100) NOT NULL
    , value          TEXT         NOT NULL
  );
  CREATE TEMP TABLE IF NOT EXISTS temp_settings (
      transaction_id INT          NOT NULL
    , key            VARCHAR(100) NOT NULL
    , value          TEXT         NOT NULL
  );
  CREATE TEMP TABLE IF NOT EXISTS temp_messages (
      transaction_id INT          NOT NULL
    , type           VARCHAR(10)  NOT NULL CHECK (type IN ('ERROR', 'SUCCESS'))
    , message        TEXT         NOT NULL
  );
  CREATE TEMP TABLE IF NOT EXISTS temp_regions (
      transaction_id INT          NOT NULL
    , display_point  VARCHAR      NOT NULL
    , sequence       INT          NOT NULL
    , content        TEXT         NOT NULL
  );
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_dblink_connection_name()
  RETURNS VARCHAR AS $$
  SELECT 'dblink_connection_' || txid_current()::varchar;
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_dblink_connect(
  i_application_id INT
)
RETURNS TEXT AS $$
  SELECT dblink_connect(pgapex.f_app_get_dblink_connection_name(),
                       'dbname=' || database_name || ' user=' || database_username || ' password=' || database_password)
  FROM pgapex.application WHERE application_id = i_application_id;
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_dblink_disconnect()
RETURNS TEXT AS $$
  SELECT dblink_disconnect(pgapex.f_app_get_dblink_connection_name());
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_add_region(
    v_display_point VARCHAR
  , i_sequence      INT
  , t_content       TEXT
)
  RETURNS void AS $$
BEGIN
  INSERT INTO temp_regions (transaction_id , display_point, sequence, content) VALUES (txid_current(), v_display_point, i_sequence, COALESCE(t_content, ''));
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_display_point_content(
  v_display_point VARCHAR
)
  RETURNS TEXT AS $$
DECLARE
  t_response TEXT;
BEGIN
  WITH display_point_content AS (
    SELECT content FROM temp_regions
    WHERE transaction_id = txid_current()
      AND display_point = v_display_point
    ORDER BY sequence
  ) SELECT COALESCE(string_agg(content, ''), '') INTO t_response FROM display_point_content;
  RETURN t_response;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_add_error_message(
  t_message      TEXT
)
  RETURNS void AS $$
BEGIN
  INSERT INTO temp_messages(transaction_id, type, message) VALUES (txid_current(), 'ERROR', t_message);
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_add_success_message(
  t_message      TEXT
)
  RETURNS void AS $$
BEGIN
  INSERT INTO temp_messages(transaction_id, type, message) VALUES (txid_current(), 'SUCCESS', t_message);
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_set_header(
  v_field_name VARCHAR
, t_value      TEXT
)
RETURNS void AS $$
BEGIN
  DELETE FROM temp_headers WHERE transaction_id = txid_current() AND field_name = lower(v_field_name);
  INSERT INTO temp_headers(transaction_id, field_name, value) VALUES (txid_current(), lower(v_field_name), t_value);
END
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_add_setting(
    v_key   VARCHAR
  , v_value VARCHAR
)
  RETURNS void AS $$
BEGIN
  DELETE FROM temp_settings WHERE transaction_id = txid_current() AND key = lower(v_key);
  INSERT INTO temp_settings(transaction_id, key, value) VALUES (txid_current(), lower(v_key), v_value);
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_setting(
    v_key   VARCHAR
)
  RETURNS varchar AS $$
DECLARE
  v_value VARCHAR;
BEGIN
  SELECT value INTO v_value FROM temp_settings WHERE transaction_id = txid_current() AND key = lower(v_key);
  RETURN v_value;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_application_id(
  v_application_id VARCHAR
)
RETURNS int AS $$
  SELECT (
    CASE
      WHEN v_application_id ~ '^[0-9]+$' AND
          (SELECT EXISTS(SELECT 1 FROM pgapex.application WHERE application_id = v_application_id::int)) THEN
            v_application_id::int
      WHEN (SELECT EXISTS(SELECT 1 FROM pgapex.application WHERE alias = v_application_id)) THEN
        (SELECT application_id FROM pgapex.application WHERE alias = v_application_id)
      ELSE
        NULL
    END
  );
$$ LANGUAGE sql
  SECURITY DEFINER
  SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_page_id(
  i_application_id INT
, v_page_id        VARCHAR
)
RETURNS int AS $$
  SELECT (
    CASE
      WHEN v_page_id ~ '^[0-9]+$' AND
          (SELECT EXISTS(SELECT 1 FROM pgapex.page WHERE page_id = v_page_id::int AND application_id = i_application_id)) THEN
            v_page_id::int
      WHEN (SELECT EXISTS(SELECT 1 FROM pgapex.page WHERE application_id = i_application_id AND alias = v_page_id)) THEN
        (SELECT page_id FROM pgapex.page WHERE application_id = i_application_id AND alias = v_page_id)
      ELSE
        NULL
    END
  );
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_error(
  v_error_message VARCHAR
)
RETURNS text AS $$
  SELECT '<html>
  <head>
    <title>Error</title>
  </head>
  <body>
    <strong>Error!</strong>
    <p>' || v_error_message || '</p>
  </body>
</html>';
$$ LANGUAGE sql
  SECURITY DEFINER
  SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_create_response(
  t_response_body TEXT
)
RETURNS json AS $$
DECLARE
  j_response JSON;
BEGIN
  SELECT json_build_object(
    'headers', coalesce(json_object(array_agg(h.field_name), array_agg(h.value)), '{}'::json)
  , 'body', t_response_body
  )
  INTO j_response
  FROM temp_headers h
  WHERE h.transaction_id = txid_current();

  RETURN j_response;
END
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_open_session(
    v_application_root VARCHAR
  , i_application_id   INT
  , j_headers          JSONB
)
  RETURNS void AS $$
DECLARE
  v_session_id      VARCHAR;
  t_expiration_time TIMESTAMP;
  j_data            JSONB;
BEGIN
  SELECT pgapex.f_app_get_cookie('PGAPEX_SESSION_' || i_application_id::VARCHAR, j_headers) INTO v_session_id;
  IF v_session_id IS NOT NULL THEN
    SELECT expiration_time, data INTO t_expiration_time, j_data FROM pgapex.session WHERE session_id = v_session_id;
    IF t_expiration_time > current_timestamp THEN
      UPDATE pgapex.session SET expiration_time = (current_timestamp + interval '1 hour') WHERE session_id = v_session_id;
      PERFORM pgapex.f_app_add_setting('session_id', v_session_id);
      IF j_data IS NOT NULL AND j_data ? 'username' THEN
        PERFORM pgapex.f_app_add_setting('username', j_data->>'username');
      END IF;
      RETURN;
    ELSE
      DELETE FROM pgapex.session WHERE session_id = v_session_id;
    END IF;
  END IF;

  SELECT encode(pgapex.digest(current_timestamp::text || random()::text || txid_current()::text || i_application_id::text, 'sha512'), 'hex') INTO v_session_id;
  PERFORM pgapex.f_app_set_cookie('PGAPEX_SESSION_' || i_application_id::VARCHAR, v_session_id || '; Path=' || v_application_root);
  PERFORM pgapex.f_app_add_setting('session_id', v_session_id);
  INSERT INTO pgapex.session (session_id, application_id, data, expiration_time)
  VALUES (v_session_id, i_application_id, '{}'::jsonb, (current_timestamp + interval '1 hour'));
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_session_id()
RETURNS varchar AS $$
  SELECT pgapex.f_app_get_setting('session_id');
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_session_write(
  v_key   VARCHAR
, v_value VARCHAR
)
RETURNS void AS $$
DECLARE
  j_new_session_data JSONB;
BEGIN
  WITH session_data AS (
    SELECT data FROM pgapex.session WHERE session_id = pgapex.f_app_get_session_id()
  ), concat_json AS (
    SELECT s1.key, s1.value FROM jsonb_each(json_build_object(lower(v_key), v_value)::jsonb) s1
    UNION ALL
    SELECT s2.key, s2.value FROM session_data, jsonb_each(session_data.data) s2
  ), with_unique_keys AS (
    SELECT DISTINCT ON (key) key, value FROM concat_json
  )
  SELECT json_object_agg(key, value) INTO j_new_session_data FROM with_unique_keys;

  UPDATE pgapex.session SET data = j_new_session_data
  WHERE session_id = pgapex.f_app_get_session_id();
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_session_read(
  v_key  VARCHAR
)
  RETURNS varchar AS $$
DECLARE
  j_session_data JSONB;
  j_value        VARCHAR;
BEGIN
  SELECT data INTO j_session_data FROM pgapex.session WHERE session_id = pgapex.f_app_get_session_id();
  IF j_session_data IS NOT NULL AND j_session_data ? lower(v_key) THEN
    SELECT j_session_data->>lower(v_key) INTO j_value;
    RETURN j_value;
  END IF;
  RETURN NULL;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_session_delete(
  v_key VARCHAR
)
RETURNS void AS $$
DECLARE
  j_new_session_data JSONB;
BEGIN
  WITH session_data AS (
    SELECT data FROM pgapex.session WHERE session_id = pgapex.f_app_get_session_id()
  ), concat_json AS (
    SELECT s2.key, s2.value FROM session_data, jsonb_each(session_data.data) s2
    WHERE s2.key <> v_key
  ), with_unique_keys AS (
    SELECT DISTINCT ON (key) key, value FROM concat_json
  )
  SELECT coalesce(json_object_agg(key, value), '{}') INTO j_new_session_data FROM with_unique_keys;

  UPDATE pgapex.session SET data = j_new_session_data
  WHERE session_id = pgapex.f_app_get_session_id();
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_cookie(
    v_cookie_name VARCHAR
  , j_headers     JSONB
)
  RETURNS VARCHAR AS $$
DECLARE
  v_cookie_value VARCHAR;
  v_cookies VARCHAR;
  v_cookie TEXT[];
BEGIN
  IF j_headers IS NULL THEN
    RETURN NULL;
  END IF;
  IF j_headers ? 'HTTP_COOKIE' THEN
  SELECT j_headers->'HTTP_COOKIE'->>0 INTO v_cookies;
  FOR v_cookie IN SELECT regexp_split_to_array(trim(c), E'=') FROM regexp_split_to_table(v_cookies, E';') AS c LOOP
    IF v_cookie[1] = v_cookie_name THEN
      RETURN v_cookie[2];
    END IF;
  END LOOP;
END IF;
RETURN NULL;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_set_cookie(
    v_cookie_name  VARCHAR
  , v_cookie_value VARCHAR
)
  RETURNS void AS $$
BEGIN
  PERFORM pgapex.f_app_set_header('set-cookie', v_cookie_name || '=' || v_cookie_value);
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_logout_link()
RETURNS varchar AS $$
  SELECT pgapex.f_app_get_setting('application_root') || '/logout/' ||  pgapex.f_app_get_setting('application_id');
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_replace_system_variables(
  t_template TEXT
)
  RETURNS text AS $$
BEGIN
  t_template := replace(t_template, '&SESSION_ID&', COALESCE(pgapex.f_app_get_session_id(), ''));
  t_template := replace(t_template, '&APPLICATION_ROOT&', COALESCE(pgapex.f_app_get_setting('application_root'), ''));
  t_template := replace(t_template, '&APPLICATION_ID&', COALESCE(pgapex.f_app_get_setting('application_id'), ''));
  t_template := replace(t_template, '&PAGE_ID&', COALESCE(pgapex.f_app_get_setting('page_id'), ''));
  t_template := replace(t_template, '&USERNAME&', COALESCE(pgapex.f_app_get_setting('username'), ''));
  t_template := replace(t_template, '&APPLICATION_NAME&', (SELECT COALESCE(name, '') FROM pgapex.application WHERE application_id = pgapex.f_app_get_setting('application_id')::int));
  t_template := replace(t_template, '&TITLE&', (SELECT COALESCE(title, '') FROM pgapex.page WHERE page_id = pgapex.f_app_get_setting('page_id')::int));
  t_template := replace(t_template, '&LOGOUT_LINK&', COALESCE(pgapex.f_app_get_logout_link(), ''));
  RETURN t_template;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_page_regions(
  i_page_id INT
)
RETURNS TABLE(
  region_id     INT
, region_type   VARCHAR
, display_point VARCHAR
, sequence      INT
, template_id   INT
, name          VARCHAR
) AS $$
  SELECT
    r.region_id
    , (CASE
       WHEN hr.region_id IS NOT NULL THEN 'HTML'
       WHEN nr.region_id IS NOT NULL THEN 'NAVIGATION'
       WHEN rr.region_id IS NOT NULL THEN 'REPORT'
       WHEN fr.region_id IS NOT NULL THEN 'FORM'
       WHEN tfr.region_id IS NOT NULL THEN 'TABULARFORM'
       WHEN dvr.region_id IS NOT NULL THEN 'DETAIL_VIEW'
       END) AS region_type
    , ptdp.display_point_id AS display_point
    , r.sequence
    , r.template_id
    , r.name
  FROM pgapex.region r
    LEFT JOIN pgapex.html_region hr ON hr.region_id = r.region_id
    LEFT JOIN pgapex.navigation_region nr ON nr.region_id = r.region_id
    LEFT JOIN pgapex.report_region rr ON rr.region_id = r.region_id
    LEFT JOIN pgapex.form_region fr ON fr.region_id = r.region_id
    LEFT JOIN pgapex.tabularform_region tfr ON tfr.region_id = r.region_id
    LEFT JOIN pgapex.detailview_region dvr ON dvr.region_id = r.region_id
    LEFT JOIN pgapex.page_template_display_point ptdp ON ptdp.page_template_display_point_id = r.page_template_display_point_id
  WHERE r.page_id = i_page_id AND r.is_visible = TRUE
  ORDER BY r.sequence;
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_parent_region_subregions(
  i_parent_region_id INT
)
RETURNS TABLE(
  subregion_id    INT,
  sequence        INT,
  template_id     INT,
  name            VARCHAR,
  query_parameter VARCHAR,
  subregion_type  VARCHAR
) AS $$
  SELECT
    sr.subregion_id,
	  sr.sequence,
	  sr.template_id,
	  sr.name,
	  sr.query_parameter,
	    (CASE
			  WHEN rr.subregion_id IS NOT NULL THEN 'REPORT'
        WHEN fr.subregion_id IS NOT NULL THEN 'FORM'
        WHEN tsr.subregion_id IS NOT NULL THEN 'TABULAR_SUBFORM'
		  END) AS subregion_type
  FROM pgapex.subregion sr
    LEFT JOIN pgapex.report_region rr ON sr.subregion_id = rr.subregion_id
    LEFT JOIN pgapex.form_region fr ON sr.subregion_id = fr.subregion_id
    LEFT JOIN pgapex.tabularform_subregion tsr ON sr.subregion_id = tsr.subregion_id
  WHERE sr.parent_region_id = i_parent_region_id AND sr.is_visible = TRUE
  ORDER BY sr.sequence;
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_create_page(
    i_application_id INT
  , i_page_id        INT
  , j_get_params     JSONB
  , j_post_params    JSONB
)
RETURNS text AS $$
DECLARE
  b_is_app_auth_required  BOOLEAN;
  b_is_page_auth_required BOOLEAN;
  t_response              TEXT;
  t_success_message       TEXT;
  t_error_message         TEXT;
  r_region                RECORD;
  v_display_point         VARCHAR;
  t_region_template       TEXT;
  t_region_content        TEXT;
  v_url                   TEXT;
  i_homepage_id           INT;
BEGIN
  SELECT authentication_scheme_id <> 'NO_AUTHENTICATION' INTO b_is_app_auth_required FROM pgapex.application WHERE application_id = i_application_id;
  SELECT is_authentication_required INTO b_is_page_auth_required FROM pgapex.page WHERE page_id = i_page_id;

  IF b_is_app_auth_required AND b_is_page_auth_required AND pgapex.f_app_is_authenticated() = FALSE THEN
    SELECT pt.header || pt.body || pt.footer, pt.success_message, pt.error_message
    INTO t_response, t_success_message, t_error_message
    FROM pgapex.page_template pt
    WHERE pt.template_id = (SELECT a.login_page_template_id
                            FROM pgapex.application a
                            WHERE a.application_id = i_application_id);
  ELSE
    FOR r_region IN (SELECT * FROM pgapex.f_app_get_page_regions(i_page_id)) LOOP

      SELECT template INTO t_region_template FROM pgapex.region_template WHERE template_id = r_region.template_id;

      IF r_region.region_type = 'HTML' THEN
        SELECT pgapex.f_app_get_html_region(r_region.region_id) INTO t_region_content;
      ELSIF r_region.region_type = 'NAVIGATION' THEN
        SELECT pgapex.f_app_get_navigation_region(r_region.region_id) INTO t_region_content;
      ELSIF r_region.region_type = 'REPORT' THEN
        SELECT pgapex.f_app_get_report_region(r_region.region_id, j_get_params) INTO t_region_content;
      ELSIF r_region.region_type = 'FORM' THEN
        SELECT pgapex.f_app_get_form_region(r_region.region_id, j_get_params) INTO t_region_content;
      ELSIF r_region.region_type = 'TABULARFORM' THEN
        SELECT pgapex.f_app_get_tabularform_region(r_region.region_id, j_get_params) INTO t_region_content;
      ELSIF r_region.region_type = 'DETAIL_VIEW' THEN
        SELECT pgapex.f_app_get_detail_view(r_region.region_id, j_get_params) INTO t_region_content;
      END IF;
      t_region_template := replace(t_region_template, '#NAME#', r_region.name);
      t_region_template := replace(t_region_template, '#BODY#', t_region_content);
      PERFORM pgapex.f_app_add_region(r_region.display_point, r_region.sequence, t_region_template);
    END LOOP;

    SELECT pt.header || pt.body || pt.footer, pt.success_message, pt.error_message
    INTO t_response, t_success_message, t_error_message
    FROM pgapex.page_template pt
    WHERE pt.template_id = (SELECT template_id FROM pgapex.page WHERE page_id = i_page_id);

    FOR v_display_point IN (SELECT distinct ptdp.display_point_id
                            FROM pgapex.page p
                            LEFT JOIN pgapex.page_template pt ON p.template_id = pt.template_id
                            LEFT JOIN pgapex.page_template_display_point ptdp ON pt.template_id = ptdp.page_template_id
                            WHERE p.page_id = i_page_id
    ) LOOP
      t_response := replace(t_response, '#' || v_display_point || '#', COALESCE(pgapex.f_app_get_display_point_content(v_display_point), ''));
    END LOOP;
  END IF;

  SELECT page_id INTO i_homepage_id FROM pgapex.page WHERE application_id = i_application_id AND is_homepage = true;
  IF i_homepage_id IS NOT NULL THEN
    SELECT pgapex.f_app_get_setting('application_root') || '/app/' || pgapex.f_app_get_setting('application_id') || '/' INTO v_url;
    t_response := replace(t_response, '#APPLICATION_HOMEPAGE_LINK#', v_url || (i_homepage_id)::varchar);
  ELSE
    t_response := replace(t_response, '#APPLICATION_HOMEPAGE_LINK#', '#');
  END IF;

  t_response := replace(t_response, '#APPLICATION_NAME#', (SELECT name FROM pgapex.application WHERE application_id = i_application_id));
  t_response := replace(t_response, '#TITLE#', (SELECT title FROM pgapex.page WHERE page_id = i_page_id));
  t_response := replace(t_response, '#LOGOUT_LINK#', pgapex.f_app_get_logout_link());
  t_response := replace(t_response, '#ERROR_MESSAGE#', pgapex.f_app_get_error_message(t_error_message));
  t_response := replace(t_response, '#SUCCESS_MESSAGE#', pgapex.f_app_get_success_message(t_success_message));
  t_response := pgapex.f_app_replace_system_variables(t_response);

  RETURN t_response;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_message(
  v_type                   VARCHAR
, t_message_template TEXT
)
  RETURNS text AS $$
DECLARE
  t_response                     TEXT;
  t_message                      TEXT;
  t_success_message_from_session TEXT;
  t_error_message_from_session   TEXT;
BEGIN
  SELECT f_app_session_read('success_message') INTO t_success_message_from_session;
  SELECT f_app_session_read('error_message') INTO t_error_message_from_session;
  IF v_type = 'SUCCESS' AND t_success_message_from_session IS NOT NULL THEN
    RETURN replace(t_message_template, '#MESSAGE#', t_success_message_from_session);
  ELSIF v_type = 'ERROR' AND t_error_message_from_session IS NOT NULL THEN
    RETURN replace(t_message_template, '#MESSAGE#', t_error_message_from_session);
  ELSE
    SELECT string_agg(message, '<br />') INTO t_message FROM temp_messages WHERE type = v_type AND transaction_id = txid_current();
    IF t_message <> '' THEN
      RETURN replace(t_message_template, '#MESSAGE#', t_message);
    END IF;
  END IF;
  RETURN '';
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_error_message(
  t_error_message_template TEXT
)
RETURNS text AS $$
BEGIN
  RETURN pgapex.f_app_get_message('ERROR', t_error_message_template);
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_success_message(
  t_success_message_template TEXT
)
RETURNS text AS $$
BEGIN
  RETURN pgapex.f_app_get_message('SUCCESS', t_success_message_template);
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_is_authenticated()
  RETURNS boolean AS $$
DECLARE
  b_is_authenticated BOOLEAN;
BEGIN
  SELECT pgapex.f_app_session_read('is_authenticated')::BOOLEAN INTO b_is_authenticated;
  IF b_is_authenticated IS NOT NULL AND b_is_authenticated = TRUE THEN
    RETURN TRUE;
  END IF;
  RETURN FALSE;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_parse_operation(
    i_application_id   INT
  , i_page_id          INT
  , v_method           VARCHAR
  , j_headers          JSONB
  , j_get_params       JSONB
  , j_post_params      JSONB
)
  RETURNS void AS $$
DECLARE
  b_is_permitted BOOLEAN;
BEGIN
  IF upper(v_method) <> 'POST' THEN
    RETURN;
  END IF;

  IF j_post_params ? 'PGAPEX_OP' AND j_post_params ? 'USERNAME' AND j_post_params ? 'PASSWORD' AND j_post_params->>'PGAPEX_OP' = 'LOGIN' THEN
    SELECT is_permitted INTO b_is_permitted
    FROM pgapex.application a,
        dblink(
          pgapex.f_app_get_dblink_connection_name()
        , 'select ' || a.authentication_function_schema_name || '.' || a.authentication_function_name || '(' || quote_nullable(j_post_params->>'USERNAME') || ',' || quote_nullable(j_post_params->>'PASSWORD') || ')'
        , false
        ) AS ( is_permitted BOOLEAN )
    WHERE application_id = i_application_id;

    IF b_is_permitted THEN
      PERFORM pgapex.f_app_session_write('is_authenticated', TRUE::VARCHAR);
      PERFORM pgapex.f_app_session_write('username', j_post_params->>'USERNAME');
      PERFORM pgapex.f_app_add_setting('username', j_post_params->>'USERNAME');
    ELSE
      PERFORM pgapex.f_app_add_error_message('Permission denied!');
    END IF;
  ELSIF j_post_params ? 'PGAPEX_REGION' THEN
    PERFORM pgapex.f_app_form_region_submit(i_page_id, (j_post_params->>'PGAPEX_REGION')::int, j_post_params);
  ELSIF j_post_params ? 'PGAPEX_TABULARFORM' THEN
    PERFORM pgapex.f_app_tabularform_region_submit(i_page_id, (j_post_params->>'PGAPEX_TABULARFORM')::int, j_post_params);
  ELSIF j_post_params ? 'PGAPEX_SUBFORM' THEN 
    PERFORM pgapex.f_app_subform_submit(i_page_id, (j_post_params->>'PGAPEX_SUBFORM')::int, j_post_params);
  ELSIF j_post_params ? 'PGAPEX_TABULAR_SUBFORM' THEN
    PERFORM pgapex.f_app_tabular_subform_submit(i_page_id, (j_post_params->>'PGAPEX_TABULAR_SUBFORM')::int, j_post_params);
  END IF;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_form_region_submit(
    i_page_id          INT
  , i_region_id        INT
  , j_post_params      JSONB
)
  RETURNS void AS $$
DECLARE
  v_schema_name       VARCHAR;
  v_function_name     VARCHAR;
  v_success_message   VARCHAR;
  v_error_message     VARCHAR;
  v_redirect_url      VARCHAR;
  t_function_call     TEXT;
  t_function_response TEXT;
  i_form_pre_fill_id  INT;
  t_pre_fill_url_params TEXT[];
  t_url_query_string TEXT;
BEGIN
  IF (SELECT NOT EXISTS(SELECT 1
                        FROM pgapex.region r
                        LEFT JOIN pgapex.form_region fr ON fr.region_id = r.region_id
                        WHERE r.page_id = i_page_id AND r.region_id = i_region_id AND fr.region_id IS NOT NULL)) THEN
    PERFORM pgapex.f_app_add_error_message('Region does not exist');
  END IF;

  SELECT schema_name, function_name, success_message, error_message, redirect_url, form_pre_fill_id
  INTO v_schema_name, v_function_name, v_success_message, v_error_message, v_redirect_url, i_form_pre_fill_id
  FROM pgapex.form_region WHERE region_id = i_region_id;

  t_function_call := 'SELECT ' || v_schema_name || '.' || v_function_name || ' ( ';
  t_function_call := t_function_call || (SELECT string_agg(a.param, ', ')
                      FROM (
                             SELECT ff.function_parameter_ordinal_position, coalesce(nullif(quote_nullable(url_params.value), ''''''), 'NULL') AS param
                             FROM pgapex.form_field ff
                               LEFT JOIN pgapex.page_item pi ON pi.form_field_id = ff.form_field_id
                               LEFT JOIN json_each_text(j_post_params::json) url_params ON url_params.key = pi.name
                             WHERE ff.region_id = i_region_id
                             ORDER BY ff.function_parameter_ordinal_position ASC
                           ) a);
  t_function_call := t_function_call || ' );';

  BEGIN
    SELECT res_func INTO t_function_response FROM dblink(pgapex.f_app_get_dblink_connection_name(), t_function_call, TRUE) AS ( res_func text );
    IF v_success_message IS NOT NULL THEN
      PERFORM pgapex.f_app_add_success_message(v_success_message);
    END IF;
    IF t_function_response IS NULL THEN
      RAISE EXCEPTION 'Function did not return any value';
    ELSIF t_function_response = 'FALSE' THEN
      RAISE EXCEPTION 'Function returned false';
    END IF;
    IF v_redirect_url IS NOT NULL THEN
      PERFORM pgapex.f_app_set_header('location', pgapex.f_app_replace_system_variables(v_redirect_url));
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      PERFORM pgapex.f_app_add_error_message(coalesce(v_error_message, SQLERRM));
  END;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_subform_submit(
    i_page_id          INT
  , i_subregion_id     INT
  , j_post_params      JSONB
)
  RETURNS void AS $$
DECLARE
  v_schema_name       VARCHAR;
  v_function_name     VARCHAR;
  v_success_message   VARCHAR;
  v_error_message     VARCHAR;
  v_redirect_url      VARCHAR;
  t_function_call     TEXT;
  t_function_response TEXT;
BEGIN
  SELECT schema_name, function_name, success_message, error_message, redirect_url
  INTO v_schema_name, v_function_name, v_success_message, v_error_message, v_redirect_url
  FROM pgapex.form_region WHERE subregion_id = i_subregion_id;

  t_function_call := 'SELECT ' || v_schema_name || '.' || v_function_name || ' ( ';
  t_function_call := t_function_call || (SELECT string_agg(a.param, ', ')
                      FROM (
                             SELECT ff.function_parameter_ordinal_position, coalesce(nullif(quote_nullable(url_params.value), ''''''), 'NULL') AS param
                             FROM pgapex.form_field ff
                               LEFT JOIN pgapex.page_item pi ON pi.form_field_id = ff.form_field_id
                               LEFT JOIN json_each_text(j_post_params::json) url_params ON url_params.key = pi.name
                             WHERE ff.subregion_id = i_subregion_id
                             ORDER BY ff.function_parameter_ordinal_position ASC
                           ) a);
  t_function_call := t_function_call || ' );';

  BEGIN
    SELECT res_func INTO t_function_response FROM dblink(pgapex.f_app_get_dblink_connection_name(), t_function_call, TRUE) AS ( res_func text );
    IF v_success_message IS NOT NULL THEN
      PERFORM pgapex.f_app_add_success_message(v_success_message);
    END IF;
    IF t_function_response IS NULL THEN
      RAISE EXCEPTION 'Function did not return any value';
    ELSIF t_function_response = 'FALSE' THEN
      RAISE EXCEPTION 'Function returned false';
    END IF;
    IF v_redirect_url IS NOT NULL THEN
      PERFORM pgapex.f_app_set_header('location', pgapex.f_app_replace_system_variables(v_redirect_url));
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      PERFORM pgapex.f_app_add_error_message(coalesce(v_error_message, SQLERRM));
  END;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_tabular_subform_submit(
    i_page_id       INT
  , i_subregion_id  INT
  , j_post_params   JSONB
)
  RETURNS void AS $$
DECLARE
  v_schema_name       VARCHAR;
  v_function_name     VARCHAR;
  v_success_message   VARCHAR;
  v_error_message     VARCHAR;
  v_redirect_url      VARCHAR;
  t_function_call     TEXT;
  i_function_id       INT;
  t_function_id       TEXT;
  t_function_params   TEXT;
  t_function_response TEXT;
  j_function_params   JSON;
  t_function_param    TEXT;
  j_function_param    JSON;
BEGIN
  SELECT (j_post_params->>'PGAPEX_BUTTON')::int INTO i_function_id;

  SELECT tsff.schema_name, tsff.function_name, tsff.success_message, tsff.error_message
    INTO v_schema_name, v_function_name, v_success_message, v_error_message
    FROM pgapex.tabular_subform_function tsff
    WHERE tsff.subregion_id = i_subregion_id AND tsff.tabular_subform_function_id = i_function_id;

  t_function_id := quote_literal(i_function_id);
  t_function_params := replace(j_post_params->>'#FUNCTION_PARAMETERS#', '''', '"');
  t_function_params := replace(t_function_params, '"{', '{');
  t_function_params := replace(t_function_params, '}"', '}');

  BEGIN
    FOR j_function_param IN SELECT value FROM json_array_elements(t_function_params::json) WHERE value->i_function_id::text IS NOT NULL
    LOOP
      t_function_call := 'SELECT ' || v_schema_name || '.' || v_function_name || '('; 
      t_function_call := t_function_call || (SELECT string_agg(quote_literal(a.value->>'value'), ', ')
                        FROM (
                                SELECT value FROM json_array_elements(j_function_param->i_function_id::text)
                                ORDER BY cast(value->'ordinal_position' AS TEXT) ASC
                        ) a);
      t_function_call := t_function_call || ');';
      SELECT res_func INTO t_function_response FROM dblink(pgapex.f_app_get_dblink_connection_name(), t_function_call, TRUE) AS ( res_func text );
      IF t_function_response IS NULL THEN
        RAISE EXCEPTION 'One of the function calls did not return any value';
      ELSIF t_function_response = 'FALSE' THEN
        RAISE EXCEPTION 'One of the function calls returned false';
      END IF;
    END LOOP;

    IF v_success_message IS NOT NULL THEN
      PERFORM pgapex.f_app_add_success_message(v_success_message);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      PERFORM pgapex.f_app_add_error_message(coalesce(v_error_message, SQLERRM));
  END;
    
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_tabularform_region_submit(
    i_page_id               INT
  , i_region_id             INT
  , j_post_params           JSONB
)
  RETURNS void AS $$
DECLARE
  v_schema_name       VARCHAR;
  v_function_name     VARCHAR;
  v_success_message   VARCHAR;
  v_error_message     VARCHAR;
  b_app_user          BOOLEAN;
  b_xmin_parameter    BOOLEAN;
  t_xmin_view_column  TEXT;
  v_view_schema       TEXT;
  v_view_name         TEXT;
  v_xmin_value_query  TEXT;
  t_unique_id         TEXT;
  t_function_params   TEXT[];
  t_function_param    TEXT;
  t_app_user_param    TEXT  := '';
  t_xmin_param        TEXT  := '';
  t_function_call     TEXT;
  t_function_response INT;
BEGIN
  IF (SELECT NOT EXISTS(SELECT 1
                        FROM pgapex.region r
                        LEFT JOIN pgapex.tabularform_region tfr ON tfr.region_id = r.region_id
                        WHERE r.page_id = i_page_id AND r.region_id = i_region_id AND tfr.region_id IS NOT NULL)) THEN
    PERFORM pgapex.f_app_add_error_message('Region does not exist');
  END IF;

  SELECT tfr.schema_name, tfr.view_name, tfr.unique_id, tfr.xmin_view_column
  INTO v_view_schema, v_view_name, t_unique_id, t_xmin_view_column
  FROM pgapex.tabularform_region tfr
  WHERE tfr.region_id = i_region_id;

  SELECT tff.schema_name, tff.function_name, tff.success_message, tff.error_message, tff.app_user, tff.xmin_parameter
  INTO v_schema_name, v_function_name, v_success_message, v_error_message, b_app_user, b_xmin_parameter
  FROM pgapex.tabularform_function tff
  WHERE tff.region_id = i_region_id AND tff.tabularform_function_id = (j_post_params->>'PGAPEX_BUTTON')::int;

  IF b_app_user IS TRUE THEN
    t_app_user_param := ', ' || quote_literal((SELECT pgapex.f_app_get_setting('username')));
  END IF;

  SELECT ARRAY(SELECT quote_literal(argument) FROM json_array_elements_text((j_post_params->>'#UNIQUE_ID_COLUMN#')::json) AS argument)
  INTO t_function_params;

  BEGIN
    FOREACH t_function_param IN ARRAY t_function_params
    LOOP
      IF b_xmin_parameter IS TRUE THEN
        t_xmin_param := ', ' || quote_literal((j_post_params->'#XMIN_COLUMN#'->>replace(t_function_param, '''', ''))::TEXT);
      END IF;
      t_function_call := 'SELECT ' || v_schema_name || '.' || v_function_name || '(' || t_function_param || coalesce(t_xmin_param, '') || t_app_user_param || ');';
      SELECT res_func INTO t_function_response FROM dblink(pgapex.f_app_get_dblink_connection_name(), t_function_call, TRUE) AS ( res_func text );
      IF t_function_response IS NULL THEN
        RAISE EXCEPTION 'One of the function calls did not return any value';
      ELSIF t_function_response = 'FALSE' THEN
        RAISE EXCEPTION 'One of the function calls returned false';
      END IF;
    END LOOP;

    IF v_success_message IS NOT NULL THEN
      PERFORM pgapex.f_app_add_success_message(v_success_message);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      PERFORM pgapex.f_app_add_error_message(coalesce(v_error_message, SQLERRM));
  END;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_html_region(
  i_region_id   INT
)
  RETURNS TEXT AS $$
DECLARE
  t_response        TEXT;
  t_app_user_value  VARCHAR;
BEGIN
  SELECT content INTO t_response FROM pgapex.html_region WHERE region_id = i_region_id;
  SELECT pgapex.f_app_get_setting('username') INTO t_app_user_value;

  IF t_app_user_value IS NOT NULL THEN
    t_response := replace(t_response, '#APP_USER#', t_app_user_value);
  END IF;

  RETURN t_response;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_navigation_items_with_levels(
  i_navigation_id   INT
)
RETURNS SETOF pgapex.t_navigation_item_with_level AS $$
  WITH RECURSIVE navigation_tree (navigation_item_id, parent_navigation_item_id, sequence, name, page_id, url, level)
  AS (
    SELECT
      navigation_item_id
      , parent_navigation_item_id
      , sequence
      , name
      , page_id
      , url
      , 1
    FROM pgapex.navigation_item
    WHERE navigation_id = i_navigation_id
      AND parent_navigation_item_id is NULL
    UNION ALL
    SELECT
      ni.navigation_item_id,
      nt.navigation_item_id,
      ni.sequence,
      ni.name,
      ni.page_id,
      ni.url,
      nt.level + 1
    FROM pgapex.navigation_item ni, navigation_tree nt
    WHERE ni.parent_navigation_item_id = nt.navigation_item_id
      AND ni.navigation_id = i_navigation_id
  )
  SELECT navigation_item_id, parent_navigation_item_id, sequence, name, page_id, url, level
  FROM navigation_tree
  ORDER BY level, parent_navigation_item_id NULLS FIRST, sequence;
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_navigation_breadcrumb(
  i_navigation_id      INT
, i_page_id            INT
)
RETURNS SETOF pgapex.t_navigation_item_with_level AS $$
  WITH RECURSIVE breadcrumb(navigation_item_id, parent_navigation_item_id, sequence, name, page_id, url, level) AS (
    SELECT * FROM pgapex.f_app_get_navigation_items_with_levels(i_navigation_id)
    WHERE page_id = i_page_id
    UNION ALL
    SELECT niwl.* FROM pgapex.f_app_get_navigation_items_with_levels(i_navigation_id) niwl, breadcrumb b
    WHERE niwl.navigation_item_id = b.parent_navigation_item_id
  )
  SELECT * FROM breadcrumb
  ORDER BY level
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_navigation_in_order (
    i_navigation_id             INT
  , i_parent_navigation_item_id INT
  , i_parent_ids                INT[]
)
  RETURNS SETOF pgapex.t_navigation_item_with_level AS $$
DECLARE
  r pgapex.t_navigation_item_with_level;
BEGIN
  FOR r IN SELECT * FROM pgapex.f_app_get_navigation_items_with_levels(i_navigation_id)
  WHERE (
    CASE
      WHEN i_parent_navigation_item_id IS NULL THEN (parent_navigation_item_id IS NULL)
      ELSE (parent_navigation_item_id = i_parent_navigation_item_id)
    END
  ) AND (
    CASE
      WHEN i_parent_ids IS NULL THEN (TRUE)
      WHEN parent_navigation_item_id IS NULL THEN (TRUE)
      ELSE (parent_navigation_item_id = ANY(i_parent_ids))
    END
  )
  ORDER BY sequence
  LOOP
    RETURN NEXT r;
    RETURN QUERY SELECT * FROM pgapex.f_app_get_navigation_in_order(i_navigation_id, r.navigation_item_id, i_parent_ids);
  END LOOP;
  RETURN;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_navigation_of_type (
    i_navigation_id             INT
  , i_page_id                   INT
  , v_navigation_type           VARCHAR
)
  RETURNS SETOF pgapex.t_navigation_item_with_level AS $$
BEGIN
  IF v_navigation_type = 'BREADCRUMB' THEN
    RETURN QUERY SELECT * FROM pgapex.f_app_get_navigation_breadcrumb(i_navigation_id, i_page_id);
  ELSIF v_navigation_type = 'SITEMAP' THEN
    RETURN QUERY SELECT * FROM pgapex.f_app_get_navigation_in_order(i_navigation_id, NULL, NULL);
  ELSE
    RETURN QUERY SELECT * FROM pgapex.f_app_get_navigation_in_order(i_navigation_id, NULL, (
      SELECT ARRAY (SELECT navigation_item_id FROM  pgapex.f_app_get_navigation_breadcrumb(i_navigation_id, i_page_id))
    ));
  END IF;
  RETURN;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_navigation_region(
  i_region_id   INT
)
  RETURNS TEXT AS $$
DECLARE
  v_url_prefix                         VARCHAR;
  v_navigation_type                    VARCHAR;
  i_navigation_id                      INT;
  i_template_id                        INT;
  i_page_id                            INT;
  b_repeat_last_level                  BOOLEAN;
  t_region_template                    TEXT;
  t_navigation_begin_template          TEXT;
  t_navigation_end_template            TEXT;
  i_navigation_template_id             INT;
  i_navigation_item_template_max_level INT;
BEGIN
  SELECT nr.navigation_type_id, nr.navigation_id, nr.template_id, nr.repeat_last_level, r.page_id, nt.navigation_begin, nt.navigation_end, nt.template_id
  INTO v_navigation_type, i_navigation_id, i_template_id, b_repeat_last_level, i_page_id, t_navigation_begin_template, t_navigation_end_template, i_navigation_template_id
  FROM pgapex.navigation_region nr
  LEFT JOIN pgapex.region r ON nr.region_id = r.region_id
  LEFT JOIN pgapex.navigation_template nt ON nr.template_id = nt.template_id
  WHERE nr.region_id = i_region_id;

  SELECT max(level) INTO i_navigation_item_template_max_level FROM pgapex.navigation_item_template WHERE navigation_template_id = i_navigation_template_id;
  SELECT pgapex.f_app_get_setting('application_root') || '/app/' || pgapex.f_app_get_setting('application_id') || '/' INTO v_url_prefix;

  SELECT string_agg(
      CASE
      WHEN n.page_id = i_page_id THEN replace(replace(replace(nit.active_template, '#NAME#', n.name), '#URL#', (
        CASE
          WHEN n.page_id IS NULL THEN n.url
          ELSE v_url_prefix || n.page_id
        END
      )), '#LEVEL#', n.level::varchar)
      ELSE replace(replace(replace(nit.inactive_template, '#NAME#', n.name), '#URL#', (
        CASE
          WHEN n.page_id IS NULL THEN n.url
          ELSE v_url_prefix || n.page_id
        END
      )), '#LEVEL#', n.level::varchar)
      END
      , '') INTO t_region_template
  FROM pgapex.f_app_get_navigation_of_type(i_navigation_id, i_page_id, v_navigation_type) n
    LEFT JOIN pgapex.navigation_item_template nit ON (
      CASE
        WHEN n.level > i_navigation_item_template_max_level AND b_repeat_last_level THEN
          nit.level = i_navigation_item_template_max_level AND nit.navigation_template_id = i_navigation_template_id
        ELSE
          n.level = nit.level AND nit.navigation_template_id = i_navigation_template_id
      END
      )
  WHERE nit.navigation_item_template_id IS NOT NULL;

  RETURN t_navigation_begin_template || t_region_template || t_navigation_end_template;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_row_count(
  v_schema_name VARCHAR
, v_view_name   VARCHAR
)
RETURNS INT AS $$
  SELECT res_row_count
  FROM dblink(pgapex.f_app_get_dblink_connection_name()
  , 'SELECT COUNT(1) FROM ' || v_schema_name || '.' || v_view_name
  , FALSE) AS ( res_row_count INT)
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_row_count_by_param(
  v_schema_name   VARCHAR
, v_view_name     VARCHAR
, parameter       VARCHAR
, parameter_value VARCHAR
)
RETURNS INT AS $$
  SELECT res_row_count
  FROM dblink(pgapex.f_app_get_dblink_connection_name()
  , 'SELECT COUNT(1) FROM ' || v_schema_name || '.' || v_view_name || ' WHERE ' || parameter || ' = ' || parameter_value
  , FALSE) AS ( res_row_count INT)
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_html_special_chars(
  t_text text
)
RETURNS TEXT AS $$
  SELECT replace(replace(replace(replace(replace(t_text, '&', '&amp;'), '"', '&quot;'), '''', '&apos;'), '>', '&gt;'), '<', '&lt;');
$$ LANGUAGE sql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_form_page_path(
  i_form_page_id INT
)
  RETURNS TEXT AS $$
DECLARE
  i_application_id INT;
  t_url            TEXT;
BEGIN
  SELECT p.application_id
  INTO i_application_id
  FROM pgapex.page p
  WHERE p.page_id = i_form_page_id;

  t_url := '../' || i_application_id::text || '/' || i_form_page_id::text;
  
  RETURN t_url;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_page_path(
  i_page_id INT
)
  RETURNS TEXT AS $$
DECLARE
  i_application_id INT;
  t_url            TEXT;
BEGIN
  SELECT p.application_id
  INTO i_application_id
  FROM pgapex.page p
  WHERE p.page_id = i_page_id;

  t_url := '../' || i_application_id::text || '/' || i_page_id::text;
  
  RETURN t_url;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_detailview_path(
  i_report_region_id  INT
)
  RETURNS TEXT AS $$
DECLARE
  i_detailview_region_id  INT;
  i_application_id        INT;
  i_page_id               INT;
  t_url                   TEXT;
BEGIN
	SELECT dvr.region_id
  INTO i_detailview_region_id
  FROM pgapex.region r
  LEFT JOIN pgapex.detailview_region dvr ON r.region_id = dvr.report_region_id
  WHERE r.region_id = i_report_region_id;

  IF i_detailview_region_id IS NOT NULL THEN
    SELECT p.application_id, p.page_id
    INTO i_application_id, i_page_id
    FROM pgapex.region r
    LEFT JOIN pgapex.page p ON r.page_id = p.page_id
    WHERE r.region_id = i_detailview_region_id;

    t_url := '../' || i_application_id::text || '/' || i_page_id::text;
  END IF;

  RETURN t_url;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_report_subregion_with_template(
  i_subregion_id              INT
, j_data                   JSON
, v_additional_parameters  VARCHAR
, v_pagination_query_param VARCHAR
, i_page_count             INT
, i_current_page           INT
, b_show_header            BOOLEAN
)
  RETURNS TEXT AS $$
DECLARE
  t_response         TEXT;
  t_pagination       TEXT     := '';
  v_url_prefix       VARCHAR;
  v_unique_id        VARCHAR;
  t_report_begin     TEXT;
  t_report_end       TEXT;
  t_header_begin     TEXT;
  t_header_row_begin TEXT;
  t_header_cell      TEXT;
  t_header_row_end   TEXT;
  t_header_end       TEXT;
  t_body_begin       TEXT;
  t_body_row_begin   TEXT;
  t_body_row_link    TEXT;
  t_body_row_cell    TEXT;
  t_body_row_end     TEXT;
  t_body_end         TEXT;
  t_pagination_begin TEXT;
  t_pagination_end   TEXT;
  t_previous_page    TEXT;
  t_next_page        TEXT;
  t_active_page      TEXT;
  t_inactive_page    TEXT;
  r_report_column    pgapex.t_report_column_with_link;
  r_report_columns   pgapex.t_report_column_with_link[];
  j_row              JSON;
  r_column           RECORD;
  t_button_link      TEXT;
  t_detailview_path  TEXT;
  t_cell_content     TEXT;
BEGIN
  SELECT rr.unique_id
  INTO v_unique_id
  FROM pgapex.report_region rr
  WHERE rr.subregion_id = i_subregion_id;

  SELECT rt.report_begin, rt.report_end, rt.header_begin, rt.header_row_begin, rt.header_cell, rt.header_row_end, rt.header_end,
         rt.body_begin, rt.body_row_begin, rt.body_row_cell, rt.body_row_end, rt.body_end,
         rt.pagination_begin, rt.pagination_end, rt.previous_page, rt.next_page, rt.active_page, rt.inactive_page
  INTO t_report_begin, t_report_end, t_header_begin, t_header_row_begin, t_header_cell, t_header_row_end, t_header_end,
       t_body_begin, t_body_row_begin, t_body_row_cell, t_body_row_end, t_body_end,
       t_pagination_begin, t_pagination_end, t_previous_page, t_next_page, t_active_page, t_inactive_page
  FROM pgapex.report_region rr
  LEFT JOIN pgapex.report_template rt ON rt.template_id = rr.template_id
  WHERE rr.subregion_id = i_subregion_id;

  SELECT ARRAY(
      SELECT ROW(rc.view_column_name, rc.heading, rc.sequence, rc.is_text_escaped, rcl.url, rcl.link_text, rcl.attributes)
      FROM pgapex.report_column rc
      LEFT JOIN pgapex.report_column_link rcl ON rcl.report_column_id = rc.report_column_id
      WHERE rc.subregion_id = i_subregion_id
      ORDER BY rc.sequence
  ) INTO r_report_columns;

  t_response := t_report_begin;

  IF b_show_header THEN
    t_response := t_response || t_header_begin || t_header_row_begin;

    FOREACH r_report_column IN ARRAY r_report_columns
    LOOP
      t_response := t_response || replace(t_header_cell, '#CELL_CONTENT#', r_report_column.heading);
    END LOOP;

    t_response := t_response || t_header_row_end || t_header_end;
  END IF;

  t_response := t_response || t_body_begin;

  IF j_data IS NOT NULL THEN
    FOR j_row IN SELECT * FROM json_array_elements(j_data)
    LOOP
      t_response := t_response || t_body_row_begin;
      IF t_body_row_link IS NOT NULL THEN
        t_button_link := replace(t_body_row_link, '#PATH#', t_detailview_path);
        t_button_link := replace(t_button_link, '#UNIQUE_ID#', v_unique_id);
        t_button_link := replace(t_button_link, '#UNIQUE_ID_VALUE#', (j_row->>v_unique_id)::text);
        t_response := t_response || t_button_link;
      END IF;

        FOREACH r_report_column IN ARRAY r_report_columns
        LOOP
          IF r_report_column.view_column_name IS NOT NULL THEN
            t_cell_content := COALESCE(j_row->>r_report_column.view_column_name, '');
            IF r_report_column.is_text_escaped THEN
              t_cell_content := pgapex.f_app_html_special_chars(t_cell_content);
            END IF;
            t_response := t_response || replace(t_body_row_cell, '#CELL_CONTENT#', t_cell_content);
          ELSE
            FOR r_column IN SELECT * FROM json_each_text(j_row)
            LOOP
              r_report_column.link_text := replace(r_report_column.link_text, '%' || r_column.key || '%', coalesce(r_column.value, ''));
              r_report_column.url := replace(r_report_column.url, '%' || r_column.key || '%', coalesce(r_column.value, ''));
            END LOOP;
            IF r_report_column.is_text_escaped THEN
              r_report_column.link_text := pgapex.f_app_html_special_chars(r_report_column.link_text);
            END IF;
            t_response := t_response || replace(t_body_row_cell, '#CELL_CONTENT#', '<a href="' || r_report_column.url || '" ' || COALESCE(r_report_column.attributes, '') || '>' || r_report_column.link_text || '</a>');
          END IF;
        END LOOP;
      t_response := t_response || t_body_row_end;
    END LOOP;
  END IF;

  t_response := t_response || t_body_end || t_report_end;

  v_url_prefix := pgapex.f_app_get_setting('application_root') || '/app/' || pgapex.f_app_get_setting('application_id') || '/' ||
    pgapex.f_app_get_setting('page_id') || '?' || v_additional_parameters || v_pagination_query_param || '=';

  IF i_page_count > 1 THEN
    t_pagination := t_pagination_begin;

    IF i_current_page > 1 THEN
      t_pagination := t_pagination || replace(t_previous_page, '#LINK#', v_url_prefix || 1);
    END IF;

    FOR p in 1 .. i_page_count
    LOOP
      IF p = i_current_page THEN
        t_pagination := t_pagination || replace(replace(t_active_page, '#LINK#', v_url_prefix || p), '#NUMBER#', p::varchar);
      ELSE
        t_pagination := t_pagination || replace(replace(t_inactive_page, '#LINK#', v_url_prefix || p), '#NUMBER#', p::varchar);
      END IF;
    END LOOP;

    IF i_current_page < i_page_count THEN
      t_pagination := t_pagination || replace(t_next_page, '#LINK#', v_url_prefix || i_page_count);
    END IF;

    t_pagination := t_pagination || t_pagination_end;
  END IF;

  RETURN replace(t_response, '#PAGINATION#', t_pagination);
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_report_region_with_template(
  i_region_id                     INT
, j_data                          JSON
, v_pagination_query_param        VARCHAR
, i_page_count                    INT
, i_current_page                  INT
, b_show_header                   BOOLEAN
, b_include_create_entity_button  BOOLEAN
, v_create_entity_button_label    VARCHAR
, i_create_entity_page_id         INT
, i_form_page_id                  INT
)
  RETURNS TEXT AS $$
DECLARE
  t_response                TEXT;
  t_pagination              TEXT     := '';
  v_url_prefix              VARCHAR;
  v_unique_id               VARCHAR;
  t_report_begin            TEXT;
  t_report_end              TEXT;
  t_buttons_row_begin       TEXT;
  t_buttons_row_content     TEXT;
  t_buttons_row_end         TEXT;
  t_header_begin            TEXT;
  t_header_row_begin        TEXT;
  t_header_cell             TEXT;
  t_header_row_end          TEXT;
  t_header_end              TEXT;
  t_body_begin              TEXT;
  t_body_row_begin          TEXT;
  t_body_row_link           TEXT;
  t_body_row_cell           TEXT;
  t_body_row_end            TEXT;
  t_body_end                TEXT;
  t_pagination_begin        TEXT;
  t_pagination_end          TEXT;
  t_previous_page           TEXT;
  t_next_page               TEXT;
  t_active_page             TEXT;
  t_inactive_page           TEXT;
  r_report_column           pgapex.t_report_column_with_link;
  r_report_columns          pgapex.t_report_column_with_link[];
  j_row                     JSON;
  r_column                  RECORD;
  t_button_link             TEXT;
  t_detailview_path         TEXT;
  t_cell_content            TEXT;
  t_button_template         TEXT;
  t_create_entity_page_path TEXT;
BEGIN
  SELECT rr.unique_id
  INTO v_unique_id
  FROM pgapex.report_region rr
  WHERE rr.region_id = i_region_id;

  IF v_unique_id IS NULL THEN
    SELECT rt.report_begin, rt.report_end, rt.header_begin, rt.header_row_begin, rt.header_cell, rt.header_row_end, rt.header_end,
         rt.body_begin, rt.body_row_begin, rt.body_row_cell, rt.body_row_end, rt.body_end,
         rt.pagination_begin, rt.pagination_end, rt.previous_page, rt.next_page, rt.active_page, rt.inactive_page
    INTO t_report_begin, t_report_end, t_header_begin, t_header_row_begin, t_header_cell, t_header_row_end, t_header_end,
         t_body_begin, t_body_row_begin, t_body_row_cell, t_body_row_end, t_body_end,
         t_pagination_begin, t_pagination_end, t_previous_page, t_next_page, t_active_page, t_inactive_page
    FROM pgapex.report_region rr
    LEFT JOIN pgapex.report_template rt ON rt.template_id = rr.template_id
    WHERE rr.region_id = i_region_id;
  ELSE
    SELECT rlt.report_begin, rlt.report_end, rlt.buttons_row_begin, rlt.buttons_row_content, rlt.buttons_row_end, rlt.header_begin, rlt.header_row_begin, rlt.header_cell, rlt.header_row_end, rlt.header_end,
         rlt.body_begin, rlt.body_row_begin, rlt.body_row_link, rlt.body_row_cell, rlt.body_row_end, rlt.body_end,
         rlt.pagination_begin, rlt.pagination_end, rlt.previous_page, rlt.next_page, rlt.active_page, rlt.inactive_page
    INTO t_report_begin, t_report_end, t_buttons_row_begin, t_buttons_row_content, t_buttons_row_end, t_header_begin, t_header_row_begin, t_header_cell, t_header_row_end, t_header_end,
         t_body_begin, t_body_row_begin, t_body_row_link, t_body_row_cell, t_body_row_end, t_body_end,
         t_pagination_begin, t_pagination_end, t_previous_page, t_next_page, t_active_page, t_inactive_page
    FROM pgapex.report_region rr
    LEFT JOIN pgapex.report_link_template rlt ON rlt.template_id = rr.link_template_id
    WHERE rr.region_id = i_region_id;

    IF i_form_page_id IS NULL THEN
      SELECT pgapex.f_app_get_detailview_path(i_region_id) INTO t_detailview_path;
    ELSE
      SELECT pgapex.f_app_get_form_page_path(i_form_page_id) INTO t_detailview_path;
    END IF;

  END IF;

  SELECT ARRAY(
      SELECT ROW(rc.view_column_name, rc.heading, rc.sequence, rc.is_text_escaped, rcl.url, rcl.link_text, rcl.attributes)
      FROM pgapex.report_column rc
      LEFT JOIN pgapex.report_column_link rcl ON rcl.report_column_id = rc.report_column_id
      WHERE rc.region_id = i_region_id
      ORDER BY rc.sequence
  ) INTO r_report_columns;

  t_response := t_report_begin;

  IF b_show_header THEN
    t_response := t_response || t_header_begin || t_header_row_begin;

    FOREACH r_report_column IN ARRAY r_report_columns
    LOOP
      t_response := t_response || replace(t_header_cell, '#CELL_CONTENT#', r_report_column.heading);
    END LOOP;

    t_response := t_response || t_header_row_end || t_header_end;
  END IF;

  IF b_include_create_entity_button THEN
    SELECT template FROM pgapex.link_button_template WHERE template_id = 1 INTO t_button_template;
    SELECT f_app_get_create_entity_page_path(i_create_entity_page_id) INTO t_create_entity_page_path;
    t_response := t_response || t_buttons_row_begin;
    t_buttons_row_content := replace(t_buttons_row_content, '#CREATE_ENTITY_BUTTON#', t_button_template);
    t_buttons_row_content := replace(t_buttons_row_content, '#LABEL#', v_create_entity_button_label);
    t_buttons_row_content := replace(t_buttons_row_content, '#PATH#', t_create_entity_page_path);
    t_response := t_response || t_buttons_row_content;
    t_response := t_response || t_buttons_row_end;
  END IF;

  t_response := t_response || t_body_begin;

  IF j_data IS NOT NULL THEN
    FOR j_row IN SELECT * FROM json_array_elements(j_data)
    LOOP
      t_response := t_response || t_body_row_begin;
      IF t_body_row_link IS NOT NULL THEN
        t_button_link := replace(t_body_row_link, '#PATH#', t_detailview_path);
        t_button_link := replace(t_button_link, '#UNIQUE_ID#', v_unique_id);
        t_button_link := replace(t_button_link, '#UNIQUE_ID_VALUE#', (j_row->>v_unique_id)::text);
        t_response := t_response || t_button_link;
      END IF;

        FOREACH r_report_column IN ARRAY r_report_columns
        LOOP
          IF r_report_column.view_column_name IS NOT NULL THEN
            t_cell_content := COALESCE(j_row->>r_report_column.view_column_name, '');
            IF r_report_column.is_text_escaped THEN
              t_cell_content := pgapex.f_app_html_special_chars(t_cell_content);
            END IF;
            t_response := t_response || replace(t_body_row_cell, '#CELL_CONTENT#', t_cell_content);
          ELSE
            FOR r_column IN SELECT * FROM json_each_text(j_row)
            LOOP
              r_report_column.link_text := replace(r_report_column.link_text, '%' || r_column.key || '%', coalesce(r_column.value, ''));
              r_report_column.url := replace(r_report_column.url, '%' || r_column.key || '%', coalesce(r_column.value, ''));
            END LOOP;
            IF r_report_column.is_text_escaped THEN
              r_report_column.link_text := pgapex.f_app_html_special_chars(r_report_column.link_text);
            END IF;
            t_response := t_response || replace(t_body_row_cell, '#CELL_CONTENT#', '<a href="' || r_report_column.url || '" ' || COALESCE(r_report_column.attributes, '') || '>' || r_report_column.link_text || '</a>');
          END IF;
        END LOOP;
      t_response := t_response || t_body_row_end;
    END LOOP;
  END IF;

  t_response := t_response || t_body_end || t_report_end;

  v_url_prefix := pgapex.f_app_get_setting('application_root') || '/app/' || pgapex.f_app_get_setting('application_id') || '/' ||
    pgapex.f_app_get_setting('page_id') || '?' || v_pagination_query_param || '=';

  IF i_page_count > 1 THEN
    t_pagination := t_pagination_begin;

    IF i_current_page > 1 THEN
      t_pagination := t_pagination || replace(t_previous_page, '#LINK#', v_url_prefix || 1);
    END IF;

    FOR p in 1 .. i_page_count
    LOOP
      IF p = i_current_page THEN
        t_pagination := t_pagination || replace(replace(t_active_page, '#LINK#', v_url_prefix || p), '#NUMBER#', p::varchar);
      ELSE
        t_pagination := t_pagination || replace(replace(t_inactive_page, '#LINK#', v_url_prefix || p), '#NUMBER#', p::varchar);
      END IF;
    END LOOP;

    IF i_current_page < i_page_count THEN
      t_pagination := t_pagination || replace(t_next_page, '#LINK#', v_url_prefix || i_page_count);
    END IF;

    t_pagination := t_pagination || t_pagination_end;
  END IF;

  RETURN replace(t_response, '#PAGINATION#', t_pagination);
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_create_entity_page_path(
  i_create_entity_page_id INT
)
  RETURNS TEXT AS $$
DECLARE
  i_application_id  INT;
  t_url             TEXT;
BEGIN
  SELECT p.application_id
  INTO i_application_id
  FROM pgapex.page p
  WHERE p.page_id = i_create_entity_page_id;

  t_url := '../' || i_application_id::text || '/' || i_create_entity_page_id::text;
  RETURN t_url;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;


----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_report_region(
    i_region_id  INT
  , j_get_params JSONB
)
  RETURNS TEXT AS $$
DECLARE
  t_region_template               TEXT;
  v_schema_name                   VARCHAR;
  v_view_name                     VARCHAR;
  i_items_per_page                INT;
  b_show_header                   BOOLEAN;
  b_include_create_entity_button  BOOLEAN;
  v_create_entity_button_label    VARCHAR;
  i_create_entity_page_id         INT; 
  i_form_page_id                  INT;
  v_pagination_query_param        VARCHAR;
  i_current_page                  INT      := 1;
  i_row_count                     INT;
  i_page_count                    INT;
  i_offset                        INT      := 0;
  j_rows                          JSON;
  v_query                         VARCHAR;
BEGIN
  SELECT rr.schema_name, rr.view_name, rr.items_per_page, rr.show_header, pi.name, rr.include_create_entity_button, rr.create_entity_button_label, rr.create_entity_page_id, rr.form_page_id
  INTO v_schema_name, v_view_name, i_items_per_page, b_show_header, v_pagination_query_param, b_include_create_entity_button, v_create_entity_button_label, i_create_entity_page_id, i_form_page_id
  FROM pgapex.report_region rr
  LEFT JOIN pgapex.page_item pi ON rr.region_id = pi.region_id
  WHERE rr.region_id = i_region_id;

  IF j_get_params IS NOT NULL AND j_get_params ? v_pagination_query_param THEN
    i_current_page := (j_get_params->>v_pagination_query_param)::INT;
  END IF;

  i_row_count := pgapex.f_app_get_row_count(v_schema_name, v_view_name);
  i_page_count := ceil(i_row_count::float/i_items_per_page::float);

  IF (i_page_count < i_current_page) OR (i_current_page < 1) THEN
    i_current_page := 1;
  END IF;

  i_offset := (i_current_page - 1) * i_items_per_page;

  v_query := 'SELECT json_agg(a) FROM (SELECT * FROM ' || v_schema_name || '.' || v_view_name || ' LIMIT ' || i_items_per_page || ' OFFSET ' || i_offset || ') AS a';

  SELECT res_rows INTO j_rows FROM dblink(pgapex.f_app_get_dblink_connection_name(), v_query, FALSE) AS ( res_rows JSON );

  RETURN pgapex.f_app_get_report_region_with_template(i_region_id, j_rows, v_pagination_query_param, i_page_count, i_current_page, b_show_header, b_include_create_entity_button, v_create_entity_button_label, i_create_entity_page_id, i_form_page_id);
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_form_region(
  i_region_id    INT
, j_get_params JSONB
)
  RETURNS TEXT AS $$
DECLARE
  t_region_template              TEXT;
  i_form_pre_fill_id             INT;
  v_button_label                 VARCHAR;
  t_form_begin_template          TEXT;
  t_form_end_template            TEXT;
  t_row_begin_template           TEXT;
  t_row_end_template             TEXT;
  t_row_template                 TEXT;
  t_mandatory_row_begin_template TEXT;
  t_mandatory_row_end_template   TEXT;
  t_mandatory_row_template       TEXT;
  t_help_text_block_template     TEXT;
  t_button_template              TEXT;
  v_pre_fill_schema              VARCHAR;
  v_pre_fill_view                VARCHAR;
  r_form_row                     RECORD;
  t_current_row_begin_template   TEXT     := '';
  t_current_row_end_template     TEXT     := '';
  t_current_row_template         TEXT     := '';
  t_form_element                 TEXT     := '';
  j_lov_rows                     JSON;
  v_query                        VARCHAR;
  t_option                       TEXT;
  t_options                      TEXT;
  t_pre_fill_url_params          TEXT[];
  j_pre_fetched_values           JSONB   := '{}';
  j_option                       JSON;
  t_subregions                   TEXT;
  t_textarea_height_property     TEXT     := '';
  t_textarea_rows_attribute      TEXT     := '';
  t_calender_background_property TEXT     := '';
BEGIN
  SELECT fr.form_pre_fill_id, fr.button_label, ft.form_begin, ft.form_end, ft.row_begin, ft.row_end, ft.row,
         ft.mandatory_row_begin, ft.mandatory_row_end, ft.mandatory_row, ft.help_text_block, bt.template, fpf.schema_name, fpf.view_name
  INTO i_form_pre_fill_id, v_button_label, t_form_begin_template, t_form_end_template, t_row_begin_template, t_row_end_template, t_row_template,
       t_mandatory_row_begin_template, t_mandatory_row_end_template, t_mandatory_row_template, t_help_text_block_template, t_button_template, v_pre_fill_schema, v_pre_fill_view
  FROM pgapex.form_region fr
  LEFT JOIN pgapex.form_template ft ON ft.template_id = fr.template_id
  LEFT JOIN pgapex.button_template bt ON bt.template_id = fr.button_template_id
  LEFT JOIN pgapex.form_pre_fill fpf ON fpf.form_pre_fill_id = fr.form_pre_fill_id
  WHERE fr.region_id = i_region_id;

  IF i_form_pre_fill_id IS NOT NULL THEN
    SELECT ARRAY( SELECT pi.name
    FROM pgapex.fetch_row_condition frc
    RIGHT JOIN pgapex.page_item pi ON pi.page_item_id = frc.url_parameter_id
    WHERE frc.form_pre_fill_id = i_form_pre_fill_id) INTO t_pre_fill_url_params;

    /*IF (j_get_params ?& t_pre_fill_url_params) = FALSE THEN
      PERFORM pgapex.f_app_add_error_message('All url params must exist to prefetch form data: ' || array_to_string(t_pre_fill_url_params, ', '));
      RETURN '';
    END IF;*/

    IF (j_get_params ?& t_pre_fill_url_params) <> FALSE THEN
      SELECT string_agg(params.param, ' AND ') INTO v_query
      FROM ( SELECT (frc.view_column_name || '=' || quote_nullable(url_params.value)) param
            FROM pgapex.fetch_row_condition frc
            LEFT JOIN pgapex.page_item pi ON pi.page_item_id = frc.url_parameter_id
            LEFT JOIN (SELECT key, value FROM json_each_text(j_get_params::json)) url_params ON url_params.key = pi.name
            WHERE frc.form_pre_fill_id = i_form_pre_fill_id
          ) params;

      v_query := 'SELECT to_json(a) FROM ' || v_pre_fill_schema || '.' || v_pre_fill_view || ' a WHERE ' || v_query || ' LIMIT 1';
      SELECT res_pre_fetch_values INTO j_pre_fetched_values FROM dblink(pgapex.f_app_get_dblink_connection_name(), v_query, FALSE) AS ( res_pre_fetch_values JSONB );
    END IF;
  
  END IF;

  t_button_template := replace(replace(t_button_template, '#NAME#', 'PGAPEX_BUTTON'), '#LABEL#', v_button_label);

  t_region_template := replace(t_form_begin_template, '#SUBMIT_BUTTON#', t_button_template);
  t_region_template := t_region_template || '<input type="hidden" name="PGAPEX_REGION" value="' || i_region_id || '">';

  FOR r_form_row IN (
    SELECT
      ff.field_type_id, ff.label, ff.is_mandatory, ff.is_visible, ff.is_read_only, ff.wysiwyg_editor, ff.default_value, ff.help_text, ff.field_pre_fill_view_column_name,
      pi.name AS form_element_name, lov.schema_name, lov.view_name, lov.label_view_column_name, lov.value_view_column_name,
      it.template AS input_template, tt.template AS textarea_template, tt.wysiwyg_editor_script,
      ddt.drop_down_begin, ddt.drop_down_end, ddt.option_begin, ddt.option_end,
      cbt.combo_box_begin, cbt.combo_box_end, cbt.option_begin AS combo_box_option_begin, cbt.option_end AS combo_box_option_end, cbt.combo_box_script,
      ct.calender_input, ct.calender_script, cf.calender_format, ffs.width, ffs.width_unit, ffs.height, ffs.height_unit, wes.menu_bar, wes.status_bar, wes.browser_spellcheck
    FROM pgapex.form_field ff
      LEFT JOIN pgapex.list_of_values lov ON lov.list_of_values_id = ff.list_of_values_id
      LEFT JOIN pgapex.page_item pi ON pi.form_field_id = ff.form_field_id
      LEFT JOIN pgapex.input_template it ON it.template_id = ff.input_template_id
      LEFT JOIN pgapex.drop_down_template ddt ON ddt.template_id = ff.drop_down_template_id
      LEFT JOIN pgapex.textarea_template tt ON tt.template_id = ff.textarea_template_id
      LEFT JOIN pgapex.combo_box_template cbt ON cbt.template_id = ff.combo_box_template_id
      LEFT JOIN pgapex.calender_template ct ON ct.template_id = ff.calender_template_id
      LEFT JOIN pgapex.calender_format cf ON cf.form_field_id = ff.form_field_id
      LEFT JOIN pgapex.form_field_size ffs ON ffs.form_field_id = ff.form_field_id
      LEFT JOIN pgapex.wysiwyg_editor_settings wes ON wes.form_field_id = ff.form_field_id
    WHERE ff.region_id = i_region_id
    ORDER BY ff.sequence ASC
  )
  LOOP
    t_form_element := '';
    r_form_row.default_value := pgapex.f_app_replace_system_variables(r_form_row.default_value);

    IF r_form_row.field_pre_fill_view_column_name IS NOT NULL AND j_pre_fetched_values ? r_form_row.field_pre_fill_view_column_name THEN
      r_form_row.default_value := j_pre_fetched_values->>r_form_row.field_pre_fill_view_column_name;
    END IF;

    IF r_form_row.is_visible THEN
      IF r_form_row.is_mandatory THEN
        t_current_row_begin_template := t_mandatory_row_begin_template;
        t_current_row_end_template := t_mandatory_row_end_template;
        t_current_row_template := t_mandatory_row_template;
      ELSE
        t_current_row_begin_template := t_row_begin_template;
        t_current_row_end_template := t_row_end_template;
        t_current_row_template := t_row_template;
      END IF;
      t_region_template := t_region_template || t_current_row_begin_template;

      IF r_form_row.field_type_id IN ('TEXT', 'PASSWORD', 'CHECKBOX') THEN
        t_form_element := r_form_row.input_template;
        IF (r_form_row.field_type_id = 'CHECKBOX') THEN
          IF r_form_row.default_value IS NOT NULL THEN
            t_form_element := replace(t_form_element, '#CHECKED#', ' checked="checked" ');
            t_form_element := replace(t_form_element, '#VALUE#', r_form_row.default_value);
          ELSE
            t_form_element := replace(t_form_element, '#CHECKED#', '');
            t_form_element := replace(t_form_element, '#VALUE#', 'TRUE');
          END IF;
        ELSE 
          t_form_element := replace(t_form_element, '#VALUE#', pgapex.f_app_html_special_chars(coalesce(r_form_row.default_value, '')));
        END IF;

      ELSIF r_form_row.field_type_id = 'RADIO' THEN
        v_query := 'SELECT json_build_object(''value'', ' || r_form_row.value_view_column_name || ', ''label'', ' || r_form_row.label_view_column_name || ') ' ||
                   ' FROM '  || r_form_row.schema_name || '.' || r_form_row.view_name;
        t_options := r_form_row.input_template;
        t_options = replace(t_options, '#VALUE#', '');
        t_options = replace(t_options, '#INPUT_LABEL#', '- NULL -');
        FOR j_option IN (SELECT res_options FROM dblink(pgapex.f_app_get_dblink_connection_name(), v_query, FALSE) AS ( res_options JSON ))
        LOOP
          t_option := r_form_row.input_template;
          t_option := replace(t_option, '#VALUE#', pgapex.f_app_html_special_chars(j_option->>'value'));
          t_option := replace(t_option, '#INPUT_LABEL#', pgapex.f_app_html_special_chars(j_option->>'label'));
          IF j_option->>'value' = r_form_row.default_value THEN
            t_option := replace(t_option, '#CHECKED#', ' checked="checked" ');
          END IF;
          t_option := replace(t_option, '#CHECKED#', '');
          t_options := t_options || t_option;
        END LOOP;
        t_form_element := t_form_element || t_options;

      ELSIF r_form_row.field_type_id = 'TEXTAREA' THEN
        t_form_element := r_form_row.textarea_template;
        t_form_element := replace(t_form_element, '#VALUE#', pgapex.f_app_html_special_chars(coalesce(r_form_row.default_value, '')));
        IF r_form_row.wysiwyg_editor = TRUE THEN
          t_form_element := t_form_element || r_form_row.wysiwyg_editor_script;
          t_form_element := replace(t_form_element, '#MENU_BAR#', r_form_row.menu_bar::TEXT);
          t_form_element := replace(t_form_element, '#STATUS_BAR#', r_form_row.status_bar::TEXT);
          t_form_element := replace(t_form_element, '#BROWSER_SPELL_CHECK#', r_form_row.browser_spellcheck::TEXT);
        END IF;
        IF r_form_row.height_unit = 'rows' THEN
          t_textarea_rows_attribute := coalesce(r_form_row.height_unit || '="' || r_form_row.height || '"', '');
        ELSE
          t_textarea_height_property := r_form_row.height || r_form_row.height_unit;
          IF r_form_row.wysiwyg_editor = FALSE THEN
            t_textarea_height_property := 'height: ' || t_textarea_height_property;
          END IF;
        END IF;
        t_form_element := replace(t_form_element, '#HEIGHT_PROPERTY#', coalesce(t_textarea_height_property, ''));
        t_form_element := replace(t_form_element, '#ROWS#', t_textarea_rows_attribute);

      ELSIF r_form_row.field_type_id = 'DROP_DOWN' THEN
        t_form_element := r_form_row.drop_down_begin;
        v_query := 'SELECT json_build_object(''value'', ' || r_form_row.value_view_column_name || ', ''label'', ' || r_form_row.label_view_column_name || ') ' ||
                   ' FROM '  || r_form_row.schema_name || '.' || r_form_row.view_name;
        t_options := '<option value="">- NULL -</option>';
        FOR j_option IN (SELECT res_options FROM dblink(pgapex.f_app_get_dblink_connection_name(), v_query, FALSE) AS ( res_options JSON ))
        LOOP
          t_option := r_form_row.option_begin;
          t_option := replace(t_option, '#VALUE#', pgapex.f_app_html_special_chars(j_option->>'value'));
          IF j_option->>'value' = r_form_row.default_value THEN
            t_option := replace(t_option, '#SELECTED#', ' selected="selected" ');
          END IF;
          t_option := replace(t_option, '#SELECTED#', '');
          t_option := t_option || pgapex.f_app_html_special_chars(j_option->>'label') || r_form_row.option_end;
          t_options := t_options || t_option;
        END LOOP;

        t_form_element := t_form_element || t_options;
        t_form_element := t_form_element || r_form_row.drop_down_end;
      ELSIF r_form_row.field_type_id = 'COMBO_BOX' THEN
        t_form_element := r_form_row.combo_box_begin;
        v_query := 'SELECT json_build_object(''value'', ' || r_form_row.value_view_column_name || ', ''label'', ' || r_form_row.label_view_column_name || ') ' ||
                   ' FROM '  || r_form_row.schema_name || '.' || r_form_row.view_name;
        t_options := '<option value="">- NULL -</option>';
        FOR j_option IN (SELECT res_options FROM dblink(pgapex.f_app_get_dblink_connection_name(), v_query, FALSE) AS ( res_options JSON ))
        LOOP
          t_option := r_form_row.combo_box_option_begin;
          t_option := replace(t_option, '#VALUE#', pgapex.f_app_html_special_chars(j_option->>'value'));
          IF j_option->>'value' = r_form_row.default_value THEN
            t_option := replace(t_option, '#SELECTED#', ' selected="selected" ');
          END IF;
          t_option := replace(t_option, '#SELECTED#', '');
          t_option := t_option || pgapex.f_app_html_special_chars(j_option->>'label') || r_form_row.combo_box_option_end;
          t_options := t_options || t_option;
        END LOOP;

        t_form_element := t_form_element || t_options;
        t_form_element := t_form_element || r_form_row.combo_box_end;
        IF r_form_row.is_read_only = FALSE THEN
          t_form_element := t_form_element || r_form_row.combo_box_script;
        END IF;
      ELSIF r_form_row.field_type_id = 'CALENDER' THEN
        t_form_element := r_form_row.calender_input;
        t_form_element := replace(t_form_element, '#VALUE#', pgapex.f_app_html_special_chars(coalesce(r_form_row.default_value, '')));
        IF r_form_row.is_read_only = FALSE THEN
          t_form_element := t_form_element || r_form_row.calender_script;
          t_calender_background_property := 'background: white';
        END IF;
        t_form_element := replace(t_form_element, '#BACKGROUND_PROPERTY#', t_calender_background_property);
        t_form_element := replace(t_form_element, '#CALENDER_FORMAT#', quote_literal(r_form_row.calender_format));
      END IF;
    ELSE
      t_current_row_begin_template := '';
      t_current_row_end_template := '';
      t_current_row_template := '#FORM_ELEMENT#';
      t_form_element := '<input type="hidden" name="#NAME#" value="#VALUE#">';
      t_form_element :=  replace(t_form_element, '#VALUE#', pgapex.f_app_html_special_chars(coalesce(r_form_row.default_value, '')));
    END IF;

    t_form_element := replace(t_form_element, '#NAME#',      pgapex.f_app_html_special_chars(r_form_row.form_element_name));
    t_form_element := replace(t_form_element, '#ROW_LABEL#', pgapex.f_app_html_special_chars(r_form_row.label));
    t_form_element := replace(t_form_element, '#WIDTH#', coalesce(r_form_row.width::TEXT, '100'));
    t_form_element := replace(t_form_element, '#WIDTH_UNIT#', coalesce(r_form_row.width_unit::TEXT, '%'));
    IF r_form_row.is_visible = TRUE AND r_form_row.help_text IS NOT NULL THEN
      t_form_element := t_form_element || t_help_text_block_template;
    END IF;
    IF r_form_row.is_read_only = TRUE THEN
      t_form_element := replace(t_form_element, '#READ_ONLY#', 'readonly');
    ELSE
      t_form_element := replace(t_form_element, '#READ_ONLY#', '');
    END IF;

    t_current_row_template := replace(t_current_row_template, '#FORM_ELEMENT#', t_form_element);
    t_current_row_template := replace(t_current_row_template, '#HELP_TEXT#',    coalesce(r_form_row.help_text, ''));
    t_current_row_template := replace(t_current_row_template, '#LABEL#',        r_form_row.label);
    t_region_template := t_region_template || t_current_row_template;
    t_region_template := t_region_template || t_current_row_end_template;
  END LOOP;
  SELECT pgapex.f_app_get_subregions(i_region_id, NULL, NULL, j_get_params) INTO t_subregions;
  t_region_template := t_region_template || replace(t_form_end_template, '#SUBMIT_BUTTON#', t_button_template);
  t_region_template := t_region_template || t_subregions;

  RETURN t_region_template;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_form_subregion(
  i_subregion_id      INT
, j_get_params        JSONB
)
  RETURNS TEXT AS $$
DECLARE
  t_region_template              TEXT;
  i_form_pre_fill_id             INT;
  v_button_label                 VARCHAR;
  t_form_begin_template          TEXT;
  t_form_end_template            TEXT;
  t_row_begin_template           TEXT;
  t_row_end_template             TEXT;
  t_row_template                 TEXT;
  t_mandatory_row_begin_template TEXT;
  t_mandatory_row_end_template   TEXT;
  t_mandatory_row_template       TEXT;
  t_help_text_block_template     TEXT;
  t_button_template              TEXT;
  v_pre_fill_schema              VARCHAR;
  v_pre_fill_view                VARCHAR;
  r_form_row                     RECORD;
  t_current_row_begin_template   TEXT     := '';
  t_current_row_end_template     TEXT     := '';
  t_current_row_template         TEXT     := '';
  t_form_element                 TEXT     := '';
  j_lov_rows                     JSON;
  v_query                        VARCHAR;
  t_option                       TEXT;
  t_options                      TEXT;
  t_pre_fill_url_params          TEXT[];
  j_pre_fetched_values           JSONB   := '{}';
  j_option                       JSON;
  t_textarea_height_property     TEXT     := '';
  t_textarea_rows_attribute      TEXT     := '';
  t_calender_background_property TEXT     := '';
BEGIN
  SELECT pfr.form_pre_fill_id, fr.button_label, ft.form_begin, ft.form_end, ft.row_begin, ft.row_end, ft.row,
         ft.mandatory_row_begin, ft.mandatory_row_end, ft.mandatory_row, ft.help_text_block, bt.template, fpf.schema_name, fpf.view_name
  INTO i_form_pre_fill_id, v_button_label, t_form_begin_template, t_form_end_template, t_row_begin_template, t_row_end_template, t_row_template,
       t_mandatory_row_begin_template, t_mandatory_row_end_template, t_mandatory_row_template, t_help_text_block_template, t_button_template, v_pre_fill_schema, v_pre_fill_view
  FROM pgapex.form_region fr
  LEFT JOIN pgapex.form_template ft ON ft.template_id = fr.template_id
  LEFT JOIN pgapex.button_template bt ON bt.template_id = fr.button_template_id
  LEFT JOIN pgapex.subregion sr ON sr.subregion_id = fr.subregion_id
  LEFT JOIN pgapex.form_region pfr ON pfr.region_id = sr.parent_region_id
  LEFT JOIN pgapex.form_pre_fill fpf ON fpf.form_pre_fill_id = pfr.form_pre_fill_id
  WHERE fr.subregion_id = i_subregion_id;

  IF i_form_pre_fill_id IS NOT NULL THEN
    SELECT ARRAY( SELECT pi.name
    FROM pgapex.fetch_row_condition frc
    RIGHT JOIN pgapex.page_item pi ON pi.page_item_id = frc.url_parameter_id
    WHERE frc.form_pre_fill_id = i_form_pre_fill_id) INTO t_pre_fill_url_params;

    /*IF (j_get_params ?& t_pre_fill_url_params) = FALSE THEN
      PERFORM pgapex.f_app_add_error_message('All url params must exist to prefetch form data: ' || array_to_string(t_pre_fill_url_params, ', '));
      RETURN '';
    END IF;*/

    IF (j_get_params ?& t_pre_fill_url_params) <> FALSE THEN
      SELECT string_agg(params.param, ' AND ') INTO v_query
      FROM ( SELECT (frc.view_column_name || '=' || quote_nullable(url_params.value)) param
            FROM pgapex.fetch_row_condition frc
            LEFT JOIN pgapex.page_item pi ON pi.page_item_id = frc.url_parameter_id
            LEFT JOIN (SELECT key, value FROM json_each_text(j_get_params::json)) url_params ON url_params.key = pi.name
            WHERE frc.form_pre_fill_id = i_form_pre_fill_id
          ) params;
    END IF;

    v_query := 'SELECT to_json(a) FROM ' || v_pre_fill_schema || '.' || v_pre_fill_view || ' a WHERE ' || v_query || ' LIMIT 1';
    SELECT res_pre_fetch_values INTO j_pre_fetched_values FROM dblink(pgapex.f_app_get_dblink_connection_name(), v_query, FALSE) AS ( res_pre_fetch_values JSONB );

  END IF;

  t_button_template := replace(replace(t_button_template, '#NAME#', 'PGAPEX_BUTTON'), '#LABEL#', v_button_label);

  t_region_template := replace(t_form_begin_template, '#SUBMIT_BUTTON#', t_button_template);
  t_region_template := t_region_template || '<input type="hidden" name="PGAPEX_SUBFORM" value="' || i_subregion_id || '">';

  FOR r_form_row IN (
    SELECT
      ff.field_type_id, ff.label, ff.is_mandatory, ff.is_visible, ff.is_read_only, ff.wysiwyg_editor, ff.default_value, ff.help_text, ff.field_pre_fill_view_column_name,
      pi.name AS form_element_name, lov.schema_name, lov.view_name, lov.label_view_column_name, lov.value_view_column_name,
      it.template AS input_template, tt.template AS textarea_template, tt.wysiwyg_editor_script,
      ddt.drop_down_begin, ddt.drop_down_end, ddt.option_begin, ddt.option_end,
      cbt.combo_box_begin, cbt.combo_box_end, cbt.option_begin AS combo_box_option_begin, cbt.option_end AS combo_box_option_end, cbt.combo_box_script,
      ct.calender_input, ct.calender_script, cf.calender_format, ffs.width, ffs.width_unit, ffs.height, ffs.height_unit, wes.menu_bar, wes.status_bar, wes.browser_spellcheck
    FROM pgapex.form_field ff
      LEFT JOIN pgapex.list_of_values lov ON lov.list_of_values_id = ff.list_of_values_id
      LEFT JOIN pgapex.page_item pi ON pi.form_field_id = ff.form_field_id
      LEFT JOIN pgapex.input_template it ON it.template_id = ff.input_template_id
      LEFT JOIN pgapex.drop_down_template ddt ON ddt.template_id = ff.drop_down_template_id
      LEFT JOIN pgapex.textarea_template tt ON tt.template_id = ff.textarea_template_id
      LEFT JOIN pgapex.combo_box_template cbt ON cbt.template_id = ff.combo_box_template_id
      LEFT JOIN pgapex.calender_template ct ON ct.template_id = ff.calender_template_id
      LEFT JOIN pgapex.calender_format cf ON cf.form_field_id = ff.form_field_id
      LEFT JOIN pgapex.form_field_size ffs ON ffs.form_field_id = ff.form_field_id
      LEFT JOIN pgapex.wysiwyg_editor_settings wes ON wes.form_field_id = ff.form_field_id
    WHERE ff.subregion_id = i_subregion_id
    ORDER BY ff.sequence ASC
  )
  LOOP
    t_form_element := '';
    r_form_row.default_value := pgapex.f_app_replace_system_variables(r_form_row.default_value);

    IF r_form_row.field_pre_fill_view_column_name IS NOT NULL AND j_pre_fetched_values ? r_form_row.field_pre_fill_view_column_name THEN
      r_form_row.default_value := j_pre_fetched_values->>r_form_row.field_pre_fill_view_column_name;
    END IF;

    IF r_form_row.is_visible THEN
      IF r_form_row.is_mandatory THEN
        t_current_row_begin_template := t_mandatory_row_begin_template;
        t_current_row_end_template := t_mandatory_row_end_template;
        t_current_row_template := t_mandatory_row_template;
      ELSE
        t_current_row_begin_template := t_row_begin_template;
        t_current_row_end_template := t_row_end_template;
        t_current_row_template := t_row_template;
      END IF;
      t_region_template := t_region_template || t_current_row_begin_template;

      IF r_form_row.field_type_id IN ('TEXT', 'PASSWORD', 'CHECKBOX') THEN
        t_form_element := r_form_row.input_template;
        IF (r_form_row.field_type_id = 'CHECKBOX') THEN
          IF r_form_row.default_value IS NOT NULL THEN
            t_form_element := replace(t_form_element, '#CHECKED#', ' checked="checked" ');
            t_form_element := replace(t_form_element, '#VALUE#', r_form_row.default_value);
          ELSE
            t_form_element := replace(t_form_element, '#CHECKED#', '');
            t_form_element := replace(t_form_element, '#VALUE#', 'TRUE');
          END IF;
        ELSE 
          t_form_element := replace(t_form_element, '#VALUE#', pgapex.f_app_html_special_chars(coalesce(r_form_row.default_value, '')));
        END IF;

      ELSIF r_form_row.field_type_id = 'RADIO' THEN
        v_query := 'SELECT json_build_object(''value'', ' || r_form_row.value_view_column_name || ', ''label'', ' || r_form_row.label_view_column_name || ') ' ||
                   ' FROM '  || r_form_row.schema_name || '.' || r_form_row.view_name;
        t_options := r_form_row.input_template;
        t_options = replace(t_options, '#VALUE#', '');
        t_options = replace(t_options, '#INPUT_LABEL#', '- NULL -');
        FOR j_option IN (SELECT res_options FROM dblink(pgapex.f_app_get_dblink_connection_name(), v_query, FALSE) AS ( res_options JSON ))
        LOOP
          t_option := r_form_row.input_template;
          t_option := replace(t_option, '#VALUE#', pgapex.f_app_html_special_chars(j_option->>'value'));
          t_option := replace(t_option, '#INPUT_LABEL#', pgapex.f_app_html_special_chars(j_option->>'label'));
          IF j_option->>'value' = r_form_row.default_value THEN
            t_option := replace(t_option, '#CHECKED#', ' checked="checked" ');
          END IF;
          t_option := replace(t_option, '#CHECKED#', '');
          t_options := t_options || t_option;
        END LOOP;
        t_form_element := t_form_element || t_options;

      ELSIF r_form_row.field_type_id = 'TEXTAREA' THEN
        t_form_element := r_form_row.textarea_template;
        t_form_element := replace(t_form_element, '#VALUE#', pgapex.f_app_html_special_chars(coalesce(r_form_row.default_value, '')));
        IF r_form_row.wysiwyg_editor = TRUE THEN
          t_form_element := t_form_element || r_form_row.wysiwyg_editor_script;
          t_form_element := replace(t_form_element, '#MENU_BAR#', r_form_row.menu_bar::TEXT);
          t_form_element := replace(t_form_element, '#STATUS_BAR#', r_form_row.status_bar::TEXT);
          t_form_element := replace(t_form_element, '#BROWSER_SPELL_CHECK#', r_form_row.browser_spellcheck::TEXT);
        END IF;
        IF r_form_row.height_unit = 'rows' THEN
          t_textarea_rows_attribute := coalesce(r_form_row.height_unit || '="' || r_form_row.height || '"', '');
        ELSE
          t_textarea_height_property := r_form_row.height || r_form_row.height_unit;
          IF r_form_row.wysiwyg_editor = FALSE THEN
            t_textarea_height_property := 'height: ' || t_textarea_height_property;
          END IF;
        END IF;
        t_form_element := replace(t_form_element, '#HEIGHT_PROPERTY#', coalesce(t_textarea_height_property, ''));
        t_form_element := replace(t_form_element, '#ROWS#', t_textarea_rows_attribute);

      ELSIF r_form_row.field_type_id = 'DROP_DOWN' THEN
        t_form_element := r_form_row.drop_down_begin;
        v_query := 'SELECT json_build_object(''value'', ' || r_form_row.value_view_column_name || ', ''label'', ' || r_form_row.label_view_column_name || ') ' ||
                   ' FROM '  || r_form_row.schema_name || '.' || r_form_row.view_name;
        t_options := '<option value="">- NULL -</option>';
        FOR j_option IN (SELECT res_options FROM dblink(pgapex.f_app_get_dblink_connection_name(), v_query, FALSE) AS ( res_options JSON ))
        LOOP
          t_option := r_form_row.option_begin;
          t_option := replace(t_option, '#VALUE#', pgapex.f_app_html_special_chars(j_option->>'value'));
          IF j_option->>'value' = r_form_row.default_value THEN
            t_option := replace(t_option, '#SELECTED#', ' selected="selected" ');
          END IF;
          t_option := replace(t_option, '#SELECTED#', '');
          t_option := t_option || pgapex.f_app_html_special_chars(j_option->>'label') || r_form_row.option_end;
          t_options := t_options || t_option;
        END LOOP;

        t_form_element := t_form_element || t_options;
        t_form_element := t_form_element || r_form_row.drop_down_end;
      ELSIF r_form_row.field_type_id = 'COMBO_BOX' THEN
        t_form_element := r_form_row.combo_box_begin;
        v_query := 'SELECT json_build_object(''value'', ' || r_form_row.value_view_column_name || ', ''label'', ' || r_form_row.label_view_column_name || ') ' ||
                   ' FROM '  || r_form_row.schema_name || '.' || r_form_row.view_name;
        t_options := '<option value="">- NULL -</option>';
        FOR j_option IN (SELECT res_options FROM dblink(pgapex.f_app_get_dblink_connection_name(), v_query, FALSE) AS ( res_options JSON ))
        LOOP
          t_option := r_form_row.combo_box_option_begin;
          t_option := replace(t_option, '#VALUE#', pgapex.f_app_html_special_chars(j_option->>'value'));
          IF j_option->>'value' = r_form_row.default_value THEN
            t_option := replace(t_option, '#SELECTED#', ' selected="selected" ');
          END IF;
          t_option := replace(t_option, '#SELECTED#', '');
          t_option := t_option || pgapex.f_app_html_special_chars(j_option->>'label') || r_form_row.combo_box_option_end;
          t_options := t_options || t_option;
        END LOOP;

        t_form_element := t_form_element || t_options;
        t_form_element := t_form_element || r_form_row.combo_box_end;
        IF r_form_row.is_read_only = FALSE THEN
          t_form_element := t_form_element || r_form_row.combo_box_script;
        END IF;
      ELSIF r_form_row.field_type_id = 'CALENDER' THEN
        t_form_element := r_form_row.calender_input;
        t_form_element := replace(t_form_element, '#VALUE#', pgapex.f_app_html_special_chars(coalesce(r_form_row.default_value, '')));
        IF r_form_row.is_read_only = FALSE THEN
          t_form_element := t_form_element || r_form_row.calender_script;
          t_calender_background_property := 'background: white';
        END IF;
        t_form_element := replace(t_form_element, '#BACKGROUND_PROPERTY#', t_calender_background_property);
        t_form_element := replace(t_form_element, '#CALENDER_FORMAT#', quote_literal(r_form_row.calender_format));
      END IF;
    ELSE
      t_current_row_begin_template := '';
      t_current_row_end_template := '';
      t_current_row_template := '#FORM_ELEMENT#';
      t_form_element := '<input type="hidden" name="#NAME#" value="#VALUE#">';
      t_form_element :=  replace(t_form_element, '#VALUE#', pgapex.f_app_html_special_chars(coalesce(r_form_row.default_value, '')));
    END IF;

    t_form_element := replace(t_form_element, '#NAME#',      pgapex.f_app_html_special_chars(r_form_row.form_element_name));
    t_form_element := replace(t_form_element, '#ROW_LABEL#', pgapex.f_app_html_special_chars(r_form_row.label));
    t_form_element := replace(t_form_element, '#WIDTH#', coalesce(r_form_row.width::TEXT, '100'));
    t_form_element := replace(t_form_element, '#WIDTH_UNIT#', coalesce(r_form_row.width_unit::TEXT, '%'));
    IF r_form_row.is_visible = TRUE AND r_form_row.help_text IS NOT NULL THEN
      t_form_element := t_form_element || t_help_text_block_template;
    END IF;
    IF r_form_row.is_read_only = TRUE THEN
      t_form_element := replace(t_form_element, '#READ_ONLY#', 'readonly');
    ELSE
      t_form_element := replace(t_form_element, '#READ_ONLY#', '');
    END IF;
    
    t_current_row_template := replace(t_current_row_template, '#FORM_ELEMENT#', t_form_element);
    t_current_row_template := replace(t_current_row_template, '#HELP_TEXT#',    coalesce(r_form_row.help_text, ''));
    t_current_row_template := replace(t_current_row_template, '#LABEL#',        r_form_row.label);
    t_region_template := t_region_template || t_current_row_template;
    t_region_template := t_region_template || t_current_row_end_template;
  END LOOP;
  t_region_template := t_region_template || replace(t_form_end_template, '#SUBMIT_BUTTON#', t_button_template);

  RETURN t_region_template;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_tabularform_region_with_template(
  i_region_id               INT
, j_data                    JSON
, v_pagination_query_param  VARCHAR
, i_page_count              INT
, i_current_page            INT
, b_show_header             BOOLEAN
)
  RETURNS TEXT AS $$
DECLARE
  t_response                TEXT;
  t_pagination              TEXT     := '';
  v_url_prefix              VARCHAR;
  t_tabularform_begin       TEXT;
  t_tabularform_end         TEXT;
  t_form_begin              TEXT;
  t_buttons_row_begin       TEXT;
  t_buttons_row_content     TEXT;
  t_buttons_row_end         TEXT;
  t_table_begin             TEXT;
  t_table_header_begin      TEXT;
  t_table_header_row_begin  TEXT;
  t_table_header_checkbox   TEXT;
  t_table_header_cell       TEXT;
  t_table_header_row_end    TEXT;
  t_table_header_end        TEXT;
  t_table_body_begin        TEXT;
  t_table_body_row_begin    TEXT;
  t_table_body_row_checkbox TEXT;
  t_table_body_row_cell     TEXT;
  t_table_body_row_end      TEXT;
  t_table_body_end          TEXT;
  t_table_end               TEXT;
  t_form_end                TEXT;
  t_pagination_begin        TEXT;
  t_pagination_end          TEXT;
  t_previous_page           TEXT;
  t_next_page               TEXT;
  t_active_page             TEXT;
  t_inactive_page           TEXT;
  t_unique_id               TEXT;
  t_xmin_view_column        TEXT;
  r_tabularform_column      pgapex.t_tabularform_column_with_link;
  r_tabularform_columns     pgapex.t_tabularform_column_with_link[];
  r_tabularform_button      pgapex.t_tabularform_button;
  r_tabularform_buttons     pgapex.t_tabularform_button[];
  t_button                  TEXT;
  t_body_checkbox           TEXT;
  j_row                     JSON;
  r_column                  RECORD;
  t_cell_content            TEXT;
BEGIN
  SELECT tft.tabularform_begin, tft.tabularform_end, tft.form_begin, tft.buttons_row_begin, tft.buttons_row_content,
         tft.buttons_row_end, tft.table_begin, tft.table_header_begin, tft.table_header_row_begin,
         tft.table_header_checkbox, tft.table_header_cell, tft.table_header_row_end, tft.table_header_end,
         tft.table_body_begin, tft.table_body_row_begin, tft.table_body_row_checkbox, tft.table_body_row_cell,
         tft.table_body_row_end, tft.table_body_end, tft.table_end, tft.form_end, tft.pagination_begin,
         tft.pagination_end, tft.previous_page, tft.next_page, tft.active_page, tft.inactive_page, tfr.unique_id, tfr.xmin_view_column
  INTO t_tabularform_begin, t_tabularform_end, t_form_begin, t_buttons_row_begin, t_buttons_row_content,
         t_buttons_row_end, t_table_begin, t_table_header_begin, t_table_header_row_begin,
         t_table_header_checkbox, t_table_header_cell, t_table_header_row_end, t_table_header_end,
         t_table_body_begin, t_table_body_row_begin, t_table_body_row_checkbox, t_table_body_row_cell,
         t_table_body_row_end, t_table_body_end, t_table_end, t_form_end, t_pagination_begin,
         t_pagination_end, t_previous_page, t_next_page, t_active_page, t_inactive_page, t_unique_id, t_xmin_view_column
  FROM pgapex.tabularform_region tfr
  LEFT JOIN pgapex.tabularform_template tft ON tft.template_id = tfr.template_id
  WHERE tfr.region_id = i_region_id;

  SELECT ARRAY(
      SELECT ROW(tfc.view_column_name, tfc.heading, tfc.sequence, tfc.is_text_escaped, tfcl.url, tfcl.link_text, tfcl.attributes)
      FROM pgapex.tabularform_column tfc
      LEFT JOIN pgapex.tabularform_column_link tfcl ON tfcl.tabularform_column_id = tfc.tabularform_column_id
      WHERE tfc.region_id = i_region_id
      ORDER BY tfc.sequence
  ) INTO r_tabularform_columns;

  SELECT ARRAY(
      SELECT ROW(tff.tabularform_function_id::text, tff.button_label, tfbt.template)
      FROM pgapex.tabularform_function tff
	    INNER JOIN pgapex.tabularform_button_template tfbt ON tff.button_template_id=tfbt.template_id
	    WHERE tff.region_id = i_region_id
	    ORDER BY tff.sequence
  ) INTO r_tabularform_buttons;

  t_form_begin := replace(t_form_begin, '#TABULARFORM_FUNCTION_ID#', i_region_id::text);

  t_response := t_tabularform_begin || t_form_begin || t_buttons_row_begin;

  FOREACH r_tabularform_button IN ARRAY r_tabularform_buttons
    LOOP
      t_button := r_tabularform_button.template;
      t_button := replace(t_button, '#VALUE#', r_tabularform_button.tabularform_function_id);
      t_button := replace(t_button, '#LABEL#', r_tabularform_button.button_label);
      t_response := t_response || t_button;
  END LOOP;

  t_response := t_response || t_buttons_row_end || t_table_begin;

  IF b_show_header THEN
    t_response := t_response || t_table_header_begin || t_table_header_row_begin || t_table_header_checkbox;

    FOREACH r_tabularform_column IN ARRAY r_tabularform_columns
    LOOP
      t_response := t_response || replace(t_table_header_cell, '#CELL_CONTENT#', r_tabularform_column.heading);
    END LOOP;

    t_response := t_response || t_table_header_row_end || t_table_header_end;
  END IF;

  t_response := t_response || t_table_body_begin;

  IF j_data IS NOT NULL THEN
    FOR j_row IN SELECT * FROM json_array_elements(j_data)
    LOOP
      t_body_checkbox := t_table_body_row_checkbox;
      t_body_checkbox := replace(t_body_checkbox, '#UNIQUE_ID_VALUE#', (j_row->>t_unique_id)::text);
      t_body_checkbox := replace(t_body_checkbox, '#XMIN_VALUE#', coalesce((j_row->>t_xmin_view_column)::text, ''));

      t_response := t_response || t_table_body_row_begin || t_body_checkbox;
        FOREACH r_tabularform_column IN ARRAY r_tabularform_columns
        LOOP
          IF r_tabularform_column.view_column_name IS NOT NULL THEN
            t_cell_content := COALESCE(j_row->>r_tabularform_column.view_column_name, '');
            IF r_tabularform_column.is_text_escaped THEN
              t_cell_content := pgapex.f_app_html_special_chars(t_cell_content);
            END IF;
            t_response := t_response || replace(t_table_body_row_cell, '#CELL_CONTENT#', t_cell_content);
          ELSE
            FOR r_column IN SELECT * FROM json_each_text(j_row)
            LOOP
              r_tabularform_column.link_text := replace(r_tabularform_column.link_text, '%' || r_column.key || '%', coalesce(r_column.value, ''));
              r_tabularform_column.url := replace(r_tabularform_column.url, '%' || r_column.key || '%', coalesce(r_column.value, ''));
            END LOOP;
            IF r_tabularform_column.is_text_escaped THEN
              r_tabularform_column.link_text := pgapex.f_app_html_special_chars(r_tabularform_column.link_text);
            END IF;
            t_response := t_response || replace(t_table_body_row_cell, '#CELL_CONTENT#', '<a href="' || r_tabularform_column.url || '" ' || COALESCE(r_tabularform_column.attributes, '') || '>' || r_tabularform_column.link_text || '</a>');
          END IF;
        END LOOP;
      t_response := t_response || t_table_body_row_end;
    END LOOP;
  END IF;

  t_response := t_response || t_table_body_end || t_table_end|| t_form_end || t_tabularform_end;

  v_url_prefix := pgapex.f_app_get_setting('application_root') || '/app/' || pgapex.f_app_get_setting('application_id') || '/' || pgapex.f_app_get_setting('page_id') || '?' || v_pagination_query_param || '=';

  IF i_page_count > 1 THEN
    t_pagination := t_pagination_begin;

    IF i_current_page > 1 THEN
      t_pagination := t_pagination || replace(t_previous_page, '#LINK#', v_url_prefix || 1);
    END IF;

    FOR p in 1 .. i_page_count
    LOOP
      IF p = i_current_page THEN
        t_pagination := t_pagination || replace(replace(t_active_page, '#LINK#', v_url_prefix || p), '#NUMBER#', p::varchar);
      ELSE
        t_pagination := t_pagination || replace(replace(t_inactive_page, '#LINK#', v_url_prefix || p), '#NUMBER#', p::varchar);
      END IF;
    END LOOP;

    IF i_current_page < i_page_count THEN
      t_pagination := t_pagination || replace(t_next_page, '#LINK#', v_url_prefix || i_page_count);
    END IF;

    t_pagination := t_pagination || t_pagination_end;
  END IF;

  RETURN replace(t_response, '#PAGINATION#', t_pagination);
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_tabularform_region(
    i_region_id  INT
  , j_get_params JSONB
)
  RETURNS TEXT AS $$
DECLARE
  t_region_template         TEXT;
  v_schema_name             VARCHAR;
  v_view_name               VARCHAR;
  i_items_per_page          INT;
  b_show_header             BOOLEAN;
  v_pagination_query_param  VARCHAR;
  i_current_page            INT      := 1;
  i_row_count               INT;
  i_page_count              INT;
  i_offset                  INT      := 0;
  j_rows                    JSON;
  v_query                   VARCHAR;
BEGIN
  SELECT tfr.schema_name, tfr.view_name, tfr.items_per_page, tfr.show_header, pi.name
  INTO v_schema_name, v_view_name, i_items_per_page, b_show_header, v_pagination_query_param
  FROM pgapex.tabularform_region tfr
  LEFT JOIN pgapex.page_item pi ON tfr.region_id = pi.tabularform_region_id
  WHERE tfr.region_id = i_region_id;

  IF j_get_params IS NOT NULL AND j_get_params ? v_pagination_query_param THEN
    i_current_page := (j_get_params->>v_pagination_query_param)::INT;
  END IF;

  i_row_count := pgapex.f_app_get_row_count(v_schema_name, v_view_name);
  i_page_count := ceil(i_row_count::float/i_items_per_page::float);

  IF (i_page_count < i_current_page) OR (i_current_page < 1) THEN
    i_current_page := 1;
  END IF;

  i_offset := (i_current_page - 1) * i_items_per_page;

  v_query := 'SELECT json_agg(a) FROM (SELECT * FROM ' || v_schema_name || '.' || v_view_name || ' LIMIT ' || i_items_per_page || ' OFFSET ' || i_offset || ') AS a';

  SELECT res_rows INTO j_rows FROM dblink(pgapex.f_app_get_dblink_connection_name(), v_query, FALSE) AS ( res_rows JSON );

  RETURN pgapex.f_app_get_tabularform_region_with_template(i_region_id, j_rows, v_pagination_query_param, i_page_count, i_current_page, b_show_header);
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_report_subregion(
    i_subregion_id            INT
  , v_parent_region_unique_id VARCHAR
  , v_argument                VARCHAR
  , v_pagination_query_param  VARCHAR
  , j_get_params              JSONB
)
  RETURNS TEXT AS $$
DECLARE
  t_region_template        TEXT;
  v_schema_name            VARCHAR;
  v_view_name              VARCHAR;
  i_items_per_page         INT;
  b_show_header            BOOLEAN;
  v_unique_id              VARCHAR;
  i_current_page           INT      := 1;
  i_row_count              INT;
  i_page_count             INT;
  i_offset                 INT      := 0;
  j_rows                   JSON;
  v_additional_parameters  VARCHAR;
  v_query                  VARCHAR;
BEGIN
  SELECT rr.schema_name, rr.view_name, rr.items_per_page, rr.show_header, rr.unique_id
  INTO v_schema_name, v_view_name, i_items_per_page, b_show_header, v_unique_id
  FROM pgapex.report_region rr
  WHERE rr.subregion_id = i_subregion_id;

  IF j_get_params IS NOT NULL AND j_get_params ? v_pagination_query_param THEN
    i_current_page := (j_get_params->>v_pagination_query_param)::INT;
  END IF;

  i_row_count := pgapex.f_app_get_row_count_by_param(v_schema_name, v_view_name, v_unique_id, v_argument);
  i_page_count := ceil(i_row_count::float/i_items_per_page::float);

  IF (i_page_count < i_current_page) OR (i_current_page < 1) THEN
    i_current_page := 1;
  END IF;

  i_offset := (i_current_page - 1) * i_items_per_page;

  v_query := 'SELECT json_agg(a) FROM (SELECT * FROM ' || v_schema_name || '.' || v_view_name
  || ' WHERE ' || v_unique_id || '=' || quote_literal(v_argument) || ' LIMIT ' || i_items_per_page || ' OFFSET ' || i_offset || ') AS a';

  SELECT res_rows INTO j_rows FROM dblink(pgapex.f_app_get_dblink_connection_name(), v_query, FALSE) AS ( res_rows JSON );

  v_additional_parameters := v_parent_region_unique_id || '=' || v_argument || '&';

  RETURN pgapex.f_app_get_report_subregion_with_template(i_subregion_id, j_rows, v_additional_parameters, v_pagination_query_param, i_page_count, i_current_page, b_show_header);
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_subregions(
    i_parent_region_id        INT
  , v_parent_region_unique_id VARCHAR
  , v_argument                VARCHAR
  , j_get_params              JSONB
)
  RETURNS TEXT AS $$
DECLARE
  r_subregion           RECORD;
  t_subregion_content   TEXT;
  t_subregion_template  TEXT;
  t_response            TEXT  := '';
BEGIN
  FOR r_subregion IN (SELECT * FROM pgapex.f_app_get_parent_region_subregions(i_parent_region_id))
    LOOP
        SELECT template INTO t_subregion_template FROM pgapex.subregion_template WHERE template_id = r_subregion.template_id;

        IF r_subregion.subregion_type = 'REPORT' THEN
          SELECT pgapex.f_app_get_report_subregion(r_subregion.subregion_id, v_parent_region_unique_id, v_argument,
          r_subregion.query_parameter, j_get_params) INTO t_subregion_content;
        ELSIF r_subregion.subregion_type = 'FORM' THEN
          SELECT pgapex.f_app_get_form_subregion(r_subregion.subregion_id, j_get_params) INTO t_subregion_content;
        ELSIF r_subregion.subregion_type = 'TABULAR_SUBFORM' THEN
          SELECT pgapex.f_app_get_tabularform_subregion(r_subregion.subregion_id, j_get_params) INTO t_subregion_content;
        END IF;

        t_subregion_template := replace(t_subregion_template, '#SUBREGION_TITLE#', r_subregion.name);
        t_response := t_response || replace(t_subregion_template, '#SUBREGION_BODY#', t_subregion_content);
    END LOOP;

  RETURN t_response;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_detail_view_with_template(
    i_region_id   INT
  , j_row         JSON
)
  RETURNS TEXT AS $$
DECLARE
  t_detailview_begin    TEXT;
  t_detailview_end      TEXT;
  t_column_heading      TEXT;
  t_column_content      TEXT;
  t_response            TEXT;
  r_detailview_column   pgapex.t_column_with_link;
  r_detailview_columns  pgapex.t_column_with_link[];
  t_heading             TEXT;
  t_content             TEXT;
  r_column              RECORD;
BEGIN
  SELECT dvt.detailview_begin, dvt.detailview_end, dvt.column_heading, dvt.column_content
  INTO t_detailview_begin, t_detailview_end, t_column_heading, t_column_content
  FROM pgapex.detailview_region dvr
  LEFT JOIN pgapex.detailview_template dvt ON dvr.template_id = dvt.template_id
  WHERE dvr.region_id = i_region_id;

  SELECT ARRAY (
	  SELECT ROW(dvc.view_column_name, dvc.heading, dvc.sequence, dvc.is_text_escaped, dvcl.url, dvcl.link_text, dvcl.attributes)
	  FROM pgapex.detailview_column dvc
	  LEFT JOIN pgapex.detailview_column_link dvcl ON dvc.detailview_column_id = dvcl.detailview_column_id
	  WHERE dvc.region_id = i_region_id
	  ORDER BY dvc.sequence
  ) INTO r_detailview_columns;

  t_response := t_detailview_begin;

  IF j_row IS NOT NULL THEN
    FOREACH r_detailview_column IN ARRAY r_detailview_columns
      LOOP
        IF r_detailview_column.view_column_name IS NOT NULL THEN
          t_heading := r_detailview_column.heading;
          t_content := COALESCE(j_row->>r_detailview_column.view_column_name, '');

          t_response := t_response || replace(t_column_heading, '#COLUMN_HEADING#', t_heading);
          t_response := t_response || replace(t_column_content, '#COLUMN_CONTENT#', t_content);
        ELSE
          FOR r_column IN SELECT * FROM json_each_text(j_row)
            LOOP
              r_detailview_column.link_text := replace(r_detailview_column.link_text, '%' || r_column.key || '%', coalesce(r_column.value, ''));
              r_detailview_column.url := replace(r_detailview_column.url, '%' || r_column.key || '%', coalesce(r_column.value, ''));
            END LOOP;
            IF r_detailview_column.is_text_escaped THEN
              r_detailview_column.link_text := pgapex.f_app_html_special_chars(r_detailview_column.link_text);
            END IF;
            t_heading := r_detailview_column.heading;

            t_response := t_response || replace(t_column_heading, '#COLUMN_HEADING#', t_heading);
            t_response := t_response || replace(t_column_content, '#COLUMN_CONTENT#', '<a href="' ||
              r_detailview_column.url || '" ' || COALESCE(r_detailview_column.attributes, '') || '>' || r_detailview_column.link_text || '</a>');
        END IF;
      END LOOP;
  END IF;

  t_response := t_response || t_detailview_end;

  RETURN t_response;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_detail_view(
    i_region_id  INT
  , j_get_params JSONB
)
  RETURNS TEXT AS $$
DECLARE
  v_schema_name       VARCHAR;
  v_view_name         VARCHAR;
  v_unique_id         VARCHAR;
  v_page_query_param  VARCHAR;
  v_query             VARCHAR;
  v_argument          VARCHAR;
  t_negative_response TEXT;
  j_row               JSONB;
  t_detailview        TEXT;
  t_subregions        TEXT;
  t_response          TEXT;
BEGIN
  SELECT dvr.schema_name, dvr.view_name, dvr.unique_id
  INTO v_schema_name, v_view_name, v_unique_id
  FROM pgapex.detailview_region dvr
  WHERE dvr.region_id = i_region_id;

  SELECT (j_get_params->>v_unique_id)::varchar INTO v_argument;

  IF (v_argument = '') IS FALSE THEN
    v_query := 'SELECT json_agg(a) FROM (SELECT * FROM ' || v_schema_name || '.' || v_view_name || ' WHERE ' ||
      v_unique_id || ' = ' || quote_literal(v_argument) || ' LIMIT 1) AS a';
  ELSE
    v_query := 'SELECT json_agg(a) FROM (SELECT * FROM ' || v_schema_name || '.' || v_view_name || ' LIMIT 1) AS a';
  END IF;

  SELECT res_rows INTO j_row FROM dblink(pgapex.f_app_get_dblink_connection_name(), v_query, FALSE) AS (res_rows JSON);

  IF j_row IS NOT NULL THEN
    SELECT pgapex.f_app_get_detail_view_with_template(i_region_id, (j_row->>0)::json) INTO t_detailview;
    SELECT pgapex.f_app_get_subregions(i_region_id, v_unique_id, (j_row->>0)::json->>v_unique_id, j_get_params) INTO t_subregions;

    t_response := t_detailview;
    t_response := t_response || t_subregions;

    RETURN t_response;
  ELSE
    t_negative_response := '<h4></span>Row not found</h4>';
    t_negative_response := t_negative_response || '<h5>View <b>' || v_schema_name || '.' || v_view_name ||
      '</b> has not row, where <b>' || v_unique_id || '</b> is <b>' || v_argument || '</b></h5>';

    RETURN t_negative_response;
  END IF;
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_tabularform_subregion(
    i_subregion_id  INT
  , j_get_params JSONB
)
  RETURNS TEXT AS $$
DECLARE
  t_region_template         TEXT;
  v_schema_name             VARCHAR;
  v_view_name               VARCHAR;
  i_current_page            INT      := 1;
  i_row_count               INT;
  i_page_count              INT;
  i_offset                  INT      := 0;
  j_rows                    JSON;
  v_query                   VARCHAR;
  
BEGIN
  SELECT tfsr.schema_name, tfsr.view_name
  INTO v_schema_name, v_view_name
  FROM pgapex.tabularform_subregion tfsr
    LEFT JOIN pgapex.subregion sr ON tfsr.subregion_id = sr.subregion_id
  WHERE tfsr.subregion_id = i_subregion_id;

  IF (json_typeof(j_get_params::json) = 'object') THEN
    SELECT string_agg(params.param, ' AND ') INTO v_query
    FROM ( SELECT (tsflc.tabular_subform_view_column_name || '=' || quote_nullable(url_params.value)) param
          FROM pgapex.tabular_subform_linked_column tsflc
          INNER JOIN (SELECT key, value FROM json_each_text(j_get_params::json)) url_params ON url_params.key = tsflc.parent_form_prefill_column_name
        ) params;
  END IF;

  v_query := 'SELECT json_agg(a) FROM (SELECT * FROM ' || v_schema_name || '.' || v_view_name || ' WHERE ' || v_query || ') AS a';

  SELECT res_rows INTO j_rows FROM dblink(pgapex.f_app_get_dblink_connection_name(), v_query, FALSE) AS ( res_rows JSON );

  RETURN pgapex.f_app_get_tabularform_subregion_with_template(i_subregion_id, j_rows);
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;

----------

CREATE OR REPLACE FUNCTION pgapex.f_app_get_tabularform_subregion_with_template(
  i_subregion_id            INT
, j_data                    JSON
)
  RETURNS TEXT AS $$
DECLARE
  t_response                  TEXT;
  v_url_prefix                VARCHAR;
  t_tabularform_begin         TEXT;
  t_tabularform_end           TEXT;
  t_form_begin                TEXT;
  t_buttons_row_begin         TEXT;
  t_buttons_row_content       TEXT;
  t_buttons_row_end           TEXT;
  t_table_begin               TEXT;
  t_table_header_begin        TEXT;
  t_table_header_row_begin    TEXT;
  t_table_header_checkbox     TEXT;
  t_table_header_page_link    TEXT := '';
  t_table_header_cell         TEXT;
  t_table_header_row_end      TEXT;
  t_table_header_end          TEXT;
  t_table_body_begin          TEXT;
  t_table_body_row_begin      TEXT;
  t_table_body_row_checkbox   TEXT;
  t_table_body_row_page_link  TEXT;
  t_table_body_row_cell       TEXT;
  t_table_body_row_end        TEXT;
  t_table_body_end            TEXT;
  t_table_end                 TEXT;
  t_form_end                  TEXT;
  t_unique_id                 TEXT;
  r_tabularform_column        pgapex.t_tabularform_column_with_link;
  r_tabularform_columns       pgapex.t_tabularform_column_with_link[];
  r_tabularform_button        pgapex.t_tabular_subform_button;
  r_tabularform_buttons       pgapex.t_tabular_subform_button[];
  t_button                    TEXT;
  t_body_checkbox             TEXT;
  t_body_page_link            TEXT := ''; 
  j_row                       JSON;
  r_column                    RECORD;
  t_cell_content              TEXT;
  t_input_value               JSON;
  t_input_value_text          TEXT;
  b_include_linked_page       BOOLEAN;
  i_linked_page_id            INT;
  v_linked_page_unique_id     TEXT;
BEGIN
  SELECT tsft.tabular_subform_begin, tsft.tabular_subform_end, tsft.form_begin, tsft.buttons_row_begin, tsft.buttons_row_content,
         tsft.buttons_row_end, tsft.table_begin, tsft.table_header_begin, tsft.table_header_row_begin,
         tsft.table_header_checkbox, tsft.table_header_cell, tsft.table_header_row_end, tsft.table_header_end,
         tsft.table_body_begin, tsft.table_body_row_begin, tsft.table_body_row_checkbox, tsft.table_body_row_page_link, tsft.table_body_row_cell,
         tsft.table_body_row_end, tsft.table_body_end, tsft.table_end, tsft.form_end,
         tfsr.include_linked_page, tfsr.linked_page_id, tfsr.linked_page_unique_id
  INTO t_tabularform_begin, t_tabularform_end, t_form_begin, t_buttons_row_begin, t_buttons_row_content,
         t_buttons_row_end, t_table_begin, t_table_header_begin, t_table_header_row_begin,
         t_table_header_checkbox, t_table_header_cell, t_table_header_row_end, t_table_header_end,
         t_table_body_begin, t_table_body_row_begin, t_table_body_row_checkbox, t_table_body_row_page_link, t_table_body_row_cell,
         t_table_body_row_end, t_table_body_end, t_table_end, t_form_end,
         b_include_linked_page, i_linked_page_id, v_linked_page_unique_id
         
  FROM pgapex.tabularform_subregion tfsr
  LEFT JOIN pgapex.tabular_subform_template tsft ON tsft.template_id = tfsr.template_id
  WHERE tfsr.subregion_id = i_subregion_id;

  SELECT ARRAY(
      SELECT ROW(tfc.view_column_name, tfc.heading, tfc.sequence, tfc.is_text_escaped, tfcl.url, tfcl.link_text, tfcl.attributes)
      FROM pgapex.tabularform_column tfc
      LEFT JOIN pgapex.tabularform_column_link tfcl ON tfcl.tabularform_column_id = tfc.tabularform_column_id
      WHERE tfc.subregion_id = i_subregion_id
      ORDER BY tfc.sequence
  ) INTO r_tabularform_columns;

  SELECT ARRAY(
      SELECT ROW(tsff.tabular_subform_function_id::text, tsff.button_label, tfbt.template)
      FROM pgapex.tabular_subform_function tsff
	    INNER JOIN pgapex.tabularform_button_template tfbt ON tsff.button_template_id=tfbt.template_id
	    WHERE tsff.subregion_id = i_subregion_id
	    ORDER BY tsff.sequence
  ) INTO r_tabularform_buttons;

  t_form_begin := replace(t_form_begin, '#TABULAR_SUBFORM_FUNCTION_ID#', i_subregion_id::text);

  t_response := t_tabularform_begin || t_form_begin || t_buttons_row_begin;

  FOREACH r_tabularform_button IN ARRAY r_tabularform_buttons
    LOOP
      t_button := r_tabularform_button.template;
      t_button := replace(t_button, '#VALUE#', r_tabularform_button.tabular_subform_function_id);
      t_button := replace(t_button, '#LABEL#', r_tabularform_button.button_label);
      t_response := t_response || t_button;
  END LOOP;

  t_response := t_response || t_buttons_row_end || t_table_begin;

  IF b_include_linked_page THEN
    t_table_header_page_link := '<th class="cell--fit-content"></th>';
  END IF;

  t_response := t_response || t_table_header_begin || t_table_header_row_begin || t_table_header_checkbox || t_table_header_page_link;

  FOREACH r_tabularform_column IN ARRAY r_tabularform_columns
  LOOP
    t_response := t_response || replace(t_table_header_cell, '#CELL_CONTENT#', r_tabularform_column.heading);
  END LOOP;

  t_response := t_response || t_table_header_row_end || t_table_header_end;

  t_response := t_response || t_table_body_begin;

  IF j_data IS NOT NULL THEN
    FOR j_row IN SELECT * FROM json_array_elements(j_data)
    LOOP
      t_body_checkbox := t_table_body_row_checkbox;

      IF b_include_linked_page THEN
        t_body_page_link := t_table_body_row_page_link;
        t_body_page_link := replace(t_body_page_link, '#PATH#', pgapex.f_app_get_page_path(i_linked_page_id));
        t_body_page_link := replace(t_body_page_link, '#UNIQUE_ID#', v_linked_page_unique_id);
        t_body_page_link := replace(t_body_page_link, '#UNIQUE_ID_VALUE#', j_row->>v_linked_page_unique_id);
      END IF;

      SELECT json_build_object(
          tsff.tabular_subform_function_id, (SELECT json_agg(
            json_build_object(
              'ordinal_position', tsffa.function_parameter_ordinal_position,
              'value', j_row->>tsffa.tabular_subform_view_column_name
            )
            )
            FROM pgapex.tabular_subform_function_argument tsffa
            WHERE tsffa.tabular_subform_function_id = tsff.tabular_subform_function_id
            )
      )
      INTO t_input_value
      FROM pgapex.tabular_subform_function tsff
      WHERE tsff.subregion_id = i_subregion_id;

      t_input_value_text := replace(t_input_value::text, '"', '''');
      t_body_checkbox := replace(t_body_checkbox, '#FUNCTION_PARAMETERS_VALUE#', t_input_value_text);


      t_response := t_response || t_table_body_row_begin || t_body_checkbox || t_body_page_link;
        FOREACH r_tabularform_column IN ARRAY r_tabularform_columns
        LOOP
          IF r_tabularform_column.view_column_name IS NOT NULL THEN
            t_cell_content := COALESCE(j_row->>r_tabularform_column.view_column_name, '');
            IF r_tabularform_column.is_text_escaped THEN
              t_cell_content := pgapex.f_app_html_special_chars(t_cell_content);
            END IF;
            t_response := t_response || replace(t_table_body_row_cell, '#CELL_CONTENT#', t_cell_content);
          ELSE
            FOR r_column IN SELECT * FROM json_each_text(j_row)
            LOOP
              r_tabularform_column.link_text := replace(r_tabularform_column.link_text, '%' || r_column.key || '%', coalesce(r_column.value, ''));
              r_tabularform_column.url := replace(r_tabularform_column.url, '%' || r_column.key || '%', coalesce(r_column.value, ''));
            END LOOP;
            IF r_tabularform_column.is_text_escaped THEN
              r_tabularform_column.link_text := pgapex.f_app_html_special_chars(r_tabularform_column.link_text);
            END IF;
            t_response := t_response || replace(t_table_body_row_cell, '#CELL_CONTENT#', '<a href="' || r_tabularform_column.url || '" ' || COALESCE(r_tabularform_column.attributes, '') || '>' || r_tabularform_column.link_text || '</a>');
          END IF;
        END LOOP;
      t_response := t_response || t_table_body_row_end;
    END LOOP;
  END IF;

  t_response := t_response || t_table_body_end || t_table_end|| t_form_end || t_tabularform_end;

  v_url_prefix := pgapex.f_app_get_setting('application_root') || '/app/' || pgapex.f_app_get_setting('application_id') || '/' || pgapex.f_app_get_setting('page_id');

  RETURN replace(t_response, '#PAGINATION#', '');
END
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pgapex, public, pg_temp;
