// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import "MBOSMOpeningWeek.h"
@import CoreLocation;

@interface MBTravelcenter : NSObject

-(instancetype)initWithDict:(NSDictionary*)json;

@property (nonatomic, strong) MBOSMOpeningWeek *openingTimesOSM;

-(CLLocationCoordinate2D)coordinate;
-(CLLocation*)location;

-(NSString*)title;
-(NSString*)address;
-(NSString*)postCode;
-(NSString*)city;
-(NSString*)openingHoursOSMString;

@end

