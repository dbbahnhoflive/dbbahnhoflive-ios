// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class Stop;
@class HafasDeparture;
@class MBOPNVStation;
NS_ASSUME_NONNULL_BEGIN

@interface MBBackNavigationState : NSObject

@property (nonatomic, strong) NSNumber *mbId;//station id (stada)
@property (nonatomic, strong) NSString *title;
@property (nonatomic) CLLocationCoordinate2D position;
@property (nonatomic, strong) NSArray<NSString*>* evaIds;

@property (nonatomic) BOOL isOPNVStation;
@property (nonatomic) BOOL isFromDeparture;
@property (nonatomic) BOOL dontRestoreTrainJourney;

@property(nonatomic,strong) Stop* _Nullable stop;
@property(nonatomic,strong) HafasDeparture* _Nullable hafasDeparture;
@property(nonatomic,strong) MBOPNVStation* _Nullable hafasStation;

@end

NS_ASSUME_NONNULL_END
