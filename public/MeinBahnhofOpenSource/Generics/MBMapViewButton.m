// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBMapViewButton.h"
#import "MBUIHelper.h"

@implementation MBMapViewButton

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(instancetype)init{
    self = [super init];
    if(self){
        [self setup];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        [self setup];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if(self){
        [self setup];
    }
    return self;
}

-(void)setup{
    UIImage* img = [UIImage db_imageNamed:@"FloatingMap"];
    if(img){
        [self setSize:CGSizeMake(img.size.width, img.size.height)];
        [self setBackgroundImage:img forState:UIControlStateNormal];
    } else {
        [self setSize:CGSizeMake(72,72)];
        [self setBackgroundColor:[UIColor db_mainColor]];
        self.layer.cornerRadius = 36;
        self.layer.shadowOffset = CGSizeMake(1.0, 2.0);
        self.layer.shadowColor = [[UIColor db_dadada] CGColor];
        self.layer.shadowRadius = 1.5;
        self.layer.shadowOpacity = 1.0;
    }
    self.accessibilityLabel = @"Karte anzeigen";

}

@end
