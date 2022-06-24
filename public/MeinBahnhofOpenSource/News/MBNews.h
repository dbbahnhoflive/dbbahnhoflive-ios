// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MBNewsType) {
    MBNewsTypeUndefined = 0,
    MBNewsTypeOffer = 1,//coupon
    MBNewsTypeDisruption = 2,
    MBNewsTypePoll = 3,
    MBNewsTypeProductsServices = 4,
    MBNewsTypeMajorDisruption = 5,
};

#define DEBUG_LOAD_UNPUBLISHED_NEWS NO

@interface MBNews : NSObject

-(BOOL)validWithData:(NSDictionary*)json;

-(nullable UIImage*)image;
-(MBNewsType)newsType;
-(NSString*)title;
-(NSString* _Nullable)subtitle;
-(NSString*)content;
-(NSString*)link;
-(BOOL)hasLink;
-(BOOL)hasValidTime;
-(NSComparisonResult)compare:(MBNews *)news;

+(NSArray*)debugData;

@end

NS_ASSUME_NONNULL_END
