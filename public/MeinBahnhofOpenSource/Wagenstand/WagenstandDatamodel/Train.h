// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>

@interface Train : NSObject

@property (nonatomic, copy) NSString *destination;
@property (nonatomic, copy) NSArray *sections;

@property (nonatomic, strong) NSString *number;
@property (nonatomic, strong) NSString *type;

- (NSString *)destinationStation;

- (NSString *)sectionRangeAsString;

@end
