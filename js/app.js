'use strict';

/* App Module */

angular.module('cubancabal', []).
  config(['$routeProvider', function($routeProvider) {
  $routeProvider.
      when('', {templateUrl: 'landing',   controller: LandingController}).
      when('/medlemssidor', {templateUrl: 'medlemssidor',   controller: MembersController}).
      when('/login', {templateUrl: 'login'}).
      when('/signup', {templateUrl: 'signup'}).
      when('/logout', {templateUrl: 'logout'}).
      when('/om', {templateUrl: 'om',   controller: LandingController}).
      when('/vanliga-fragor', {templateUrl: 'vanliga-fragor',   controller: FAQController});
}]);