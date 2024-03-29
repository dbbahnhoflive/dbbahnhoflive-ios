// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBLargeButton.h"
#import "MBUIHelper.h"

@implementation MBLargeButton

-(instancetype)initWithFrame:(CGRect)frame{
    if(frame.size.height == 0){
        frame.size = CGSizeMake(frame.size.width, 60);
    }
    self = [super initWithFrame:frame];
    if(self){
        self.layer.cornerRadius = self.sizeHeight/2;
        [self setTitle:@"Title" forState:UIControlStateNormal];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self setBackgroundColor:[UIColor db_GrayButton]];
        [self.titleLabel setFont:[UIFont db_BoldEighteen]];
        [self configureDefaultShadow];
    }
    return self;
}

@end
