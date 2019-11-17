CREATE TABLE pgapex.report_column (
	report_column_ID SERIAL NOT NULL,
	report_column_type_ID VARCHAR ( 30 ) NOT NULL,
	region_ID INTEGER,
	subregion_ID INTEGER,
	view_column_name VARCHAR ( 64 ),
	heading VARCHAR ( 60 ) NOT NULL,
	sequence INTEGER NOT NULL,
	is_text_escaped BOOLEAN DEFAULT TRUE NOT NULL,
	CONSTRAINT pk_report_column PRIMARY KEY (report_column_ID),
	CONSTRAINT chk_report_column_sequence_must_be_not_negative CHECK (sequence >= 0)
	);
CREATE INDEX idx_report_column_view_column_name ON pgapex.report_column (view_column_name );
CREATE INDEX idx_report_column_report_column_type_id ON pgapex.report_column (report_column_type_ID );
CREATE INDEX idx_report_column_region_id ON pgapex.report_column (region_ID );
CREATE INDEX idx_report_column_subregion_id ON pgapex.report_column (subregion_ID );
CREATE TABLE pgapex.report_column_link (
	report_column_link_ID SERIAL NOT NULL,
	report_column_ID INTEGER NOT NULL,
	url VARCHAR ( 255 ) NOT NULL,
	link_text VARCHAR ( 60 ) NOT NULL,
	attributes VARCHAR ( 255 ),
	CONSTRAINT uq_report_column_link_report_column_id UNIQUE (report_column_ID),
	CONSTRAINT pk_report_column_link PRIMARY KEY (report_column_link_ID)
	);
CREATE TABLE pgapex.report_column_type (
	report_column_type_ID VARCHAR ( 30 ) NOT NULL,
	CONSTRAINT pk_report_column_type PRIMARY KEY (report_column_type_ID)
	);
CREATE TABLE pgapex.tabularform_column (
	tabularform_column_ID SERIAL NOT NULL,
	tabularform_column_type_ID VARCHAR ( 30 ) NOT NULL,
	region_ID INTEGER NOT NULL,
	view_column_name VARCHAR ( 64 ),
	heading VARCHAR ( 60 ) NOT NULL,
	sequence INTEGER NOT NULL,
	is_text_escaped BOOLEAN DEFAULT TRUE NOT NULL,
	CONSTRAINT pk_tabularform_column PRIMARY KEY (tabularform_column_ID),
	CONSTRAINT chk_tabularform_column_sequence_must_be_not_negative CHECK (sequence >= 0)
	);
CREATE INDEX idx_tabularform_column_view_column_name ON pgapex.tabularform_column (view_column_name );
CREATE INDEX idx_tabularform_column_tabularform_column_type_id ON pgapex.tabularform_column (tabularform_column_type_ID );
CREATE INDEX idx_tabularform_column_region_id ON pgapex.tabularform_column (region_ID );
CREATE TABLE pgapex.tabularform_column_link (
	tabularform_column_link_ID SERIAL NOT NULL,
	tabularform_column_ID INTEGER NOT NULL,
	url VARCHAR ( 255 ) NOT NULL,
	link_text VARCHAR ( 60 ) NOT NULL,
	attributes VARCHAR ( 255 ),
	CONSTRAINT uq_tabularform_column_link_tabularform_column_id UNIQUE (tabularform_column_ID),
	CONSTRAINT pk_tabularform_column_link PRIMARY KEY (tabularform_column_link_ID)
	);
CREATE TABLE pgapex.tabularform_column_type (
	tabularform_column_type_ID VARCHAR ( 30 ) NOT NULL,
	CONSTRAINT pk_tabularform_column_type PRIMARY KEY (tabularform_column_type_ID)
	);
CREATE TABLE pgapex.input_template_type (
	input_template_type_ID VARCHAR ( 10 ) NOT NULL,
	CONSTRAINT pk_input_template_type PRIMARY KEY (input_template_type_ID)
	);
CREATE TABLE pgapex.display_point (
	display_point_ID VARCHAR ( 30 ) NOT NULL,
	CONSTRAINT pk_display_point PRIMARY KEY (display_point_ID)
	);
CREATE TABLE pgapex.authentication_scheme (
	authentication_scheme_ID VARCHAR ( 30 ) NOT NULL,
	CONSTRAINT PK_authentication_scheme PRIMARY KEY (authentication_scheme_ID)
	);
CREATE TABLE pgapex.textarea_template (
	template_ID INTEGER NOT NULL,
	template TEXT NOT NULL,
	CONSTRAINT pk_textarea_template PRIMARY KEY (template_ID)
	);
CREATE TABLE pgapex.button_template (
	template_ID INTEGER NOT NULL,
	template TEXT NOT NULL,
	CONSTRAINT pk_button_template PRIMARY KEY (template_ID)
	);
CREATE TABLE pgapex.navigation (
	navigation_ID SERIAL NOT NULL,
	application_ID INTEGER NOT NULL,
	name VARCHAR ( 60 ) NOT NULL,
	CONSTRAINT pk_navigation PRIMARY KEY (navigation_ID),
	CONSTRAINT uq_navigation_application_id_name UNIQUE (application_ID, name),
	CONSTRAINT chk_navigation_name_must_be_longer_than_0 CHECK (length(trim(name))>0)
	);
CREATE TABLE pgapex.input_template (
	template_ID INTEGER NOT NULL,
	template TEXT NOT NULL,
	input_template_type_ID VARCHAR ( 10 ) NOT NULL,
	CONSTRAINT pk_input_template PRIMARY KEY (template_ID)
	);
CREATE INDEX idx_input_template_input_template_type_id ON pgapex.input_template (input_template_type_ID );
CREATE TABLE pgapex.page_template (
	template_ID INTEGER NOT NULL,
	page_type_ID VARCHAR ( 10 ) NOT NULL,
	header TEXT NOT NULL,
	body TEXT NOT NULL,
	footer TEXT NOT NULL,
	error_message TEXT NOT NULL,
	success_message TEXT NOT NULL,
	CONSTRAINT pk_page_template PRIMARY KEY (template_ID)
	);
CREATE INDEX idx_page_template_page_type_id ON pgapex.page_template (page_type_ID );
CREATE TABLE pgapex.function (
	name VARCHAR ( 255 ) NOT NULL,
	function_ID INTEGER NOT NULL,
	schema_ID INTEGER NOT NULL,
	data_type_ID INTEGER,
	CONSTRAINT PK_function116 PRIMARY KEY (function_ID)
	);
