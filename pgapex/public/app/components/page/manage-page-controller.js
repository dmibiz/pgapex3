'use strict';
(function (window) {
  var angular = window.angular;
  var module = angular.module('pgApexApp.page');

  function ManagePageController($scope, $location, $routeParams, pageService, templateService, databaseService, formErrorService, helperService) {
    this.$scope = $scope;
    this.$location = $location;
    this.$routeParams = $routeParams;
    this.pageService = pageService;
    this.templateService = templateService;
    this.databaseService = databaseService;
    this.formErrorService = formErrorService;
    this.$scope.helper = helperService;

    this.init();
  }

  ManagePageController.prototype.init = function() {
    this.$scope.mode = this.isCreatePage() ? 'create' : 'edit';
    this.$scope.templates = [];
    this.$scope.page = {};
    this.$scope.formError = this.formErrorService.empty();

    this.$scope.savePage = this.savePage.bind(this);

    this.initPageTemplates();
    this.loadPage();
  };

  ManagePageController.prototype.isCreatePage = function() {
    return this.$location.path().endsWith('/create');
  };

  ManagePageController.prototype.isEditPage = function() {
    return this.$location.path().endsWith('/edit');
  };

  ManagePageController.prototype.initPageTemplates = function() {
    this.templateService.getPageTemplates().then(function (response) {
      this.$scope.templates = response.getDataOrDefault([]);
    }.bind(this));
  };

  ManagePageController.prototype.getApplicationId = function() {
    return this.$routeParams.applicationId ? parseInt(this.$routeParams.applicationId) : null;
  };
  
  ManagePageController.prototype.getPageId = function() {
    return this.$routeParams.pageId ? parseInt(this.$routeParams.pageId) : null;
  };

  ManagePageController.prototype.savePage = function() {
    this.pageService.savePage(
      this.getApplicationId(),
      this.getPageId(),
      this.$scope.page.title,
      this.$scope.page.alias || null,
      this.$scope.page.template,
      this.$scope.page.isHomepage || false,
      this.$scope.page.isAuthenticationRequired || false
    ).then(this.handleSaveResponse.bind(this));
  };

  ManagePageController.prototype.handleSaveResponse = function(response) {
    if (!response.hasErrors()) {
      this.$location.path('/application-builder/app/' + this.getApplicationId() + '/pages');
      return;
    } else {
      this.$scope.formError = this.formErrorService.parseApiResponse(response);
    }
  };

  ManagePageController.prototype.loadPage = function() {
    if (!this.isEditPage()) { return; }
    this.pageService.getPage(this.getPageId()).then(function (response) {
      this.$scope.page = response.getDataOrDefault({'attributes': {}}).attributes;
    }.bind(this));
  };

  function init() {
    module.controller('pgApexApp.page.ManagePageController',
      ['$scope', '$location', '$routeParams', 'pageService',
      'templateService','databaseService', 'formErrorService', 'helperService', ManagePageController]);
  }

  init();
})(window);