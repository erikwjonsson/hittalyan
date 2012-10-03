'use strict';

/* Controllers */

function IndexController($scope, $http, $rootScope, $location) {
  $scope.logout = function() {
    $http.post("logout").
      success(function() {
        $rootScope.loggedIn = false;
        $location.path('/');
      }).
      error(function() {
        $rootScope.loggedIn = false;
        $location.path('/');
      });
  };
};

function LandingController($scope) {
  $scope.message = "There is no spoon. Revenge!";
};

function LoginController($scope, $http, $location, $rootScope) {
  $scope.submit = function() {
    if ( $scope.login.$valid == true) {
      $scope.data = {email: $scope.email,
                     password: $scope.password};
      $http.post("login", $scope.data).
        success(function(data, status) {
          $rootScope.loggedIn = true;
          $location.path('/medlemssidor');
        }).
        error(function(data, status) {
          $rootScope.loggedIn = false;
          $scope.message = data;
          alert($rootScope.loggedIn);
        });
    };
  };
};

function FAQController($scope) {
  $scope.message = "Look within and you will find the answers you seek.";
};

function SignupController($scope, $http, $location) {
  $scope.submit = function() {
    if ( $scope.signup.$valid == true) {
      $scope.data = {email: $scope.email,
                    password: $scope.password};
      $http.post("signup", $scope.data).
        success(function(data, status) {
          $location.path('/');
        }).
        error(function(data, status) {
        });
    };
  };
};

function MembersController($scope) {
  $scope.message = "Look within and you will find the answers you seek.";
};

function TestController($scope, $http, $location) {
  $scope.message = "Nil";
  $scope.data = {};
  $scope.submit = function() {
    $scope.message = $scope.input;
    $scope.data = {message: $scope.message};
    $http.post("test", $scope.data).
      success(function(data, status) {
        $scope.status = status;
        $location.path('/medlemssidor');
      }).
      error(function(data, status) {
        $scope.status = status;
        $scope.message = data;
      });
  };
};