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
INSERT INTO pgapex.template (template_id, name) VALUES (22, 'Create entity page template');


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

    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js"></script>
    <script src="/resources/js/region.js"></script>
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

INSERT INTO pgapex.form_template (template_id, form_begin, form_end, row_begin, row_end, row, mandatory_row_begin, mandatory_row_end, mandatory_row)
VALUES(7, '<form class="form-horizontal" method="POST" action="">', '#SUBMIT_BUTTON#</form>',
'<div class="form-group">', '</div>', '<label class="col-sm-2 control-label" title="#HELP_TEXT#">#LABEL#</label><div class="col-sm-10">#FORM_ELEMENT#</div>',
'<div class="form-group">', '</div>', '<label class="col-sm-2 control-label" title="#HELP_TEXT#">#LABEL# *</label><div class="col-sm-10">#FORM_ELEMENT#</div>');

INSERT INTO pgapex.drop_down_template (template_id, drop_down_begin, drop_down_end, option_begin, option_end)
VALUES (8, '<select class="form-control" name="#NAME#">', '</select>', '<option value="#VALUE#"#SELECTED#>', '</option>');

INSERT INTO pgapex.button_template (template_id, template) VALUES (9, '<div class="form-group">
  <div class="col-sm-offset-2 col-sm-10">
    <button type="submit" name="#NAME#" class="btn btn-primary">#LABEL#</button>
  </div>
</div>');

INSERT INTO pgapex.textarea_template (template_id, template) VALUES (10, '<textarea class="form-control" placeholder="#ROW_LABEL#" name="#NAME#">#VALUE#</textarea>');

INSERT INTO pgapex.input_template (template_id, input_template_type_id, template) VALUES (11, 'TEXT', '<input type="text" class="form-control" placeholder="#ROW_LABEL#" name="#NAME#" value="#VALUE#">');
INSERT INTO pgapex.input_template (template_id, input_template_type_id, template) VALUES (12, 'PASSWORD', '<input type="password" class="form-control" placeholder="#ROW_LABEL#" name="#NAME#" value="#VALUE#">');
INSERT INTO pgapex.input_template (template_id, input_template_type_id, template) VALUES (13, 'RADIO', '<div><input type="radio" name="#NAME#" value="#VALUE#"#CHECKED#> #INPUT_LABEL#</div>');
INSERT INTO pgapex.input_template (template_id, input_template_type_id, template) VALUES (14, 'CHECKBOX', '<input type="checkbox" class="checkbox" name="#NAME#" value="#VALUE#"#CHECKED#>');

INSERT INTO pgapex.tabularform_template (template_ID, tabularform_begin, tabularform_end, form_begin, buttons_row_begin,
buttons_row_content, buttons_row_end, table_begin, table_header_begin, table_header_row_begin, table_header_checkbox,
table_header_cell, table_header_row_end, table_header_end, table_body_begin, table_body_row_begin,
table_body_row_checkbox, table_body_row_cell, table_body_row_end, table_body_end, table_end, form_end, pagination_begin,
pagination_end, previous_page, next_page, active_page, inactive_page)
VALUES (15, '<div>', '#PAGINATION#</div></div>', '<form method="POST" name="custom" action><input type="hidden" name="PGAPEX_TABULARFORM" value="#TABULARFORM_FUNCTION_ID#">',
'<div class="form-group pull-right">', '#SUBMIT_BUTTON#',
'</div>', '<div class="form-group"><table class="table table-bordered">', '<thead>', '</tr>',
'<th class="cell--fit-content"><input type="checkbox" onclick="checkAll(this)"></th>', '<th>#CELL_CONTENT#</th>', '</tr>', '</thead>',
'<tbody>', '<tr>', '<td class="cell--fit-content"><input type="checkbox" name="#UNIQUE_ID_COLUMN#[]" value="#UNIQUE_ID_VALUE#"></td>',
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
VALUES (1, '<a href="#PATH#" class="btn btn-primary btn" role="button">#LABEL#</a>');
