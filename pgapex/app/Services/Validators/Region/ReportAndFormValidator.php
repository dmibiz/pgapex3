<?php

namespace App\Services\Validators\Region;


use App\Http\Request;
use App\Services\Validators\Validator;

class ReportAndFormValidator extends Validator {
    private $database;

    function __construct($database) {
      $this->database = $database;
    }

    public function validate(Request $request) {
        $this->validateView($request);
        $this->validateUniqueId($request);
        $this->validateReportName($request);
        $this->validateReportRegionTemplate($request);
        $this->validateReportSequence($request);
        $this->validateReportTemplate($request);
        $this->validateItemsPerPage($request);
        $this->validatePaginationQueryParameter($request);
        $this->validateColumns($request->getApiAttribute('reportColumns'), $request->getApiAttribute('addReportColumnsFormName'));
        $this->validateFormPageId($request);
      }
    
      protected function validateView($request) {
        $viewSchema = trim($request->getApiAttribute('viewSchema'));
        $viewName = ($request->getApiAttribute('viewName'));
        if ($viewSchema === '' || $viewName === '' || $viewSchema === null || $viewName === null) {
          $this->addError('region.viewIsMandatory', '/data/attributes/view');
        }
      }
    
      protected function validateUniqueId($request) {
        $uniqueId = trim($request->getApiAttribute('uniqueId'));
        if ($uniqueId === '') {
          $this->addError('region.uniqueIdIsMandatory', '/data/attributes/uniqueId');
        }
      }
    
      protected function validateReportName($request) {
        $name = trim($request->getApiAttribute('reportName', ''));
        if ($name === '' || $name === null) {
          $this->addError('region.nameIsMandatory', '/data/attributes/reportName');
        }
      }
    
      protected function validateReportRegionTemplate($request) {
        $template = $request->getApiAttribute('reportRegionTemplate');
        if (!$this->isValidNumericId($template)) {
          $this->addError('page.regionTemplateIsMandatory', '/data/attributes/reportRegionTemplate');
        }
      }
    
      protected function validateReportSequence($request) {
        $regionId = $request->getApiAttribute('reportRegionId');
        $pageId = $request->getApiAttribute('reportPageId');
        $pageTemplateDisplayPointId = $request->getApiAttribute('pageTemplateDisplayPointId');
        $sequence = $request->getApiAttribute('reportSequence');
    
        if (!$this->isValidSequence($sequence)) {
          $this->addError('region.sequenceIsMandatory', '/data/attributes/reportSequence');
        } elseif ($sequence < 0) {
          $this->addError('region.minValueIsZero', '/data/attributes/reportSequence');
        } elseif (!$this->regionMayHaveASequence($regionId, $pageId, $pageTemplateDisplayPointId, $sequence)) {
          $this->addError('region.sequenceAlreadyExists', '/data/attributes/reportSequence');
        }
      }
    
      private function regionMayHaveASequence($regionId, $pageId, $pageTemplateDisplayPointId, $sequence) {
        $connection = $this->database->getConnection();
        $statement = $connection->prepare('SELECT pgapex.f_region_region_may_have_a_sequence(:regionId, :pageId, :pageTemplateDisplayPointId, :sequence)');
        $statement->bindValue(':regionId', $regionId);
        $statement->bindValue(':pageId', $pageId);
        $statement->bindValue(':pageTemplateDisplayPointId', $pageTemplateDisplayPointId);
        $statement->bindValue(':sequence', $sequence);
        $statement->execute();
        return $statement->fetchColumn() === true;
      }
    
      protected function validateReportTemplate($request) {
        $template = $request->getApiAttribute('reportTemplate');
        if (!$this->isValidNumericId($template)) {
          $this->addError('region.reportTemplateIsMandatory', '/data/attributes/reportTemplate');
        }
      }
    
      protected function validateItemsPerPage($request) {
        $itemsPerPage = $request->getApiAttribute('reportItemsPerPage');
        $pointer = '/data/attributes/reportItemsPerPage';
        if ($itemsPerPage === null || !is_int($itemsPerPage)) {
          $this->addError('region.itemsPerPageIsMandatory', $pointer);
        } elseif ($itemsPerPage < 1) {
          $this->addError('region.minValueIsOne', $pointer);
        }
      }
    
      protected function validatePaginationQueryParameter($request) {
        $paginationQueryParameter = $request->getApiAttribute('reportPaginationQueryParameter');
        $pointer = '/data/attributes/reportPaginationQueryParameter';
        if (trim($paginationQueryParameter) === '') {
          $this->addError('region.paginationQueryParameterIsMandatory', $pointer);
        } elseif (!$this->isValidPageItem($paginationQueryParameter)) {
          $this->addError('region.paginationQueryParameterMayConsistOfCharsAndUnderscores', $pointer);
        }
      }
    
      protected function validateFormPageId($request) {
        $pageId = $request->getApiAttribute('formPageId');
        if (!$this->isValidNumericId($pageId)) {
          $this->addError('region.pageIsMandatory', '/data/attributes/formPageId');
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
}