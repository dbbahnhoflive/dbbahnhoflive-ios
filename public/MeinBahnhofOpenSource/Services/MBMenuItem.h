// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Mantle/Mantle.h>

@interface MBMenuItem : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSString *type;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSArray *services;
@property (nonatomic, assign, readonly) NSInteger position;

- (UIImage*) iconForType;
- (NSArray*) servicesByPosition;


@end
