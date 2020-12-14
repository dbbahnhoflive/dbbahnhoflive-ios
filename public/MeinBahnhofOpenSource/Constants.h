// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Constants : NSObject

+(void)setup;

+(NSString*)kBusinesshubKey;
+(NSString*)kNewsApiKey;
+(NSString*)kBusinessHubProdBaseUrl;
+(NSString*)kPTSPath;


+(NSString*)kHafasKey;
+(NSString*)kMapsKey;
+(NSString*)kSentryDNS;

+(UIColor*)dbMainColor;

@end
