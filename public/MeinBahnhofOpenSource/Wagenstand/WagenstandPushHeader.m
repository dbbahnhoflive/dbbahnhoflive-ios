// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "WagenstandPushHeader.h"

@interface WagenstandPushHeader()

@end

@implementation WagenstandPushHeader


-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        self.label = [[UILabel alloc] init];
        self.label.numberOfLines = 0;
        self.label.lineBreakMode = NSLineBreakByWordWrapping;
        self.label.text = @"Erinnerung vor Einfahrt des Zuges senden.";
        self.label.textColor = [UIColor db_787d87];
        self.label.font = [UIFont db_RegularTwelve];
        
        self.label.isAccessibilityElement = NO;

        self.pushSwitch = [[UISwitch alloc] init];
        self.pushSwitch.accessibilityLabel = self.label.text;
        
        self.leftIcon = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_sprechblase"]];
        
        [self addSubview:self.label];
        [self addSubview:self.pushSwitch];
        [self addSubview:self.leftIcon];
    }
    return self;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    [self.leftIcon setGravityLeft:20-4];
    [self.leftIcon centerViewVerticalInSuperView];
    
    [self.pushSwitch centerViewVerticalInSuperView];
    [self.pushSwitch setGravityRight:15];
    self.label.frame = CGRectMake(40, 0, self.sizeWidth-40-15-self.pushSwitch.sizeWidth-15, self.sizeHeight);
    
}

@end
