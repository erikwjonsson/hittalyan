'use strict';

/* Controllers */

function LandingController($scope) {
  $scope.message = "There is no spoon. Revenge!";
};

function LoginController($scope, $http, $location) {
  $scope.submit = function() {
    $scope.data = {email: $scope.email,
                   password: $scope.password};
    $http.post("login", $scope.data).
      success(function(data, status) {
        $scope.loggedin = true;
        $location.path('/medlemssidor');
      }).
      error(function(data, status) {
        $scope.message = data;
        alert($scope.message);
      });
  };
};

function FAQController($scope) {
  $scope.message = "Look within and you will find the answers you seek.";
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