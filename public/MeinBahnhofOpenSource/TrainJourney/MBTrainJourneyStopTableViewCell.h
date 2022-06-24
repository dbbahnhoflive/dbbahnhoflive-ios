// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <UIKit/UIKit.h>
#import "MBTrainJourneyStop.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBTrainJourneyStopTableViewCell : UITableViewCell

-(void)setStop:(MBTrainJourneyStop*)stop isFirst:(BOOL)isFirst isLast:(BOOL)isLast isCurrentStation:(BOOL)isCurrentStation;
-(void)setStopWithString:(NSString *)stationTitle isFirst:(BOOL)isFirst isLast:(BOOL)isLast isCurrentStation:(BOOL)isCurrentStation;

@end

NS_ASSUME_NONNULL_END
