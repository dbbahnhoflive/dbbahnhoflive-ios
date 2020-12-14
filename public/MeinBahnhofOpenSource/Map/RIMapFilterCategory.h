// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
#import "RIMapFilterEntry.h"
@interface RIMapFilterCategory : MTLModel <MTLJSONSerializing>

@property(nonatomic,strong) NSString* appcat;
@property(nonatomic,strong) NSArray* presets;
@property(nonatomic,strong) NSArray* items;

@end
