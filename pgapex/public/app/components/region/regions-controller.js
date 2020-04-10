 'use strict';
(function (window) {
  var angular = window.angular;
  var module = angular.module('pgApexApp.region');

  function RegionsController($scope, $routeParams, regionService, helperService, pageService) {
    this.$scope = $scope;
    this.$routeParams = $routeParams;
    this.regionService = regionService;
    this.helperService = helperService;
    this.pageService = pageService;

    this.init();
    $scope.deleteRegion = this.deleteRegion.bind(this);
  }

  RegionsController.prototype.init = function() {
    this.$scope.routeParams = this.$routeParams;
    this.$scope.displayPointsWithRegions = [];
    this.$scope.pageTitle = '';

    this.loadDisplayPointsWithRegions();
    this.loadPageTitle();
  };

  RegionsController.prototype.getPageId = function() {
    return this.$routeParams.pageId || null;
  };

  RegionsController.prototype.loadPageTitle = function() {
    this.pageService.getPage(this.getPageId()).then(function (response) {
      var responseData = response.getDataOrDefault([]);
      this.$scope.pageTitle = responseData.attributes.title;
    }.bind(this));
  };

  RegionsController.prototype.loadDisplayPointsWithRegions = function() {
    this.regionService.getDisplayPointsWithRegions(this.getPageId()).then(function (response) {
      this.$scope.displayPointsWithRegions = response.getDataOrDefault([]);
      this.regionService.sortDisplayPointsWithRegions(this.$scope.displayPointsWithRegions);
    }.bind(this));
  };

  RegionsController.prototype.deleteRegion = function(regionId) {
    this.helperService.confirm('region.deleteRegion',
                               'region.areYouSureThatYouWantToDeleteThisRegion',
                               'region.deleteRegion',
                               'region.cancel')
    .result.then(this.sendDeleteRequest(regionId).bind(this));
  };

  RegionsController.prototype.sendDeleteRequest = function(regionId) {
    return function() {
      return this.regionService.deleteRegion(regionId).then(this.loadDisplayPointsWithRegions.bind(this));
    };
  };

  function init() {
    module.controller('pgApexApp.region.RegionsController', [
    '$scope', 
    '$routeParams', 
    'regionService', 
    'helperService', 
    'pageService', 
    RegionsController]);
  }

  init();
})(window);