# SocialAuthenticationPlugin for Cordova / PhoneGap & iOS 6

by Patrick Heneise ([@PatrickHeneise](http://twitter.com/PatrickHeneise), [about.me/PatrickHeneise](http://about.me/PatrickHeneise))

With this plugin you perform a reverse OAuth authentication with Twitter to register users with your service.

To understand reverse authentication, read [this article](https://dev.twitter.com/docs/ios/using-reverse-auth)

## Installation

1. Within Xcode, copy the folder SocialAuthenticationPlugin to your plugin directory
2. Copy authentication.js to your javascript directory
3. Add authentication.js to your index.html
4. Find the Cordova.plist file in the project navigator, expand the "Plugins" sub-tree, and add a new entry. For the key, add **com.phonegap.authentication**, and its value will be **SocialAuthenticationPlugin**
5. Whitelist `https://api.twitter.com/` in your **ExternalHosts** in **Cordova.plist**
6. From the **Build Settings** tab, click **Add Build Phase** and select **Add User-Defined Setting**, add "TWITTER_CONSUMER_KEY" and "TWITTER_CONSUMER_SECRET" to your user-defined values.
7. From the **Build Phases** tab, expand **Link Binary With Libraries**, then click on the **+** button
8. Select **Twitter.framework**, **Social.framework** and **Accounts.framework** then click Add
9. In Build Phases, Compile Sources, add the following line to TWSignedRequest.m

    -D'TWITTER_CONSUMER_KEY=@"$(TWITTER_CONSUMER_KEY)"' -D'TWITTER_CONSUMER_SECRET=@"$(TWITTER_CONSUMER_SECRET)"'

9. Add `-fno-objc-arc` to NSData+Base64.m, OAuth+Additions.m and OAuthCore.m

See example/ for a working version. You have to change the TWITTER_CONSUMER_KEY and TWITTER_CONSUMER_SECRET to the values for your Twitter application (https://dev.twitter.com/apps).