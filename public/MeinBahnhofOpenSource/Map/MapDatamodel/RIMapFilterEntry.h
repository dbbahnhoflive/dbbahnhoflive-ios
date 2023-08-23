// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
@interface RIMapFilterEntry : MTLModel <MTLJSONSerializing>

@property(nonatomic,strong) NSString* title;
@property(nonatomic,strong) NSString* menucat;
@property(nonatomic,strong) NSString* menusubcat;
@property(nonatomic,strong) NSArray* presets;

@end
