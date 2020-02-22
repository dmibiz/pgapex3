'use strict';
(function (window) {
  var module = window.angular.module('pgApexApp.page');

  function AddTabularSubFormDirective() {
    return {
      scope: {
        viewsWithColumns: '=',
        tabularSubForm: '=',
        formError: '=',
        mode: '=',
        index: '=',
        preFillColumns: '=',
        functions: '=',
        pages: '='
      },
      controller: 'pgApexApp.region.AddTabularSubFormController',
      templateUrl: 'app/partials/subregion/add-tabular-subform.html',
      restrict: 'E'
    };
  }

  function init() {
    module.directive('addTabularSubForm', AddTabularSubFormDirective);
  }

  init();
})(window);