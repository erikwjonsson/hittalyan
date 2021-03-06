'use strict';

/* Controllers */

function IndexController($rootScope, $scope, $http, $location, analytics) {
  $scope.navBarCollapsed = true;
  defineViewHelperMethodsInRootScope($rootScope, $http, $location);
  // Wedon't use this much anymore. Could maybe be removed.
  // getEnvironment($http, $rootScope);
}

function LandingController($scope, analytics) {
  LOGIN_DESTINATION = '/medlemssidor';
  $scope.message = "There is no spoon. Revenge!";
}

function AboutController($scope, $http, analytics) {
  LOGIN_DESTINATION = '/medlemssidor';
  $scope.messageSent = false;

  $scope.submit = function() {
    if ($scope.contact.$valid === true) {
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

function LoginController($scope, $http, $routeParams, $location, analytics) {
  function loggedInSuccess() {
    feedBackSymbolOk($scope, "Loggar in...");
    $scope.email = "";
    $scope.password = "";
    loginFormSuccess($scope.data.email);
    $location.path(LOGIN_DESTINATION);

    // Reset login destination
    LOGIN_DESTINATION = '/medlemssidor';
  }

  $scope.submit = function() {
    feedBackSymbolWorking($scope, "Loggar in...") ;
    if ( $scope.login.$valid === true ) {
      $scope.data = {email: $scope.email,
                     password: $scope.password};
      $http.post("login", $scope.data).
        success(function(data, status) {
          if (status === 200) {
            loggedInSuccess();
          }
          else {
            loginFormFail($scope);
          }
        }).
        error(function(data, status) {
          loginFormFail($scope);
        });
    }
    else {
      loginFormFail($scope);
    }
  };
}

function NavbarLoginController($scope, $http, $routeParams, $location, analytics) {
  function loggedInSuccess() {
    $scope.email = "";
    $scope.password = "";
    $location.path(LOGIN_DESTINATION);

    // Reset login destination
    LOGIN_DESTINATION = '/medlemssidor';
    
    loginFormSuccess($scope.data.email);
  }

  function loggedInFail($scope) {
    $scope.password = "";
    localStorage.loggedIn = "false";
    localStorage.userName = "";
    alert("Felaktigt användarnamn eller lösenord.");
  }

  $scope.submit = function() {
    feedBackSymbolWorking($scope, "Loggar in...");
    if ( $scope.login.$valid === true ) {
      $scope.data = {email: $scope.email,
                     password: $scope.password};
      $http.post("login", $scope.data).
        success(function(data, status) {
          if (status === 200) {
            loggedInSuccess();
          }
          else {
            loggedInFail($scope);
          }
        }).
        error(function(data, status) {
          loggedInFail($scope);
        });
    }
    else {
      loggedInFail($scope);
    }
  };
}

function FAQController($scope, $routeParams, analytics) {
  LOGIN_DESTINATION = '/medlemssidor';
}

function SignupController($scope, $http, $location, analytics) {
  LOGIN_DESTINATION = '/medlemssidor';

  $scope.trafficSourceOptions = [{name: "Affisch", value: "Affisch"},
                                {name: "Blogg", value: "Blogg"},
                                {name: "Facebookannons", value: "Facebookannons"},
                                {name: "Facebookgrupp", value: "Facebookgrupp"},
                                {name: "Googleannons", value: "Googleannons"},
                                {name: "Googlesökning", value: "Googlesökning"},
                                {name: "Rabattsida", value: "Rabattsida"},
                                {name: "Tidningsartikel", value: "Tidningsartikel"},
                                {name: "Tipsad av kompis", value: "Tipsad av kompis"},
                                {name: "Annat", value: "Annat"}]

  function loggedInSuccess() {
    trackConversion();
    $scope.message = "Registrering lyckad. Loggar in...";
    $http.post("login", $scope.data).
    success(function(data, status) {
      $scope.message = "Inloggad. Omdirigerar...";
      loginFormSuccess($scope.data.email);
      buyPackage("PREMIUM30SMS");
    }).
    error(function(data, status) {
      $scope.message = "Registrering lyckad men inloggning misslyckad";
      $scope.working = false;
      $scope.cross = true;
      localStorage.loggedIn = "false";
    });
  }

  function loggedInFail() {
    $scope.message = "Registrering misslyckad";
    $scope.working = false;
    $scope.cross = true;
  }

  buyPackage = function(sku) {
    data = {'sku': sku,
            'code': "NONE"};
    $http.post("payson_pay", data).
      success(function(data, status) {
        window.location = data;
      }).
      error(function(data, status) {
      });
  };

  $scope.submit = function() {
    if ( $scope.signup.$valid === true) {
      $scope.data = {email: $scope.email,
                     password: $scope.password,
                     first_name: $scope.first_name,
                     last_name: $scope.last_name,
                     referred_by: $scope.referred_by,
                     traffic_source: $scope.traffic_source.value};
      $scope.message = "Registrerar...";
      $scope.working = true;
      $scope.cross = false;
      $http.post("signup", {data: $scope.data }).
        success(function(data, status) {
          // Hack because of some funky business happening...
          if (status === 200) {
            loggedInSuccess();
          }
          else {
            loggedInFail();
          }
          
      }).
        error(function(data, status) {
          loggedInFail();
        });
    }
  };
}

function MemberSidebarController($scope) {
  $scope.memberSidebarUrl = "membersidebar"
}

function MembersController($scope, $http, analytics) {
  $scope.userData = {};
  $scope.showFirstDayMessage = false;
  $scope.showNoApartmentsMessage = false;
  $scope.smsActiveState = true;
  $scope.showUserInactiveMessage = false;
  $scope.showBlurredApartments = false;

  // Sorting of apartments
  $scope.sortingOrderedBy = 'advertisement_found_at';
  $scope.sortingReversed = 'true';

  $scope.range = function(n) {
    return new Array(n);
  };

  $scope.isOrderedBy = function(predicate) {
    if (predicate === $scope.sortingOrderedBy) {
      return true;
    }
    return false;
  };

  function firstDay() {
    function mongoIdToDate(mongoId) {
      timestamp = mongoId.toString().substring(0,8);
      date = new Date(parseInt(timestamp, 16) * 1000);
      return date;
    }

    membershipDate = mongoIdToDate($scope.userData._id);
    console.log("membership date: " + membershipDate);
    date = new Date();
    yesterday = new Date(date.setDate(date.getDate() - 1));
    console.log("yesterday: " + yesterday);
    if (membershipDate <= yesterday) {
      return false;
    }
    return true;
  };

  $http.get("medlemssidor/user" + mingDate()).
    success(function(data, status) {
      $scope.userData = data;
      $scope.showFirstDayMessage = firstDay();
      $scope.smsActiveState = setSmsActiveState($scope.userData.sms_until);
      $scope.showUserInactiveMessage = !$scope.userData.active;
      $scope.showBlurredApartments = !$scope.userData.active;
      if ($scope.userData.active === true) {
        $scope.apartments = [];
        $http.get("medlemssidor/apartments_list" + mingDate()).
          success(function(data, status) {
            $scope.apartments = data;
          }).
          then(function() {
            $scope.showNoApartmentsMessage = ($scope.apartments.length === 0)
        });
      };
    }).
    error(function(data, status) {
    });
}

function SettingsController($scope, $http, $location, analytics) {
  // Making room for namespaces
  $scope.userData = {};
  $scope.passwordSettings = {};
  $scope.accountTermination = {};
  $scope.allSettings = {};
  $scope.apartmentsEstimate = null;
  $scope.fewApartmentsEstimate = false;
  $scope.manyApartmentsEstimate = false;
  $scope.validMobileNumber = true;
  $scope.smsActiveState = true;
  $scope.showUserInactiveMessage = false;
  
  $scope.cities = [{name: "Stockholm", value: 0},
                   {name: "Malmö", value: 1},
                   {name: "Gävle", value: 2},
                   {name: "Eskilstuna", value: 3}];
  $scope.city = $scope.cities[0];

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
  $scope.stopSendValues = [{name: "21:00", value: 2100},
                           {name: "21:30", value: 2130},
                           {name: "22:00", value: 2200},
                           {name: "22:30", value: 2230},
                           {name: "23:00", value: 2300},
                           {name: "23:30", value: 2330},
                           {name: "00:00", value: 2359}];
  $scope.startSendValues = [{name: "05:00", value: 500},
                            {name: "05:30", value: 530},
                            {name: "06:00", value: 600},
                            {name: "06:30", value: 630},
                            {name: "07:00", value: 700},
                            {name: "07:30", value: 730},
                            {name: "08:00", value: 800}];
  
  function findTime(timeDigits, arr) {
    for (var i = 0; i < arr.length; i++) {
      if (arr[i].value == timeDigits) {
        return arr[i];
      }
    }
    return undefined;
  }

  function notificationTimesOn() {
    if ($scope.startSend.value === 0 || $scope.stopSend.value === 2359) {
      // Set default values
      $scope.stopSend = $scope.stopSendValues[0];
      $scope.startSend = $scope.startSendValues[0];
      $scope.submitAllSettings();
    }
    else {
      // Display the values from the db
      $scope.stopSend = findTime($scope.userData.stop_sending_notifications_at, $scope.stopSendValues);
      $scope.startSend = findTime($scope.userData.start_sending_notifications_at, $scope.startSendValues);
    }
    $scope.notificationTimes = true;
  }

  function notificationTimesOff() {
    $scope.startSend.value = 0;
    $scope.stopSend.value = 2359;
    $scope.notificationTimes = false;
    $scope.submitAllSettings();
  }

  $scope.triggerNotificationTimes = function() {
    if ($scope.notificationTimes === true) {
      // becomes checked
      notificationTimesOn();
    }
    else {
      // becomes unchecked
      notificationTimesOff();
    }
  };
  $scope.stopSend = {};
  $scope.startSend = {};
  $scope.notificationTimes = false;

  $http.get("medlemssidor/user" + mingDate()).
    success(function(data, status) {
      $scope.userData = data;
      $scope.showUserInactiveMessage = !$scope.userData.active;
      $scope.roomsMin = $scope.roomValuesMin[data.filter.rooms.min - 1];
      if (data.filter.rooms.max === 999) {
        $scope.roomsMax = $scope.roomValuesMax[$scope.roomValuesMax.length - 1];
      } else{
        $scope.roomsMax = $scope.roomValuesMax[data.filter.rooms.max - 1];
      }
      if (data.filter.rent === 999999) {
        $scope.rent = $scope.rentValues[$scope.rentValues.length - 1];
      } else{
        $scope.rent = $scope.rentValues[data.filter.rent/500 -2];
      }
      $scope.areaMin = $scope.areaValuesMin[data.filter.area.min/5 -2];
      if (data.filter.area.max === 9999) {
        $scope.areaMax = $scope.areaValuesMax[$scope.areaValuesMax.length - 1];
      } else{
        $scope.areaMax = $scope.areaValuesMax[data.filter.area.max/5 -2];
      }
      $scope.smsActiveState = setSmsActiveState($scope.userData.sms_until);
      $scope.stopSend.value = $scope.userData.stop_sending_notifications_at;
      $scope.startSend.value = $scope.userData.start_sending_notifications_at;

      if ($scope.startSend.value !== 0 || $scope.stopSend.value !== 2359) {
        notificationTimesOn();
      }

    }).
    error(function(data, status) {
      //alert(data)
    });

  $scope.submitAllSettings = function() {
    if ( $scope.allSettingsForm.$valid === true) {
      var userData = $scope.userData;
      userData.filter.rooms.min = $scope.roomsMin.value;
      userData.filter.rooms.max = $scope.roomsMax.value;
      userData.filter.rent = $scope.rent.value;
      userData.filter.area.min = $scope.areaMin.value;
      userData.filter.area.max = $scope.areaMax.value;
      userData.stop_sending_notifications_at = $scope.stopSend.value;
      userData.start_sending_notifications_at = $scope.startSend.value;
      var data = {data: userData};
      
      feedBackSymbolWorking($scope.allSettings, "Sparar...");
      $http.post("medlemssidor/user", data);
    }
    console.log("submittedAllSettings");
  };
  
  $scope.addCity = function() {
    $scope.userData.filter.cities.pushUnique($scope.city.name);
    $scope.changeHandler();
  };
  
  $scope.removeCity = function(city) {
    $scope.userData.filter.cities.remove(city);
    $scope.changeHandler();
  };

  $scope.getApartmentsEstimate = function() {
    $http.get("medlemssidor/apartments_estimate/" + $scope.roomsMin.value + "/" + $scope.roomsMax.value + "/" + $scope.rent.value + "/" + $scope.areaMin.value + "/" + $scope.areaMax.value + "/" + JSON.stringify($scope.userData.filter.cities))
      .success(function(data, status) {
        $scope.apartmentsEstimate = data.count;
        if (data.count <= 10 ) {
          $scope.manyApartmentsEstimate = false;
          $scope.fewApartmentsEstimate = true;
        }
        else {
          $scope.fewApartmentsEstimate = false;
          $scope.manyApartmentsEstimate = true;
        };
      });
    console.log("gotApartmentEstimate");
  };

  $scope.changeHandler = function() {
    $scope.getApartmentsEstimate();
    $scope.submitAllSettings();
  };
  
  $scope.submitPasswordSettings = function() {
    if ( $scope.passwordChange.$valid === true ) {
      if ( $scope.new_password === $scope.repeat_password) {
        $scope.data = {new_password: $scope.new_password,
                       old_password: $scope.old_password};
        feedBackSymbolWorking($scope.passwordSettings, "Sparar...");
        $http.post("medlemssidor/change_password", $scope.data).
          success(function(data, status) {
            //alert(data);
            if (status === 400) {
              feedBackSymbolNotOk($scope.passwordSettings, "Ditt gamla lösenord verkar inte stämma");
            }else {
              feedBackSymbolOk($scope.passwordSettings, "Lösenord ändrat");
            }
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
    if ($scope.accountTermination.$valid === true) {
      $scope.data = {password: $scope.terminationPassword};
      feedBackSymbolWorking($scope.accountTermination, "Avslutar konto...");
      $http.post("medlemssidor/account_termination", $scope.data).
        success(function(data, status) {
          if (status === 400) {
            feedBackSymbolNotOk($scope.accountTermination, "Ditt konto kunde ej avslutas. Försök igen senare.");
          } else{
            alert("Ditt konto är avslutat.");
            feedBackSymbolOk($scope.accountTermination, "Konto avslutat");
            logout($http, $location);
          };
        }).
        error(function(data, status) {
          // alert("Ditt konto kunde ej avslutas. Försök igen senare.");
          feedBackSymbolNotOk($scope.accountTermination, "Ditt konto kunde ej avslutas. Försök igen senare.");
        });
    }
  };

  validateMobileNumber = function() {
    var mobileNumber = $scope.userData.mobile_number;
    if (!mobileNumber) {
      $scope.validMobileNumber = true;
    }
    else if (mobileNumber[0] != "0" && mobileNumber[0] != "+") {
      $scope.validMobileNumber = false;
    }
    else {
      $scope.validMobileNumber = true;
    }
  };

  $scope.mobileNumberChangeHandler = function() {
    validateMobileNumber();
    $scope.submitAllSettings();
  };
}

function ApartmentsController($scope, $http, analytics) {
  $scope.userData = {};
  
  $scope.userData.active = true;
  $http.get("medlemssidor/apartments_list" + mingDate()).
    success(function(data, status) {
      $scope.apartments = data;
    }).
    error(function(data, status) {
      $scope.apartments = [{address: "Något slags fel"}];
  });

  $http.get("medlemssidor/user" + mingDate()).
    success(function(data, status) {
      $scope.userData = data;
    }).
    error(function(data, status) {
    });
}

function PremiumServicesController($scope, $http, analytics) {
  $scope.showForm = false;
  $scope.showCouponForm = false;
  $scope.showCouponInfo = false;
  $scope.smsActiveState = true;
  $scope.showUserInactiveMessage = false;

  $scope.coupon = {code: "NONE",
                   discount_in_percentage_units: 0,
                   valid: false};

  $http.get("medlemssidor/user" + mingDate()).
    success(function(data, status) {
      $scope.userData = data;
      $scope.showUserInactiveMessage = !$scope.userData.active;
      $scope.smsActiveState = setSmsActiveState($scope.userData.sms_until);
      // alert(data);
    }).
    error(function(data, status) {
      //alert(data);
    });

  $http.get("medlemssidor/packages" + mingDate()).
    success(function(data, status) {
      $scope.packages = data;
      $scope.packages.sort(function(a, b) {
        return a.priority - b.priority;
      });
      // alert(data);
    }).
    error(function(data, status) {
      //alert(data);
    });

  $scope.submitNameInfo = function() {
    if ( $scope.nameForm.$valid === true) {
      data = {data: $scope.userData};
      $http.post("medlemssidor/user", data).
        success(function(data, status) {
          //alert("success");
          $scope.buyPackage($scope.sku);
        }).
        error(function(data, status) {
          //alert("error");
        });
    }
  };

  $scope.buyPackage = function(sku) {
    $scope.sku = sku;
    if ($scope.userData.first_name !== "" && $scope.userData.last_name !== "") {
      data = {'sku': sku,
              'code': $scope.coupon.code};
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
    }
  };
  
  $scope.submitCoupon = function() {
    var getString = "medlemssidor/coupon" + "/" + $scope.couponCode;
    $http.get(getString + mingDate()).
      success(function(data, status) {
        $scope.coupon = data;
        $scope.showCouponInfo = true;
        console.log($scope.coupon);
      }).
      error(function(data, status) {
        $scope.coupon = data;
        $scope.showCouponInfo = true;
      });
  };
  
  $scope.toggleCouponForm = function() {
    $scope.showCouponForm = !$scope.showCouponForm;
  };
  
  $scope.imageURL = function(name) {
    return "images/package_" + name.toLowerCase() + ".png";
  };
  
  $scope.couponifyPrice = function(pkg, coupon) {
    var package_price = (pkg.unit_price_in_ore/100);
    var discount = (coupon.discount_in_percentage_units/100);

    return Math.floor(package_price*(1-discount)*1.25);
  };
}

function PaymentConfirmationController($scope, $http) {
  function capitalizeFirstLetter(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
  }

  $scope.smsActiveState = true;
  $scope.emailProvider = {}

  $http.get("medlemssidor/user" + mingDate()).
    success(function(data, status) {
      $scope.userData = data;
      $scope.smsActiveState = setSmsActiveState($scope.userData.sms_until);

      $scope.emailProvider.displayName = capitalizeFirstLetter($scope.userData.email.split('@')[1]);
      $scope.emailProvider.url = "http://www." + $scope.emailProvider.displayName.toLowerCase();
      // alert(data);
    }).
    error(function(data, status) {
      //alert(data);
    });
}

function CampaignController($scope, $http, analytics) {
  
}

function PasswordResetController($scope, $http, analytics) {
  LOGIN_DESTINATION = '/medlemssidor';

  $scope.mailSent = false;
  $scope.submit = function() {
    if ( $scope.passwordreset.$valid === true) {
      $scope.data = {email: $scope.email};
      $http.post("passwordreset", $scope.data).
        success(function(data, status) {
          //alert(data);
        }).
        error(function(data, status) {
          alert("E-postmeddelandet kunde ej skickas. Försök igen senare.");
        });
      $scope.mailSent = true;
    }
  };
}

function PasswordResetConfirmationController($scope, $http, $routeParams, $location, analytics) {
  // $scope.message = "Lösenordet återställs. Var god vänta...."
  function loggedInSuccess() {
    $scope.new_password = "";
    loginFormSuccess($scope.data.email);
    $location.path('/medlemssidor');
  }

  $scope.submit = function() {
    if ( $scope.new_password === $scope.repeat_password ) {
      if ( $scope.passwordresetconfirmation.$valid === true) {
        $scope.data = {hash: $routeParams.hash,
                       new_password: $scope.new_password};
        $http.post("passwordreset", $scope.data).
          success(function(data, status) {
            $scope.data = {email: data.email,
                           password: $scope.new_password};
            $http.post("login", $scope.data).
              success(function(data, status) {
                if (status === 200) {
                  loggedInSuccess();
                }
                else {
                  loginFormFail($scope);
                }
              }).
              error(function(data, status) {
                loginFormFail($scope);
              });
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


function ShitController(analytics) {
}

function TestController(analytics) {
}

// Extensions

// Check if value exists in array
Array.prototype.exists = function(element) {
  for(var i=0; i<this.length; i++) {
    if(this[i] === element ){
      return true;
    }
  }
  return false;
};

// Push to array if unique value
Array.prototype.pushUnique = function(new_element) {
  if (this.exists(new_element) === true) {
    return false;
  }
  return this.push(new_element);
};

// Remove element from array by value
Array.prototype.remove = function() {
  var what, a = arguments, L = a.length, ax;
  while (L && this.length) {
    what = a[--L];
    while ((ax = this.indexOf(what)) !== -1) {
      this.splice(ax, 1);
    }
  }
  return this;
};

// General Controller helper functions
function setSmsActiveState(sms_until) {
  if (new Date(sms_until) > new Date()) {
    return true;
  } else{
    return false;
  }
};

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

// Assumes form with field called password to be emptied on failed login.
function loginFormFail($scope) {
  $scope.password = "";
  localStorage.loggedIn = "false";
  localStorage.userName = "";
  feedBackSymbolNotOk($scope, "Felaktigt användarnamn eller lösenord.");
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
}

function getEnvironment($http, $rootScope) {
  $http.get("environment" + mingDate()).
    success(function(data, status) {
      environment = data;
    }).
    error(function(data, status) {
      environment = null;
    });
}

// I'm alone and useless now. please use me. Or abuse me. Anything!
function deTokenify() {
  if (window.location.search !== "") {
    var l = window.location;
    window.location = l.protocol + "//" + l.host + l.pathname + l.hash;
  }
}

function mingDate() {
  var date = Date();
  return "?ming=" + date + "mongo";
}

function trackConversion() {
  google_conversion_id = 984866425;
  google_conversion_label = "l9YnCLfbyggQ-bzP1QM";
  var image = new Image(1,1);
  image.src = 'http://www.googleadservices.com/pagead/conversion/' +
    google_conversion_id + '/?label=' + google_conversion_label +
    '&value=1&guid=ON&script=0';
}

// Special function for defining view helper methods in $rootScope
// Use sparingly. Subject to re-evaluation.
function defineViewHelperMethodsInRootScope($rootScope, $http, $location) {
  $rootScope.oneDayBefore = function(date) {
    var d = new Date(date);
    d.setDate(d.getDate() - 1);
    return d;
  }

  $rootScope.userName = function() {
    return localStorage.userName;
  };

  $rootScope.isLoggedIn = function() {
    return localStorage.loggedIn === "true";
  };

  $rootScope.logout = function() {
    logout($http, $location);
  };
  
  $rootScope.production = function() {
    return environment === "production";
  };
  
  $rootScope.development = function() {
    return environment === "development";
  };
  
  $rootScope.test = function() {
    return environment === "test";
  };
  
  $rootScope.testDev = function() {
    return ($rootScope.development() || $rootScope.test());
  };
}
