'use strict';

/* Controllers */

function IndexController($rootScope, $scope, $http, $location) {
  defineViewHelperMethodsInRootScope($rootScope, $http, $location);
}

function LandingController($scope) {
  $scope.message = "There is no spoon. Revenge!";
}

function AboutController($scope, $http) {
  $scope.messageSent = false;

  $scope.submit = function() {
    if ($scope.contact.$valid == true) {
      var data = {email: $scope.email,
                  message: $scope.message};

      $http.post("message", data)
            .success(function(data, status) {
              $scope.email = "";
              $scope.message = "";
            });
            $scope.messageSent = true;
    }
  };
}

function LoginController($scope, $http, $routeParams, $location) {

  $scope.submit = function() {
    if ( $scope.login.$valid == true ) {
      $scope.data = {email: $scope.email,
                     password: $scope.password};
      $http.post("login", $scope.data).
        success(function(data, status) {
          $scope.email = "";
          $scope.password = "";
          loginFormSuccess($scope.data['email']);
          $location.path('/medlemssidor');
        }).
        error(function(data, status) {
          if ( status == "401") {
            loginFormFail($scope);
          };
          $scope.message = data;
        });
    }
    else {
      loginFormFail($scope);
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
      $scope.message = "Registrerar...";
      $scope.working = true;
      $scope.cross = false;
      $http.post("signup", $scope.data).
        success(function(data, status) {
          $scope.message = "Registrering lyckad. Loggar in..."
          $http.post("login", $scope.data).
            success(function(data, status) {
              $scope.message = "Inloggad. Omdirigerar..."
              loginFormSuccess($scope.data['email']);
              $location.path('/medlemssidor');
            }).
            error(function(data, status) {
              $scope.message = "Registrering lyckad men inloggning misslyckad"
              $scope.working = false;
              $scope.cross = true;
              localStorage.loggedIn = "false";
            });
        }).
        error(function(data, status) {
          $scope.message = "Registrering misslyckad"
          $scope.working = false;
          $scope.cross = true;
        });
    }
  };
}

function MembersController($scope) {
}

