// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface Train : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy) NSDictionary *destination;
@property (nonatomic, copy) NSArray *sections;

@property (nonatomic, strong) NSString *number;
@property (nonatomic, strong) NSString *type;

- (NSString *)destinationStation;
- (NSArray *)destinationVia;

- (NSString *)sectionRangeAsString;
- (NSString *) destinationViaAsString;

@end