CREATE INDEX TC_function328 ON pgapex.function (schema_ID );
CREATE INDEX TC_function329 ON pgapex.function (data_type_ID );
CREATE TABLE pgapex.navigation_item (
	navigation_item_ID SERIAL NOT NULL,
	parent_navigation_item_ID INTEGER,
	navigation_ID INTEGER NOT NULL,
	page_ID INTEGER,
	name VARCHAR ( 60 ) NOT NULL,
	sequence INTEGER NOT NULL,
	url VARCHAR ( 255 ),
	CONSTRAINT pk_navigation_item PRIMARY KEY (navigation_item_ID),
	CONSTRAINT uq_navigation_item_navigation_id_page_id UNIQUE (navigation_ID, page_ID),
	CONSTRAINT chk_navigation_item_sequence_is_not_negative CHECK (sequence >= 0),
	CONSTRAINT chk_navigation_item_name_must_be_longer_than_0 CHECK (length(trim(name))>0),
	CONSTRAINT chk_navigation_item_can_not_refer_back_to_itself CHECK ((parent_navigation_item_id IS NULL) OR (parent_navigation_item_id <> navigation_item_id)),
	CONSTRAINT chk_navigation_item_must_refer_to_page_xor_url CHECK ((page_id IS NULL AND url IS NOT NULL) OR (page_id IS NOT NULL AND url IS NULL)),
	CONSTRAINT chk_navigation_item_url_must_be_longer_than_0 CHECK ((url IS NULL) OR (length(trim(url))>0))
	);
CREATE UNIQUE INDEX uq_navigation_item_sub_item_sequence ON pgapex.navigation_item (navigation_ID , parent_navigation_item_ID , sequence ) WHERE parent_navigation_item_ID IS NOT NULL;
CREATE INDEX idx_navigation_item_navigation_id ON pgapex.navigation_item (navigation_ID );
CREATE UNIQUE INDEX uq_navigation_item_root_item_sequence ON pgapex.navigation_item (navigation_ID , sequence ) WHERE parent_navigation_item_ID IS NULL;
CREATE INDEX idx_navigation_item_page_id ON pgapex.navigation_item (page_ID );
CREATE INDEX idx_navigation_item_parent_navigation_item_id ON pgapex.navigation_item (parent_navigation_item_ID );
CREATE TABLE pgapex.page_item (
	page_item_ID SERIAL NOT NULL,
	page_ID INTEGER NOT NULL,
	region_ID INTEGER,
	tabularform_region_ID INTEGER,
	form_field_ID INTEGER,
	name VARCHAR ( 60 ) NOT NULL,
	CONSTRAINT uq_page_item_page_id_name UNIQUE (page_ID, name),
	CONSTRAINT pk_page_item PRIMARY KEY (page_item_ID),
	CONSTRAINT uq_page_item_form_field_id_page_id UNIQUE (form_field_ID, page_ID),
	CONSTRAINT uq_page_item_region_id_page_id UNIQUE (region_ID, page_ID),
	CONSTRAINT chk_page_item_name_may_contain_alphabet_underscore_hypen CHECK (name~ '^[a-zA-Z_-]+$'),
	CONSTRAINT chk_page_item_must_refer_to_only_one_region CHECK (num_nonnulls(region_id, tabularform_region_id, form_field_ID) = 1),
	CONSTRAINT chk_page_item_name_is_not_empty CHECK (length(trim(name)) > 0)
	);
CREATE INDEX idx_page_item_page_id ON pgapex.page_item (page_ID );
CREATE TABLE pgapex.view_column (
	name VARCHAR ( 255 ) NOT NULL,
	column_ID INTEGER NOT NULL,
	data_type_ID INTEGER NOT NULL,
	view_ID INTEGER NOT NULL,
	CONSTRAINT PK_column120 PRIMARY KEY (column_ID)
	);
CREATE INDEX TC_column335 ON pgapex.view_column (data_type_ID );
CREATE INDEX TC_column334 ON pgapex.view_column (view_ID );
CREATE TABLE pgapex.view (
	name VARCHAR ( 255 ) NOT NULL,
	view_ID INTEGER NOT NULL,
	schema_ID INTEGER NOT NULL,
	CONSTRAINT PK_view119 PRIMARY KEY (view_ID)
	);
CREATE INDEX TC_view333 ON pgapex.view (schema_ID );
CREATE TABLE pgapex.navigation_template (
	template_ID INTEGER NOT NULL,
	navigation_begin TEXT NOT NULL,
	navigation_end TEXT NOT NULL,
	CONSTRAINT pk_navigation_template PRIMARY KEY (template_ID)
	);
CREATE TABLE pgapex.session (
	session_ID VARCHAR ( 128 ) NOT NULL,
	application_ID INTEGER NOT NULL,
	data JSONB NOT NULL,
	expiration_time TIMESTAMP NOT NULL,
	CONSTRAINT pk_session PRIMARY KEY (session_ID)
	);
CREATE INDEX idx_session_expiration_time ON pgapex.session (expiration_time );
CREATE INDEX idx_session_application_id ON pgapex.session (application_ID );
CREATE TABLE pgapex.application (
	application_ID SERIAL NOT NULL,
	authentication_scheme_ID VARCHAR ( 30 ) NOT NULL DEFAULT 'NO_AUTHENTICATION',
	login_page_template_ID INTEGER,
	database_name VARCHAR ( 64 ) NOT NULL,
	authentication_function_name VARCHAR ( 64 ),
	authentication_function_schema_name VARCHAR ( 64 ),
	name VARCHAR ( 60 ) NOT NULL,
	alias VARCHAR ( 30 ),
	database_username VARCHAR ( 64 ) NOT NULL,
	database_password VARCHAR ( 64 ) NOT NULL,
	CONSTRAINT uq_application_alias UNIQUE (alias),
	CONSTRAINT uq_application_name UNIQUE (name),
	CONSTRAINT pk_application PRIMARY KEY (application_ID),
	CONSTRAINT chk_application_authentication_scheme_requires_function CHECK ((authentication_scheme_id = 'NO_AUTHENTICATION' AND authentication_function_name IS NULL) OR (authentication_scheme_id <> 'NO_AUTHENTICATION' AND authentication_function_name IS NOT NULL)),
	CONSTRAINT chk_application_authentication_function_name_and_schema_coexist CHECK ((authentication_function_name IS NULL AND authentication_function_schema_name IS NULL) OR
(authentication_function_name IS NOT NULL AND authentication_function_schema_name IS NOT NULL)),
	CONSTRAINT chk_application_authentication_function_requires_login_template CHECK ((authentication_scheme_id = 'NO_AUTHENTICATION' AND login_page_template_id IS NULL) OR (authentication_scheme_id <> 'NO_AUTHENTICATION' AND login_page_template_id IS NOT NULL)),
	CONSTRAINT chk_application_alias_must_contain_char CHECK ((alias IS NULL) OR ((alias ~* '.*[a-z].*') AND (alias ~* '^\w*$')))
	);
