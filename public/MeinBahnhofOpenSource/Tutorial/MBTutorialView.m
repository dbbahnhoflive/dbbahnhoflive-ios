// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBTutorialView.h"
#import "MBLabel.h"

#import "MBStationSearchViewController.h"
#import "MBRootContainerViewController.h"
#import "MBStationTabBarViewController.h"

#import "MBTutorial.h"
#import "MBTutorialManager.h"
#import "MBUIHelper.h"

@interface MBTutorialView()

@property(nonatomic,strong) UIView* background;
@property(nonatomic,strong) MBLabel* messageLabel;
@property(nonatomic,strong) MBLabel* titleLabel;
@property(nonatomic,strong) UIView* line;
@property(nonatomic,strong) UIImageView* icon;
@property(nonatomic,strong) UIButton* closeX;
@property(nonatomic,strong) UILabel* okLabel;



@end

@implementation MBTutorialView

-(instancetype)initWithTutorial:(MBTutorial *)tutorial{
    self = [super initWithFrame:CGRectZero];
    if(self){
        self.backgroundColor = [UIColor whiteColor];
        
        self.accessibilityViewIsModal = YES;
        
        self.layer.shadowOffset = CGSizeMake(1.0, 2.0);
        self.layer.shadowColor = [[UIColor db_dadada] CGColor];
        self.layer.shadowRadius = 5;
        self.layer.shadowOpacity = 1.0;
        
        self.icon = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"tutorialicon"]];
        [self addSubview:self.icon];
        
        /*
         self.background = [[UIView alloc] initWithFrame:CGRectZero];
         self.background.backgroundColor = [UIColor whiteColor];
         self.background.userInteractionEnabled = YES;
         [self addSubview:self.background];
         */
        self.titleLabel = [[MBLabel alloc] initWithFrame:CGRectZero];
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.opaque = NO;
        self.titleLabel.textColor = [UIColor blackColor];
        self.titleLabel.font = [UIFont db_BoldSixteen];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.titleLabel];
        
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
        
        self.closeX = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        [self.closeX setImage:[UIImage db_imageNamed:@"app_schliessen"] forState:UIControlStateNormal];
        self.closeX.accessibilityLabel = @"Schließen";
        [self.closeX addTarget:self action:@selector(userClosed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.closeX];
        
        /*
         self.okLabel = [[UILabel alloc] initWithFrame:CGRectZero];
         self.okLabel.text = @"OK";
         self.okLabel.textColor = [UIColor whiteColor];
         self.okLabel.backgroundColor = [UIColor clearColor];
         self.okLabel.textAlignment = NSTextAlignmentCenter;
         self.okLabel.font = [UIFont db_BoldSixteen];
         [self addSubview:self.okLabel];
         */
        self.userInteractionEnabled = YES;
        
        self.tutorial = tutorial;
        self.titleLabel.text = tutorial.title;
        self.messageLabel.text = tutorial.text;
        
        self.isAccessibilityElement = YES;
        self.titleLabel.isAccessibilityElement = NO;
        self.messageLabel.isAccessibilityElement = NO;
        self.closeX.isAccessibilityElement = NO;
        self.accessibilityLabel = [NSString stringWithFormat:@"Hinweis: %@. %@.",self.titleLabel.text,self.messageLabel.text];
        self.accessibilityHint = @"Zum Schließen doppeltippen.";
        
        [self setNeedsLayout];
    }
    return self;
}

-(BOOL)accessibilityActivate{
    [self userClosed];
    return YES;
}


-(void)layoutSubviews{
    CGRect superviewFrame = self.superview.frame;
    self.frame =CGRectMake(16, 0, superviewFrame.size.width-2*16, superviewFrame.size.height);
    self.background.frame = CGRectMake(0, 0, superviewFrame.size.width, superviewFrame.size.height);
  
    [self.closeX setGravityTop:4];
    [self.closeX setGravityRight:4];
    
    [self.icon setGravityTop:13];
    [self.icon setGravityLeft:16];

    CGSize size = [self.titleLabel sizeThatFits:CGSizeMake(self.size.width-40-40, MAXFLOAT)];
    self.titleLabel.frame = CGRectMake(40,16, ceilf(size.width), ceilf(size.height));
    
    self.line.frame = CGRectMake(0, 47, self.sizeWidth, 3);
    
    size = [self.messageLabel sizeThatFits:CGSizeMake(self.size.width-18*2, MAXFLOAT)];
    self.messageLabel.frame = CGRectMake(18, CGRectGetMaxY(self.line.frame)+15, ceilf(size.width), ceilf(size.height));
    
    CGFloat totalHeight = CGRectGetMaxY(self.messageLabel.frame)+15;
    self.height = totalHeight;

    [self setGravityBottom:16+self.viewYOffset];
    //self.okLabel.frame = CGRectMake(0, CGRectGetMaxY(self.messageLabel.frame)+20, superviewFrame.size.width, 50);
}


-(void)userClosed{
    [[MBTutorialManager singleton] userClosedTutorial:self.tutorial];
}



@end
