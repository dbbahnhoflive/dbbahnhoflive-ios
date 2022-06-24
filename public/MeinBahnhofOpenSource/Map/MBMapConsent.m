// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBMapConsent.h"
#import "MBMapConsentViewController.h"

@interface MBMapConsent()
@property(nonatomic) BOOL consentStatus;
@end

@implementation MBMapConsent

+ (MBMapConsent*)sharedInstance
{
    static MBMapConsent *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[self alloc] init];
    });
    return sharedClient;
}

-(void)showConsentDialogInViewController:(UIViewController*)vc completion:(void (^)(void))completion{
    if(self.consentStatus){
        completion();
        return;
    }
    [MBMapConsentViewController presentAlertOnViewController:vc consentCompletion:^{
        self.consentStatus = true;
        completion();
    }];
}

@end
