'use strict';
(function (window) {
  var angular = window.angular;
  var module = angular.module('pgApexApp');

  function TemplateService(apiService) {
    this.apiService = apiService;
  }

  // Deprecated
  TemplateService.prototype.getTemplates = function (themeId) {
    return this.apiService.get('api/template/templates.json', {"themeId" : themeId});
  };

  // Deprecated
  TemplateService.prototype.getThemes = function (applicationId) {
    return this.apiService.get('api/template/themes.json', {"applicationId": applicationId});
  };

  TemplateService.prototype.getLoginTemplates = function () {
    return this.apiService.get('template/login-templates');
  };

  TemplateService.prototype.getPageTemplates = function () {
    return this.apiService.get('template/page-templates');
  };

  TemplateService.prototype.getRegionTemplates = function () {
    return this.apiService.get('template/region-templates');
  };

  TemplateService.prototype.getNavigationTemplates = function () {
    return this.apiService.get('template/navigation-templates');
  };

  TemplateService.prototype.getReportTemplates = function () {
    return this.apiService.get('template/report-templates');
  };

  TemplateService.prototype.getReportLinkTemplates = function () {
    return this.apiService.get('template/report-link-templates');
  };

  TemplateService.prototype.getDetailViewTemplates = function () {
    return this.apiService.get('template/detail-view-templates');
  };

  TemplateService.prototype.getFormTemplates = function () {
    return this.apiService.get('template/form-templates');
  };

  TemplateService.prototype.getTabularFormTemplates = function() {
    return this.apiService.get('template/tabularform-templates');
  };

  TemplateService.prototype.getButtonTemplates = function () {
    return this.apiService.get('template/button-templates');
  };

  TemplateService.prototype.getTextInputTemplates = function () {
    return this.apiService.get('template/input-templates/text');
  };

  TemplateService.prototype.getPasswordInputTemplates = function () {
    return this.apiService.get('template/input-templates/password');
  };

  TemplateService.prototype.getCheckboxInputTemplates = function () {
    return this.apiService.get('template/input-templates/checkbox');
  };

  TemplateService.prototype.getRadioInputTemplates = function () {
    return this.apiService.get('template/input-templates/radio');
  };

  TemplateService.prototype.getTextareaTemplates = function () {
    return this.apiService.get('template/textarea-templates');
  };

  TemplateService.prototype.getDropDownTemplates = function () {
    return this.apiService.get('template/drop-down-templates');
  };

  TemplateService.prototype.getTabularFormButtonTemplates = function () {
    return this.apiService.get('template/tabularform-button-templates');
  };

  TemplateService.prototype.getComboBoxTemplates = function () {
    return this.apiService.get('template/combo-box-templates');
  }

  TemplateService.prototype.getCalendarTemplates = function() {
    return this.apiService.get('template/calendar-templates')
  }

  function init() {
    module.service('templateService', ['apiService', TemplateService]);
  }

  init();
})(window);