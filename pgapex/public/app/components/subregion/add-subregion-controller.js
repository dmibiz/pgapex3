'use strict';
(function (window) {
  var module = window.angular.module('pgApexApp.page');

  function AddSubRegionController($scope, databaseService, regionService, helperService) {
    this.$scope = $scope;
    this.databaseService = databaseService;
    this.regionService = regionService;
    this.$scope.helper = helperService;
    this.init();
  }

  AddSubRegionController.prototype.init = function () {
    this.$scope.addSubRegion = this.addSubRegion.bind(this);
    this.$scope.deleteSubRegion = this.deleteSubRegion.bind(this);

    this.initViewsWithColumns();
  };

  AddSubRegionController.prototype.addSubRegion = function (type) {
    this.$scope.lastSequence++;
    var newSubRegion = {'type': type, 'view': {'attributes': {}}, 'sequence': this.$scope.lastSequence};
    if (type === 'SUBREPORT') newSubRegion.columns = [];
    if (type === 'TABULAR_SUBFORM') {
      newSubRegion.buttons = [];
      newSubRegion.formColumns = [];
      newSubRegion.includeLinkedPage = false;
    }
    this.$scope.subRegions.push(newSubRegion);
  };

  AddSubRegionController.prototype.deleteSubRegion = function (position) {
    this.$scope.subRegions.splice(position, 1);
  };

  AddSubRegionController.prototype.initViewsWithColumns = function() {
    this.databaseService.getViewsWithColumns(this.$scope.applicationId).then(function (response) {
      this.$scope.viewsWithColumns = response.getDataOrDefault([]);
    }.bind(this));
  };

  function init() {
    module.controller('pgApexApp.region.AddSubRegionController', ['$scope', 'databaseService', 'regionService',
      'helperService', AddSubRegionController]);
  }

  init();
})(window);