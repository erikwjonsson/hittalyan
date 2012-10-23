﻿'use strict';

/* App Module */

angular.module('cubancabal', [])
  .config(['$routeProvider', function($routeProvider) {
  $routeProvider.
      when('/', {templateUrl: 'landing',   controller: LandingController}).
      when('/medlemssidor', {templateUrl: 'medlemssidor', controller: MembersController}).
      when('/medlemssidor/filtersettings', {templateUrl: '/medlemssidor/filtersettings', controller: FiltersController}).
      when('/medlemssidor/apartments', {templateUrl: '/medlemssidor/apartments_template', controller: ApartmentsController}).
      when('/login', {templateUrl: 'login', controller: LoginController}).
      when('/registrera', {templateUrl: 'signup', controller: SignupController}).
      when('/om', {templateUrl: 'om',   controller: LandingController}).
      when('/test', {templateUrl: 'test',   controller: TestController}).
      when('/vanliga-fragor', {templateUrl: 'vanliga-fragor', controller: FAQController}).
      when('/losenordsaterstallning', {templateUrl: 'passwordreset', controller: PasswordResetController}).
      otherwise({redirectTo: '/'});
}])
  .run( function($rootScope, $location) {
    $rootScope.$on( "$routeChangeStart", function(event, next, current) {
      if ( next.templateUrl == "login" ) {
        if ( localStorage.loggedIn ) {
          $location.path('/medlemssidor');
          next.templateUrl = 'medlemssidor';
        }
      }
      if ( next.templateUrl ) {
        if ( next.templateUrl.indexOf("medlemssidor") != -1) {
          if ( localStorage.loggedIn == "false" || localStorage.loggedIn == null) {
            $location.path('/login');
            next.templateUrl = 'login';
          }
        }
      }        
    });
    
    $rootScope.$on( "$routeChangeError", function(event, next, current) {
      $location.path('/');
      // $rootScope
    })
  });