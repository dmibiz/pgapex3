'use strict';
(function (window) {
  var module = window.angular.module('pgApexApp.page');

  function AddSubFormController($scope, $routeParams, databaseService, formErrorService, templateService) {
    this.$scope = $scope;
    this.$routeParams = $routeParams;
    this.databaseService = databaseService;
    this.formErrorService = formErrorService;
    this.templateService = templateService;

    /*$scope.$watch('subForm.columns', function (items) {
      $scope.subFormForm.$setValidity('columnsArrayLength', items.length > 0);
    }, true);*/

    this.init();
  }

  AddSubFormController.prototype.init = function () {
    this.$scope.changeViewColumns = this.changeViewColumns.bind(this);
    this.$scope.subForm.index = this.$scope.index;
    this.$scope.subForm.paginationQueryParameter = 'subform_page';
    this.$scope.subForm.itemsPerPage = 15;
    this.$scope.applicationId = this.getApplicationId();

    this.$scope.changeSubFormFunctionParameters = this.changeSubFormFunctionParameters.bind(this);

    this.$scope.trackView = function(view) {
      if (!view || !view.attributes) { return view; }
      return view.attributes.schema + '.' + view.attributes.name;
    }.bind(this);

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
    
    this.initFunctionsWithParameters();
    this.initButtonTemplates();
    this.initInputTemplates();
    this.initTextareaTemplates();
    this.initDropDownTemplates();
    this.initComboBoxTemplates();
    this.initCalenderTemplates();
    this.loadSubForm();
  };

  AddSubFormController.prototype.setViewColumns = function() {
    if (!this.$scope.subForm) { return; }
    var view = this.$scope.viewsWithColumns.filter(function (view) {
      return view.attributes.schema === this.$scope.subForm.view.attributes.schema &&
        view.attributes.name === this.$scope.subForm.view.attributes.name;
    }.bind(this));
    if (view.length > 0) {
      this.$scope.viewColumns = view[0].attributes.columns;
    }
  };

  AddSubFormController.prototype.changeViewColumns = function() {
    this.setViewColumns();
  };

  AddSubFormController.prototype.setLastSequences = function() {
    var lastSequenceOfColumns = Math.max.apply(Math, this.$scope.subForm.columns.map(function (column) {
      return column.attributes.sequence;
    }));

    this.$scope.lastSequenceOfColumns = isFinite(lastSequenceOfColumns) ? lastSequenceOfColumns : 0;
  };

  AddSubFormController.prototype.loadSubForm = function() {
    if (this.$scope.mode === 'edit') {
      this.$scope.subForm.view = {'attributes':
        {
          'schema': this.$scope.subForm.viewSchema,
          'name': this.$scope.subForm.viewName
        }
      };
      //this.setViewColumns();
      //this.setLastSequences();
    }
  };

  AddSubFormController.prototype.initFunctionsWithParameters = function() {
    this.databaseService.getFunctionsWithParameters(this.getApplicationId()).then(function (response) {
      var functionsWithParameters = response.getDataOrDefault([]);
      functionsWithParameters.forEach(function (functionWithParameters) {
        functionWithParameters.attributes.parameters.sort(function(firstParameter, secondParameter) {
          firstParameter.attributes.ordinalPosition - secondParameter.attributes.ordinalPosition;
        });
      });
      functionsWithParameters.forEach(function(functionWithParameters) {
        this.addDisplayTextToFunction(functionWithParameters);
      }.bind(this));
      this.$scope.functionsWithParameters = functionsWithParameters;
    }.bind(this));
  };

  AddSubFormController.prototype.addDisplayTextToFunction = function(functionWithParameters) {
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

  function init() {
    module.controller('pgApexApp.region.AddSubFormController', ['$scope', '$routeParams', 'databaseService', 'formErrorService', 'templateService', AddSubFormController]);
  }

  AddSubFormController.prototype.getApplicationId = function() {
    return this.$routeParams.applicationId ? this.$routeParams.applicationId : null;
  };

  AddSubFormController.prototype.changeSubFormFunctionParameters = function() {
    this.$scope.subForm.functionParameters = this.$scope.subForm.function.attributes.parameters;
  };

  AddSubFormController.prototype.initButtonTemplates = function() {
    this.templateService.getButtonTemplates().then(function (response) {
      this.$scope.buttonTemplates = response.getDataOrDefault([]);
    }.bind(this));
  };

  AddSubFormController.prototype.initInputTemplates = function() {
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

  AddSubFormController.prototype.initTextareaTemplates = function() {
    this.templateService.getTextareaTemplates().then(function (response) {
      this.$scope.textareaTemplates = response.getDataOrDefault([]);
    }.bind(this));
  };

  AddSubFormController.prototype.initDropDownTemplates = function() {
    this.templateService.getDropDownTemplates().then(function (response) {
      this.$scope.dropDownTemplates = response.getDataOrDefault([]);
    }.bind(this));
  };

  AddSubFormController.prototype.initComboBoxTemplates = function() {
    this.templateService.getComboBoxTemplates().then(function (response) {
      this.$scope.comboBoxTemplates = response.getDataOrDefault([]);
    }.bind(this));
  };

  AddSubFormController.prototype.initCalenderTemplates = function() {
    this.templateService.getCalenderTemplates().then(function (response) {
      this.$scope.calenderTemplates = response.getDataOrDefault([]);
    }.bind(this));
  };

  AddSubFormController.prototype.getFormFields = function() {
    return this.$scope.region.functionParameters.map(function (functionParameter) {
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
          "listOfValuesLabel": (functionParameter.listOfValuesLabel) ? functionParameter.listOfValuesLabel.attributes.name : null
        }
      };
    });
  };

  init();
})(window);