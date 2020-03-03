'use strict';
(function (window) {
  var angular = window.angular;
  var module = angular.module('pgApexApp.page');

  function ManageFormRegionController($scope, $location, $routeParams, regionService,
                                        templateService, databaseService, formErrorService, helperService, pageService) {
    this.$scope = $scope;
    this.$scope.helper = helperService;
    this.$location = $location;
    this.$routeParams = $routeParams;
    this.regionService = regionService;
    this.templateService = templateService;
    this.databaseService = databaseService;
    this.formErrorService = formErrorService;
    this.pageService = pageService;

    this.init();
  }

  ManageFormRegionController.prototype.init = function() {
    this.$scope.mode = this.isCreatePage() ? 'create' : 'edit';
    this.$scope.formError = this.formErrorService.empty();
    this.$scope.region = {
      'sequence': 1,
      'functionParameters': [],
      'formPreFillColumns': [],
      'subRegions': [],
      'function': {'attributes': {'parameters': []}}
    };
    this.$scope.regionTemplates = [];
    this.$scope.formTemplates = [];
    this.$scope.buttonTemplates = [];
    this.$scope.textInputTemplates = [];
    this.$scope.passwordInputTemplates = [];
    this.$scope.radioInputTemplates = [];
    this.$scope.checkboxInputTemplates = [];
    this.$scope.textareaTemplates = [];
    this.$scope.dropDownTemplates = [];
    this.$scope.comboBoxTemplates = [];
    this.$scope.calenderTemplates = [];
    this.$scope.viewsWithColumns = [];
    this.$scope.functionsWithParameters = [];
    this.$scope.region.formPreFillColumns = [];
    this.$scope.applicationId = this.getApplicationId();
    
    this.$scope.changeFunctionParameters = this.changeFunctionParameters.bind(this);
    this.$scope.changeFormPreFillColumns = this.changeFormPreFillColumns.bind(this);
    this.$scope.atLeastOneFormPreFillColumnHasValue = this.atLeastOneFormPreFillColumnHasValue.bind(this);

    this.$scope.trackDatabaseObject = function(databaseObject) {
      if (!databaseObject || !databaseObject.attributes) { return databaseObject; }
      return databaseObject.attributes.schema + '.' + databaseObject.attributes.name;
    };

    this.$scope.getFunctionParameterTemplates = function(functionParameter) {
      if (!functionParameter || !functionParameter.fieldType) { return []; }
      if (functionParameter.fieldType === 'TEXT') { return this.$scope.textInputTemplates; }
      if (functionParameter.fieldType === 'PASSWORD') { return this.$scope.passwordInputTemplates; }
      if (functionParameter.fieldType === 'CHECKBOX') { return this.$scope.checkboxInputTemplates; }
      if (functionParameter.fieldType === 'RADIO') { return this.$scope.radioInputTemplates; }
      if (functionParameter.fieldType === 'TEXTAREA') { return this.$scope.textareaTemplates; }
      if (functionParameter.fieldType === 'DROP_DOWN') { return this.$scope.dropDownTemplates; }
      if (functionParameter.fieldType === "COMBO_BOX") { return this.$scope.comboBoxTemplates; }
      if (functionParameter.fieldType === "CALENDER") { return this.$scope.calenderTemplates; }
      return [];
    }.bind(this);

    this.$scope.saveRegion = this.saveRegion.bind(this);
    
    this.initRegionTemplates();
    this.initFormTemplates();
    this.initButtonTemplates();
    this.initFunctionsWithParameters();
    this.initInputTemplates();
    this.initTextareaTemplates();
    this.initDropDownTemplates();
    this.initComboBoxTemplates();
    this.initCalenderTemplates();
    this.initViewsWithColumns();
    this.initAvailablePages();
    this.loadRegion();
  };

  ManageFormRegionController.prototype.initViewsWithColumns = function() {
    this.databaseService.getViewsWithColumns(this.getApplicationId()).then(function (response) {
      this.$scope.viewsWithColumns = response.getDataOrDefault([]);

    }.bind(this));
  };

  ManageFormRegionController.prototype.initRegionTemplates = function() {
    this.templateService.getRegionTemplates().then(function (response) {
      this.$scope.regionTemplates = response.getDataOrDefault([]);
    }.bind(this));
  };

  ManageFormRegionController.prototype.initFormTemplates = function() {
    this.templateService.getFormTemplates().then(function (response) {
      this.$scope.formTemplates = response.getDataOrDefault([]);
    }.bind(this));
  };

  ManageFormRegionController.prototype.initButtonTemplates = function() {
    this.templateService.getButtonTemplates().then(function (response) {
      this.$scope.buttonTemplates = response.getDataOrDefault([]);
    }.bind(this));
  };

  ManageFormRegionController.prototype.initInputTemplates = function() {
    this.templateService.getTextInputTemplates().then(function (response) {
      this.$scope.textInputTemplates = response.getDataOrDefault([]);
    }.bind(this));
    this.templateService.getPasswordInputTemplates().then(function (response) {
      this.$scope.passwordInputTemplates = response.getDataOrDefault([]);
    }.bind(this));
    this.templateService.getRadioInputTemplates().then(function (response) {
      this.$scope.radioInputTemplates = response.getDataOrDefault([]);
    }.bind(this));
    this.templateService.getCheckboxInputTemplates().then(function (response) {
      this.$scope.checkboxInputTemplates = response.getDataOrDefault([]);
    }.bind(this));
  };

  ManageFormRegionController.prototype.initTextareaTemplates = function() {
    this.templateService.getTextareaTemplates().then(function (response) {
      this.$scope.textareaTemplates = response.getDataOrDefault([]);
    }.bind(this));
  };

  ManageFormRegionController.prototype.initDropDownTemplates = function() {
    this.templateService.getDropDownTemplates().then(function (response) {
      this.$scope.dropDownTemplates = response.getDataOrDefault([]);
    }.bind(this));
  };

  ManageFormRegionController.prototype.initComboBoxTemplates = function() {
    this.templateService.getComboBoxTemplates().then(function (response) {
      this.$scope.comboBoxTemplates = response.getDataOrDefault([]);
    }.bind(this));
  };

  ManageFormRegionController.prototype.initCalenderTemplates = function() {
    this.templateService.getCalenderTemplates().then(function (response) {
      this.$scope.calenderTemplates = response.getDataOrDefault([]);
    }.bind(this));
  };

  ManageFormRegionController.prototype.initFunctionsWithParameters = function() {
    this.databaseService.getFunctionsWithParameters(this.getApplicationId()).then(function (response) {
      var functionsWithParameters = response.getDataOrDefault([]);
      functionsWithParameters.forEach(function (functionWithParameters) {
        functionWithParameters.attributes.parameters.sort(function(firstParameter, secondParameter) {
          return firstParameter.attributes.ordinalPosition - secondParameter.attributes.ordinalPosition;
        });
      });
      functionsWithParameters.forEach(function(functionWithParameters) {
        this.addDisplayTextToFunction(functionWithParameters);
      }.bind(this));
      this.$scope.functionsWithParameters = functionsWithParameters;
    }.bind(this));
  };

  ManageFormRegionController.prototype.addDisplayTextToFunction = function(functionWithParameters) {
    var displayText = functionWithParameters.attributes.schema;
    displayText += '.';
    displayText += functionWithParameters.attributes.name;
    displayText += '(';
    displayText += functionWithParameters.attributes.parameters.map(function(parameter) {
      return [parameter.attributes.name, parameter.attributes.argumentType].join(' ');
    }).join(', ');
    displayText += ')';
    functionWithParameters.attributes.displayText = displayText;
  };

  ManageFormRegionController.prototype.changeFunctionParameters = function() {
    this.$scope.region.functionParameters = this.$scope.region.function.attributes.parameters;
  };

  ManageFormRegionController.prototype.changeFormPreFillColumns = function() {
    var view = this.$scope.region.formPreFillView;
    this.$scope.region.formPreFillColumns = [];
    if (view.attributes.columns) {
      view.attributes.columns.forEach(function(column) {
        this.$scope.region.formPreFillColumns.push({'column': column, 'value': ''});
      }.bind(this));
    }
  };

  ManageFormRegionController.prototype.atLeastOneFormPreFillColumnHasValue = function() {
    var columns = this.$scope.region.formPreFillColumns;
    if (columns === null) {
      return false;
    }
    for(var i = 0; i < columns.length; i++) {
      if (columns[i].value !== null && columns[i].value.trim() !== '') {
        return true;
      }
    }
    return false;
  };

  ManageFormRegionController.prototype.isCreatePage = function() {
    return this.$location.path().endsWith('/create');
  };

  ManageFormRegionController.prototype.isEditPage = function() {
    return this.$location.path().endsWith('/edit');
  };

  ManageFormRegionController.prototype.getDisplayPoint = function() {
    return this.$routeParams.displayPoint ? this.$routeParams.displayPoint : null;
  };
  
  ManageFormRegionController.prototype.getPageId = function() {
    return this.$routeParams.pageId ? this.$routeParams.pageId : null;
  };
  
  ManageFormRegionController.prototype.getRegionId = function() {
    return this.$routeParams.regionId ? this.$routeParams.regionId : null;
  };
  
  ManageFormRegionController.prototype.getApplicationId = function() {
    return this.$routeParams.applicationId ? this.$routeParams.applicationId : null;
  };

  ManageFormRegionController.prototype.saveRegion = function() {
    this.regionService.saveFormRegion(
      this.getPageId(),
      this.getDisplayPoint(),
      this.getRegionId(),
      this.$scope.region.name,
      this.$scope.region.sequence,
      this.$scope.region.regionTemplate,
      this.$scope.region.isVisible || false,
      this.$scope.region.formTemplate,
      this.$scope.region.buttonTemplate,
      this.$scope.region.buttonLabel,
      this.$scope.region.successMessage || null,
      this.$scope.region.errorMessage || null,
      this.$scope.region.redirectUrl || null,
      this.$scope.region.function.attributes.schema,
      this.$scope.region.function.attributes.name,
      this.$scope.region.formPreFill || false,
      this.getFormFields(this.$scope.region.functionParameters),
      this.getPreFill(),
      this.getSubRegions()
    ).then(this.handleSaveResponse.bind(this));
  };

  ManageFormRegionController.prototype.getFormFields = function(functionParameters) {
    return functionParameters.map(function (functionParameter) {
      return {
        "type": "form-field",
        "attributes": {
          "fieldType": functionParameter.fieldType,
          "fieldTemplate": parseInt(functionParameter.fieldTemplate),
          "label": functionParameter.label,
          "inputName": functionParameter.inputName,
          "sequence": parseInt(functionParameter.sequence),
          "isMandatory": functionParameter.isMandatory || false,
          "isVisible": functionParameter.isVisible || false,
          "defaultValue": functionParameter.defaultValue || null,
          "helpText": functionParameter.helpText || null,
          "functionParameterType": functionParameter.attributes.argumentType,
          "functionParameterOrdinalPosition": functionParameter.attributes.ordinalPosition,
          "preFillColumn": functionParameter.preFillColumn || null,
          "listOfValuesSchema": (functionParameter.listOfValuesView) ? functionParameter.listOfValuesView.attributes.schema : null,
          "listOfValuesView": (functionParameter.listOfValuesView) ? functionParameter.listOfValuesView.attributes.name : null,
          "listOfValuesValue": (functionParameter.listOfValuesValue) ? functionParameter.listOfValuesValue.attributes.name : null,
          "listOfValuesLabel": (functionParameter.listOfValuesLabel) ? functionParameter.listOfValuesLabel.attributes.name : null,
          "calenderFormat": functionParameter.calenderFormat || null,
          "width": functionParameter.width || null,
          "widthUnit": functionParameter.widthUnit || null,
          "height": functionParameter.height || null,
          "heightUnit": functionParameter.heightUnit || null
        }
      };
    });
  };

  ManageFormRegionController.prototype.getPreFill = function() {
    if (!this.$scope.region.formPreFill) {
      return null;
    }
    return {
      "type": "pre-fill",
      "attributes": {
        "schemaName": this.$scope.region.formPreFillView.attributes.schema,
        "viewName": this.$scope.region.formPreFillView.attributes.name,
        "conditions": this.$scope.region.formPreFillColumns.map(function(condition) {
          return {
            "columnName": condition.column.attributes.name,
            "value": condition.value || null
          }
        })
      }
    }
  };

  ManageFormRegionController.prototype.handleSaveResponse = function(response) {
    if (!response.hasErrors()) {
      this.$location.path('/application-builder/app/' + this.getApplicationId()
                        + '/pages/' + this.getPageId() + '/regions');
      return;
    } else {
      this.$scope.formError = this.formErrorService.parseApiResponse(response);
    }
  };

  ManageFormRegionController.prototype.loadRegion = function() {
    if (!this.isEditPage()) { return; }
    this.regionService.getRegion(this.getRegionId()).then(function (response) {
      this.$scope.region = response.getDataOrDefault({'attributes': {}}).attributes;
      this.setLastSequences();
    }.bind(this));
  };

  ManageFormRegionController.prototype.getApplicationId = function() {
    return this.$routeParams.applicationId ? parseInt(this.$routeParams.applicationId) : null;
  };

  ManageFormRegionController.prototype.getSubRegions = function() {
    return this.$scope.region.subRegions.map((subRegion) => {
      if (subRegion.type === 'SUBFORM') {
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
            'formTemplateId': 7,
            'formSubmitButtonTemplateId': 9,
            'viewSchema': subRegion.view.attributes.schema,
            'viewName': subRegion.view.attributes.name,
            'itemsPerPage': subRegion.itemsPerPage,
            'showHeader': true,
            'linkedColumn': subRegion.functionParameters,
            'addSubregionFormName': 'subform/' + subRegion.index,
            'functionParameters': this.getFormFields(subRegion.functionParameters),
            'function': subRegion.function,
            'buttonLabel': subRegion.buttonLabel,
            'successMessage': subRegion.successMessage,
            'errorMessage': subRegion.errorMessage
          }
        };
      } else if (subRegion.type === 'TABULAR_SUBFORM') {
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
            'tabularFormTemplateId': 26,
            'itemsPerPage': subRegion.itemsPerPage,
            'buttons': subRegion.buttons,
            'view': subRegion.view,
            'linkedColumns': subRegion.linkedColumns,
            'formColumns': subRegion.formColumns,
            'includeLinkedPage': subRegion.includeLinkedPage,
            'linkedPageId': subRegion.linkedPageId || null,
            'linkedPageUniqueId': subRegion.linkedPageUniqueId || null,
            'addSubregionFormName': 'tabular-subform/' + subRegion.index
          }
        }
      } else {
        return null;
      }
    });
  };

  ManageFormRegionController.prototype.initAvailablePages = function() {
    this.pageService.getPages(this.$scope.applicationId).then(function (response) {
      this.$scope.pages = response.getDataOrDefault([]);
    }.bind(this));
  };

  ManageFormRegionController.prototype.setLastSequences = function() {

    var lastSequenceOfSubRegions = Math.max.apply(Math,
      this.$scope.region.subRegions.map(function (subRegion) {
        return subRegion.sequence;
    }));

    this.$scope.lastSequenceOfSubRegions = isFinite(lastSequenceOfSubRegions) ? lastSequenceOfSubRegions : 0;
  };

  function init() {
    module.controller('pgApexApp.region.ManageFormRegionController',
      ['$scope', '$location', '$routeParams', 'regionService',
      'templateService', 'databaseService', 'formErrorService', 'helperService', 'pageService', ManageFormRegionController]);
  }

  init();
})(window);