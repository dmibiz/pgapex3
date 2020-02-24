<?php

namespace App\Services\Validators\Region;


use App\Http\Request;

class FormRegionValidator extends RegionValidator {
  function __construct($database) {
    parent::__construct($database);
  }

  public function validate(Request $request) {
    parent::validate($request);
    $this->validateFormTemplate($request);
    $this->validateButtonTemplate($request);
    $this->validateButtonLabel($request->getApiAttribute('buttonLabel'));
    $this->validateFunction($request->getApiAttribute('functionSchema'), $request->getApiAttribute('functionName'));

    $formInputNames = $this->getFormInputNames($request);
    $this->validatePreFillForm($request, $formInputNames);
    $this->validateFormInputs($request->getApiAttribute('formFields'));

    $this->validateSubRegions($request);
  }

  private function validateFormTemplate(Request $request) {
    $template = $request->getApiAttribute('formTemplate');
    if (!$this->isValidNumericId($template)) {
      $this->addError('region.formTemplateIsMandatory', '/data/attributes/formTemplate');
    }
  }

  private function validateButtonTemplate(Request $request) {
    $template = $request->getApiAttribute('buttonTemplate');
    if (!$this->isValidNumericId($template)) {
      $this->addError('region.buttonTemplateIsMandatory', '/data/attributes/buttonTemplate');
    }
  }

  private function validateButtonLabel($label) {
    if ($label === null || trim($label) === '') {
      $this->addError('region.buttonLabelIsMandatory', '/data/attributes/buttonLabel');
    }
  }

  private function validateFunction($functionSchema, $functionName) {
    if ($functionSchema === null || $functionName === null ||
      trim($functionSchema) === '' || trim($functionName) === '')
    {
      $this->addError('region.functionIsMandatory', '/data/attributes/function');
    }
  }

  private function validatePreFillForm(Request $request, $formInputNames) {
    $isPreFill = $request->getApiAttribute('formPreFill');
    if (!$isPreFill) {
      return;
    }
    $preFill = $request->getApiAttribute('preFill');

    if ($preFill === null) {
      $this->addError('region.preFillFieldsMustBeFilled', '/data/attributes/formPreFill');
    }

    $schemaName = $preFill['attributes']['schemaName'];
    $viewName = $preFill['attributes']['viewName'];
    if ($schemaName === null || $viewName === null ||
        trim($schemaName) === '' || trim($viewName) === '')
    {
      $this->addError('region.viewIsMandatory', '/data/attributes/formPreFillView');
    }

    $conditionIsMissing = true;
    foreach ($preFill['attributes']['conditions'] as $condition) {
      $conditionValue = $condition['value'];
      if ($conditionValue !== null) {
        $conditionIsMissing = false;
        if (!in_array($conditionValue, $formInputNames)) {
          $this->addError('region.conditionValueMustHaveSameNameWithFormInputName', '/data/attributes/formPreFillColumns');
        }
      }
    }
    if ($conditionIsMissing) {
      $this->addError('region.atLeastOneColumnConditionMustBeAdded', '/data/attributes/formPreFillColumns');
    }

  }

  private function getFormInputNames(Request $request) {
    $formFields = $request->getApiAttribute('formFields');
    $formFieldInputNames = [];
    foreach ($formFields as $formField) {
      $inputName = $formField['attributes']['inputName'];
      if ($inputName !== null && trim($inputName) !== '') {
        $formFieldInputNames[] = $inputName;
      }
    }
    return $formFieldInputNames;
  }

  private function validateFormInputs($formFields) {
    $sequences = [];

    for ($i = 0; $i < count($formFields); $i++) {
      $formField = $formFields[$i]['attributes'];

      if (trim($formField['inputName']) === '') {
        $this->addError('region.inputNameIsMandatory', '/data/attributes/functionParameters/' . $i . '/inputName');
      }

      if (trim($formField['label']) === '') {
        $this->addError('region.labelIsMandatory', '/data/attributes/functionParameters/' . $i . '/label');
      }

      if (!$this->isValidSequence($formField['sequence'])) {
        $this->addError('region.sequenceIsMandatory', '/data/attributes/functionParameters/' . $i . '/sequence');
      } else {
        if (in_array($formField['sequence'], $sequences)) {
          $this->addError('region.sequenceAlreadyExists', '/data/attributes/functionParameters/' . $i . '/sequence');
        }
        $sequences[] = $formField['sequence'];
      }

      if (!in_array($formField['fieldType'], ['TEXT', 'PASSWORD', 'RADIO', 'CHECKBOX', 'DROP_DOWN', 'TEXTAREA', 'COMBO_BOX', 'CALENDER'])) {
        $this->addError('region.fieldTypeIsMandatory', '/data/attributes/functionParameters/' . $i . '/fieldType');
      }

      if (!$this->isValidNumericId($formField['fieldTemplate'])) {
        $this->addError('region.fieldTemplateIsMandatory', '/data/attributes/functionParameters/' . $i . '/fieldTemplate');
      }

      if (in_array($formField['fieldType'], ['RADIO', 'DROP_DOWN', 'COMBO_BOX'])) {
        $schemaName = $formField['listOfValuesSchema'];
        $viewName = $formField['listOfValuesView'];
        if ($schemaName === null || $viewName === null | trim($schemaName) === '' || trim($viewName) === '') {
          $this->addError('region.listOfValuesViewIsMandatory', '/data/attributes/functionParameters/' . $i . '/listOfValuesView');
        }
        if ($formField['listOfValuesLabel'] === null || trim($formField['listOfValuesLabel']) === '') {
          $this->addError('region.listOfValuesLabelIsMandatory', '/data/attributes/functionParameters/' . $i . '/listOfValuesLabel');
        }
        if ($formField['listOfValuesValue'] === null || trim($formField['listOfValuesValue']) === '') {
          $this->addError('region.listOfValuesValueIsMandatory', '/data/attributes/functionParameters/' . $i . '/listOfValuesValue');
        }
      }

      if ($formField['fieldType'] === 'CALENDER' && (trim($formField['calenderFormat']) === '' || $formField['calenderFormat'] === null)) {
        $this->addError('region.calenderFormatIsMandatory', '/data/attributes/functionParameters/' . $i . '/calenderFormat');
      }

      if (!in_array($formField['fieldType'], ['RADIO', 'CHECKBOX'])) {
        if (trim($formField['width']) === '' || $formField['width'] === null) {
          $this->addError('region.widthIsMandatory', '/data/attributes/functionParameters/' . $i . '/calenderFormat');
        }
        if (trim($formField['widthUnit']) === '' || $formField['widthUnit'] === null) {
          $this->addError('region.widthUnitIsMandatory', '/data/attributes/functionParameters/' . $i . '/calenderFormat');
        }
      }
    }
  }

