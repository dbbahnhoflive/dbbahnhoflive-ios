// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBContentSearchButton.h"

@interface MBContentSearchButton()
@property(nonatomic,strong) UIImageView* lupeImg;
@property(nonatomic,strong) UILabel* textLabel;

@end

@implementation MBContentSearchButton


-(instancetype)init{
    self = [super init];
    if(self){
        self.accessibilityLabel = @"Suche am Bahnhof";
        self.backgroundColor = [UIColor whiteColor];
        
        self.contentSearchButtonShadow = [[UIView alloc]initWithFrame:CGRectZero];
        self.contentSearchButtonShadow.isAccessibilityElement = NO;
        self.contentSearchButtonShadow.userInteractionEnabled = NO;
        self.contentSearchButtonShadow.backgroundColor = [UIColor whiteColor];
        self.contentSearchButtonShadow.layer.shadowColor = [[UIColor db_dadada] CGColor];
        self.contentSearchButtonShadow.layer.shadowOffset = CGSizeMake(3.0, 3.0);
        self.contentSearchButtonShadow.layer.shadowRadius = 2;
        self.contentSearchButtonShadow.layer.shadowOpacity = 1.0;
        [self addSubview:self.contentSearchButtonShadow];
        
        UIImageView* lupeImg = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_lupe"]];
        self.lupeImg = lupeImg;
        [self addSubview:lupeImg];
        
        UILabel* text = [[UILabel alloc] initWithFrame:CGRectZero];
        self.textLabel = text;
        text.isAccessibilityElement = NO;
        text.text = STATION_SEARCH_PLACEHOLDER;
        text.font = [UIFont db_RegularFourteen];
        text.textColor = [UIColor db_787d87];
        text.alpha = 0.8;
        [text sizeToFit];
        [self addSubview:text];
        
    }
    return self;
}

- (void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    self.layer.cornerRadius = self.frame.size.height/2;
    
    [self.lupeImg centerViewInSuperView];
    [self.lupeImg setGravityRight:30-3];
    [self.textLabel centerViewInSuperView];
    [self.textLabel setGravityLeft:24];

    self.contentSearchButtonShadow.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    self.contentSearchButtonShadow.layer.cornerRadius = self.layer.cornerRadius;

}

-(void)layoutForScreenWidth:(NSInteger)w{
    int finalWidth = (int)(w*0.872);
    self.frame = CGRectMake((w-finalWidth)/2, 0, finalWidth, 60);
}

-(void)setAlpha:(CGFloat)alpha{
    [super setAlpha:alpha];
    self.contentSearchButtonShadow.alpha = self.alpha;
}

-(void)setHidden:(BOOL)hidden{
    [super setHidden:hidden];
    [self.contentSearchButtonShadow setHidden:hidden];
}

@end
