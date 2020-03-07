<?php
namespace App\Http\Controllers;

use App\Http\Request;
use App\Http\Response;
use Psr\Container\ContainerInterface as ContainerInterface;
use App\Models\App;

class AppController extends Controller {
  private $app;

  public function __construct(ContainerInterface $container) {
    parent::__construct($container);
    $this->app = new App($this->getContainer()['db']);
  }

  private function getAppModel() {
    return $this->app;
  }

  public function queryPage(Request $request, Response $response, $args) {
    Header( "Cache-Control: no-store, no-cache, post-check=0, pre-check=0" );
    Header( "Pragma: no-cache" );
    $applicationId = $args['applicationId'];
    $pageId = isset($args['pageId']) ? $args['pageId'] : null;
    $method = $request->getMethod();
    $headers = json_encode($request->getHeaders());
    $getParams = json_encode($request->getQueryParams());
    $postParams = json_encode($request->getParsedBody());
    $queryResponse = json_decode($this->getAppModel()->queryPage($_SERVER['SCRIPT_NAME'], $applicationId, $pageId, $method, $headers, $getParams, $postParams), true);
    return $this->createResponse($response, $queryResponse);
  }

  public function logout(Request $request, Response $response, $args) {
    $applicationId = $args['applicationId'];
    $headers = json_encode($request->getHeaders());
    $queryResponse = json_decode($this->getAppModel()->logout($_SERVER['SCRIPT_NAME'], $applicationId, $headers), true);
    return $this->createResponse($response, $queryResponse);
  }

  private function createResponse($response, $queryResponse) {
    $newResponse = $response;
    if ($queryResponse['headers'] !== null) {
      foreach ($queryResponse['headers'] as $key => $value) {
        $newResponse = $newResponse->withHeader($key, $value);
      }
    }
    $newResponse->getBody()->write($queryResponse['body']);
    return $newResponse;
  }
}