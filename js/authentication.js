var SocialAuthenticationPlugin = function (){};

SocialAuthenticationPlugin.prototype.isTwitterAvailable = function(response) {
  cordova.exec(response, null, "com.phonegap.authentication", "isTwitterAvailable", []);
};

SocialAuthenticationPlugin.prototype.returnTwitterAccounts = function(response) {
  cordova.exec(response, null, "com.phonegap.authentication", "returnTwitterAccounts", []);
};

SocialAuthenticationPlugin.prototype.performTwitterReverseAuthentication = function(success, error, username){
  options = {};
  options.username = username;
  cordova.exec(success, error, "com.phonegap.authentication", "performTwitterReverseAuthentication", [options]);
};

cordova.addConstructor(function() {
  if(!window.plugins) window.plugins = {};
  window.plugins.SocialAuthenticationPlugin = new SocialAuthenticationPlugin();
});
