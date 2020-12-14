// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MBStationOccupancy : NSObject

//average and current values are scaled to a range from 0..255
@property(nonatomic,strong) NSArray<NSArray<NSNumber*>*>* averageCounts;

@property(nonatomic) NSInteger currentDay;
@property(nonatomic) NSInteger currentHour;

@property(nonatomic) NSInteger currentCount;
@property(nonatomic) NSInteger currentLevel;

@end

NS_ASSUME_NONNULL_END
