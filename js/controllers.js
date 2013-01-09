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
}

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
    if ( $scope.login.$valid == true ) {
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
    }
  };
}

function FAQController($scope, $routeParams) {
}

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
    }
  };
}

function MembersController($scope) {
}

function FiltersController($scope, $http) {
  $scope.roomValues = [1, 2, 3, 4, 5, 6, 7, 8, 9];
  $scope.rentValues = [1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000,
                       5500, 6000, 6500, 7000, 7500, 8000, 8500, 9000, 9500,
                       10000, 10500, 11000, 11500, 12000, 12500, 13000, 13500,
                       14000, 14500]
  $scope.areaValues = [10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80,
                       90, 95, 100 ,105, 110, 115, 120, 125, 130, 135, 140,145]
  $scope.submit = function() {
    if ( $scope.filtersettings.$valid == true) {
      $scope.data = {roomsMin: $scope.roomsMin,
                     roomsMax: $scope.roomsMax,
                     rent: $scope.rent,
                     areaMin: $scope.areaMin,
                     areaMax: $scope.areaMax};
      $http.post("filter", $scope.data).
        success(function(data, status) {
          alert(data);
        }).
        error(function(data, status) {
          alert("Natural 1");
        });
    }
  };
}

function ApartmentsController($scope, $http) {
  $http.get("medlemssidor/apartments_list").
    success(function(data, status) {
      $scope.apartments = data;
    }).
    error(function(data, status) {
      $scope.apartments = "Något slags fel";
    })
}

function PasswordController($scope, $http) {
  $scope.submit = function() {
    if ( $scope.new_password == $scope.repeat_password ) {
      if ( $scope.passwordChange.$valid == true){
        $scope.data = {old_password: $scope.old_password,
                       new_password: $scope.new_password};
        $http.post("change_password", $scope.data).
          success(function(data, status) {
            alert(data);
            $scope.new_password = "";
            $scope.repeat_password = "";
            $scope.old_password = "";
          }).
          error(function(data, status) {
            alert("Natural 1");
          });
      }
    }
    else {
      alert("Lösenorden överrensstämmer inte");
    }
  };
}

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
    }
  };
}

function PasswordResetConfirmationController($scope, $http, $routeParams, $location) {
  // $scope.message = "Lösenordet återställs. Var god vänta...."

  $scope.submit = function() {
    if ( $scope.new_password == $scope.repeat_password ) {
      if ( $scope.passwordresetconfirmation.$valid == true) {
        $scope.data = {hash: $routeParams['hash'],
                       new_password: $scope.new_password};
        $http.post("passwordreset", $scope.data).
          success(function(data, status) {
            alert(data);
            $location.path('/');
          }).
          error(function(data, status) {
            $scope.message = data;
            alert("Natural 1");
          });
      }
    }
    else {
      alert("Lösenorden överrensstämmer inte");
    }
  };
}

function TestController($scope) {
  
}
