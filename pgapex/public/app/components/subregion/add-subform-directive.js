'use strict';
(function (window) {
  var module = window.angular.module('pgApexApp.page');

  function AddSubFormDirective() {
    return {
      scope: {
        viewsWithColumns: '=',
        subForm: '=',
        formError: '=',
        mode: '=',
        index: '=',
        subFormPreFillColumns: '='
      },
      controller: 'pgApexApp.region.AddSubFormController',
      templateUrl: 'app/partials/subregion/add-subform.html',
      restrict: 'E'
    };
  }

  function init() {
    module.directive('addSubForm', AddSubFormDirective);
  }

  init();
})(window);