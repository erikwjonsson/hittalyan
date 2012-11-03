'use strict';

/* Controllers */

function IndexController($scope, $http, $location) {
  $scope.isLoggedIn = function() {
    return localStorage.loggedIn == "true";
  };

  $scope.logout = function() {
    $http.post("logout").
      success(function() {
        localStorage.loggedIn = "false";
        $location.path('/');
      }).
      error(function() {
        localStorage.loggedIn = "false";
        $location.path('/');
      });
  };
};

function LandingController($scope) {
  $scope.message = "There is no spoon. Revenge!";
};

function LoginController($scope, $http, $location) {
  var invalidInput = function() {
    $scope.password = "";
    localStorage.loggedIn = "false";
    alert("Nu skrev du allt fel din jävel");
  };

  $scope.submit = function() {
    if ( $scope.login.$valid == true) {
      $scope.data = {email: $scope.email,
                     password: $scope.password};
      $http.post("login", $scope.data).
        success(function(data, status) {
          $scope.email = "";
          $scope.password = "";
          localStorage.loggedIn = "true";
          $location.path('/medlemssidor');
        }).
        error(function(data, status) {
          if ( status == "401") {
            invalidInput();
          };
          $scope.message = data;
        });
    }
    else {
      invalidInput();
    };
  };
};

function FAQController($scope, $routeParams) {
  $scope.message = "Look within and you will find the answers you seek.";
};

function SignupController($scope, $http, $location) {
  $scope.submit = function() {
    if ( $scope.signup.$valid == true) {
      $scope.data = {email: $scope.email,
                    password: $scope.password};
      $http.post("signup", $scope.data).
        success(function(data, status) {
          $location.path('/medlemssidor');
        }).
        error(function(data, status) {
        });
    };
  };
};

function MembersController($scope) {
  $scope.message = "Look within and you will find the answers you seek.";
};

function FiltersController($scope, $http) {
  $scope.submit = function() {
    if ( $scope.filtersettings.$valid == true) {
      $scope.data = {rooms: $scope.rooms,
                    rent: $scope.rent,
                    area: $scope.area};
      $http.post("filter", $scope.data).
        success(function(data, status) {
          alert(data);
        }).
        error(function(data, status) {
          alert("Natural 1");
        });
    };
  };
};

function ApartmentsController($scope, $http) {
  $http.get("medlemssidor/apartments_list").
    success(function(data, status) {
      $scope.apartments = data;
    }).
    error(function(data, status) {
      $scope.apartments = "Något slags fel";
    });
};

function PasswordResetController($scope, $http) {
  $scope.submit = function() {
    if ( $scope.passwordreset.$valid == true) {
      $scope.data = {email: $scope.email};
      $http.post("passwordreset", $scope.data).
        success(function(data, status) {
          alert(data);
        }).
        error(function(data, status) {
          alert("Natural 1");
        });
    };
  };
};

function PasswordResetConfirmationController($scope, $http, $routeParams) {
  $scope.message = "Lösenordet återställs. Var god vänta...."
  
  $scope.data = {hash: $routeParams['hash']};
  $http.post("passwordreset", $scope.data).
    success(function(data, status) {
      $scope.message = "Lösenord återställt. Ett mail kommer inom kort med ditt nya lösenord.";
      alert(data)
    }).
    error(function(data, status) {
      alert("Natural 1");
    });
};

function TestController($scope) {
  
};