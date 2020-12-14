// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>

@interface MBPTSAvailabilityTimes : NSObject

-(instancetype)initWithArray:(NSArray*)availability;//new PTS

@property(nonatomic,strong) NSMutableArray<NSString*>* availabilityStrings;
-(NSString*)availabilityString;

@end
