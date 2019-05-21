'use strict';
(function (window) {
  let module = window.angular.module('pgApexApp.page');

  function AddSubRegionDirective() {
    return {
      scope: {
        mode: '=',
        subRegions: '=',
        formError: '=',
        applicationId: '=',
        detailViewRegionId: '='
      },
      controller: 'pgApexApp.region.AddSubRegionController',
      templateUrl: 'app/partials/subregion/add-subregion.html',
      restrict: 'E'
    };
  }

  function init() {
    module.directive('addSubRegion', AddSubRegionDirective);
  }

  init();
})(window);