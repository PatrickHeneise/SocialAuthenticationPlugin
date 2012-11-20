//
//  SocialAuthenticationPlugin.h
//  SocialAuthenticationPlugin
//
//  Copyright (c) 2012 by Patrick Heneise, @PatrickHeneise
//
//
//    Permission is hereby granted, free of charge, to any person obtaining a
//    copy of this software and associated documentation files (the
//    "Software"), to deal in the Software without restriction, including
//    without limitation the rights to use, copy, modify, merge, publish,
//    distribute, sublicense, and/or sell copies of the Software, and to permit
//    persons to whom the Software is furnished to do so, subject to the
//    following conditions:
//
//    The above copyright notice and this permission notice shall be included
//    in all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
//    NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
//    DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
//    OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
//    USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SocialAuthenticationPlugin.h"

#define TW_API_ROOT                  @"https://api.twitter.com"

// the reverse target should return the OAuth reverse header as described here:
// https://dev.twitter.com/docs/ios/using-reverse-auth. If you're using node.js
// have a look at this gist by @npenree:
// https://gist.github.com/f60a49a498d13c1bcf36#file_express.js
#define TW_OAUTH_REVERSE_TARGET      @"http://localhost:3000/auth/twitter/reverse"

// a handler for your oauth access token. If you're using node.js and passport.js,
// check out this strategy: https://github.com/drudge/passport-twitter-token
#define TW_OAUTH_URL_REQUEST_TOKEN   @"http://localhost:3000/auth/twitter/request_token"

#define TW_OAUTH_URL_AUTH_TOKEN      TW_API_ROOT "/oauth/access_token"

// change to your application key
#define TW_CONSUMER_KEY              @"your consumer key"

@interface SocialAuthenticationPlugin()

@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) NSArray *accounts;

@end

@implementation SocialAuthenticationPlugin

-(CDVPlugin*) initWithWebView:(UIWebView *)theWebView {
  self = (SocialAuthenticationPlugin*) [super initWithWebView:theWebView];
  if (self) {
    _accountStore = [[ACAccountStore alloc] init];
  }
  return self;
}

- (void) isTwitterAvailable:(CDVInvokedUrlCommand*)command {
  //  Get access to the user's Twitter account(s)
  [self obtainAccessToAccountsWithBlock:^(BOOL granted) {
    
    CDVPluginResult* pluginResult = nil;
    NSString* javaScript = nil;
    if(granted) {
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
      javaScript = [pluginResult toSuccessCallbackString:command.callbackId];
    } else {
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
      javaScript = [pluginResult toErrorCallbackString:command.callbackId];
    }
    [self performCallbackOnMainThreadforJS:javaScript];
  }];
}

- (void)obtainAccessToAccountsWithBlock:(void (^)(BOOL))block {
  ACAccountType *twitterType = [_accountStore
                                accountTypeWithAccountTypeIdentifier:
                                ACAccountTypeIdentifierTwitter];
  
  ACAccountStoreRequestAccessCompletionHandler handler =
  ^(BOOL granted, NSError *error) {
    if (granted) {
      self.accounts = [_accountStore accountsWithAccountType:twitterType];
    }
    
    block(granted);
  };
  
  [_accountStore requestAccessToAccountsWithType:twitterType
                                         options:nil
                                      completion:handler];
}

- (void) returnTwitterAccounts:(CDVInvokedUrlCommand*)command {
  CDVPluginResult* pluginResult = nil;
  NSString* javaScript = nil;
  
  if ([self isLocalTwitterAccountAvailable]) {
    NSMutableArray *accountNames = [[NSMutableArray alloc] init];
    
    for (ACAccount *acct in _accounts) {
      [accountNames addObject:acct.username];
    }
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:accountNames];
    javaScript = [pluginResult toSuccessCallbackString:command.callbackId];
    [accountNames release];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    javaScript = [pluginResult toErrorCallbackString:command.callbackId];
  }
  [self writeJavascript:javaScript];
}

// The JS must run on the main thread because you can't make a uikit call (uiwebview) from another thread (what twitter does for calls)
- (void) performCallbackOnMainThreadforJS:(NSString*)javascript{
  [super performSelectorOnMainThread:@selector(writeJavascript:)
                          withObject:javascript
                       waitUntilDone:YES];
}

/**
 *  Performs the reverse authentication.
 *
 *  Step 1: Request a signed request token from your server
 *  Step 2: Use the reverse OAuth header from your server and submit it to Twitter
 *  Step 3: Send the oauth_token and oauth_token_secret from Twitter to your server
 *  
 *  pluginResult OK or ERROR
 */
