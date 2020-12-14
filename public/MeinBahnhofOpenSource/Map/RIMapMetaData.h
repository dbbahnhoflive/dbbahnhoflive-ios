// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RIMapMetaData : NSObject

@property(nonatomic) CLLocationCoordinate2D coordinate;
@property(nonatomic,strong) NSArray<NSNumber*>* evaNumbers;

@end

NS_ASSUME_NONNULL_END
