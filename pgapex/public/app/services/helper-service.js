'use strict';
(function (window) {
  var angular = window.angular;
  var module = angular.module('pgApexApp');

  function HelperService($uibModal) {
    this.$uibModal = $uibModal;
  }

  HelperService.prototype.confirm = function (title, body, okText, cancelText) {
    return this.$uibModal.open({
      templateUrl: "app/partials/helper/confirmation-modal.html",
      controller: ['$scope', '$uibModalInstance', function($scope, $uibModalInstance) {
        $scope.title = title;
        $scope.body = body;
        $scope.okText = okText;
        $scope.cancelText = cancelText;
        $scope.ok = function() {
          $uibModalInstance.close(true);
        };
        $scope.cancel = function() {
          $uibModalInstance.dismiss(false);
        };
      }]
    });
  };

  HelperService.prototype.info = function (body) {
    return this.$uibModal.open({
      templateUrl: "app/partials/helper/info-modal.html",
      controller: ['$scope', '$uibModalInstance', function($scope, $uibModalInstance) {
        $scope.body = body;
        $scope.ok = function() {
          $uibModalInstance.close(true);
        };
      }]
    });
  };

  HelperService.prototype.calendarFormatInfo = function() {
    return this.$uibModal.open({
      templateUrl: "app/partials/helper/calendar-format-info-modal.html",
      controller: ['$scope', '$uibModalInstance', function($scope, $uibModalInstance) {
        $scope.ok = function() {
          $uibModalInstance.close(true);
        };
      }]
    });
  };

  function init() {
    module.service('helperService', ['$uibModal', HelperService]);
  }

  init();
})(window);