- (void) performTwitterReverseAuthentication:(CDVInvokedUrlCommand*)command {
  ACAccount* selectedTwitterAccount = [[[ACAccount alloc] init] autorelease];
  CDVPluginResult* pluginResult = nil;
  NSString* javaScript = nil;
  
  for (ACAccount *acct in _accounts) {
    if([acct.username isEqualToString:([command.arguments objectAtIndex:0])]) {
      selectedTwitterAccount = acct;
    }
  }
  
  // Perform step 1 and retrieve the access token from your server
  NSString *urlString = [NSString stringWithFormat:TW_OAUTH_REVERSE_TARGET];
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
  [request setURL:[NSURL URLWithString:urlString]];
  [request setHTTPMethod:@"POST"];
  NSHTTPURLResponse* urlResponse = nil;
  NSError *error = [[NSError alloc] init];
  NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
  NSString *oauthAccessToken = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
  
  // Perform step 2 and request access to your app
  if ([urlResponse statusCode] >= 200 && [urlResponse statusCode] < 300) {
    NSDictionary *step2Params = [[NSMutableDictionary alloc] init];
    [step2Params setValue:TW_CONSUMER_KEY forKey:@"x_reverse_auth_target"];
    [step2Params setValue:oauthAccessToken forKey:@"x_reverse_auth_parameters"];
    
    NSURL *authTokenURL = [NSURL URLWithString:TW_OAUTH_URL_AUTH_TOKEN];
    id<GenericTwitterRequest> step2Request =
    [self requestWithUrl:authTokenURL
              parameters:step2Params
           requestMethod:SLRequestMethodPOST];
    
    [step2Request setAccount:selectedTwitterAccount];
    
    // execute the request
    [step2Request performRequestWithHandler:^(NSData *responseData, NSURLResponse *urlResponse, NSError *step2error) {
      NSString *responseStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
      CDVPluginResult* pluginResult = nil;
      NSString* javaScript = nil;
      
      // Perform step 3 and send the oauth result to your server
      NSString *tokenUrlString = [NSString stringWithFormat:TW_OAUTH_URL_REQUEST_TOKEN];
      NSMutableURLRequest *tokenRequest = [[NSMutableURLRequest alloc] init];
      [tokenRequest setURL:[NSURL URLWithString:tokenUrlString]];
      [tokenRequest setHTTPMethod:@"POST"];
      NSMutableData *postBody = [NSMutableData data];
      [postBody appendData:responseData];
      [tokenRequest setHTTPBody:postBody];
      NSHTTPURLResponse* tokenUrlResponse = nil;
      NSError *tokenError = [[NSError alloc] init];
      NSData *tokenResponseData = [NSURLConnection sendSynchronousRequest:tokenRequest returningResponse:&tokenUrlResponse error:&tokenError];
      NSString *tokenResponse = [[NSString alloc] initWithData:tokenResponseData encoding:NSUTF8StringEncoding];
      if ([tokenUrlResponse statusCode] >= 200 && [tokenUrlResponse statusCode] < 300) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        javaScript = [pluginResult toSuccessCallbackString:command.callbackId];
      }
      [tokenError release];
      [tokenRequest release];
      [tokenResponse release];
      [responseStr release];
      [self performCallbackOnMainThreadforJS:javaScript];
    }];
    [step2Params release];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    javaScript = [pluginResult toErrorCallbackString:command.callbackId];
  }
  [request release];
  [error release];
  [oauthAccessToken release];
  [self performCallbackOnMainThreadforJS:javaScript];
}

/**
 *  Returns true if there are local Twitter accounts available for use.
 *
 *  Both iOS5 and iOS6 provide convenience methods to check if accounts are
 *  available locally.  Here, we just call the method that is available at
 *  run-time.
 */
- (BOOL)isLocalTwitterAccountAvailable {
  //  checks to see if we have Social.framework
  return [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
}

/**
 *  Returns a generic self-signing request that can be used to perform Twitter
 *  API requests.
 *
 *  @param  The URL of the endpoint to retrieve
 *  @dict   The API parameters to include with the request
 *  @requestMethod  The HTTP method to use
 */
- (id<GenericTwitterRequest>)requestWithUrl:(NSURL *)url
                                 parameters:(NSDictionary *)dict
                              requestMethod:(SLRequestMethod )requestMethod
{
  NSParameterAssert(url);
  NSParameterAssert(dict);
  NSParameterAssert(requestMethod);
  return (id<GenericTwitterRequest>)
  [SLRequest requestForServiceType:SLServiceTypeTwitter
                     requestMethod:requestMethod
                               URL:url
                        parameters:dict];
  
}

@end