CREATE INDEX idx_application_authentication_function_name ON pgapex.application (authentication_function_name );
CREATE INDEX idx_application_authentication_function_schema_name ON pgapex.application (authentication_function_schema_name );
CREATE INDEX idx_application_login_page_template_id ON pgapex.application (login_page_template_ID );
CREATE INDEX idx_application_authentication_scheme_id ON pgapex.application (authentication_scheme_ID );
CREATE TABLE pgapex.form_field (
	form_field_ID SERIAL NOT NULL,
	region_ID INTEGER NOT NULL,
	field_type_ID VARCHAR ( 10 ) NOT NULL,
	list_of_values_ID INTEGER,
	input_template_ID INTEGER,
	drop_down_template_ID INTEGER,
	textarea_template_ID INTEGER,
	field_pre_fill_view_column_name VARCHAR ( 64 ),
	label VARCHAR ( 255 ) NOT NULL,
	sequence INTEGER NOT NULL,
	is_mandatory BOOLEAN DEFAULT FALSE NOT NULL,
	is_visible BOOLEAN DEFAULT TRUE NOT NULL,
	default_value VARCHAR ( 60 ),
	help_text VARCHAR ( 255 ),
	function_parameter_type VARCHAR ( 64 ) NOT NULL,
	function_parameter_ordinal_position SMALLINT NOT NULL,
	CONSTRAINT pk_form_field PRIMARY KEY (form_field_ID),
	CONSTRAINT uq_form_field_list_of_values_id UNIQUE (list_of_values_ID),
	CONSTRAINT uq_form_field_region_id_fun_par_ordinal_position UNIQUE (region_ID, function_parameter_ordinal_position),
	CONSTRAINT chk_form_field_extarea_template_must_match_field_type CHECK ((textarea_template_id IS NOT NULL AND field_type_id = 'TEXTAREA') OR
(textarea_template_id IS NULL AND field_type_id <> 'TEXTAREA')),
	CONSTRAINT chk_form_field_only_one_template_can_be_chosen CHECK ((input_template_id IS NOT NULL AND textarea_template_id IS NULL AND drop_down_template_id IS NULL) OR
(input_template_id IS NULL AND textarea_template_id IS NOT NULL AND drop_down_template_id IS NULL) OR
(input_template_id IS NULL AND textarea_template_id IS NULL AND drop_down_template_id IS NOT NULL)),
	CONSTRAINT chk_form_field_input_template_must_match_field_type CHECK ((input_template_id IS NOT NULL AND field_type_id IN ('TEXT', 'PASSWORD', 'RADIO', 'CHECKBOX')) OR
(input_template_id IS NULL AND field_type_id NOT IN ('TEXT', 'PASSWORD', 'RADIO', 'CHECKBOX'))),
	CONSTRAINT chk_form_field_function_parameter_ordinal_position_is_gt_0 CHECK (function_parameter_ordinal_position > 0),
	CONSTRAINT chk_form_field_drop_down_template_must_match_field_type CHECK ((drop_down_template_id IS NOT NULL AND field_type_id = 'DROP_DOWN') OR
(drop_down_template_id IS NULL AND field_type_id <> 'DROP_DOWN')),
	CONSTRAINT chk_form_field_list_of_values_requires_specific_field_type CHECK ((list_of_values_id IS NULL AND field_type_id NOT IN ('DROP_DOWN', 'RADIO')) OR
(list_of_values_id IS NOT NULL AND field_type_id IN ('DROP_DOWN', 'RADIO'))),
	CONSTRAINT chk_form_field_sequence_must_be_not_negative CHECK (sequence >= 0)
	);
CREATE INDEX idx_form_field_field_type_id ON pgapex.form_field (field_type_ID );
CREATE INDEX idx_form_field_list_of_values_id ON pgapex.form_field (list_of_values_ID );
CREATE INDEX idx_form_field_textarea_template_id ON pgapex.form_field (textarea_template_ID );
CREATE INDEX idx_form_field_input_template_id ON pgapex.form_field (input_template_ID );
CREATE INDEX idx_form_field_drop_down_template_id ON pgapex.form_field (drop_down_template_ID );
CREATE TABLE pgapex.form_region (
	region_ID INTEGER NOT NULL,
	form_pre_fill_ID INTEGER,
	template_ID INTEGER NOT NULL,
	button_template_ID INTEGER NOT NULL,
	schema_name VARCHAR ( 64 ) NOT NULL,
	function_name VARCHAR ( 64 ) NOT NULL,
	button_label VARCHAR ( 255 ) NOT NULL,
	success_message VARCHAR ( 255 ),
	error_message VARCHAR ( 255 ),
	redirect_url VARCHAR ( 255 ),
	CONSTRAINT uq_form_region_form_pre_fill_id UNIQUE (form_pre_fill_ID),
	CONSTRAINT pk_form_region PRIMARY KEY (region_ID)
	);
CREATE INDEX idx_form_region_button_template_id ON pgapex.form_region (button_template_ID );
CREATE INDEX idx_form_region_template_id ON pgapex.form_region (template_ID );
CREATE INDEX idx_form_region_function_name ON pgapex.form_region (function_name );
CREATE INDEX idx_form_region_schema_name ON pgapex.form_region (schema_name );
CREATE TABLE pgapex.parameter (
	name VARCHAR ( 255 ) NOT NULL,
	ordinal_position INTEGER NOT NULL,
	parameter_ID INTEGER NOT NULL,
	function_ID INTEGER NOT NULL,
	data_type_ID INTEGER NOT NULL,
	CONSTRAINT PK_parameter117 PRIMARY KEY (parameter_ID)
	);
CREATE INDEX TC_parameter331 ON pgapex.parameter (data_type_ID );
CREATE INDEX TC_parameter330 ON pgapex.parameter (function_ID );
CREATE TABLE pgapex.drop_down_template (
	template_ID INTEGER NOT NULL,
	drop_down_begin TEXT NOT NULL,
	drop_down_end TEXT NOT NULL,
	option_begin TEXT NOT NULL,
	option_end TEXT NOT NULL,
	CONSTRAINT pk_drop_down_template PRIMARY KEY (template_ID)
	);
CREATE TABLE pgapex.page_type (
	page_type_ID VARCHAR ( 10 ) NOT NULL,
	CONSTRAINT pk_page_type PRIMARY KEY (page_type_ID)
	);
