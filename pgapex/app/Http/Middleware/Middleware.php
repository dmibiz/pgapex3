<?php
namespace App\Http\Middleware;

use Psr\Container\ContainerInterface as ContainerInterface;

abstract class Middleware {
  private $container;

  public function __construct(ContainerInterface $container) {
    $this->container = $container;
  }

  public function getContainer() {
    return $this->container;
  }
}