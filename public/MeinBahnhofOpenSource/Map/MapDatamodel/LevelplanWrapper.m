// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "LevelplanWrapper.h"

@implementation LevelplanWrapper

- (instancetype) initWithLevelNumber:(NSInteger)levelNumber levelString:(NSString*)levelString
{
    if (self = [super init]) {
        self.levelNumber = levelNumber;
        self.levelString = levelString;
    }
    return self;
}

-(NSString *)description{
    return [NSString stringWithFormat:@"LevelplanWrapper: levelNumber=%ld, levelString=%@",(long)_levelNumber,_levelString];
}


@end
