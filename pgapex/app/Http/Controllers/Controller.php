<?php
namespace App\Http\Controllers;

use Psr\Container\ContainerInterface as ContainerInterface;

abstract class Controller {
  private $container;

  public function __construct(ContainerInterface $container) {
    $this->container = $container;
  }

  public function getContainer() {
    return $this->container;
  }
}