CREATE TABLE pgapex.report_region (
  	report_region_ID BIGSERIAL NOT NULL,
	region_ID INTEGER,
	subregion_ID INTEGER,
	template_ID INTEGER,
	link_template_ID INTEGER,
	schema_name VARCHAR ( 64 ) NOT NULL,
	view_name VARCHAR ( 64 ) NOT NULL,
	items_per_page INTEGER NOT NULL,
	show_header BOOLEAN DEFAULT TRUE NOT NULL,
	include_create_entity_button BOOLEAN DEFAULT FALSE NOT NULL,
	create_entity_button_label VARCHAR,
	create_entity_page_id INTEGER,
	form_page_id INTEGER,
	unique_id VARCHAR ( 64 ),
	CONSTRAINT pk_report_region PRIMARY KEY (report_region_ID),
	CONSTRAINT uq_report_region_region_id UNIQUE (region_ID),
	CONSTRAINT uq_report_region_subregion_id UNIQUE (subregion_ID),
	CONSTRAINT chk_report_region_cannot_be_region_and_subregion_same_time CHECK (num_nonnulls(region_ID, subregion_ID) = 1),
	CONSTRAINT chk_report_region_cannot_be_two_different_templates CHECK (num_nonnulls(template_ID, link_template_ID) = 1)
	);
CREATE INDEX idx_report_region_view_name ON pgapex.report_region (view_name );
CREATE INDEX idx_report_region_schema_name ON pgapex.report_region (schema_name );
CREATE INDEX idx_report_region_template_id ON pgapex.report_region (template_ID );
CREATE INDEX idx_report_region_link_template_id ON pgapex.report_region (link_template_ID );
CREATE TABLE pgapex.page_template_display_point (
	page_template_display_point_ID INTEGER NOT NULL,
	page_template_ID INTEGER NOT NULL,
	display_point_ID VARCHAR ( 30 ) NOT NULL,
	description VARCHAR ( 60 ) NOT NULL,
	CONSTRAINT pk_page_template_display_point PRIMARY KEY (page_template_display_point_ID)
	);
CREATE INDEX idx_page_template_display_point_display_point_id ON pgapex.page_template_display_point (display_point_ID );
CREATE INDEX idx_page_template_display_point_page_template_id ON pgapex.page_template_display_point (page_template_ID );
CREATE TABLE pgapex.form_pre_fill (
	form_pre_fill_ID SERIAL NOT NULL,
	schema_name VARCHAR ( 64 ) NOT NULL,
	view_name VARCHAR ( 64 ) NOT NULL,
	CONSTRAINT pk_form_pre_fill PRIMARY KEY (form_pre_fill_ID)
	);
CREATE INDEX idx_form_pre_fill_view_name ON pgapex.form_pre_fill (view_name );
CREATE INDEX idx_form_pre_fill_schema_name ON pgapex.form_pre_fill (schema_name );
CREATE TABLE pgapex.template (
	template_ID INTEGER NOT NULL,
	name VARCHAR ( 60 ) NOT NULL,
	CONSTRAINT PK_template PRIMARY KEY (template_ID),
	CONSTRAINT uq_template_name UNIQUE (name)
	);
CREATE TABLE pgapex.fetch_row_condition (
	fetch_row_condition_ID SERIAL NOT NULL,
	form_pre_fill_ID INTEGER NOT NULL,
	url_parameter_id INTEGER NOT NULL,
	view_column_name VARCHAR ( 64 ) NOT NULL,
	CONSTRAINT pk_fetch_row_condition PRIMARY KEY (fetch_row_condition_ID)
	);
CREATE INDEX idx_fetch_row_condition_view_column_name ON pgapex.fetch_row_condition (view_column_name );
CREATE INDEX idx_fetch_row_condition_form_pre_fill_id ON pgapex.fetch_row_condition (form_pre_fill_ID );
CREATE INDEX idx_fetch_row_condition_url_parameter_id ON pgapex.fetch_row_condition (url_parameter_id );
CREATE TABLE pgapex.tabularform_region(
  region_ID INTEGER NOT NULL,
	template_ID INTEGER NOT NULL,
	schema_name VARCHAR ( 64 ) NOT NULL,
	view_name VARCHAR ( 64 ) NOT NULL,
	items_per_page INTEGER NOT NULL,
	show_header BOOLEAN DEFAULT TRUE NOT NULL,
	unique_ID VARCHAR ( 64 ) NOT NULL,
	CONSTRAINT pk_tabularform_region PRIMARY KEY (region_ID)
  );
CREATE INDEX idx_tabularform_region_view_name ON pgapex.tabularform_region (view_name );
CREATE INDEX idx_tabularform_region_schema_name ON pgapex.tabularform_region (schema_name );
CREATE INDEX idx_tabularform_region_template_id ON pgapex.tabularform_region (template_ID );
CREATE TABLE pgapex.html_region (
	region_ID INTEGER NOT NULL,
	content TEXT,
	CONSTRAINT pk_html_region PRIMARY KEY (region_ID)
	);
CREATE TABLE pgapex.database (
	name VARCHAR ( 255 ) NOT NULL,
	database_ID INTEGER NOT NULL,
	CONSTRAINT PK_database121 PRIMARY KEY (database_ID)
	);
CREATE TABLE pgapex.navigation_type (
	navigation_type_ID VARCHAR ( 10 ) NOT NULL,
	CONSTRAINT pk_navigation_type PRIMARY KEY (navigation_type_ID)
	);
CREATE TABLE pgapex.field_type (
	field_type_ID VARCHAR ( 10 ) NOT NULL,
	CONSTRAINT pk_field_type PRIMARY KEY (field_type_ID)
	);
CREATE TABLE pgapex.schema (
	name VARCHAR ( 255 ) NOT NULL,
	schema_ID INTEGER NOT NULL,
	database_ID INTEGER NOT NULL,
	CONSTRAINT PK_schema115 PRIMARY KEY (schema_ID)
	);
CREATE INDEX TC_schema327 ON pgapex.schema (database_ID );
CREATE TABLE pgapex.navigation_item_template (
	navigation_item_template_ID INTEGER NOT NULL,
	navigation_template_ID INTEGER NOT NULL,
	active_template TEXT NOT NULL,
	inactive_template TEXT NOT NULL,
	level INTEGER NOT NULL,
	CONSTRAINT pk_navigation_item_template PRIMARY KEY (navigation_item_template_ID),
	CONSTRAINT chk_navigation_item_template_level_must_be_positive CHECK (level > 0)
	);
CREATE INDEX idx_navigation_item_template_navigation_template_id ON pgapex.navigation_item_template (navigation_template_ID );
CREATE TABLE pgapex.form_template (
	template_ID INTEGER NOT NULL,
	form_begin TEXT NOT NULL,
	form_end TEXT NOT NULL,
	row_begin TEXT NOT NULL,
	row_end TEXT NOT NULL,
	row TEXT NOT NULL,
	mandatory_row_begin TEXT NOT NULL,
	mandatory_row_end TEXT NOT NULL,
	mandatory_row TEXT NOT NULL,
	CONSTRAINT pk_form_template PRIMARY KEY (template_ID)
	);
