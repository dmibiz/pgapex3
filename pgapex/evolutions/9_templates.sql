INSERT INTO pgapex.template (template_id, name) VALUES (1, 'Login page');
INSERT INTO pgapex.template (template_id, name) VALUES (2, 'Normal page');
INSERT INTO pgapex.template (template_id, name) VALUES (3, 'Top navigation template');
INSERT INTO pgapex.template (template_id, name) VALUES (4, 'Region template');
INSERT INTO pgapex.template (template_id, name) VALUES (5, 'Navigation region template');
INSERT INTO pgapex.template (template_id, name) VALUES (6, 'Report template');
INSERT INTO pgapex.template (template_id, name) VALUES (7, 'Form template');
INSERT INTO pgapex.template (template_id, name) VALUES (8, 'Drop-down template');
INSERT INTO pgapex.template (template_id, name) VALUES (9, 'Button template');
INSERT INTO pgapex.template (template_id, name) VALUES (10, 'Textarea template');
INSERT INTO pgapex.template (template_id, name) VALUES (11, 'Text input template');
INSERT INTO pgapex.template (template_id, name) VALUES (12, 'Password input template');
INSERT INTO pgapex.template (template_id, name) VALUES (13, 'Radio template');
INSERT INTO pgapex.template (template_id, name) VALUES (14, 'Checkbox template');
INSERT INTO pgapex.template (template_id, name) VALUES (15, 'Tabular form template');
INSERT INTO pgapex.template (template_id, name) VALUES (16, 'Default button');
INSERT INTO pgapex.template (template_id, name) VALUES (17, 'Green button');
INSERT INTO pgapex.template (template_id, name) VALUES (18, 'Red button');
INSERT INTO pgapex.template (template_id, name) VALUES (19, 'Report with links template');
INSERT INTO pgapex.template (template_id, name) VALUES (20, 'Default detail view page');
INSERT INTO pgapex.template (template_id, name) VALUES (21, 'Subregion template');
INSERT INTO pgapex.template (template_id, name) VALUES (22, 'Link button template');
INSERT INTO pgapex.template (template_id, name) VALUES (23, 'Report with form links template');
INSERT INTO pgapex.template (template_id, name) VALUES (24, 'Calender template');
INSERT INTO pgapex.template (template_id, name) VALUES (25, 'Combo box template');



INSERT INTO pgapex.navigation_template (template_id, navigation_begin, navigation_end) VALUES (3, '<ul class="nav navbar-nav">', '</ul>');
INSERT INTO pgapex.navigation_item_template (navigation_item_template_id, navigation_template_id, active_template, inactive_template, level) VALUES (1, 3, '<li class="active"><a href="#URL#">#NAME#</a></li>', '<li><a href="#URL#">#NAME#</a></li>', 1);


