<?php
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Message\ResponseInterface as Response;
use App\Http\Middleware\ApiMiddleware;
use App\Http\Middleware\AuthMiddleware;

$app->any('/', function (Request $request, Response $response) {
  $content = file_get_contents(__DIR__ . '/views/index.html');
  return str_replace('{$pgApexPath}', $_SERVER['SCRIPT_NAME'], $content);
});

$app->map(['GET', 'POST'], '/app/{applicationId}[/{pageId}]', '\App\Http\Controllers\AppController:queryPage');
$app->get('/logout/{applicationId}', '\App\Http\Controllers\AppController:logout');

$app->group('/api', function () {
  $this->post('/auth/login', '\App\Http\Controllers\AuthController:login');

  $this->group('', function () {
    $this->get('/auth/logout', '\App\Http\Controllers\AuthController:logout');

    $this->get('/application/applications', '\App\Http\Controllers\ApplicationController:getApplications');
    $this->get('/application/applications/{id}', '\App\Http\Controllers\ApplicationController:getApplication');
    $this->post('/application/applications/{id}/delete', '\App\Http\Controllers\ApplicationController:deleteApplication');
    $this->post('/application/save', '\App\Http\Controllers\ApplicationController:saveApplication');
    $this->post('/application/applications/authentication/save', '\App\Http\Controllers\ApplicationController:saveApplicationAuthentication');
    $this->get('/application/applications/{id}/authentication', '\App\Http\Controllers\ApplicationController:getApplicationAuthentication');

    $this->get('/database/databases', '\App\Http\Controllers\DatabaseController:getDatabases');
    $this->get('/database/authentication-functions/{applicationId}', '\App\Http\Controllers\DatabaseController:getAuthenticationFunctions');
    $this->get('/database/views/columns/{applicationId}', '\App\Http\Controllers\DatabaseController:getViewsWithColumns');
    $this->get('/database/functions-with-parameters/{applicationId}', '\App\Http\Controllers\DatabaseController:getFunctionsWithParameters');
    $this->post('/database/refresh-database-objects', '\App\Http\Controllers\DatabaseController:refreshDatabaseObjects');

    $this->get('/template/login-templates', '\App\Http\Controllers\TemplateController:getLoginTemplates');
    $this->get('/template/page-templates', '\App\Http\Controllers\TemplateController:getPageTemplates');
    $this->get('/template/region-templates', '\App\Http\Controllers\TemplateController:getRegionTemplates');
    $this->get('/template/navigation-templates', '\App\Http\Controllers\TemplateController:getNavigationTemplates');
    $this->get('/template/report-templates', '\App\Http\Controllers\TemplateController:getReportTemplates');
    $this->get('/template/report-link-templates', '\App\Http\Controllers\TemplateController:getReportLinkTemplates');
    $this->get('/template/detail-view-templates', '\App\Http\Controllers\TemplateController:getDetailViewTemplates');
    $this->get('/template/form-templates', '\App\Http\Controllers\TemplateController:getFormTemplates');
    $this->get('/template/tabularform-templates', '\App\Http\Controllers\TemplateController:getTabularFormTemplates');
    $this->get('/template/button-templates', '\App\Http\Controllers\TemplateController:getButtonTemplates');
    $this->get('/template/textarea-templates', '\App\Http\Controllers\TemplateController:getTextareaTemplates');
    $this->get('/template/drop-down-templates', '\App\Http\Controllers\TemplateController:getDropDownTemplates');
    $this->get('/template/tabularform-button-templates', '\App\Http\Controllers\TemplateController:getTabularFormButtonTemplates');
    $this->get('/template/input-templates/{inputType}', '\App\Http\Controllers\TemplateController:getInputTemplates');
    $this->get('/template/combo-box-templates', '\App\Http\Controllers\TemplateController:getComboBoxTemplates');
    $this->get('/template/calender-templates', '\App\Http\Controllers\TemplateController:getCalenderTemplates');

    $this->get('/page/pages/{applicationId}', '\App\Http\Controllers\PageController:getPages');
    $this->post('/page/page/save', '\App\Http\Controllers\PageController:savePage');
    $this->get('/page/page/{id}', '\App\Http\Controllers\PageController:getPage');
    $this->post('/page/page/{id}/delete', '\App\Http\Controllers\PageController:deletePage');

    $this->get('/navigation/navigations/{applicationId}', '\App\Http\Controllers\NavigationController:getNavigations');
    $this->post('/navigation/navigation/save', '\App\Http\Controllers\NavigationController:saveNavigation');
    $this->get('/navigation/navigation/{id}', '\App\Http\Controllers\NavigationController:getNavigation');
    $this->post('/navigation/navigation/{id}/delete', '\App\Http\Controllers\NavigationController:deleteNavigation');

    $this->get('/navigation/navigation/{id}/items', '\App\Http\Controllers\NavigationController:getNavigationItems');
    $this->get('/navigation/navigation/item/{id}', '\App\Http\Controllers\NavigationController:getNavigationItem');
    $this->post('/navigation/navigation/item/{id}/delete', '\App\Http\Controllers\NavigationController:deleteNavigationItem');
    $this->post('/navigation/navigation/item/save', '\App\Http\Controllers\NavigationController:saveNavigationItem');

    $this->get('/region/page/{pageId}/regions', '\App\Http\Controllers\RegionController:getDisplayPointsWithRegions');
    $this->get('/region/region/{id}', '\App\Http\Controllers\RegionController:getRegion');
    $this->post('/region/region/{id}/delete', '\App\Http\Controllers\RegionController:deleteRegion');
    $this->post('/region/region/html/save', '\App\Http\Controllers\RegionController:saveHtmlRegion');
    $this->post('/region/region/navigation/save', '\App\Http\Controllers\RegionController:saveNavigationRegion');
    $this->post('/region/region/report/save', '\App\Http\Controllers\RegionController:saveReportRegion');
    $this->post('/region/region/report-and-detailview/save', '\App\Http\Controllers\RegionController:saveReportAndDetailViewRegion');
    $this->post('/region/region/report-and-form/save', '\App\Http\Controllers\RegionController:saveReportAndFormRegion');
    $this->post('/region/region/form/save', '\App\Http\Controllers\RegionController:saveFormRegion');
    $this->post('/region/region/tabularform/save', '\App\Http\Controllers\RegionController:saveTabularFormRegion');
  })->add(new AuthMiddleware($this->getContainer()));

})->add(new ApiMiddleware($app->getContainer()));