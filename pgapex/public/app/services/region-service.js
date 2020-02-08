'use strict';
(function (window) {
  var angular = window.angular;
  var module = angular.module('pgApexApp');

  function RegionService(apiService) {
    this.apiService = apiService;
  }

  RegionService.prototype.getDisplayPointsWithRegions = function (pageId) {
    return this.apiService.get('region/page/' + pageId + '/regions');
  };

  RegionService.prototype.getRegion = function (regionId) {
    return this.apiService.get('region/region/' + regionId);
  };

  RegionService.prototype.deleteRegion = function (regionId) {
    return this.apiService.post('region/region/' + regionId + '/delete');
  };

  // DEPRECATED
  RegionService.prototype.getHtmlRegion = function (regionId) {
    return this.apiService.get('api/region/html-region.json', {"regionId": regionId});
  };

  // DEPRECATED
  RegionService.prototype.getNavigationRegion = function (regionId) {
    return this.apiService.get('api/region/navigation-region.json', {"regionId": regionId});
  };

  // DEPRECATED
  RegionService.prototype.getReportRegion = function (regionId) {
    return this.apiService.get('api/region/report-region.json', {"regionId": regionId});
  };

  // DEPRECATED
  RegionService.prototype.getFormRegion = function (regionId) {
    return this.apiService.get('api/region/form-region.json', {"regionId": regionId});
  };

  RegionService.prototype.sortDisplayPointsWithRegions = function(displayPointsWithRegions) {
    displayPointsWithRegions.forEach(function(displayPoint) {
      displayPoint.attributes.regions = displayPoint.attributes.regions.sort(function(firstItem, secondItem) {
        return firstItem.attributes.sequence - secondItem.attributes.sequence;
      });
    });
  };

  RegionService.prototype.saveHtmlRegion = function (pageId, pageTemplateDisplayPointId, regionId, name, sequence, regionTemplate, isVisible, content) {
    var attributes = {
      "regionId": regionId,
      "pageId": pageId,
      "regionTemplate": regionTemplate,
      "pageTemplateDisplayPointId": pageTemplateDisplayPointId,
      "name": name,
      "sequence": sequence,
      "isVisible": isVisible,
      "content": content
    };
    var request = this.apiService.createApiRequest()
      .setAttributes(attributes)
      .getRequest();
    return this.apiService.post('region/region/html/save', request);
  };

  RegionService.prototype.saveNavigationRegion = function (pageId, pageTemplateDisplayPointId, regionId, name, sequence, regionTemplate, isVisible,
                                                          navigationTemplate, navigationType, navigation, repeatLastLevel) {
    var attributes = {
      "regionId": regionId,
      "pageId": pageId,
      "regionTemplate": regionTemplate,
      "pageTemplateDisplayPointId": pageTemplateDisplayPointId,
      "name": name,
      "sequence": sequence,
      "isVisible": isVisible,
      "navigationTemplate": navigationTemplate,
      "navigationType": navigationType,
      "navigation": navigation,
      "repeatLastLevel": repeatLastLevel
    };
    var request = this.apiService.createApiRequest()
      .setAttributes(attributes)
      .getRequest();
    return this.apiService.post('region/region/navigation/save', request);
  };

  RegionService.prototype.saveReportRegion = function (pageId, pageTemplateDisplayPointId, regionId, name, sequence, regionTemplate, isVisible,
                                                        reportTemplate, viewSchema, viewName, showHeader, itemsPerPage,
                                                        paginationQueryParameter, reportColumns) {
    var attributes = {
      "regionId": regionId,
      "pageId": pageId,
      "regionTemplate": regionTemplate,
      "pageTemplateDisplayPointId": pageTemplateDisplayPointId,
      "name": name,
      "sequence": sequence,
      "isVisible": isVisible,

      "reportTemplate": reportTemplate,
      "viewSchema": viewSchema,
      "viewName": viewName,
      "showHeader": showHeader,
      "itemsPerPage": itemsPerPage,
      "paginationQueryParameter": paginationQueryParameter,
      "reportColumns": reportColumns
    };
    var request = this.apiService.createApiRequest()
      .setAttributes(attributes)
      .getRequest();
    return this.apiService.post('region/region/report/save', request);
  };

  RegionService.prototype.saveReportAndDetailViewRegion = function (viewSchema, viewName, uniqueId, reportRegionId,
                                                                    reportName, reportSequence, reportRegionTemplate,
                                                                    reportIsVisible, reportTemplate, reportShowHeader,
                                                                    reportItemsPerPage, reportPaginationQueryParameter,
                                                                    reportPageId, detailViewRegionId, detailViewName,
                                                                    detailViewSequence, detailViewRegionTemplate,
                                                                    detailViewIsVisible, detailViewTemplate, detailViewPageId,
                                                                    reportIncludeEntityCreateButton, reportCreateEntityButtonLabel,
                                                                    reportCreateEntityPageId,
                                                                    reportColumns, detailViewColumns, pageTemplateDisplayPointId,
                                                                    subRegions, addReportColumnsFormName, addDetailViewColumnsFormName) {
                                                                    
    var attributes = {
      'viewSchema': viewSchema,
      'viewName': viewName,
      'uniqueId': uniqueId,
      'reportRegionId': reportRegionId,
      'reportName': reportName,
      'reportSequence': reportSequence,
      'reportRegionTemplate': reportRegionTemplate,
      'reportIsVisible': reportIsVisible,
      'reportTemplate': reportTemplate,
      'reportShowHeader': reportShowHeader,
      'reportItemsPerPage': reportItemsPerPage,
      'reportPaginationQueryParameter': reportPaginationQueryParameter,
      'reportPageId': reportPageId,
      'detailViewRegionId': detailViewRegionId,
      'detailViewName': detailViewName,
      'detailViewSequence': detailViewSequence,
      'detailViewRegionTemplate': detailViewRegionTemplate,
      'detailViewIsVisible': detailViewIsVisible,
      'detailViewTemplate': detailViewTemplate,
      'detailViewPageId': detailViewPageId,
      'reportColumns': reportColumns,
      'detailViewColumns': detailViewColumns,
      'pageTemplateDisplayPointId': pageTemplateDisplayPointId,
      'subRegions': subRegions,
      'addReportColumnsFormName': addReportColumnsFormName,
      'addDetailViewColumnsFormName': addDetailViewColumnsFormName,
      'reportIncludeEntityCreateButton': reportIncludeEntityCreateButton,
      'reportCreateEntityButtonLabel': reportCreateEntityButtonLabel,
      'reportCreateEntityPageId': reportCreateEntityPageId
    };

    var request = this.apiService.createApiRequest()
      .setAttributes(attributes)
      .getRequest();

    return this.apiService.post('region/region/report-and-detailview/save', request);
  };

  RegionService.prototype.saveReportAndFormRegion = function(viewSchema, viewName, uniqueId, reportRegionId,
                                                        reportName, reportSequence, reportRegionTemplate,
                                                        reportIsVisible, reportTemplate, reportShowHeader,
                                                        reportItemsPerPage, reportPaginationQueryParameter,
                                                        reportPageId, reportIncludeEntityCreateButton, reportCreateEntityButtonLabel,
                                                        reportCreateEntityPageId, formPageId, reportColumns, pageTemplateDisplayPointId,
                                                        subRegions, addReportColumnsFormName) {
    var attributes = {
      'viewSchema': viewSchema,
      'viewName': viewName,
      'uniqueId': uniqueId,
      'reportRegionId': reportRegionId,
      'reportName': reportName,
      'reportSequence': reportSequence,
      'reportRegionTemplate': reportRegionTemplate,
      'reportIsVisible': reportIsVisible,
      'reportTemplate': reportTemplate,
      'reportShowHeader': reportShowHeader,
      'reportItemsPerPage': reportItemsPerPage,
      'reportPaginationQueryParameter': reportPaginationQueryParameter,
      'reportPageId': reportPageId,
      'reportColumns': reportColumns,
      'pageTemplateDisplayPointId': pageTemplateDisplayPointId,
      'subRegions': subRegions,
      'addReportColumnsFormName': addReportColumnsFormName,
      'reportIncludeEntityCreateButton': reportIncludeEntityCreateButton,
      'reportCreateEntityButtonLabel': reportCreateEntityButtonLabel,
      'reportCreateEntityPageId': reportCreateEntityPageId,
      'formPageId': formPageId
    };

    console.log(attributes);
    var request = this.apiService.createApiRequest()
      .setAttributes(attributes)
      .getRequest();

    return this.apiService.post('region/region/report-and-form/save', request);
  }

  RegionService.prototype.saveFormRegion = function (pageId, pageTemplateDisplayPointId, regionId, name, sequence, regionTemplate, isVisible,
                                                        formTemplate, buttonTemplate, buttonLabel, successMessage,
                                                        errorMessage, redirectUrl, functionSchema, functionName, formPreFill,
                                                        formFields, preFill, subRegions) {
    var attributes = {
      "pageId": pageId,
      "pageTemplateDisplayPointId": pageTemplateDisplayPointId,
      "regionId": regionId,
      "name": name,
      "sequence": sequence,
      "regionTemplate": regionTemplate,
      "isVisible": isVisible,
      "formTemplate": formTemplate,
      "buttonTemplate": buttonTemplate,
      "buttonLabel": buttonLabel,
      "successMessage": successMessage,
      "errorMessage": errorMessage,
      "redirectUrl": redirectUrl,
      "functionSchema": functionSchema,
      "functionName": functionName,
      "formPreFill": formPreFill,
      "formFields": formFields,
      "preFill": preFill,
      "subRegions": subRegions
    };
    var request = this.apiService.createApiRequest()
      .setAttributes(attributes)
      .getRequest();
    
    return this.apiService.post('region/region/form/save', request);
  };
  
  RegionService.prototype.saveTabularFormRegion = function (pageId, pageTemplateDisplayPointId, regionId, regionTemplate,
                                                            name, sequence, isVisible, tabularFormTemplate, viewSchema,
                                                            viewName, showHeader, itemsPerPage,
                                                            paginationQueryParameter, uniqueId, tabularFormColumns,
                                                            tabularFormButtons, addTabularFormColumnsFormName) {
    var attributes = {
      "pageId": pageId,
      "pageTemplateDisplayPointId": pageTemplateDisplayPointId,
      "regionId": regionId,
      "regionTemplate": regionTemplate,
      "name": name,
      "sequence": sequence,
      "isVisible": isVisible,
      "tabularFormTemplate": tabularFormTemplate,
      "viewSchema": viewSchema,
      "viewName": viewName,
      "showHeader": showHeader,
      "itemsPerPage": itemsPerPage,
      "paginationQueryParameter": paginationQueryParameter,
      "uniqueId": uniqueId,
      "tabularFormColumns": tabularFormColumns,
      "tabularFormButtons": tabularFormButtons,
      "addTabularFormColumnsFormName": addTabularFormColumnsFormName
    };

    var request = this.apiService.createApiRequest()
      .setAttributes(attributes)
      .getRequest();

    return this.apiService.post('region/region/tabularform/save', request);
  };

  function init() {
    module.service('regionService', ['apiService', RegionService]);
  }

  init();
})(window);