'use strict';
(function (window) {
  var angular = window.angular;
  var module = angular.module('pgApexApp');

  function NavigationController($scope, $location, $routeParams, pageService) {
    this.pageService = pageService;
    var path = $location.path();
    $scope.routeParams = $routeParams;
    $scope.pageTitle = '';

    $scope.isApplicationBuilderPage = function () {
      return path.startsWith('/application-builder');
    }

    $scope.isPagesPage = function () {
      return path.startsWith('/application-builder') && path.contains('/pages');
    }

    $scope.isNavigationsPage = function () {
      return path.startsWith('/application-builder') && path.contains('/navigations');
    }
    this.$scope = $scope;

    this.loadPageTitle();
  }

  function init() {
    module.controller('pgApexApp.NavigationController', ['$scope', '$location', '$routeParams', 'pageService', NavigationController]);
  }

  NavigationController.prototype.getPageId = function() {
    return this.$scope.routeParams.pageId || null;
  };

  NavigationController.prototype.loadPageTitle = function() {
    var pageId = this.getPageId();
    if (pageId) {
      this.pageService.getPage(pageId).then(function (response) {
        var responseData = response.getDataOrDefault([]);
        this.$scope.pageTitle = responseData.attributes.title;
      }.bind(this));
    }
  };

  init();
})(window);