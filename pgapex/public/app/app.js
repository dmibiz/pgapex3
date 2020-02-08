'use strict';
(function (window) {
  var angular = window.angular;
  var modules = ['pascalprecht.translate', 'frapontillo.bootstrap-duallistbox', 'angular-loading-bar',
                'ui.bootstrap', 'ngRoute', 'pgApexApp.auth', 'pgApexApp.application',
                'pgApexApp.page', 'pgApexApp.template', 'pgApexApp.workspace',
                'pgApexApp.user', 'pgApexApp.navigation', 'pgApexApp.region'];

  function routeProviderConfig ($routeProvider, $locationProvider, $httpProvider) {
    $routeProvider
    .otherwise({ redirectTo: '/application-builder/applications' });

    var interceptor = ['$location', '$q', function($location, $q) {
      return {
        'responseError': function(response) {
          if(response.status === 401) {
            $location.path('/login');
            return $q.reject(response);
          } else {
            return $q.reject(response);
          }
        }
      };
    }];

    $httpProvider.interceptors.push(interceptor);
  }

  function translateProviderConfig ($translateProvider, $translatePartialLoaderProvider) {
    $translateProvider.useLoader('$translatePartialLoader', {
      urlTemplate: 'app/lang/{lang}/{part}.json'
    });
    $translateProvider.useSanitizeValueStrategy(null);
    $translateProvider.preferredLanguage('en');
    $translatePartialLoaderProvider.addPart('general');
  }

  function cfpLoadingBarProviderConfig (cfpLoadingBarProvider) {
    cfpLoadingBarProvider.includeSpinner = false;
  }

  function loadPgApexApplication(angular) {
    angular
    .module('pgApexApp', modules)
    .config(['$routeProvider', '$locationProvider', '$httpProvider', routeProviderConfig])
    .config(['$translateProvider', '$translatePartialLoaderProvider', translateProviderConfig])
    .config(['cfpLoadingBarProvider', cfpLoadingBarProviderConfig])
    .filter('preFillColumnsWithValues', function() {
      return function(formPreFillColumns) {
        return formPreFillColumns.filter(preFillColumn => preFillColumn.value);
      }
    });
  }

  function init() {
    window.document.addEventListener('DOMContentLoaded', (function() {
      loadPgApexApplication(angular);
    })(angular));
  }

  init();

})(window);