CREATE TABLE pgapex.region (
	region_ID SERIAL NOT NULL,
	page_ID INTEGER NOT NULL,
	template_ID INTEGER NOT NULL,
	page_template_display_point_ID INTEGER NOT NULL,
	name VARCHAR ( 60 ) NOT NULL,
	sequence INTEGER NOT NULL,
	is_visible BOOLEAN DEFAULT TRUE NOT NULL,
	CONSTRAINT uq_region_page_id_page_template_display_point_id_sequence UNIQUE (page_ID, page_template_display_point_ID, sequence),
	CONSTRAINT pk_region PRIMARY KEY (region_ID)
	);
CREATE INDEX idx_region_page_id ON pgapex.region (page_ID );
CREATE INDEX idx_region_template_id ON pgapex.region (template_ID );
CREATE INDEX idx_region_page_template_display_point_id ON pgapex.region (page_template_display_point_ID );
CREATE TABLE pgapex.region_template (
	template_ID INTEGER NOT NULL,
	template TEXT NOT NULL,
	CONSTRAINT pk_region_template PRIMARY KEY (template_ID)
	);
CREATE TABLE pgapex.page (
	page_ID SERIAL NOT NULL,
	application_ID INTEGER NOT NULL,
	template_ID INTEGER NOT NULL,
	title VARCHAR ( 60 ) NOT NULL,
	alias VARCHAR ( 60 ),
	is_homepage BOOLEAN DEFAULT FALSE NOT NULL,
	is_authentication_required BOOLEAN DEFAULT FALSE NOT NULL,
	CONSTRAINT pk_page PRIMARY KEY (page_ID),
	CONSTRAINT uq_page_application_id_alias UNIQUE (application_ID, alias)
	);
CREATE INDEX idx_page_application_id ON pgapex.page (application_ID );
CREATE INDEX idx_page_template_id ON pgapex.page (template_ID );
CREATE TABLE pgapex.navigation_region (
	region_ID INTEGER NOT NULL,
	navigation_type_ID VARCHAR ( 10 ) NOT NULL,
	navigation_ID INTEGER NOT NULL,
	template_ID INTEGER NOT NULL,
	repeat_last_level BOOLEAN DEFAULT TRUE NOT NULL,
	CONSTRAINT pk_navigation_region PRIMARY KEY (region_ID)
	);
CREATE INDEX idx_navigation_region_navigation_id ON pgapex.navigation_region (navigation_ID );
CREATE INDEX idx_navigation_region_template_id ON pgapex.navigation_region (template_ID );
CREATE INDEX idx_navigation_region_navigation_type_id ON pgapex.navigation_region (navigation_type_ID );
CREATE TABLE pgapex.list_of_values (
	list_of_values_ID SERIAL NOT NULL,
	value_view_column_name VARCHAR ( 64 ) NOT NULL,
	label_view_column_name VARCHAR ( 64 ) NOT NULL,
	view_name VARCHAR ( 64 ) NOT NULL,
	schema_name VARCHAR ( 64 ) NOT NULL,
	CONSTRAINT pk_list_of_values PRIMARY KEY (list_of_values_ID)
	);
CREATE INDEX idx_list_of_values_label_view_column_name ON pgapex.list_of_values (label_view_column_name );
CREATE INDEX idx_list_of_values_view_name ON pgapex.list_of_values (view_name );
CREATE INDEX idx_list_of_values_value_view_column_name ON pgapex.list_of_values (value_view_column_name );
CREATE TABLE pgapex.data_type (
	data_type VARCHAR ( 255 ) NOT NULL,
	data_type_ID INTEGER NOT NULL,
	schema_ID INTEGER NOT NULL,
	CONSTRAINT PK_data_type118 PRIMARY KEY (data_type_ID)
	);
CREATE INDEX TC_data_type332 ON pgapex.data_type (schema_ID );
CREATE TABLE pgapex.report_template (
	template_ID INTEGER NOT NULL,
	report_begin TEXT NOT NULL,
	report_end TEXT NOT NULL,
	header_begin TEXT NOT NULL,
	header_row_begin TEXT NOT NULL,
	header_cell TEXT NOT NULL,
	header_row_end TEXT NOT NULL,
	header_end TEXT NOT NULL,
	body_begin TEXT NOT NULL,
	body_row_begin TEXT NOT NULL,
	body_row_cell TEXT NOT NULL,
	body_row_end TEXT NOT NULL,
	body_end TEXT NOT NULL,
	pagination_begin TEXT NOT NULL,
	pagination_end TEXT NOT NULL,
	previous_page TEXT NOT NULL,
	next_page TEXT NOT NULL,
	active_page TEXT NOT NULL,
	inactive_page TEXT NOT NULL,
	CONSTRAINT pk_report_template PRIMARY KEY (template_ID)
	);
CREATE TABLE pgapex.report_link_template (
	template_ID INTEGER NOT NULL,
	report_begin TEXT NOT NULL,
	report_end TEXT NOT NULL,
	buttons_row_begin TEXT NOT NULL,
	buttons_row_content TEXT NOT NULL,
	buttons_row_end TEXT NOT NULL,
	header_begin TEXT NOT NULL,
	header_row_begin TEXT NOT NULL,
	header_cell TEXT NOT NULL,
	header_row_end TEXT NOT NULL,
	header_end TEXT NOT NULL,
	body_begin TEXT NOT NULL,
	body_row_begin TEXT NOT NULL,
	body_row_link TEXT NOT NULL,
	body_row_cell TEXT NOT NULL,
	body_row_end TEXT NOT NULL,
	body_end TEXT NOT NULL,
	pagination_begin TEXT NOT NULL,
	pagination_end TEXT NOT NULL,
	previous_page TEXT NOT NULL,
	next_page TEXT NOT NULL,
	active_page TEXT NOT NULL,
	inactive_page TEXT NOT NULL,
	CONSTRAINT pk_report_link_template PRIMARY KEY (template_ID)
  );
