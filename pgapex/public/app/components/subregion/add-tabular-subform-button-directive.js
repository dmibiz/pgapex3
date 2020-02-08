'use strict';
(function (window) {
  var module = window.angular.module('pgApexApp.page');

  function AddTabularSubFormButtonDirective() {
    return {
      scope: {
        buttons: '=',
        functions: '=',
        buttonTemplates: '=',
        formError: '=',
        lastSequence: '=',
        viewColumns: '=',
        title: '@',
        attributeTitle: '@'
      },
      controller: 'pgApexApp.region.AddTabularSubFormButtonController',
      templateUrl: 'app/partials/subregion/add-tabular-subform-button.html',
      restrict: 'E'
    };
  }

  function init() {
    module.directive('addTabularSubFormButton', AddTabularSubFormButtonDirective);
  }

  init();
})(window);