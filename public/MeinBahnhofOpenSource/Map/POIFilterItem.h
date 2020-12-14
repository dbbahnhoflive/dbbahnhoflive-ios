// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>

@interface POIFilterItem : NSObject<NSCopying>

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *iconKey;
@property (nonatomic, strong) NSArray *subItems;
@property (nonatomic, assign) BOOL active;

- (instancetype) initWithTitle:(NSString*)title andIconKey:(NSString*)iconKey;

@end
