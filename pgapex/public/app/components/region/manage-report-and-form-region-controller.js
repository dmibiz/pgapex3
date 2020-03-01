'use strict';
(function (window) {
  var module = window.angular.module('pgApexApp.page');

  function ManageReportAndFormRegionController($scope, $location, $routeParams, regionService, pageService,
                                            templateService, databaseService, formErrorService, helperService) {
    this.$scope = $scope;
    this.$location = $location;
    this.$routeParams = $routeParams;
    this.regionService = regionService;
    this.pageService = pageService;
    this.templateService = templateService;
    this.databaseService = databaseService;
    this.formErrorService = formErrorService;
    this.$scope.helper = helperService;

    this.init();
  }

  ManageReportAndFormRegionController.prototype.init = function () {
    this.$scope.detailViewAppId = this.getApplicationId();

    this.$scope.region = {
      'reportSequence': 1,
      'reportShowHeader': true,
      'reportIncludeEntityCreateButton': false,
      'reportItemsPerPage': 15,
      'reportColumns': [],
      'detailViewSequence': 1,
      'detailViewColumns': [],
      'subRegions': [],
      'reportPaginationQueryParameter': 'report_for_detail_view_page'
    };

    this.$scope.mode = this.isCreatePage() ? 'create' : 'edit';
    this.$scope.changeViewColumns = this.changeViewColumns.bind(this);
    this.$scope.saveRegion = this.saveRegion.bind(this);
    this.$scope.formError = this.formErrorService.empty();

    this.$scope.trackView = function(view) {
      if (!view || !view.attributes) { return view; }
      return view.attributes.schema + '.' + view.attributes.name;
    }.bind(this);

    this.initViewsWithColumns();
    this.initRegionTemplates();
    this.initReportLinkTemplates();
    this.initDetailViewTemplates();
    this.initAvailablePages();
  };

  ManageReportAndFormRegionController.prototype.getApplicationId = function() {
    return this.$routeParams.applicationId ? parseInt(this.$routeParams.applicationId) : null;
  };

  ManageReportAndFormRegionController.prototype.isCreatePage = function () {
    return this.$location.path().endsWith('/create');
  };

  ManageReportAndFormRegionController.prototype.isEditPage = function() {
    return this.$location.path().endsWith('/edit');
  };

  ManageReportAndFormRegionController.prototype.initViewsWithColumns = function() {
    this.databaseService.getViewsWithColumns(this.$scope.detailViewAppId).then(function (response) {
      this.$scope.viewsWithColumns = response.getDataOrDefault([]);
      this.setViewColumns();

      this.loadRegion();
    }.bind(this));
  };

  ManageReportAndFormRegionController.prototype.initRegionTemplates = function() {
    this.templateService.getRegionTemplates().then(function (response) {
      this.$scope.regionTemplates = response.getDataOrDefault([]);
    }.bind(this));
  };

  ManageReportAndFormRegionController.prototype.initReportLinkTemplates = function() {
    this.templateService.getReportLinkTemplates().then(function (response) {
      this.$scope.reportTemplates = response.getDataOrDefault([]);
    }.bind(this));
  };

  ManageReportAndFormRegionController.prototype.initDetailViewTemplates = function() {
    this.templateService.getDetailViewTemplates().then(function (response) {
      this.$scope.detailViewTemplates = response.getDataOrDefault([]);
    }.bind(this));
  };

  ManageReportAndFormRegionController.prototype.initAvailablePages = function() {
    this.pageService.getPages(this.$scope.detailViewAppId).then(function (response) {
      this.$scope.pages = response.getDataOrDefault([]);
    }.bind(this));
  };

  ManageReportAndFormRegionController.prototype.changeViewColumns = function() {
    this.setViewColumns();
    this.resetUniqueIdSelection();
    this.resetColumnsSelection();
  };

  ManageReportAndFormRegionController.prototype.setViewColumns = function() {
    if (!this.$scope.region.view) { return; }
    var view = this.$scope.viewsWithColumns.filter(function (view) {
      return view.attributes.schema === this.$scope.region.view.attributes.schema &&
        view.attributes.name === this.$scope.region.view.attributes.name;
    }.bind(this));
    if (view.length > 0) {
      this.$scope.viewColumns = view[0].attributes.columns;
    }
  };

  ManageReportAndFormRegionController.prototype.resetUniqueIdSelection = function() {
    this.$scope.region.uniqueId = '';
  };

  ManageReportAndFormRegionController.prototype.resetColumnsSelection = function() {
    this.$scope.region.reportColumns.forEach(function (reportColumn) {
      if (reportColumn.attributes.type === 'COLUMN')  {
        reportColumn.attributes.column = '';
      }
    });

    this.$scope.region.detailViewColumns.forEach(function (reportColumn) {
      if (reportColumn.attributes.type === 'COLUMN')  {
        reportColumn.attributes.column = '';
      }
    });
  };

  ManageReportAndFormRegionController.prototype.getRegionId = function() {
    return this.$routeParams.regionId ? parseInt(this.$routeParams.regionId) : null;
  };

  ManageReportAndFormRegionController.prototype.getPageId = function() {
    return this.$routeParams.pageId ? parseInt(this.$routeParams.pageId) : null;
  };

  ManageReportAndFormRegionController.prototype.getDisplayPoint = function() {
    return this.$routeParams.displayPoint ? parseInt(this.$routeParams.displayPoint) : null;
  };

  ManageReportAndFormRegionController.prototype.getReportColumns = function() {
    return this.$scope.region.reportColumns.map(function(reportColumn) {
      if (reportColumn.attributes.type === 'COLUMN') {
        return {
          'type': 'report-column',
          'attributes': {
            'type': reportColumn.attributes.type,
            'column': reportColumn.attributes.column,
            'heading': reportColumn.attributes.heading,
            'isTextEscaped': reportColumn.attributes.isTextEscaped || false,
            'sequence': reportColumn.attributes.sequence
          }
        };
      } else {
        return {
          'type': 'report-column',
          'attributes': {
            'type': reportColumn.attributes.type,
            'heading': reportColumn.attributes.heading,
            'isTextEscaped': reportColumn.attributes.isTextEscaped || false,
            'sequence': reportColumn.attributes.sequence,
            'linkText': reportColumn.attributes.linkText,
            'linkUrl': reportColumn.attributes.linkUrl,
            'linkAttributes': reportColumn.attributes.linkAttributes || null
          }
        };
      }
    });
  };

  ManageReportAndFormRegionController.prototype.getDetailViewColumns = function() {
    return this.$scope.region.detailViewColumns.map(function(detailViewColumn) {
      if (detailViewColumn.attributes.type === 'COLUMN') {
        return {
          'type': 'detailview-column',
          'attributes': {
            'type': detailViewColumn.attributes.type,
            'column': detailViewColumn.attributes.column,
            'heading': detailViewColumn.attributes.heading,
            'isTextEscaped': detailViewColumn.attributes.isTextEscaped || false,
            'sequence': detailViewColumn.attributes.sequence
          }
        };
      } else {
        return {
          'type': 'detailview-column',
          'attributes': {
            'type': detailViewColumn.attributes.type,
            'heading': detailViewColumn.attributes.heading,
            'isTextEscaped': detailViewColumn.attributes.isTextEscaped || false,
            'sequence': detailViewColumn.attributes.sequence,
            'linkText': detailViewColumn.attributes.linkText,
            'linkUrl': detailViewColumn.attributes.linkUrl,
            'linkAttributes': detailViewColumn.attributes.linkAttributes || null
          }
        };
      }
    });
  };

  function getSubReportColumns(subRegion) {
    return subRegion.columns.map(function(column) {
      if (column.attributes.type === 'COLUMN') {
        return {
          'type': 'subreport-column',
          'attributes': {
            'type': column.attributes.type,
            'column': column.attributes.column,
            'heading': column.attributes.heading,
            'isTextEscaped': column.attributes.isTextEscaped || false,
            'sequence': column.attributes.sequence
          }
        };
      } else {
        return {
          'type': 'subreport-column',
          'attributes': {
            'type': column.attributes.type,
            'heading': column.attributes.heading,
            'isTextEscaped': column.attributes.isTextEscaped || false,
            'sequence': column.attributes.sequence,
            'linkText': column.attributes.linkText,
            'linkUrl': column.attributes.linkUrl,
            'linkAttributes': column.attributes.linkAttributes || null
          }
        };
      }
    });
  }

  ManageReportAndFormRegionController.prototype.getSubRegions = function() {
    return this.$scope.region.subRegions.map(function (subRegion) {
      if (subRegion.type === 'SUBREPORT') {
        return {
          'type': subRegion.type,
          'attributes': {
            'subRegionId': subRegion.subRegionId || null,
            'subRegionTemplateId': 21,
            'name': subRegion.name,
            'sequence': subRegion.sequence,
            'isVisible': true,
            'paginationQueryParameter': subRegion.paginationQueryParameter,
            'parentRegionId': subRegion.parentRegionId || null,
            'reportTemplateId': 6,
            'viewSchema': subRegion.view.attributes.schema,
            'viewName': subRegion.view.attributes.name,
            'itemsPerPage': subRegion.itemsPerPage,
            'showHeader': true,
            'linkedColumn': subRegion.linkedColumn,
            'columns': getSubReportColumns(subRegion),
            'addSubregionFormName': 'subreport/' + subRegion.index
          }
        };
      } else {
        return null;
      }
    });
  };

  ManageReportAndFormRegionController.prototype.saveRegion = function () {
    this.regionService.saveReportAndFormRegion(
      this.$scope.region.view.attributes.schema,
      this.$scope.region.view.attributes.name,
      this.$scope.region.uniqueId,
      this.$scope.region.reportRegionId || null,
      this.$scope.region.reportName,
      this.$scope.region.reportSequence,
      this.$scope.region.reportRegionTemplate,
      this.$scope.region.reportIsVisible,
      this.$scope.region.reportTemplate,
      this.$scope.region.reportShowHeader,
      this.$scope.region.reportItemsPerPage,
      this.$scope.region.reportPaginationQueryParameter,
      this.$scope.region.reportPageId || this.getPageId(),
      this.$scope.region.reportIncludeEntityCreateButton,
      this.$scope.region.reportCreateEntityButtonLabel,
      this.$scope.region.reportCreateEntityPageId,
      this.$scope.region.formPageId,
      this.getReportColumns(),
      this.getDisplayPoint(),
      this.getSubRegions(),
      'reportColumns'
    ).then(this.handleSaveResponse.bind(this));
  };

  ManageReportAndFormRegionController.prototype.handleSaveResponse = function(response) {
    if (!response.hasErrors()) {
      this.$location.path('/application-builder/app/' + this.getApplicationId() + '/pages/' + this.getPageId() +
        '/regions');
    } else {
      this.$scope.formError = this.formErrorService.parseApiResponse(response);
    }
  };

  ManageReportAndFormRegionController.prototype.setLastSequences = function() {
    var lastSequenceOfReportColumns = Math.max.apply(Math,
      this.$scope.region.reportColumns.map(function (reportColumn) {
        return reportColumn.attributes.sequence;
    }));

    var lastSequenceOfSubRegions = Math.max.apply(Math,
      this.$scope.region.subRegions.map(function (subRegion) {
        return subRegion.sequence;
    }));

    this.$scope.lastSequenceOfReportColumns = isFinite(lastSequenceOfReportColumns) ? lastSequenceOfReportColumns : 0;
    this.$scope.lastSequenceOfSubRegions = isFinite(lastSequenceOfSubRegions) ? lastSequenceOfSubRegions : 0;
  };

  ManageReportAndFormRegionController.prototype.loadRegion = function() {
    if (!this.isEditPage()) { return; }
    this.regionService.getRegion(this.getRegionId()).then(function (response) {
      var region = response.getDataOrDefault({'attributes': {}});
      region.view = {'attributes': {'schema': region.viewSchema, 'name': region.viewName}};
      this.$scope.region = region;

      if (this.$scope.region.reportColumns === null) {
        this.$scope.region.reportColumns = [];
      }

      this.setLastSequences();
      this.setViewColumns();
    }.bind(this));
  };

  function init() {
    module.controller('pgApexApp.region.ManageReportAndFormRegionController', ['$scope', '$location', '$routeParams',
      'regionService', 'pageService', 'templateService', 'databaseService', 'formErrorService', 'helperService',
      ManageReportAndFormRegionController]);
  }

  init();
})(window);