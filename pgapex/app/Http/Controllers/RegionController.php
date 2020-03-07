<?php
namespace App\Http\Controllers;

use App\Http\Request;
use App\Http\Response;
use App\Services\Validators\Region\FormRegionValidator;
use App\Services\Validators\Region\HtmlRegionValidator;
use App\Services\Validators\Region\NavigationRegionValidator;
use App\Services\Validators\Region\ReportAndDetailViewValidator;
use App\Services\Validators\Region\ReportRegionValidator;
use App\Services\Validators\Region\TabularFormRegionValidator;
use App\Services\Validators\Region\ReportAndFormValidator;
use Psr\Container\ContainerInterface as ContainerInterface;
use App\Models\Region;

class RegionController extends Controller {
  private $region;

  public function __construct(ContainerInterface $container) {
    parent::__construct($container);
    $this->region = new Region($this->getContainer()['db']);
  }

  private function getRegionModel() {
    return $this->region;
  }

  public function getDisplayPointsWithRegions(Request $request, Response $response, $args) {
    return $response->setApiDataAsJson($this->getRegionModel()->getDisplayPointsWithRegions($args['pageId']))
      ->getApiResponse();
  }

  public function getRegion(Request $request, Response $response, $args) {
    return $response->setApiDataAsJson($this->getRegionModel()->getRegion($args['id']))
      ->getApiResponse();
  }

  public function deleteRegion(Request $request, Response $response, $args) {
    return $response->setApiDataAsJson($this->getRegionModel()->deleteRegion($args['id']))
      ->getApiResponse();
  }

  public function saveHtmlRegion(Request $request, Response $response) {
    $validator = $this->getHtmlRegionValidator();
    $validator->validate($request);
    if (!$validator->hasErrors()) {
      $this->getRegionModel()->saveHtmlRegion($request);
    }
    $validator->attachErrorsToResponse($response);
    return $response->getApiResponse();
  }

  public function saveNavigationRegion(Request $request, Response $response) {
    $validator = $this->getNavigationRegionValidator();
    $validator->validate($request);
    if (!$validator->hasErrors()) {
      $this->getRegionModel()->saveNavigationRegion($request);
    }
    $validator->attachErrorsToResponse($response);
    return $response->getApiResponse();
  }

  public function saveReportRegion(Request $request, Response $response) {
    $validator = $this->getReportRegionValidator();
    $validator->validate($request);
    if (!$validator->hasErrors()) {
      $this->getRegionModel()->saveReportRegion($request);
    }
    $validator->attachErrorsToResponse($response);
    return $response->getApiResponse();
  }

  public function saveReportAndDetailViewRegion(Request $request, Response $response) {
    $validator = $this->getReportAndDetailViewValidator();
    $validator->validate($request);
    if (!$validator->hasErrors()) {
      $this->getRegionModel()->saveReportAndDetailViewRegion($request);
    }
    $validator->attachErrorsToResponse($response);
    return $response->getApiResponse();
  }

  public function saveReportAndFormRegion(Request $request, Response $response) {
    $validator = $this->getReportAndFormValidator();
    $validator->validate($request);
    if (!$validator->hasErrors()) {
      $this->getRegionModel()->saveReportAndFormRegion($request);
    }
    $validator->attachErrorsToResponse($response);
    return $response->getApiResponse();
  }

  public function saveFormRegion(Request $request, Response $response) {
    $validator = $this->getFormRegionValidator();
    $validator->validate($request);
    if (!$validator->hasErrors()) {
      $this->getRegionModel()->saveFormRegion($request);
    }
    $validator->attachErrorsToResponse($response);
    return $response->getApiResponse();
  }

  public function saveTabularFormRegion(Request $request, Response $response) {
    $validator = $this->getTabularFormRegionValidator();
    $validator->validate($request);
    if (!$validator->hasErrors()) {
      $this->getRegionModel()->saveTabularFormRegion($request);
    }
    $validator->attachErrorsToResponse($response);
    return $response->getApiResponse();
  }

  private function getHtmlRegionValidator() {
    return new HtmlRegionValidator($this->getContainer()['db']);
  }

  private function getNavigationRegionValidator() {
    return new NavigationRegionValidator($this->getContainer()['db']);
  }

  private function getReportRegionValidator() {
    return new ReportRegionValidator($this->getContainer()['db']);
  }

  private function getReportAndDetailViewValidator() {
    return new ReportAndDetailViewValidator($this->getContainer()['db']);
  }

  private function getFormRegionValidator() {
    return new FormRegionValidator($this->getContainer()['db']);
  }

  private function getTabularFormRegionValidator() {
    return new TabularFormRegionValidator($this->getContainer()['db']);
  }

  private function getReportAndFormValidator() {
    return new ReportAndFormValidator($this->getContainer()['db']);
  }
}