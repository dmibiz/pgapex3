<?php

namespace App\Models;

use App\Http\Request;
use PDO;

class App extends Model {
  public function queryPage($appRoot, $applicationId, $pageId, $method, $headers, $getParams, $postParams) {
    $connection = $this->getDb()->getConnection();
    $statement = $connection->prepare('SELECT pgapex.f_app_query_page(:appRoot, :applicationId, :pageId, :method, :headers, :getParams, :postParams)');
    $statement->bindValue(':appRoot',       $appRoot,       PDO::PARAM_STR);
    $statement->bindValue(':applicationId', $applicationId, PDO::PARAM_STR);
    $statement->bindValue(':pageId',        $pageId,        PDO::PARAM_STR);
    $statement->bindValue(':method',        $method,        PDO::PARAM_STR);
    $statement->bindValue(':headers',       $headers,       PDO::PARAM_STR);
    $statement->bindValue(':getParams',     $getParams,     PDO::PARAM_STR);
    $statement->bindValue(':postParams',    $postParams,    PDO::PARAM_STR);
    $statement->execute();
    return $statement->fetchColumn();
  }

  public function logout($appRoot, $applicationId, $headers) {
    $connection = $this->getDb()->getConnection();
    $statement = $connection->prepare('SELECT pgapex.f_app_logout(:appRoot, :applicationId, :headers)');
    $statement->bindValue(':appRoot',       $appRoot,       PDO::PARAM_STR);
    $statement->bindValue(':applicationId', $applicationId, PDO::PARAM_STR);
    $statement->bindValue(':headers',       $headers,       PDO::PARAM_STR);
    $statement->execute();
    return $statement->fetchColumn();
  }
}