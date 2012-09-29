'use strict';

/* App Module */

angular.module('cubancabal', []).
  config(['$routeProvider', function($routeProvider) {
  $routeProvider.
      when('', {templateUrl: 'landing',   controller: LandingController}).
      when('/medlemssidor', {templateUrl: 'medlemssidor', controller: MembersController}).
      when('/medlemssidor/filtersettings', {templateUrl: '/medlemssidor/filtersettings', controller: MembersController}).
      when('/medlemssidor/apartments', {templateUrl: '/medlemssidor/apartments', controller: MembersController}).
      when('/login', {templateUrl: 'login', controller: LoginController}).
      when('/signup', {templateUrl: 'signup'}).
      when('/logout', {templateUrl: 'logout'}).
      when('/om', {templateUrl: 'om',   controller: LandingController}).
      when('/test', {templateUrl: 'test',   controller: TestController}).
      when('/vanliga-fragor', {templateUrl: 'vanliga-fragor', controller: FAQController});
}]);