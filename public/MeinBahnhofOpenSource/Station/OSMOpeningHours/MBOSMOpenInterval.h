// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MBOSMOpenInterval : NSObject

@property(nonatomic,strong) NSDate* startTime;
@property(nonatomic,strong) NSDate* endTime;
@property(nonatomic,strong) NSString* _Nullable comment;

@end

NS_ASSUME_NONNULL_END
