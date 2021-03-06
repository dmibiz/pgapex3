<?php

use App\Http\Request;
use App\Http\Response;
use App\Services\Session;
use App\Services\Database;
use App\Services\Authentication;
use Slim\Http\Headers;
use Slim\Container;

$settings = require __DIR__ . '/config.php';

$container = new Container($settings);

$container['db'] = function ($container) {
  return new Database($container['settings']['db']);
};

$container['session'] = function ($container) {
  return new Session();
};

$container['auth'] = function ($container) {
  return new Authentication($container->get('session'), $container->get('db'));
};

$container['request'] = function ($container) {
  return Request::createFromEnvironment($container->get('environment'));
};

$container['response'] = function ($container) {
  $headers = new Headers(['Content-Type' => 'text/html; charset=UTF-8']);
  $response = new Response(200, $headers);
  return $response->withProtocolVersion($container->get('settings')['httpVersion']);
};

return $container;