// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>

@interface MBStationTopView : UIView

@property (nonatomic, strong) NSString *title;

@property (nonatomic, strong) NSNumber* stationId;

- (void)hideSubviews:(BOOL)hide;

@end
