// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import "RIMapPoi.h"

@interface MBEinkaufsbahnhofStore : NSObject

+(MBEinkaufsbahnhofStore*)parse:(NSDictionary*)dict;

@property(nonatomic,strong) NSString* name;
@property(nonatomic,strong) NSNumber* category_id;

@property(nonatomic,strong) NSString* web;
@property(nonatomic,strong) NSString* phone;
@property(nonatomic,strong) NSString* email;
@property(nonatomic,strong) NSString* location;
@property(nonatomic,strong) NSArray* paymentTypes;

@property(nonatomic,strong) NSArray* openingTimes;

-(ShopOpenState)isOpen;
@end
