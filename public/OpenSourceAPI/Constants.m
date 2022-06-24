// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//
//
//  Constants.m
//  Open Source Version!
//
#import "Constants.h"
#import "UIColor+DBColor.h"

@implementation Constants

+(void)setup{
    
}

+(NSString*)kBusinesshubKey{
    return @"";
}
+(NSString*)kNewsApiKey{
    return @"";
}
+(NSString*)dbAPIKey{
    return @"ae429e8b34b1366eb37ca466260f92f8";
}

+(NSString*)kDBAPI{
    return @"https://apis.deutschebahn.com/db/apis";
}
+(NSString*)kBusinessHubProdBaseUrl{
    return @"";
}

+(NSString*)dbAPIClient{
    return @"be998c9dd20ae7b9440839580644fc47";
}

+(NSString*)dbFastaKey{
    return @"15d020725ecb768ea41a5925a26bf50e";
}
+(NSString*)dbFastaClient{
    return @"1c5f5114b79924f8d34d50cb601d4dd6";
}


+(NSString*)kRISStationsPath{
    return @"ris-stations/v1";
}

+(NSString*)rimapKey{
    return @"";
}
+(NSString*)rimapHost{
    return @"";
}
+(NSString*)kHafasKey{
    return @"";
}
+(NSString*)kMapsKey{
    return @"";
}
+(NSString*)kSentryDNS{
    return nil;
}

+(UIColor*)dbMainColor{
    return [UIColor dbColorWithRGB:0xED7200];
}

@end