INSERT INTO pgapex.page_template (template_id, page_type_id, header, body, footer, error_message, success_message) VALUES (1, 'LOGIN', '<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>#APPLICATION_NAME# :: #TITLE#</title>

    <!-- Bootstrap core CSS -->
    <link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" type="text/css" href="/app/style.css">
    <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
      <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
    <![endif]-->
  </head>', '  <body>
    <nav class="navbar navbar-inverse">
      <div class="container">
        <div class="navbar-header">
          <a class="navbar-brand" href="#APPLICATION_HOMEPAGE_LINK#">#APPLICATION_NAME#</a>
        </div>
      </div>
    </nav>


    <div class="container">
      #SUCCESS_MESSAGE#
      #ERROR_MESSAGE#
      <form class="form-horizontal" method="post" action="">
        <input name="PGAPEX_OP" type="hidden" value="LOGIN">
        <div class="form-group">
          <div class="col-sm-12">
            <div class="input-group">
              <span class="input-group-addon">
                <span class="glyphicon glyphicon-user" aria-hidden="true"></span>
              </span>
              <input name="USERNAME" type="text" class="form-control" required autofocus>
            </div>
          </div>
        </div>
        <div class="form-group">
          <div class="col-sm-12">
            <div class="input-group">
              <span class="input-group-addon">
                <span class="glyphicon glyphicon-lock" aria-hidden="true"></span>
              </span>
              <input name="PASSWORD" type="password" class="form-control" required>
            </div>
          </div>
        </div>
        <div class="form-group">
          <div class="col-sm-12">
            <button type="submit" class="btn btn-primary btn-block">Login</button>
          </div>
        </div>
      </form>
    </div><!-- /.container -->

    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js"></script>
  </body>', '</html>', '<div class="alert alert-danger" role="alert">#MESSAGE#</div>', '<div class="alert alert-success" role="alert">#MESSAGE#</div>');
INSERT INTO pgapex.page_template (template_id, page_type_id, header, body, footer, error_message, success_message) VALUES (2, 'NORMAL', '<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>#APPLICATION_NAME# :: #TITLE#</title>

    <!-- Bootstrap core CSS -->
    <link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" type="text/css" href="http://localhost:8000/app/style.css">
    <link rel="stylesheet" type="text/css" href="http://localhost:8000/resources/css/combobox.css">
    <link rel="stylesheet" type="text/css" href="http://localhost:8000/resources/css/anytime.css">
    <link rel="stylesheet" href="//code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css">
    <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
      <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
    <![endif]-->
    <script src="https://cdn.tiny.cloud/1/8mf38z9ml3a6pc9o3ge0527gvgf951l9r8k0u2encfe4yyv2/tinymce/5/tinymce.min.js" referrerpolicy="origin"></script>
  </head>', '  <body>
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js"></script>
    <script src="https://code.jquery.com/ui/1.12.1/jquery-ui.js"></script>
    <script src="http://localhost:8000/resources/js/combobox.js"></script>
    <script src="http://localhost:8000/resources/js/anytime.js"></script>
    <script src="http://localhost:8000/resources/js/formregion.js"></script>
    <script src="/resources/js/region.js"></script>
    <nav class="navbar navbar-inverse">
      <div class="container">
        <div class="navbar-header">
          <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">
            <span class="sr-only">Toggle navigation</span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <a class="navbar-brand" href="#APPLICATION_HOMEPAGE_LINK#">#APPLICATION_NAME#</a>
        </div>
        <div id="navbar" class="collapse navbar-collapse">
        #POSITION_1#
        </div><!--/.nav-collapse -->
      </div>
    </nav>
    <div class="container">
      #SUCCESS_MESSAGE#
      #ERROR_MESSAGE#
      #BODY#
    </div><!-- /.container -->
  </body>', '</html>', '<div class="alert alert-danger" role="alert">#MESSAGE#</div>', '<div class="alert alert-success" role="alert">#MESSAGE#</div>');

INSERT INTO pgapex.region_template (template_id, template) VALUES (4, '<div class="panel panel-default">
  <div class="panel-heading">#NAME#</div>
  <div class="panel-body">#BODY#</div>
</div>');

INSERT INTO pgapex.region_template (template_id, template) VALUES (5, '#BODY#');


INSERT INTO pgapex.page_template_display_point (page_template_display_point_id, page_template_id, display_point_id, description) VALUES (1, 2, 'BODY', 'Body');
INSERT INTO pgapex.page_template_display_point (page_template_display_point_id, page_template_id, display_point_id, description) VALUES (2, 2, 'POSITION_1', 'Navigation');

INSERT INTO pgapex.report_template (template_ID, report_begin, report_end,
                                    header_begin, header_row_begin, header_cell, header_row_end, header_end,
                                    body_begin, body_row_begin, body_row_cell, body_row_end, body_end,
                                    pagination_begin, pagination_end, previous_page, next_page, active_page, inactive_page)
VALUES (6, '<div><table class="table table-bordered">', '</table>#PAGINATION#</div>',
'<thead>', '<tr>', '<th>#CELL_CONTENT#</th>', '</tr>', '</thead>',
'<tbody>', '<tr>', '<td>#CELL_CONTENT#</td>', '</tr>', '</tbody>',
'<nav><ul class="pagination">', '</ul></nav>', '<li><a href="#LINK#">&laquo;</a></li>', '<li><a href="#LINK#">&raquo;</a></li>', '<li class="active"><a href="#LINK#">#NUMBER#</a></li>', '<li><a href="#LINK#">#NUMBER#</a></li>');

INSERT INTO pgapex.form_template (template_id, form_begin, form_end, row_begin, row_end, row, mandatory_row_begin, mandatory_row_end, mandatory_row, help_text_block)
VALUES(7, '<form class="form-horizontal" method="POST" action="">', '#SUBMIT_BUTTON#</form>',
'<div class="form-group">', '</div>', '<label class="col-sm-2 control-label" title="#HELP_TEXT#">#LABEL#</label><div class="col-sm-10">#FORM_ELEMENT#</div>',
'<div class="form-group">', '</div>', '<label class="col-sm-2 control-label" title="#HELP_TEXT#">#LABEL# *</label><div class="col-sm-10">#FORM_ELEMENT#</div>',
'<div style="width: #WIDTH##WIDTH_UNIT#"><small class="form-text text-muted">#HELP_TEXT#</small></div>');

INSERT INTO pgapex.drop_down_template (template_id, drop_down_begin, drop_down_end, option_begin, option_end)
VALUES (8, '<select class="form-control" name="#NAME#" style="width: #WIDTH##WIDTH_UNIT#" #READ_ONLY#>', '</select>', '<option value="#VALUE#"#SELECTED#>', '</option>');

INSERT INTO pgapex.button_template (template_id, template) VALUES (9, '<div class="form-group">
  <div class="col-sm-offset-2 col-sm-10">
    <button type="submit" name="#NAME#" class="btn btn-primary">#LABEL#</button>
  </div>
</div>');

INSERT INTO pgapex.textarea_template (template_id, template, wysiwyg_editor_script) VALUES (10, '<textarea id="#NAME#" class="form-control" placeholder="#ROW_LABEL#" name="#NAME#" style="width: #WIDTH##WIDTH_UNIT#;#HEIGHT_PROPERTY#" #ROWS# #READ_ONLY#>#VALUE#</textarea>', '<script>
    tinymce.init({
      selector : "##NAME#",
      plugins: "lists link code",
      width: "#WIDTH##WIDTH_UNIT#",
      height: "#HEIGHT_PROPERTY#",
      menubar: #MENU_BAR#,
      statusbar: #STATUS_BAR#,
      browser_spellcheck: #BROWSER_SPELL_CHECK#,
      contextmenu: false,
      toolbar: "undo redo | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | table | fontsizeselect | link | code",
      entity_encoding : "raw",
      default_link_target: "_blank",
      forced_root_block : false,
      convert_newlines_to_brs : true
    });
  </script>');

INSERT INTO pgapex.input_template (template_id, input_template_type_id, template) VALUES (11, 'TEXT', '<input type="text" class="form-control" placeholder="#ROW_LABEL#" name="#NAME#" value="#VALUE#" style="width: #WIDTH##WIDTH_UNIT#" #READ_ONLY#>');
INSERT INTO pgapex.input_template (template_id, input_template_type_id, template) VALUES (12, 'PASSWORD', '<input type="password" class="form-control" placeholder="#ROW_LABEL#" name="#NAME#" value="#VALUE#" style="width: #WIDTH##WIDTH_UNIT#" #READ_ONLY#>');
INSERT INTO pgapex.input_template (template_id, input_template_type_id, template) VALUES (13, 'RADIO', '<div><input type="radio" name="#NAME#" value="#VALUE#"#CHECKED# #READ_ONLY#> #INPUT_LABEL#</div>');
INSERT INTO pgapex.input_template (template_id, input_template_type_id, template) VALUES (14, 'CHECKBOX', '<input type="hidden" value="FALSE" name="#NAME#"><input type="checkbox" class="checkbox" name="#NAME#" value="#VALUE#"#CHECKED# #READ_ONLY#>');

INSERT INTO pgapex.tabularform_template (template_ID, tabularform_begin, tabularform_end, form_begin, buttons_row_begin,
buttons_row_content, buttons_row_end, table_begin, table_header_begin, table_header_row_begin, table_header_checkbox,
table_header_cell, table_header_row_end, table_header_end, table_body_begin, table_body_row_begin,
table_body_row_checkbox, table_body_row_cell, table_body_row_end, table_body_end, table_end, form_end, pagination_begin,
pagination_end, previous_page, next_page, active_page, inactive_page)
VALUES (15, '<div>', '#PAGINATION#</div></div>', '<form method="POST" name="custom" action><input type="hidden" name="PGAPEX_TABULARFORM" value="#TABULARFORM_FUNCTION_ID#">',
'<div class="form-group pull-right">', '#SUBMIT_BUTTON#',
'</div>', '<div class="form-group"><table class="table table-bordered">', '<thead>', '</tr>',
'<th class="cell--fit-content"><input type="checkbox" onclick="checkAll(this)"></th>', '<th>#CELL_CONTENT#</th>', '</tr>', '</thead>',
'<tbody>', '<tr>', '<td class="cell--fit-content"><input type="checkbox" name="#UNIQUE_ID_COLUMN#[]" value="#UNIQUE_ID_VALUE#"><input type="hidden" name="#XMIN_COLUMN#[#UNIQUE_ID_VALUE#]" value="#XMIN_VALUE#"></td>',
'<td>#CELL_CONTENT#</td>', '</td>', '</tbody>', '</table>', '</form>', '<nav><ul class="pagination">', '</ul></nav>',
'<li><a href="#LINK#">&laquo;</a></li>', '<li><a href="#LINK#">&raquo;</a></li>',
'<li class="active"><a href="#LINK#">#NUMBER#</a></li>', '<li><a href="#LINK#">#NUMBER#</a></li>');

INSERT INTO pgapex.tabularform_button_template (template_ID, template) VALUES (16,
'<button type="submit" name="PGAPEX_BUTTON" value="#VALUE#"class="btn btn-secondary btn--margin-left">#LABEL#</button>');
INSERT INTO pgapex.tabularform_button_template (template_ID, template) VALUES (17,
'<button type="submit" name="PGAPEX_BUTTON" value="#VALUE#"class="btn btn-success btn--margin-left">#LABEL#</button>');
INSERT INTO pgapex.tabularform_button_template (template_ID, template) VALUES (18,
'<button type="submit" name="PGAPEX_BUTTON" value="#VALUE#"class="btn btn-danger btn--margin-left">#LABEL#</button>');

INSERT INTO pgapex.report_link_template (template_ID, report_begin, report_end, buttons_row_begin, buttons_row_content, buttons_row_end,
                                    header_begin, header_row_begin, header_cell, header_row_end, header_end,
                                    body_begin, body_row_begin, body_row_link, body_row_cell, body_row_end, body_end,
                                    pagination_begin, pagination_end, previous_page, next_page, active_page, inactive_page)
VALUES (19, '<div><table class="table table-bordered">', '</table>#PAGINATION#</div>', '<div class="form-group pull-right">', '#CREATE_ENTITY_BUTTON#', '</div>',
'<thead>', '<tr><th ></th>', '<th>#CELL_CONTENT#</th>', '</tr>', '</thead>',
'<tbody>', '<tr>', '<td class="cell--fit-content"><a href="#PATH#?#UNIQUE_ID#=#UNIQUE_ID_VALUE#"><span class="glyphicon glyphicon-list"></span></td>', '<td>#CELL_CONTENT#</td>', '</tr>', '</tbody>',
'<nav><ul class="pagination">', '</ul></nav>', '<li><a href="#LINK#">&laquo;</a></li>', '<li><a href="#LINK#">&raquo;</a></li>', '<li class="active"><a href="#LINK#">#NUMBER#</a></li>', '<li><a href="#LINK#">#NUMBER#</a></li>');

INSERT INTO pgapex.detailview_template (template_ID, detailview_begin, detailview_end, column_heading,
column_content)
VALUES (20, '<dl class="dl-horizontal">', '</dl>', '<dt>#COLUMN_HEADING#</dt>',
'<dd style="margin-bottom: 2em">#COLUMN_CONTENT#</dd>');

INSERT INTO pgapex.subregion_template (template_id, template) VALUES (21, '<div class="panel panel-info subregion"> <div class="panel-heading">#SUBREGION_TITLE#</div> #SUBREGION_BODY# </div>');

/*Pgapex 3*/
INSERT INTO pgapex.link_button_template(template_ID, template)
VALUES (22, '<a href="#PATH#" class="btn btn-primary btn" role="button">#LABEL#</a>');

INSERT INTO pgapex.report_link_template (template_ID, report_begin, report_end, buttons_row_begin, buttons_row_content, buttons_row_end,
                                    header_begin, header_row_begin, header_cell, header_row_end, header_end,
                                    body_begin, body_row_begin, body_row_link, body_row_cell, body_row_end, body_end,
                                    pagination_begin, pagination_end, previous_page, next_page, active_page, inactive_page)
VALUES (23, '<div><table class="table table-bordered">', '</table>#PAGINATION#</div>', '<div class="form-group pull-right">', '#CREATE_ENTITY_BUTTON#', '</div>',
'<thead>', '<tr><th ></th>', '<th>#CELL_CONTENT#</th>', '</tr>', '</thead>',
'<tbody>', '<tr>', '<td class="cell--fit-content"><a href="#PATH#?#UNIQUE_ID#=#UNIQUE_ID_VALUE#"><span class="glyphicon glyphicon-edit"></span></td>', '<td>#CELL_CONTENT#</td>', '</tr>', '</tbody>',
'<nav><ul class="pagination">', '</ul></nav>', '<li><a href="#LINK#">&laquo;</a></li>', '<li><a href="#LINK#">&raquo;</a></li>', '<li class="active"><a href="#LINK#">#NUMBER#</a></li>', '<li><a href="#LINK#">#NUMBER#</a></li>');

INSERT INTO pgapex.calender_template (template_ID, calender_input, calender_script)
VALUES (24, '<input type="text" id="#NAME#" class="form-control" size="50" placeholder="#ROW_LABEL#" name="#NAME#" value="#VALUE#" style="#BACKGROUND_PROPERTY#; width: #WIDTH##WIDTH_UNIT#" #READ_ONLY#/>', '<script>
                                                                      AnyTime.picker( "#NAME#",
                                                                          { format: #CALENDER_FORMAT#, firstDOW: 1 } );
                                                                  </script>');

INSERT INTO pgapex.combo_box_template (template_id, combo_box_begin, combo_box_end, option_begin, option_end, combo_box_script)
VALUES (25, '<select id="#NAME#" class="form-control" name="#NAME#" style="width: #WIDTH##WIDTH_UNIT#" #READ_ONLY#>', '</select>', '<option value="#VALUE#"#SELECTED#>', '</option>', '<script>$(document).ready(function() { $( "##NAME#" ).combobox(); }); $("##NAME#").next().children("input").ready(function() { $("##NAME#").next().children("input").css("width", "#WIDTH##WIDTH_UNIT#"); });</script>');

INSERT INTO pgapex.tabular_subform_template (template_ID, tabular_subform_begin, tabular_subform_end, form_begin, buttons_row_begin,
buttons_row_content, buttons_row_end, table_begin, table_header_begin, table_header_row_begin, table_header_checkbox,
table_header_cell, table_header_row_end, table_header_end, table_body_begin, table_body_row_begin,
table_body_row_checkbox, table_body_row_page_link, table_body_row_cell, table_body_row_end, table_body_end, table_end, form_end, pagination_begin,
pagination_end, previous_page, next_page, active_page, inactive_page)
VALUES (26, '<div>', '#PAGINATION#</div></div>', '<form method="POST" name="custom" action><input type="hidden" name="PGAPEX_TABULAR_SUBFORM" value="#TABULAR_SUBFORM_FUNCTION_ID#">',
'<div class="form-group pull-right">', '#SUBMIT_BUTTON#',
'</div>', '<div class="form-group tabular-subform-table-container"><table class="table table-bordered">', '<thead>', '</tr>',
'<th class="cell--fit-content"><input type="checkbox" onclick="checkAll(this)"></th>', '<th>#CELL_CONTENT#</th>', '</tr>', '</thead>',
'<tbody>', '<tr>', '<td class="cell--fit-content"><input type="checkbox" name="#FUNCTION_PARAMETERS#[]" value="#FUNCTION_PARAMETERS_VALUE#"></td>',
'<td class="cell--fit-content"><a href="#PATH#?#UNIQUE_ID#=#UNIQUE_ID_VALUE#"><span class="glyphicon glyphicon-edit"></td>','<td>#CELL_CONTENT#</td>', '</td>', '</tbody>', '</table>', '</form>', '<nav><ul class="pagination">', '</ul></nav>',
'<li><a href="#LINK#">&laquo;</a></li>', '<li><a href="#LINK#">&raquo;</a></li>',
'<li class="active"><a href="#LINK#">#NUMBER#</a></li>', '<li><a href="#LINK#">#NUMBER#</a></li>');



