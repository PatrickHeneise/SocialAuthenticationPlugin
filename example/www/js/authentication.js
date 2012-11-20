(function(cordova) {

  function SocialAuthenticationPlugin (){};

  SocialAuthenticationPlugin.prototype.isTwitterAvailable = function(callback) {
    cordova.exec(callback, null, 'Authentication', 'isTwitterAvailable', []);
  };

  SocialAuthenticationPlugin.prototype.returnTwitterAccounts = function(callback) {
    cordova.exec(callback, null, 'Authentication', 'returnTwitterAccounts', []);
  };

  SocialAuthenticationPlugin.prototype.performTwitterReverseAuthentication = function(success, error, username) {
    options = {};
    options.username = username;
    cordova.exec(success, error, 'Authentication', 'performTwitterReverseAuthentication', [username]);
  };

  cordova.addConstructor(function() {
    if(!window.plugins) window.plugins = {};
      window.plugins.socialAuthenticationPlugin = new SocialAuthenticationPlugin();
    });

})(window.cordova || window.Cordova);