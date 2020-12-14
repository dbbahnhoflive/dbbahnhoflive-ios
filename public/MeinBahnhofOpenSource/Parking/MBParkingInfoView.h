// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "MBParkingInfo.h"

@class MBParkingInfo;

@protocol MBParkingInfoDelegate <NSObject>

@optional
- (void) didOpenOverviewForParking:(MBParkingInfo *)parking;
- (void) didOpenTarifForParking:(MBParkingInfo *)parking;
- (void) didStartNavigationForParking:(MBParkingInfo *)parking;

@end

@interface MBParkingInfoView : UIView

@property (nonatomic, weak) id<MBParkingInfoDelegate> delegate;
- (instancetype)initWithParkingItem:(MBParkingInfo *)item;

@end
