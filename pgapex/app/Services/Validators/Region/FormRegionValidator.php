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
    $this->validateButtonLabel($request);
    $this->validateFunction($request);

    $formInputNames = $this->getFormInputNames($request);
    $this->validatePreFillForm($request, $formInputNames);
    $this->validateFormInputs($request);
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

  private function validateButtonLabel(Request $request) {
    $label = $request->getApiAttribute('buttonLabel');
    if ($label === null || trim($label) === '') {
      $this->addError('region.buttonLabelIsMandatory', '/data/attributes/buttonLabel');
    }
  }

  private function validateFunction(Request $request) {
    $functionSchema = $request->getApiAttribute('functionSchema');
    $functionName = $request->getApiAttribute('functionName');

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

  private function validateFormInputs(Request $request) {
    $formFields = $request->getApiAttribute('formFields');
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
    }
  }
}