CREATE TABLE pgapex.tabularform_template (
	template_ID INTEGER NOT NULL,
	tabularform_begin TEXT NOT NULL,
	tabularform_end TEXT NOT NULL,
	form_begin TEXT NOT NULL,
	buttons_row_begin TEXT NOT NULL,
	buttons_row_content TEXT NOT NULL,
	buttons_row_end TEXT NOT NULL,
	table_begin TEXT NOT NULL,
	table_header_begin TEXT NOT NULL,
	table_header_row_begin TEXT NOT NULL,
	table_header_checkbox TEXT NOT NULL,
	table_header_cell TEXT NOT NULL,
	table_header_row_end TEXT NOT NULL,
	table_header_end TEXT NOT NULL,
	table_body_begin TEXT NOT NULL,
	table_body_row_begin TEXT NOT NULL,
	table_body_row_checkbox TEXT NOT NULL,
	table_body_row_cell TEXT NOT NULL,
	table_body_row_end TEXT NOT NULL,
	table_body_end TEXT NOT NULL,
	table_end TEXT NOT NULL,
	form_end TEXT NOT NULL,
	pagination_begin TEXT NOT NULL,
	pagination_end TEXT NOT NULL,
	previous_page TEXT NOT NULL,
	next_page TEXT NOT NULL,
	active_page TEXT NOT NULL,
	inactive_page TEXT NOT NULL,
	CONSTRAINT pk_tabularform_template PRIMARY KEY (template_ID)
	);
CREATE TABLE pgapex.tabularform_function (
  tabularform_function_ID SERIAL NOT NULL,
  region_ID INTEGER NOT NULL,
  button_template_ID INTEGER NOT NULL,
  schema_name VARCHAR ( 64 ) NOT NULL,
  function_name VARCHAR ( 64 ) NOT NULL,
  button_label VARCHAR ( 255 ) NOT NULL,
  sequence INT NOT NULL,
  success_message VARCHAR ( 255 ) NOT NULL,
	error_message VARCHAR ( 255 ) NOT NULL,
	app_user BOOLEAN DEFAULT FALSE,
  CONSTRAINT pk_tabularform_function PRIMARY KEY (tabularform_function_ID),
  CONSTRAINT chk_tabularform_function_sequence_must_be_not_negative CHECK (sequence >= 0)
  );
CREATE TABLE pgapex.tabularform_button_template (
  template_ID INTEGER NOT NULL,
  template TEXT NOT NULL,
  CONSTRAINT pk_tabularform_button_template PRIMARY KEY (template_ID)
  );
CREATE TABLE pgapex.detailview_region (
  region_ID INTEGER NOT NULL,
  report_region_ID INTEGER NOT NULL,
  template_ID INTEGER NOT NULL,
  schema_name VARCHAR ( 64 ) NOT NULL,
  view_name VARCHAR ( 64 ) NOT NULL,
  unique_id VARCHAR ( 64 ) NOT NULL,
  CONSTRAINT pk_detailview_region PRIMARY KEY (region_ID)
  );
CREATE INDEX idx_detailview_region_template_ID ON pgapex.detailview_region (template_ID);
CREATE INDEX idx_detailview_region_schema_name ON pgapex.detailview_region (schema_name);
CREATE INDEX idx_detailview_region_view_name ON pgapex.detailview_region (view_name);
CREATE TABLE pgapex.detailview_template (
  template_ID INTEGER NOT NULL,
  detailview_begin TEXT NOT NULL,
  detailview_end TEXT NOT NULL,
  column_heading TEXT NOT NULL,
  column_content TEXT NOT NULL,
  CONSTRAINT pk_detailview_template PRIMARY KEY (template_ID)
  );
CREATE TABLE pgapex.detailview_column_type (
  detailview_column_type_ID VARCHAR ( 30 ) NOT NULL,
  CONSTRAINT pk_detailview_column_type PRIMARY KEY (detailview_column_type_ID)
  );
CREATE TABLE pgapex.detailview_column (
  detailview_column_ID SERIAL NOT NULL,
  detailview_column_type_ID VARCHAR ( 30 ) NOT NULL,
  region_ID INTEGER NOT NULL,
  view_column_name VARCHAR ( 64 ) NOT NULL,
  heading VARCHAR ( 60 ) NOT NULL,
  sequence INTEGER NOT NULL,
  is_text_escaped BOOLEAN DEFAULT TRUE NOT NULL,
  CONSTRAINT pk_detailview_column PRIMARY KEY (detailview_column_ID),
	CONSTRAINT chk_detailview_column_sequence_must_be_not_negative CHECK (sequence >= 0)
  );
CREATE INDEX idx_detailview_column_view_column_name ON pgapex.detailview_column (view_column_name);
CREATE INDEX idx_detailview_column_detailview_column_type_id ON pgapex.detailview_column (detailview_column_type_ID);
CREATE INDEX idx_detailview_column_region_id ON pgapex.detailview_column (region_ID);
CREATE TABLE pgapex.detailview_column_link (
  detailview_column_link_ID SERIAL NOT NULL,
  detailview_column_ID INTEGER NOT NULL,
  url VARCHAR ( 255 ) NOT NULL,
  link_text VARCHAR ( 60 ) NOT NULL,
  attributes VARCHAR ( 255 ),
  CONSTRAINT uq_detailview_column_link_detailview_column_id UNIQUE (detailview_column_ID),
	CONSTRAINT pk_detailview_column_link PRIMARY KEY (detailview_column_link_ID)
  );
CREATE TABLE pgapex.subregion (
  subregion_ID SERIAL NOT NULL,
  parent_region_ID INTEGER NOT NULL,
  template_ID INTEGER NOT NULL,
  name VARCHAR ( 60 ) NOT NULL,
  sequence INTEGER NOT NULL,
  is_visible BOOLEAN NOT NULL,
  query_parameter VARCHAR ( 60 ),
  CONSTRAINT pk_subregion PRIMARY KEY (subregion_ID)
  );
CREATE INDEX idx_subregion_parent_region_id ON pgapex.subregion (parent_region_ID);
CREATE INDEX idx_subregion_template_id ON pgapex.subregion (template_ID);
CREATE TABLE pgapex.subregion_template (
	template_ID INTEGER NOT NULL,
	template TEXT NOT NULL,
	CONSTRAINT pk_subregion_template PRIMARY KEY (template_ID)
	);

/* PgApex3 new tables */
CREATE TABLE pgapex.link_button_template (
	template_ID INTEGER NOT NULL,
	template TEXT NOT NULL,
	CONSTRAINT pk_link_button_template PRIMARY KEY (template_ID)
	);

CREATE TABLE pgapex.report_form_template (
	template_ID INTEGER NOT NULL,
	report_begin TEXT NOT NULL,
	report_end TEXT NOT NULL,
	buttons_row_begin TEXT NOT NULL,
	buttons_row_content TEXT NOT NULL,
	buttons_row_end TEXT NOT NULL,
	header_begin TEXT NOT NULL,
	header_row_begin TEXT NOT NULL,
	header_cell TEXT NOT NULL,
	header_row_end TEXT NOT NULL,
	header_end TEXT NOT NULL,
	body_begin TEXT NOT NULL,
	body_row_begin TEXT NOT NULL,
	body_row_link TEXT NOT NULL,
	body_row_cell TEXT NOT NULL,
	body_row_end TEXT NOT NULL,
	body_end TEXT NOT NULL,
	pagination_begin TEXT NOT NULL,
	pagination_end TEXT NOT NULL,
	previous_page TEXT NOT NULL,
	next_page TEXT NOT NULL,
	active_page TEXT NOT NULL,
	inactive_page TEXT NOT NULL,
	CONSTRAINT pk_report_form_template PRIMARY KEY (template_ID)
  );

