'use strict';
(function (window) {
  var angular = window.angular;

  function routeProviderConfig ($routeProvider) {
    $routeProvider
    .when('/application-builder/app/:applicationId/pages/:pageId/regions', {
      controller: 'pgApexApp.region.RegionsController',
      templateUrl: 'app/partials/region/regions.html'
    })
    .when('/application-builder/app/:applicationId/pages/:pageId/regions/:displayPoint/html/create', {
      controller: 'pgApexApp.region.ManageHtmlRegionController',
      templateUrl: 'app/partials/region/manage-html-region.html'
    })
    .when('/application-builder/app/:applicationId/pages/:pageId/regions/:displayPoint/html/:regionId/edit', {
      controller: 'pgApexApp.region.ManageHtmlRegionController',
      templateUrl: 'app/partials/region/manage-html-region.html'
    })
    .when('/application-builder/app/:applicationId/pages/:pageId/regions/:displayPoint/navigation/create', {
      controller: 'pgApexApp.region.ManageNavigationRegionController',
      templateUrl: 'app/partials/region/manage-navigation-region.html'
    })
    .when('/application-builder/app/:applicationId/pages/:pageId/regions/:displayPoint/navigation/:regionId/edit', {
      controller: 'pgApexApp.region.ManageNavigationRegionController',
      templateUrl: 'app/partials/region/manage-navigation-region.html'
    })
    .when('/application-builder/app/:applicationId/pages/:pageId/regions/:displayPoint/report/create', {
      controller: 'pgApexApp.region.ManageReportRegionController',
      templateUrl: 'app/partials/region/manage-report-region.html'
    })
    .when('/application-builder/app/:applicationId/pages/:pageId/regions/:displayPoint/report/:regionId/edit', {
      controller: 'pgApexApp.region.ManageReportRegionController',
      templateUrl: 'app/partials/region/manage-report-region.html'
    })
    .when('/application-builder/app/:applicationId/pages/:pageId/regions/:displayPoint/form/create', {
      controller: 'pgApexApp.region.ManageFormRegionController',
      templateUrl: 'app/partials/region/manage-form-region.html'
    })
    .when('/application-builder/app/:applicationId/pages/:pageId/regions/:displayPoint/form/:regionId/edit', {
      controller: 'pgApexApp.region.ManageFormRegionController',
      templateUrl: 'app/partials/region/manage-form-region.html'
    })
    .when('/application-builder/app/:applicationId/pages/:pageId/regions/:displayPoint/tabular-form/create', {
      controller: 'pgApexApp.region.ManageTabularFormRegionController',
      templateUrl: 'app/partials/region/manage-tabular-form-region.html'
    })
    .when('/application-builder/app/:applicationId/pages/:pageId/regions/:displayPoint/tabular-form/:regionId/edit', {
      controller: 'pgApexApp.region.ManageTabularFormRegionController',
      templateUrl: 'app/partials/region/manage-tabular-form-region.html'
    })
    .when( '/application-builder/app/:applicationId/pages/:pageId/regions/:displayPoint/report-and-detail-view/create', {
      controller: 'pgApexApp.region.ManageDetailViewRegionController',
      templateUrl: 'app/partials/region/manage-detail-view-region.html'
    })
    .when('/application-builder/app/:applicationId/pages/:pageId/regions/:displayPoint/detail-view/:regionId/edit', {
      controller: 'pgApexApp.region.ManageDetailViewRegionController',
      templateUrl: 'app/partials/region/manage-detail-view-region.html'
    })
    .when( '/application-builder/app/:applicationId/pages/:pageId/regions/:displayPoint/report-for-form/create', {
      controller: 'pgApexApp.region.ManageReportAndFormRegionController',
      templateUrl: 'app/partials/region/manage-report-and-form-region.html'
    })
    .when('/application-builder/app/:applicationId/pages/:pageId/regions/:displayPoint/report-for-form/:regionId/edit', {
      controller: 'pgApexApp.region.ManageReportAndFormRegionController',
      templateUrl: 'app/partials/region/manage-report-and-form-region.html'
    })
    .when('/application-builder/app/:applicationId/pages/:pageId/regions/:displayPoint/report-for-detail-view/:regionId/edit', {
      controller: 'pgApexApp.region.ManageDetailViewRegionController',
      templateUrl: 'app/partials/region/manage-detail-view-region.html'
    });
  }

  function translatePartialLoaderProviderConfig($translatePartialLoaderProvider) {
    $translatePartialLoaderProvider.addPart('region');
  }

  function init() {
    angular
    .module('pgApexApp.region', ['pgApexApp'])
    .config(['$routeProvider', routeProviderConfig])
    .config(['$translatePartialLoaderProvider', translatePartialLoaderProviderConfig]);
  }

  init();
})(window);