  protected function validateSubRegions($request) {
    $subRegions = $request->getApiAttribute('subRegions');
    $sequences = [];

    for ($i = 0; $i < count($subRegions); $i++) {
      $subRegion = $subRegions[$i]['attributes'];

      if ($subRegion['name'] === '') {
        $this->addError('region.nameIsMandatory', '/data/attributes/' . $subRegion['addSubregionFormName'] . '/name');
      }

      if (!$this->isValidSequence($subRegion['sequence'])) {
        $this->addError('region.sequenceIsMandatory', '/data/attributes/' . $subRegion['addSubregionFormName'] . '/sequence');
      } else {
        if (in_array($subRegion['sequence'], $sequences)) {
          $this->addError('region.sequenceAlreadyExists', '/data/attributes/' . $subRegion['addSubregionFormName'] . '/sequence');
        }
        $sequences[] = $subRegion['sequence'];
      }

      /*if ($subRegion['linkedColumn'] === '') {
        $this->addError('region.linkedColumnIsMandatory', '/data/attributes/' . $subRegion['addSubregionFormName'] . '/linkedColumn');
      }*/

      switch ($subRegions[$i]['type']) {
        case 'SUBFORM':
          $this->validateSubForm($subRegion);
          break;
        case 'TABULAR_SUBFORM':
          $this->validateTabularSubForm($subRegion);
          break;
      }
    }
  }

  protected function validateColumns($columns, $formName) {
    $sequences = [];

    for ($i = 0; $i < count($columns); $i++) {
      $column = $columns[$i]['attributes'];
      if (trim($column['heading']) === '') {
        $this->addError('region.headingIsMandatory', '/data/attributes/addColumnLink/' . $formName . '/' . $i . '/heading');
      }
      if (!$this->isValidSequence($column['sequence'])) {
        $this->addError('region.sequenceIsMandatory', '/data/attributes/addColumnLink' . $formName . '/' . $i . '/sequence');
      } else {
        if (in_array($column['sequence'], $sequences)) {
          $this->addError('region.sequenceAlreadyExists', '/data/attributes/addColumnLink/' . $formName . '/' . $i . '/sequence');
        }
        $sequences[] = $column['sequence'];
      }

      if ($column['type'] === 'COLUMN'){
        if (trim($column['column']) === '') {
          $this->addError('region.columnIsMandatory', '/data/attributes/addColumnLink/' . $formName . '/' . $i . '/column');
        }
      } else {
        if (trim($column['linkUrl']) === '') {
          $this->addError('region.linkUrlIsMandatory', '/data/attributes/addColumnLink/' . $formName . '/' . $i . '/linkUrl');
        }
        if (trim($column['linkText']) === '') {
          $this->addError('region.linkTextIsMandatory', '/data/attributes/addColumnLink/' . $formName . '/' . $i . '/linkText');
        }
      }
    }
  }

  protected function validateSubForm($subRegion) {
    $this->validateButtonLabel($subRegion['buttonLabel']);
    $this->validateFunction($subRegion['function']['attributes']['schema'], $subRegion['function']['attributes']['name']);
    $this->validateFormInputs($subRegion['functionParameters']);
  }

  protected function validateTabularSubForm($subRegion) {
    $this->validateColumns($subRegion['formColumns'], $subRegion['addSubregionFormName']);
    $viewSchema = trim($subRegion['view']['attributes']['schema']);
      $viewName = ($subRegion['view']['attributes']['name']);
      if ($viewSchema === '' || $viewName === '') {
        $this->addError('region.viewIsMandatory', '/data/attributes/' . $subRegion['addSubregionFormName'] . '/view');
    }
  }
}