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

@interface SocialAuthenticationPlugin()

@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) TWAPIManager *apiManager;
@property (nonatomic, strong) NSArray *accounts;
@property (nonatomic, strong) UIButton *reverseAuthBtn;

@end

@implementation SocialAuthenticationPlugin
@synthesize excludedActivityTypes;

-(CDVPlugin*) initWithWebView:(UIWebView *)theWebView {
    self = (SocialAuthenticationPlugin*) [super initWithWebView:theWebView];
    if (self) {
      _accountStore = [[ACAccountStore alloc] init];
      _apiManager = [[TWAPIManager alloc] init];
    }
    return self;
}

- (void) performTwitterReverseAuthentication:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options {
  NSString* callbackId = [arguments objectAtIndex:0];
  NSString* accountName = [options objectForKey:@"username"];

  ACAccount* selectedTwitterAccount;

  for (ACAccount *acct in _accounts) {
    if([acct.username isEqualToString:(accountName)]) {
      selectedTwitterAccount = acct;
    }
  }

  [_apiManager
   performReverseAuthForAccount:selectedTwitterAccount
   withHandler:^(NSData *responseData, NSError *error) {
     if (responseData) {
       NSString *responseStr = [[NSString alloc]
                                initWithData:responseData
                                encoding:NSUTF8StringEncoding];
       
       NSArray *parts = [responseStr
                         componentsSeparatedByString:@"&"];
       
       CDVPluginResult* pluginResult = nil;
       NSString* javaScript = nil;
       pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:parts];
       javaScript = [pluginResult toSuccessCallbackString:callbackId];
       [self performCallbackOnMainThreadforJS:javaScript];
       [responseStr release];
     }
     else {
       CDVPluginResult* pluginResult = nil;
       NSString* javaScript = nil;
       pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
       javaScript = [pluginResult toErrorCallbackString:callbackId];
       [self performCallbackOnMainThreadforJS:javaScript];
     }
  }];
}

- (void) isTwitterAvailable:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options {
  //  Get access to the user's Twitter account(s)
  [self obtainAccessToAccountsWithBlock:^(BOOL granted) {
    dispatch_async(dispatch_get_main_queue(), ^{
      NSString* callbackId = [arguments objectAtIndex:0];
      
      CDVPluginResult* pluginResult = nil;
      NSString* javaScript = nil;
      if(granted) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        javaScript = [pluginResult toSuccessCallbackString:callbackId];
      } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        javaScript = [pluginResult toErrorCallbackString:callbackId];
      }
      [self writeJavascript:javaScript];
    });
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
  
  //  This method changed in iOS6.  If the new version isn't available, fall
  //  back to the original (which means that we're running on iOS5+).
  if ([_accountStore
       respondsToSelector:@selector(requestAccessToAccountsWithType:
                                    options:
                                    completion:)]) {
         [_accountStore requestAccessToAccountsWithType:twitterType
                                                options:nil
                                             completion:handler];
       }
  else {
    [_accountStore requestAccessToAccountsWithType:twitterType
                             withCompletionHandler:handler];
  }
}

-(void) returnTwitterAccounts:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options {
  NSString* callbackId = [arguments objectAtIndex:0];
  
  CDVPluginResult* pluginResult = nil;
  NSString* javaScript = nil;
  
  if ([TWAPIManager isLocalTwitterAccountAvailable]) {
    NSMutableArray *accountNames = [[NSMutableArray alloc] init];

    for (ACAccount *acct in _accounts) {
      [accountNames addObject:acct.username];
    }
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:accountNames];
    javaScript = [self writeJavascript:[pluginResult toSuccessCallbackString:callbackId]];
    [accountNames release];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    javaScript = [pluginResult toErrorCallbackString:callbackId];
  }
  [self writeJavascript:javaScript];
}

// The JS must run on the main thread because you can't make a uikit call (uiwebview) from another thread (what twitter does for calls)
- (void) performCallbackOnMainThreadforJS:(NSString*)javascript{
  [super performSelectorOnMainThread:@selector(writeJavascript:)
                          withObject:javascript
                       waitUntilDone:YES];
}

@end
