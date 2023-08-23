// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>


@interface LevelplanWrapper : NSObject

@property (nonatomic, assign) NSInteger levelNumber;
@property (nonatomic, strong) NSString* levelString;

- (instancetype) initWithLevelNumber:(NSInteger)levelNumber levelString:(NSString*)levelString;

@end
