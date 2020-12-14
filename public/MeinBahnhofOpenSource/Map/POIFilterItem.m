// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "POIFilterItem.h"

@implementation POIFilterItem

- (instancetype) init
{
    if (self = [super init]) {
        self.active = YES;
    }
    return self;
}

- (instancetype) initWithTitle:(NSString*)title andIconKey:(NSString*)iconKey;
{
    if (self = [super init]) {
        self.title = title;
        self.active = YES;
        self.subItems = nil;
        self.iconKey = iconKey;
    }
    return self;
}

-(id)copyWithZone:(NSZone *)zone{
    POIFilterItem* copy = [[[self class] alloc] init];
    if (copy) {
        copy.title = [self.title copyWithZone:zone];
        copy.active = self.active;
        copy.iconKey = [self.iconKey copyWithZone:zone];
        if(self.subItems){
            copy.subItems = [[NSArray alloc] initWithArray:self.subItems copyItems:YES];
        }
    }
    return copy;
}

@end
