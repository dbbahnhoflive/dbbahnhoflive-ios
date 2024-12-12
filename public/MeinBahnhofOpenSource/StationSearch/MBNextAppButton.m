// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBNextAppButton.h"
#import "UIView+Frame.h"
#import "UIColor+DBColor.h"
#import "UIFont+DBFont.h"
#import "MBLabel.h"
#import "MBNews.h"
#import "AppDelegate.h"

@interface MBNextAppButton()
@property(nonatomic,strong) MBLabel* messageLabel;
@property(nonatomic,strong) MBLabel* headerLabel;
@property(nonatomic,strong) UIView* line;
@property(nonatomic,strong) UIImageView* chevron;

@end

@implementation MBNextAppButton

-(instancetype)init{
    self = [super init];
    if(self){
        self.backgroundColor = UIColor.whiteColor;
        self.layer.shadowOffset = CGSizeMake(1.0, 2.0);
        self.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.layer.shadowRadius = 5;
        self.layer.shadowOpacity = 0.4;
        
        self.clipsToBounds = NO;
        
        self.headerLabel = [[MBLabel alloc] initWithFrame:CGRectZero];
        self.headerLabel.numberOfLines = 2;
        self.headerLabel.backgroundColor = [UIColor clearColor];
        self.headerLabel.opaque = NO;
        self.headerLabel.textColor = [UIColor blackColor];
        self.headerLabel.font = [UIFont db_BoldSixteen];
        self.headerLabel.textAlignment = NSTextAlignmentLeft;
        [self addSubview:self.headerLabel];
        
        self.line = [[UIView alloc] initWithFrame:CGRectZero];
        self.line.backgroundColor = [UIColor db_mainColor];
        [self addSubview:self.line];
        
        self.messageLabel = [[MBLabel alloc] initWithFrame:CGRectZero];
        self.messageLabel.numberOfLines = 0;
        self.messageLabel.backgroundColor = [UIColor clearColor];
        self.messageLabel.opaque = NO;
        self.messageLabel.textColor = [UIColor blackColor];
        self.messageLabel.font = [UIFont db_RegularFourteen];
        self.messageLabel.textAlignment = NSTextAlignmentLeft;
        [self addSubview:self.messageLabel];
        
        self.chevron = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"app_links_pfeil"]];
        self.chevron.isAccessibilityElement = NO;
        [self addSubview:self.chevron];
        
        if(AppDelegate.appDelegate.appDisabled){
            self.headerLabel.text = NEW_APP_TITLE_DISABLED;
            self.messageLabel.text = NEW_APP_TEXT_DISABLED;
        } else {
            self.headerLabel.text = NEW_APP_HEADER;
            self.messageLabel.text = [NSString stringWithFormat:@"%@:\n%@",NEW_APP_TITLE,NEW_APP_TEXT];
        }
        self.accessibilityLabel = [NSString stringWithFormat:@"%@. %@",self.headerLabel.text,self.messageLabel.text];
        self.accessibilityHint = @"Für weitere Informationen doppeltippen.";
    }
    return self;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    [self layoutUI];
}

-(void)layoutUI{
    [self setWidth:self.superview.sizeWidth-2*15];
    [self setGravityLeft:15];

    CGSize size = [self.headerLabel sizeThatFits:CGSizeMake(self.size.width-40-40, MAXFLOAT)];
    self.headerLabel.frame = CGRectMake(16,16, ceilf(size.width), ceilf(size.height));
    
    self.line.frame = CGRectMake(0, CGRectGetMaxY(self.headerLabel.frame)+7, self.sizeWidth, 3);
    
    size = [self.messageLabel sizeThatFits:CGSizeMake(self.size.width-18*2-10, MAXFLOAT)];
    self.messageLabel.frame = CGRectMake(18, CGRectGetMaxY(self.line.frame)+15, ceilf(size.width), ceilf(size.height));
    
    CGFloat totalHeight = CGRectGetMaxY(self.messageLabel.frame)+15;
    self.height = totalHeight;
    
    [self.chevron setGravityRight:10];
    [self.chevron setGravityTop:self.line.frame.origin.y+(2*15+self.messageLabel.sizeHeight)/2-self.chevron.sizeHeight/2];

}

@end