ALTER TABLE pgapex.button_template ADD CONSTRAINT fk_button_template_template_id FOREIGN KEY (template_ID) REFERENCES pgapex.template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.page_item ADD CONSTRAINT fk_page_item_region_id FOREIGN KEY (region_ID) REFERENCES pgapex.report_region (region_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.page_item ADD CONSTRAINT fk_page_item_tabularform_id FOREIGN KEY (tabularform_region_ID) REFERENCES pgapex.tabularform_region (region_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.page_item ADD CONSTRAINT fk_page_item_page_id FOREIGN KEY (page_ID) REFERENCES pgapex.page (page_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.page_item ADD CONSTRAINT fk_page_item_form_field_id FOREIGN KEY (form_field_ID) REFERENCES pgapex.form_field (form_field_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.form_template ADD CONSTRAINT fk_form_template_template_id FOREIGN KEY (template_ID) REFERENCES pgapex.template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.drop_down_template ADD CONSTRAINT fk_drop_down_template_template_id FOREIGN KEY (template_ID) REFERENCES pgapex.template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.page_template ADD CONSTRAINT fk_page_template_template_id FOREIGN KEY (template_ID) REFERENCES pgapex.template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.page_template ADD CONSTRAINT fk_page_template_page_type_id FOREIGN KEY (page_type_ID) REFERENCES pgapex.page_type (page_type_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.input_template ADD CONSTRAINT fk_input_template_template_id FOREIGN KEY (template_ID) REFERENCES pgapex.template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.input_template ADD CONSTRAINT fk_input_template_input_template_type_id FOREIGN KEY (input_template_type_ID) REFERENCES pgapex.input_template_type (input_template_type_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.report_template ADD CONSTRAINT fk_report_template_template_id FOREIGN KEY (template_ID) REFERENCES pgapex.template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.report_link_template ADD CONSTRAINT fk_report_link_template_template_id FOREIGN KEY (template_ID) REFERENCES pgapex.template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.tabularform_template ADD CONSTRAINT fk_tabularform_template_template_id FOREIGN KEY (template_ID) REFERENCES pgapex.template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.function ADD CONSTRAINT FK_function133 FOREIGN KEY (schema_ID) REFERENCES pgapex.schema (schema_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.function ADD CONSTRAINT FK_function139 FOREIGN KEY (data_type_ID) REFERENCES pgapex.data_type (data_type_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.fetch_row_condition ADD CONSTRAINT fk_fetch_row_condition_form_pre_fill_id FOREIGN KEY (form_pre_fill_ID) REFERENCES pgapex.form_pre_fill (form_pre_fill_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.fetch_row_condition ADD CONSTRAINT fk_fetch_row_condition_url_parameter_id FOREIGN KEY (url_parameter_id) REFERENCES pgapex.page_item (page_item_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.region_template ADD CONSTRAINT fk_region_template_template_id FOREIGN KEY (template_ID) REFERENCES pgapex.template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.view ADD CONSTRAINT FK_view132 FOREIGN KEY (schema_ID) REFERENCES pgapex.schema (schema_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.data_type ADD CONSTRAINT FK_data_type134 FOREIGN KEY (schema_ID) REFERENCES pgapex.schema (schema_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.report_region ADD CONSTRAINT fk_report_region_region_id FOREIGN KEY (region_ID) REFERENCES pgapex.region (region_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.report_region ADD CONSTRAINT fk_report_region_template_id FOREIGN KEY (template_ID) REFERENCES pgapex.report_template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.report_region ADD CONSTRAINT fk_report_region_subregion_id FOREIGN KEY (subregion_ID) REFERENCES pgapex.subregion (subregion_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.report_region ADD CONSTRAINT fk_report_region_link_template_id FOREIGN KEY (link_template_ID) REFERENCES pgapex.report_link_template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.tabularform_region ADD CONSTRAINT fk_tabularform_region_region_id FOREIGN KEY (region_ID) REFERENCES pgapex.region (region_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.tabularform_region ADD CONSTRAINT fk_tabularform_region_template_id FOREIGN KEY (template_ID) REFERENCES pgapex.tabularform_template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.navigation_item ADD CONSTRAINT fk_navigation_item_parent_navigation_item_id FOREIGN KEY (parent_navigation_item_ID) REFERENCES pgapex.navigation_item (navigation_item_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.navigation_item ADD CONSTRAINT fk_navigation_item_navigation_id FOREIGN KEY (navigation_ID) REFERENCES pgapex.navigation (navigation_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.navigation_item ADD CONSTRAINT fk_navigation_item_page_id FOREIGN KEY (page_ID) REFERENCES pgapex.page (page_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.form_field ADD CONSTRAINT fk_form_field_drop_down_template_id FOREIGN KEY (drop_down_template_ID) REFERENCES pgapex.drop_down_template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.form_field ADD CONSTRAINT fk_form_field_list_of_values_id FOREIGN KEY (list_of_values_ID) REFERENCES pgapex.list_of_values (list_of_values_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.form_field ADD CONSTRAINT fk_form_field_input_template_id FOREIGN KEY (input_template_ID) REFERENCES pgapex.input_template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.form_field ADD CONSTRAINT fk_form_field_textarea_template_id FOREIGN KEY (textarea_template_ID) REFERENCES pgapex.textarea_template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.form_field ADD CONSTRAINT fk_form_field_field_type_id FOREIGN KEY (field_type_ID) REFERENCES pgapex.field_type (field_type_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.form_field ADD CONSTRAINT fk_form_field_region_id FOREIGN KEY (region_ID) REFERENCES pgapex.form_region (region_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.application ADD CONSTRAINT fk_application_authentication_scheme_id FOREIGN KEY (authentication_scheme_ID) REFERENCES pgapex.authentication_scheme (authentication_scheme_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.application ADD CONSTRAINT fk_application_login_page_template_id FOREIGN KEY (login_page_template_ID) REFERENCES pgapex.page_template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.navigation_item_template ADD CONSTRAINT fk_navigation_item_template_template_id FOREIGN KEY (navigation_template_ID) REFERENCES pgapex.navigation_template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.view_column ADD CONSTRAINT FK_column144 FOREIGN KEY (view_ID) REFERENCES pgapex.view (view_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.view_column ADD CONSTRAINT FK_column141 FOREIGN KEY (data_type_ID) REFERENCES pgapex.data_type (data_type_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.parameter ADD CONSTRAINT FK_parameter137 FOREIGN KEY (function_ID) REFERENCES pgapex.function (function_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.parameter ADD CONSTRAINT FK_parameter140 FOREIGN KEY (data_type_ID) REFERENCES pgapex.data_type (data_type_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.session ADD CONSTRAINT fk_session_application_id FOREIGN KEY (application_ID) REFERENCES pgapex.application (application_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.navigation ADD CONSTRAINT fk_navigation_application_id FOREIGN KEY (application_ID) REFERENCES pgapex.application (application_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.report_column ADD CONSTRAINT fk_report_column_report_column_type_id FOREIGN KEY (report_column_type_ID) REFERENCES pgapex.report_column_type (report_column_type_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.report_column ADD CONSTRAINT fk_report_column_region_id FOREIGN KEY (region_ID) REFERENCES pgapex.report_region (region_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.report_column ADD CONSTRAINT fk_report_column_subregion_id FOREIGN KEY (subregion_ID) REFERENCES pgapex.report_region (subregion_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.tabularform_column ADD CONSTRAINT fk_tabularform_column_tabularform_column_type_id FOREIGN KEY (tabularform_column_type_ID) REFERENCES pgapex.tabularform_column_type (tabularform_column_type_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.tabularform_column ADD CONSTRAINT fk_tabularform_column_region_id FOREIGN KEY (region_ID) REFERENCES pgapex.tabularform_region (region_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.tabularform_function ADD CONSTRAINT fk_tabularform_function_region_id FOREIGN KEY (region_ID) REFERENCES pgapex.tabularform_region (region_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.page_template_display_point ADD CONSTRAINT fk_page_template_display_point_diplay_point_id FOREIGN KEY (display_point_ID) REFERENCES pgapex.display_point (display_point_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.page_template_display_point ADD CONSTRAINT fk_page_template_display_point_page_template_id FOREIGN KEY (page_template_ID) REFERENCES pgapex.page_template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.page ADD CONSTRAINT fk_page_template_id FOREIGN KEY (template_ID) REFERENCES pgapex.page_template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.page ADD CONSTRAINT fk_page_application_id FOREIGN KEY (application_ID) REFERENCES pgapex.application (application_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.textarea_template ADD CONSTRAINT fk_textarea_template_template_id FOREIGN KEY (template_ID) REFERENCES pgapex.template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.html_region ADD CONSTRAINT fk_html_region_region_id FOREIGN KEY (region_ID) REFERENCES pgapex.region (region_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.region ADD CONSTRAINT fk_region_template_id FOREIGN KEY (template_ID) REFERENCES pgapex.region_template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.region ADD CONSTRAINT fk_region_page_id FOREIGN KEY (page_ID) REFERENCES pgapex.page (page_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.region ADD CONSTRAINT fk_region_page_template_display_point_id FOREIGN KEY (page_template_display_point_ID) REFERENCES pgapex.page_template_display_point (page_template_display_point_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.subregion ADD CONSTRAINT fk_subregion_parent_region_id FOREIGN KEY (parent_region_ID) REFERENCES pgapex.detailview_region (region_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.subregion ADD CONSTRAINT fk_subregion_template_id FOREIGN KEY (template_ID) REFERENCES pgapex.subregion_template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.form_region ADD CONSTRAINT fk_form_region_region_id FOREIGN KEY (region_ID) REFERENCES pgapex.region (region_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.form_region ADD CONSTRAINT fk_form_region_form_pre_fill_id FOREIGN KEY (form_pre_fill_ID) REFERENCES pgapex.form_pre_fill (form_pre_fill_ID)  ON DELETE SET NULL ON UPDATE NO ACTION;
ALTER TABLE pgapex.form_region ADD CONSTRAINT fk_form_region_template_id FOREIGN KEY (template_ID) REFERENCES pgapex.form_template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.form_region ADD CONSTRAINT fk_form_region_button_template_id FOREIGN KEY (button_template_ID) REFERENCES pgapex.button_template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.navigation_region ADD CONSTRAINT fk_navigation_region_region_id FOREIGN KEY (region_ID) REFERENCES pgapex.region (region_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.navigation_region ADD CONSTRAINT fk_navigation_region_navigation_id FOREIGN KEY (navigation_ID) REFERENCES pgapex.navigation (navigation_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.navigation_region ADD CONSTRAINT fk_navigation_region_template_id FOREIGN KEY (template_ID) REFERENCES pgapex.navigation_template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.navigation_region ADD CONSTRAINT fk_navigation_region_navigation_type_id FOREIGN KEY (navigation_type_ID) REFERENCES pgapex.navigation_type (navigation_type_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.schema ADD CONSTRAINT FK_schema151 FOREIGN KEY (database_ID) REFERENCES pgapex.database (database_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.navigation_template ADD CONSTRAINT fk_navigation_template_template_id FOREIGN KEY (template_ID) REFERENCES pgapex.template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.report_column_link ADD CONSTRAINT fk_report_column_link_report_column_id FOREIGN KEY (report_column_ID) REFERENCES pgapex.report_column (report_column_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.tabularform_column_link ADD CONSTRAINT fk_tabularform_column_link_tabularform_column_id FOREIGN KEY (tabularform_column_ID) REFERENCES pgapex.tabularform_column (tabularform_column_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.tabularform_button_template ADD CONSTRAINT fk_tabularform_button_template_template_id FOREIGN KEY (template_ID) REFERENCES pgapex.template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.detailview_region ADD CONSTRAINT fk_detailview_region_region_id FOREIGN KEY (region_ID) REFERENCES pgapex.region (region_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.detailview_region ADD CONSTRAINT fk_detailview_region_template_id FOREIGN KEY (template_ID) REFERENCES pgapex.detailview_template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.detailview_template ADD CONSTRAINT fk_detailview_template_template_id FOREIGN KEY (template_ID) REFERENCES pgapex.template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.detailview_column ADD CONSTRAINT fk_detailview_column_region_id FOREIGN KEY (region_ID) REFERENCES pgapex.detailview_region (region_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.detailview_column ADD CONSTRAINT fk_detailview_column_detailview_column_type_id FOREIGN KEY (detailview_column_type_ID) REFERENCES pgapex.detailview_column_type (detailview_column_type_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pgapex.detailview_column_link ADD CONSTRAINT fk_detailview_column_link_detailview_column_id FOREIGN KEY (detailview_column_ID) REFERENCES pgapex.detailview_column (detailview_column_ID)  ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE pgapex.report_form_template ADD CONSTRAINT fk_report_form_template_template_id FOREIGN KEY (template_ID) REFERENCES pgapex.template (template_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION;