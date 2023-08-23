// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBTutorial.h"

@implementation MBTutorial

+(MBTutorial *)tutorialWithIdentifier:(MBTutorialViewType)identifier title:(NSString *)title text:(NSString *)text countdown:(NSInteger)countdown{
    return [MBTutorial tutorialWithIdentifier:identifier title:title text:text countdown:countdown ruleBlock:nil];
}

+(MBTutorial *)tutorialWithIdentifier:(MBTutorialViewType)identifier title:(NSString *)title text:(NSString *)text countdown:(NSInteger)countdown ruleBlock:(TutorialRuleBlock)ruleBlock{
    MBTutorial* res = [[MBTutorial alloc] initWithIdentifier:identifier title:title text:text countdown:countdown];
    res.ruleBlock = ruleBlock;
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
