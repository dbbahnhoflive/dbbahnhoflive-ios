// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import "MBNews.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBCouponCategory : NSObject

-(NSString*)title;
+(UIImage*)image;
@property(nonatomic,strong) NSArray<MBNews*>* items;

@end

NS_ASSUME_NONNULL_END