function SettingsController($scope, $http, $location) {
  // Making room for namespaces
  $scope.passwordSettings = {};
  $scope.accountTermination = {};
  $scope.allSettings = {};

  $scope.roomValuesMin = [{name: "1", value: 1},
                          {name: "2", value: 2},
                          {name: "3", value: 3},
                          {name: "4", value: 4},
                          {name: "5", value: 5},
                          {name: "6", value: 6},
                          {name: "7", value: 7},
                          {name: "8", value: 8},
                          {name: "9", value: 9}];
  $scope.roomValuesMax = [{name: "1", value: 1},
                          {name: "2", value: 2},
                          {name: "3", value: 3},
                          {name: "4", value: 4},
                          {name: "5", value: 5},
                          {name: "6", value: 6},
                          {name: "7", value: 7},
                          {name: "8", value: 8},
                          {name: "9", value: 9},
                          {name: "10+", value: 999}];
  $scope.rentValues = [{name: "1000", value: 1000},
                       {name: "1500", value: 1500},
                       {name: "2000", value: 2000},
                       {name: "2500", value: 2500},
                       {name: "3000", value: 3000},
                       {name: "3500", value: 3500},
                       {name: "4000", value: 4000},
                       {name: "4500", value: 4500},
                       {name: "5000", value: 5000},
                       {name: "5500", value: 5500},
                       {name: "6000", value: 6000},
                       {name: "6500", value: 6500},
                       {name: "7000", value: 7000},
                       {name: "7500", value: 7500}, 
                       {name: "8000", value: 8000},
                       {name: "8500", value: 8500},
                       {name: "9000", value: 9000},
                       {name: "9500", value: 9500},
                       {name: "10000", value: 10000},
                       {name: "10500", value: 10500}, 
                       {name: "11000", value: 11000},
                       {name: "11500", value: 11500},
                       {name: "12000", value: 12000},
                       {name: "12500", value: 12500},
                       {name: "13000", value: 13000},
                       {name: "13500", value: 13500},
                       {name: "14000", value: 14000},
                       {name: "14500", value: 14500},
                       {name: "15000+", value: 999999}];
  $scope.areaValuesMin = [{name: "10", value: 10},
                          {name: "15", value: 15},
                          {name: "20", value: 20},
                          {name: "25", value: 25},
                          {name: "30", value: 30},
                          {name: "35", value: 35},
                          {name: "40", value: 40},
                          {name: "45", value: 45},
                          {name: "50", value: 50},
                          {name: "55", value: 55},
                          {name: "60", value: 60},
                          {name: "65", value: 65},
                          {name: "70", value: 70},
                          {name: "75", value: 75},
                          {name: "80", value: 80},
                          {name: "90", value: 90},
                          {name: "95", value: 95},
                          {name: "100", value: 100},
                          {name: "105", value: 105},
                          {name: "110", value: 110},
                          {name: "115", value: 115},
                          {name: "120", value: 120},
                          {name: "125", value: 125},
                          {name: "130", value: 130},
                          {name: "135", value: 135},
                          {name: "140", value: 140},
                          {name: "145", value: 145}];
  $scope.areaValuesMax = [{name: "10", value: 10},
                          {name: "15", value: 15},
                          {name: "20", value: 20},
                          {name: "25", value: 25},
                          {name: "30", value: 30},
                          {name: "35", value: 35},
                          {name: "40", value: 40},
                          {name: "45", value: 45},
                          {name: "50", value: 50},
                          {name: "55", value: 55},
                          {name: "60", value: 60},
                          {name: "65", value: 65},
                          {name: "70", value: 70},
                          {name: "75", value: 75},
                          {name: "80", value: 80},
                          {name: "85", value: 85},
                          {name: "90", value: 90},
                          {name: "95", value: 95},
                          {name: "100", value: 100},
                          {name: "105", value: 105},
                          {name: "110", value: 110},
                          {name: "115", value: 115},
                          {name: "120", value: 120},
                          {name: "125", value: 125},
                          {name: "130", value: 130},
                          {name: "135", value: 135},
                          {name: "140", value: 140},
                          {name: "145", value: 145},
                          {name: "150+", value: 9999}];

  $http.get("medlemssidor/settings").
    success(function(data, status) {
      $scope.roomsMin = $scope.roomValuesMin[data.filter.roomsMin - 1];
      if (data.filter.roomsMax == 999) {
        $scope.roomsMax = $scope.roomValuesMax[$scope.roomValuesMax.length - 1];
      } else{
        $scope.roomsMax = $scope.roomValuesMax[data.filter.roomsMax - 1];
      };
      if (data.filter.rent == 999999) {
        $scope.rent = $scope.rentValues[$scope.rentValues.length - 1];
      } else{
        $scope.rent = $scope.rentValues[data.filter.rent/500 -2];
      };
      $scope.areaMin = $scope.areaValuesMin[data.filter.areaMin/5 -2];
      if (data.filter.areaMax == 9999) {
        $scope.areaMax = $scope.areaValuesMax[$scope.areaValuesMax.length - 1];
      } else{
        $scope.areaMax = $scope.areaValuesMax[data.filter.areaMax/5 -2];
      };
      $scope.emailNotification = data.notify_by_email;
      $scope.smsNotification = data.notify_by_sms;
      $scope.pushNotification = data.notify_by_push_note;
      $scope.mobileNumber = data.mobile_number;
      $scope.firstName = data.first_name;
      $scope.lastName = data.last_name;
    }).
    error(function(data, status) {
      //alert(data)
    });
  
  $scope.submitAllSettings = function() {
    if ( $scope.allSettingsForm.$valid == true) {
      feedBackSymbolWorking($scope.allSettings, "Sparar...");
      var filterSettings = {rooms_min: $scope.roomsMin.value,
                            rooms_max: $scope.roomsMax.value,
                            rent: $scope.rent.value,
                            area_min: $scope.areaMin.value,
                            area_max: $scope.areaMax.value};
      var notificationSettings = {email: $scope.emailNotification,
                                  sms: $scope.smsNotification,
                                  push: $scope.pushNotification};
      var personalInformationSettings = {mobile_number: $scope.mobileNumber,
                                         first_name: $scope.firstName,
                                         last_name: $scope.lastName};
      var data = {data: {filter_settings: filterSettings,
                         notification_settings: notificationSettings,
                         personal_information_settings: personalInformationSettings}};
      $http.post("medlemssidor/settings", data).
        success(function(data, status) {
          //alert(data);
          feedBackSymbolOk($scope.allSettings, "Inställningar sparade");
        }).
        error(function(data, status) {
          //alert(data);
          feedBackSymbolNotOk($scope.allSettings, "Inställningar INTE sparade");
        });
    }
    else {
      feedBackSymbolNotOk($scope.allSettings, "Inställningar INTE sparade");
    }
  };
  
  $scope.submitPasswordSettings = function() {
    if ( $scope.passwordChange.$valid == true ) {
      if ( $scope.new_password == $scope.repeat_password) {
        $scope.data = {new_password: $scope.new_password,
                       old_password: $scope.old_password};
        feedBackSymbolWorking($scope.passwordSettings, "Sparar...");
        $http.post("medlemssidor/change_password", $scope.data).
          success(function(data, status) {
            //alert(data);
            feedBackSymbolOk($scope.passwordSettings, "Inställningar sparade");
          }).
          error(function(data, status) {
            //alert("Natural 1");
            feedBackSymbolNotOk($scope.passwordSettings, "Ditt gamla lösenord verkar inte stämma");
          });
      }
      else {
        // alert("Lösenorden överrensstämmer inte");
        feedBackSymbolNotOk($scope.passwordSettings, "Nytt och upprepat lösenord överrensstämmer inte");
      }
    }
    else {
      feedBackSymbolNotOk($scope.passwordSettings, "Fält saknas");
    }
    $scope.new_password = "";
    $scope.repeat_password = "";
    $scope.old_password = "";
  };

  $scope.terminateAccount = function() {
    if ($scope.accountTermination.$valid == true) {
      $scope.data = {password: $scope.terminationPassword};
      feedBackSymbolWorking($scope.accountTermination, "Avslutar konto...");
      $http.post("medlemssidor/account_termination", $scope.data).
        success(function(data, status) {
          alert("Ditt konto är avslutat.");
          feedBackSymbolOk($scope.accountTermination, "Konto avslutat");
          logout($http, $location)
        }).
        error(function(data, status) {
          // alert("Ditt konto kunde ej avslutas. Försök igen senare.");
          feedBackSymbolNotOk($scope.accountTermination, "Ditt konto kunde ej avslutas. Försök igen senare.");
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
      $scope.apartments = [{address: "Något slags fel"}];
    })
}

function PasswordResetController($scope, $http) {
  $scope.submit = function() {
    if ( $scope.passwordreset.$valid == true) {
      $scope.data = {email: $scope.email};
      $http.post("passwordreset", $scope.data).
        success(function(data, status) {
          //alert(data);
        }).
        error(function(data, status) {
          alert("Lösenordet kunde ej återställas. Försök igen senare.");
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
            //alert(data);
            $location.path('/');
          }).
          error(function(data, status) {
            $scope.message = data;
            //alert("Natural 1");
          });
      }
    }
    else {
      alert("Lösenorden överrensstämmer inte");
    }
  };
}

function PremiumServicesController($scope, $http) {
  deTokenify();
  $scope.premiumUntil = null;
  $scope.smsLeft = 0;
  $scope.showForm = false;
  settingsData = {};

  $http.get("medlemssidor/settings").
    success(function(data, status) {
      settingsData = data;
      $scope.premiumUntil = settingsData.premium_until;
      $scope.smsLeft = settingsData.sms_account;
      $scope.firstName = settingsData.first_name;
      $scope.lastName = settingsData.last_name;
      $scope.mobileNumber = settingsData.mobile_number;
      // alert(data);
    }).
    error(function(data, status) {
      //alert(data);
    });

  $http.get("medlemssidor/packages").
    success(function(data, status) {
      $scope.packages = data;
      // alert(data);
    }).
    error(function(data, status) {
      //alert(data);
    });

  $scope.submitNameInfo = function() {
    if ( $scope.nameForm.$valid == true) {
      data = {data: {mobile_number: $scope.mobileNumber,
                     first_name: $scope.firstName,
                     last_name: $scope.lastName}};
      $http.post("medlemssidor/personal_information", data).
        success(function(data, status) {
          //alert("success");
          settingsData.first_name = $scope.first_name;
          settingsData.last_name = $scope.last_name;
          $scope.buyPackage($scope.sku);
        }).
        error(function(data, status) {
          //alert("error");
        });
    }
  };

  $scope.buyPackage = function(sku) {
    $scope.sku = sku
    if (settingsData.first_name != "" && settingsData.last_name != "") {
      data = {'sku': sku}
      $http.post("payson_pay", data).
        success(function(data, status) {
          //alert(data);
          window.location = data;
        }).
        error(function(data, status) {
          //alert(data);
        });
    } else{
      $scope.showForm = true; 
    };
  };
}

function TestController($scope) {
  deTokenify();
}

// General Controller helper functions

// Assumes form with field called password to be emptied on failed login.
function feedBackSymbolOk(scope, message) {
  scope.feedBackSymbol = "<i class='icon-ok checkmark okness icon-large'></i>";
  scope.message = message;
}

function feedBackSymbolNotOk(scope, message) {
  scope.feedBackSymbol = "<i class='icon-remove checkmark wrongness icon-large'></i>";
  scope.message = message;
}

function feedBackSymbolWorking(scope, message) {
  scope.feedBackSymbol = "<i class='icon-spinner checkmark icon-spin icon-large'></i>";
  scope.message = message;
}

function loginFormFail($scope) {
  $scope.password = "";
  localStorage.loggedIn = "false";
  localStorage.userName = "";
  alert("Felaktigt användarnamn eller lösenord.");
}

function loginFormSuccess(email) {
  localStorage.loggedIn = "true";
  localStorage.userName = email;
}

function logout($http, $location) {
  $http.post("logout").
    success(function() {
      localStorage.loggedIn = "false";
      $location.path('/');
      localStorage.userName = null;
    }).
    error(function() {
      localStorage.loggedIn = "false";
      $location.path('/');
      localStorage.userName = null;
    });
};

function deTokenify() {
  if (window.location.search != "") {
    var l = window.location;
    window.location = l.protocol + "//" + l.host + l.pathname + l.hash;
  };
}

// Special function for defining view helper methods in $rootScope
// Use sparingly. Subject to re-evaluation.
function defineViewHelperMethodsInRootScope($rootScope, $http, $location) {
  $rootScope.userName = function() {
    return localStorage.userName;
  };

  $rootScope.isLoggedIn = function() {
    return localStorage.loggedIn == "true";
  };

  $rootScope.logout = function() {
    logout($http, $location);
  };
}
