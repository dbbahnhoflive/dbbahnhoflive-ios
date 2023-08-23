// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBAccompanimentTeaserView.h"
#import "UIView+Frame.h"
#import "UIFont+DBFont.h"
#import "UIImage+MBImage.h"
#import "MBExternalLinkButton.h"
#import "MBUrlOpening.h"

@interface MBAccompanimentTeaserView()
@property(nonatomic,strong) UIView* background;
@property(nonatomic,strong) UILabel* headerLabel;
@property(nonatomic,strong) UILabel* textLabel;
@property(nonatomic,strong) UIImageView* image;
@property(nonatomic,strong) MBExternalLinkButton* linkButton;
@property(nonatomic,strong) UIButton* voiceOverButton;
@end

@implementation MBAccompanimentTeaserView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.background = [UIView new];
        self.background.backgroundColor = UIColor.whiteColor;
        [self.background configureH1Shadow];
        [self addSubview:self.background];
        
        self.headerLabel = [UILabel new];
        self.headerLabel.textColor = UIColor.blackColor;
        self.headerLabel.font = [UIFont db_BoldEighteen];
        self.headerLabel.numberOfLines = 0;
        self.headerLabel.text = @"DB Wegbegleitung";
        [self.background addSubview:self.headerLabel];
        
        self.textLabel = [UILabel new];
        self.textLabel.textColor = UIColor.blackColor;
        self.textLabel.font = [UIFont db_RegularFourteen];
        self.textLabel.numberOfLines = 0;
        self.textLabel.text = @"Orientierungshilfe für blinde\nund sehbeeinträchtigte Reisende.";
        [self.background addSubview:self.textLabel];
        
        self.image = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"wegbegleitung_icon"]];
        [self.image setSize:CGSizeMake(52, 52)];
        [self.background addSubview:self.image];
        
        self.linkButton = [MBExternalLinkButton createButton];
        //[self.linkButton addTarget:self action:@selector(linkButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.background addSubview:self.linkButton];
        
        self.voiceOverButton = [UIButton new];
        [self addSubview:self.voiceOverButton];
        [self.voiceOverButton addTarget:self action:@selector(linkButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        self.voiceOverButton.accessibilityLabel = [NSString stringWithFormat:@"%@. %@",self.headerLabel.text,self.textLabel.text];
        self.voiceOverButton.accessibilityHint = @"Zum Öffnen des externen Links doppeltippen";
        self.image.isAccessibilityElement = false;
        self.headerLabel.isAccessibilityElement = false;
        self.textLabel.isAccessibilityElement = false;
        self.linkButton.isAccessibilityElement = false;
    }
    return self;
}

-(void)linkButtonPressed{
    [MBUrlOpening openURL:[NSURL URLWithString:WEGBEGLEITUNG_LINK]];
}


-(void)layoutSubviews{
    [super layoutSubviews];
    self.background.frame = CGRectMake(0, 0, self.frame.size.width-2*8, self.frame.size.height);
    self.voiceOverButton.frame = self.background.frame;
    
    [self.linkButton setGravityRight:10];
    [self.linkButton setGravityTop:10];

    [self.image setGravityLeft:15];
    [self.image centerViewVerticalInSuperView];

    NSInteger w = self.sizeWidth-(CGRectGetMaxX(self.image.frame)+15)-50;
    CGSize s = [self.headerLabel sizeThatFits:CGSizeMake(w, 100)];
    [self.headerLabel setSize:s];
    [self.headerLabel setGravityTop:25];
    [self.headerLabel setRight:self.image withPadding:15];
    
    [self.textLabel setGravityLeft:self.headerLabel.frame.origin.x];
    [self.textLabel setBelow:self.headerLabel withPadding:2];
    s = [self.textLabel sizeThatFits:CGSizeMake(w, 100)];
    [self.textLabel setSize:s];
    
}

@end
