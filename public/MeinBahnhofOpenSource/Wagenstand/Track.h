// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <UIKit/UIKit.h>
#import <Mantle/Mantle.h>

@interface Track : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSString *number;
@property (nonatomic, copy, readonly) NSString *name;

+ (NSArray*)trackNumbers:(NSArray*)tracks;

@end
