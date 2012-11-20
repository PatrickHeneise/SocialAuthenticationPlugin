# SocialAuthenticationPlugin for Cordova / PhoneGap & iOS 6

by Patrick Heneise ([@PatrickHeneise](http://twitter.com/PatrickHeneise), [about.me/PatrickHeneise](http://about.me/PatrickHeneise))

With this plugin you perform a reverse OAuth authentication with Twitter to register users with your service.

To understand reverse authentication, read [this article](https://dev.twitter.com/docs/ios/using-reverse-auth)

## Installation

1. Within Xcode, copy the folder SocialAuthenticationPlugin to your plugin directory
2. Copy authentication.js to your javascript directory
3. Add authentication.js to your index.html
4. Find the Cordova.plist file in the project navigator, expand the "Plugins" sub-tree, and add a new entry. For the key, add **Authentication**, and its value will be **SocialAuthenticationPlugin**
5. Whitelist `https://api.twitter.com/` and your application server (localhost:3000 in the demo) in your **ExternalHosts** in **Cordova.plist**
6. Add your Twitter consumer key (https://dev.twitter.com/apps) to SocialAuthenticationPlugin.m line 45
7. From the **Build Phases** tab, expand **Link Binary With Libraries**, then click on the **+** button
8. Select **Twitter.framework**, **Social.framework** and **Accounts.framework** then click Add

See example/ for a working version.

## Application Server

For a node.js/passport.js application server, you can use this passport strategy https://github.com/drudge/passport-twitter-token and this route https://gist.github.com/f60a49a498d13c1bcf36#file_express.js.
