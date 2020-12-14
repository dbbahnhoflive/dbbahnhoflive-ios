// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import "MBNews.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBNewsResponse : NSObject

-(instancetype)initWithResponse:(NSDictionary*)json;
-(BOOL)isValid;
-(NSArray<MBNews*>*)currentNewsItems;
-(NSArray<MBNews*>*)currentOfferItems;

@end

NS_ASSUME_NONNULL_END
