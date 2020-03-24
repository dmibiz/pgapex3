<?php
namespace App\Services\Validators;

use App\Http\Request;
use App\Http\Response;
use App\Services\Service;

abstract class Validator implements Service {
  private $errors = [];

  public function addError($details, $pointer) {
    return $this->errors[$pointer][] = $details;
  }

  public function hasErrors() {
    return count($this->errors) > 0;
  }

  public function getErrors() {
    return $this->errors;
  }

  public function attachErrorsToResponse(Response $response) {
    foreach ($this->errors as $pointer => $details) {
      foreach ($details as $key => $detail) {
        $response->addApiErrorWithPointer($detail, $pointer);
      }
    }
  }

  protected function isValidNumericId($id) {
    return ($id !== null && is_int($id) && $id > 0);
  }

  protected function isValidSequence($sequence) {
    return ($sequence !== null && is_int($sequence));
  }

  protected function isValidPageItem($paginationQueryParameter) {
    return preg_match('/[a-zA-Z_]+/', $paginationQueryParameter);
  }

  protected function isValidFormInputName($formInputName) {
    return $this->isValidPageItem($formInputName);
  }

  abstract public function validate(Request $request);
}