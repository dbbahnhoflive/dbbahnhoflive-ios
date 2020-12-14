// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBTutorial.h"

@implementation MBTutorial

+(MBTutorial *)tutorialWithIdentifier:(MBTutorialViewType)identifier title:(NSString *)title text:(NSString *)text countdown:(NSInteger)countdown{
    MBTutorial* res = [[MBTutorial alloc] initWithIdentifier:identifier title:title text:text countdown:countdown];
    return res;
}

-(instancetype)initWithIdentifier:(MBTutorialViewType)identifier title:(NSString *)title text:(NSString *)text countdown:(NSInteger)countdown{
    self = [super init];
    if(self){
        self.identifier = identifier;
        self.title = title;
        self.text = text;
        self.countdown = countdown;
        self.closedByUser = NO;
        self.currentCount = self.countdown;
    }
    return self;
}

@end
