<?php

defined('DEBUG') or define('DEBUG', false);

if (DEBUG) {
  error_reporting(E_ALL);
  ini_set('display_errors', 1);
}

require __DIR__ . '/helpers.php';
require __DIR__ . '/../vendor/autoload.php';

$services = require __DIR__ . '/services.php';

$app = new \Slim\App($services);

require __DIR__ . '/routes.php';
$services['db']->connect()  || die('Could not connect to database.');
$app->run();
$services['db']->close();