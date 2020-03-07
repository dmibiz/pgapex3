<?php
namespace App\Http\Controllers;

use App\Http\Request;
use App\Http\Response;
use Psr\Container\ContainerInterface as ContainerInterface;
use App\Services\Validators\Auth\LoginValidator;

class AuthController extends Controller {
  public function __construct(ContainerInterface $container) {
    parent::__construct($container);
  }

  public function login(Request $request, Response $response) {
    $validator = new LoginValidator();
    $validator->validate($request);

    if (!$validator->hasErrors()) {
      $username = $request->getApiAttribute('username');
      $password = $request->getApiAttribute('password');
      if(!$this->getAuth()->login($username, $password)) {
        $validator->addError('auth.wrongUsernameOrPassword', '/data/attributes/username');
      }
    }

    $validator->attachErrorsToResponse($response);

    return $response->getApiResponse();
  }

  public function logout(Request $request, Response $response) {
    $this->getAuth()->logout();
    return $response->getApiResponse();
  }

  private function getAuth() {
    return $this->getContainer()->get('auth');
  }
}