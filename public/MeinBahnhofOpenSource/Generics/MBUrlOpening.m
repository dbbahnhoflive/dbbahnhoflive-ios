// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBUrlOpening.h"
#import <UIKit/UIKit.h>

@implementation MBUrlOpening

+(void)openURL:(NSURL *)url{
    if([self canOpenURL:url]){
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}
+(BOOL)canOpenURL:(NSURL *)url{
    return [[UIApplication sharedApplication] canOpenURL:url];
}

@end
