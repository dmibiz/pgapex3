<?php

namespace Tests\App\Services\Validators\Auth;

use App\Services\Validators\Region\ReportAndFormValidator;

class ReportAndFormValidatorTest extends \TestCase {
  private $validator;
  private $request;

  protected function setUp() {
    $this->validator = $this->spy(ReportAndFormValidator::class);
    $this->request = $this->mock('App\Http\Request');
  }

  public function testValidateReportName() {
    $this->request->shouldReceive('getApiAttribute')->with('reportName', '')->andReturn('');
    $this->invokeObjectMethod($this->validator, 'validateReportName', [$this->request]);

    $this->assertEquals(1, count($this->validator->getErrors()));
  }

  public function testValidateView() {
    $this->request->shouldReceive('getApiAttribute')->with('viewSchema')->andReturn('public');
    $this->request->shouldReceive('getApiAttribute')->with('viewName')->andReturn(null);
    $this->invokeObjectMethod($this->validator, 'validateView', [$this->request]);

    $this->assertEquals(1, count($this->validator->getErrors()));
  }

  public function testValidateUniqueId() {
    $this->request->shouldReceive('getApiAttribute')->with('uniqueId')->andReturn('');
    $this->invokeObjectMethod($this->validator, 'validateUniqueId', [$this->request]);

    $this->assertEquals(1, count($this->validator->getErrors()));
  }

  public function testValidateReportRegionTemplate() {
    $this->request->shouldReceive('getApiAttribute')->with('reportRegionTemplate')->andReturn(null);
    $this->invokeObjectMethod($this->validator, 'validateReportRegionTemplate', [$this->request]);
    $this->assertEquals(1, count($this->validator->getErrors()));
  }

  public function testValidateReportSequence() {
    $this->request->shouldReceive('getApiAttribute')->with('reportRegionId')->andReturn(1);
    $this->request->shouldReceive('getApiAttribute')->with('reportPageId')->andReturn(1);
    $this->request->shouldReceive('getApiAttribute')->with('pageTemplateDisplayPointId')->andReturn(1);
    $this->request->shouldReceive('getApiAttribute')->with('reportIncludeEntityCreateButton')->andReturn(1);
    $this->request->shouldReveive('getApiAttribute')->with('reportCreateEntityPageId')->andReturn(1);
    $this->request->shouldReveive('getApiAttribute')->with('reportCreateEntityButtonLabel')->andReturn(1);

    $this->request->shouldReceive('getApiAttribute')->with('reportSequence')->andReturn(-1);
    $this->invokeObjectMethod($this->validator, 'validateReportSequence', [$this->request]);
    $this->assertEquals(1, count($this->validator->getErrors()));

    $this->request->shouldReceive('getApiAttribute')->with('reportSequence')->andReturn(null);
    $this->invokeObjectMethod($this->validator, 'validateReportSequence', [$this->request]);
    $this->assertEquals(1, count($this->validator->getErrors()));
  }

  public function testValidateReportTemplate() {
    $this->request->shouldReceive('getApiAttribute')->with('reportTemplate')->andReturn(null);
    $this->invokeObjectMethod($this->validator, 'validateReportTemplate', [$this->request]);
    $this->assertEquals(1, count($this->validator->getErrors()));
  }

  public function testValidateItemsPerPage() {
    $this->request->shouldReceive('getApiAttribute')->with('reportItemsPerPage')->andReturn(-1);
    $this->invokeObjectMethod($this->validator, 'validateItemsPerPage', [$this->request]);

    $this->assertEquals(1, count($this->validator->getErrors()));
  }

  public function testValidatePaginationQueryParameter() {
    $this->request->shouldReceive('getApiAttribute')->with('reportPaginationQueryParameter')->andReturn(null);
    $this->invokeObjectMethod($this->validator, 'validatePaginationQueryParameter', [$this->request]);
    $this->assertEquals(1, count($this->validator->getErrors()));

    $this->request->shouldReceive('getApiAttribute')->with('reportPaginationQueryParameter')->andReturn('page-1');
    $this->invokeObjectMethod($this->validator, 'validatePaginationQueryParameter', [$this->request]);
    $this->assertEquals(1, count($this->validator->getErrors()));

    $this->request->shouldReceive('getApiAttribute')->with('reportPaginationQueryParameter')->andReturn(-1);
    $this->invokeObjectMethod($this->validator, 'validatePaginationQueryParameter', [$this->request]);
    $this->assertEquals(1, count($this->validator->getErrors()));
  }

  public function testValidateFormPageId() {
    $this->request->shouldReceive('getApiAttribute')->with('formPageId')->andReturn('');
    $this->invokeObjectMethod($this->validator, 'validateFormPageId', [$this->request]);
    $this->assertEquals(1, count($this->validator->getErrors()));
  }
}
