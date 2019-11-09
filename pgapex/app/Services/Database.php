<?php

namespace App\Services;

use \PDO;

class Database implements Service {
  private $settings;
  private $connection = null;

  public function __construct($settings) {
    $this->settings = $settings;
  }

  private function getDns() {
    $dns = '';
    $dns .= $this->settings['driver'] . ':';
    $dns .= 'host=' . $this->settings['host'] . ';';
    $dns .= 'port=' . $this->settings['port'] . ';';
    $dns .= 'dbname=' . $this->settings['dbname'];
    return $dns;
  }
  
  private function getUsername() {
    return $this->settings['username'];
  }

  private function getPassword() {
    return $this->settings['password'];
  }

  public function connect() {
    try {
      $this->connection = new PDO($this->getDns(), $this->getUsername(), $this->getPassword());
      return true;
    } catch(\Exception $e) {
      echo $e;
    }
    return false;
  }

  public function getConnection() {
    return $this->connection;
  }

  public function close() {
    $this->connection = null;
  }
}