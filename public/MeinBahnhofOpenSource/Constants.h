// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Constants : NSObject

+(void)setup;

+(NSString*)kDBAPI;
+(NSString*)dbAPIKey;
+(NSString*)dbAPIClient;

+(NSString*)dbFastaKey;
+(NSString*)dbFastaClient;

+(NSString*)kBusinesshubKey;
+(NSString*)kNewsApiKey;
+(NSString*)kBusinessHubProdBaseUrl;

+(NSString*)kRISStationsPath;
+(NSString*)rimapHost;
+(NSString*)rimapKey;
+(NSString*)kHafasKey;
+(NSString*)kMapsKey;
+(NSString*)kSentryDNS;

+(UIColor*)dbMainColor;


+(BOOL)usePushServices;


@end
