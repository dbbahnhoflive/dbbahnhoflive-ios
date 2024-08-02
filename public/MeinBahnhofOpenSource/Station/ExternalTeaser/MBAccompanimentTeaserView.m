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
#import "UIColor+DBColor.h"
#import "MBTrackingManager.h"
#import "MBRootContainerViewController.h"
#import "MBContentSearchResult.h"

#import "MBServiceListCollectionViewController.h"
#import "MBServiceListTableViewController.h"

@interface MBAccompanimentTeaserView()
@property(nonatomic,strong) UIView* background;
@property(nonatomic,strong) UILabel* headerLabel;
@property(nonatomic,strong) UILabel* textLabel;
@property(nonatomic,strong) UIImageView* image;
@property(nonatomic,strong) MBExternalLinkButton* linkButton;
@property(nonatomic,strong) UIButton* voiceOverButton;
@property(nonatomic,strong) UIImageView* shapeImage;
@end

@implementation MBAccompanimentTeaserView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self){
        self.background = [UIView new];
        self.background.backgroundColor = UIColor.db_SEV;
        [self.background configureH1Shadow];
        [self addSubview:self.background];
        
        self.headerLabel = [UILabel new];
        self.headerLabel.textColor = UIColor.whiteColor;
        self.headerLabel.font = [UIFont db_BoldFourteen];
        self.headerLabel.numberOfLines = 0;
        self.headerLabel.text = @"DB Wegbegleitung";
        [self.background addSubview:self.headerLabel];
        
        self.textLabel = [UILabel new];
        self.textLabel.textColor = UIColor.whiteColor;
        self.textLabel.font = [UIFont db_RegularFourteen];
        self.textLabel.numberOfLines = 0;
        self.textLabel.text = @"Orientierungshilfe per Videoanruf\nfür sehbeeinträchtigte Reisende.";
        self.textLabel.accessibilityLabel = @"Dieser Service dient als Orientierungshilfe für blinde und sehbeeinträchtigte Reisende. Sie werden über Video-Telefonie mit einem Mitarbeiter im Kundencenter der Deutschen Bahn verbunden.";
        [self.background addSubview:self.textLabel];
        
        self.image = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"SEV_Icon"]];
        [self.image setSize:CGSizeMake(50, 50)];
        [self.background addSubview:self.image];
        
        self.shapeImage = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"schraege_Linie"]resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeTile]];
        [self.background addSubview:self.shapeImage];
        
        self.voiceOverButton = [UIButton new];
        [self addSubview:self.voiceOverButton];
        [self.voiceOverButton addTarget:self action:@selector(linkButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        self.voiceOverButton.accessibilityLabel = [NSString stringWithFormat:@"%@. %@",self.headerLabel.text,self.textLabel.accessibilityLabel];
        self.voiceOverButton.accessibilityHint = @"Zum Öffnen doppeltippen";
        self.image.isAccessibilityElement = false;
        self.headerLabel.isAccessibilityElement = false;
        self.textLabel.isAccessibilityElement = false;
        self.linkButton.isAccessibilityElement = false;
    }
    return self;
}

-(void)linkButtonPressed{
    //[MBUrlOpening openURL:[NSURL URLWithString:WEGBEGLEITUNG_LINK]];
    [MBTrackingManager trackActionsWithStationInfo:@[@"h1",@"tap",@"wegbegleitungteaser"]];
    MBContentSearchResult* res = [MBContentSearchResult searchResultWithKeywords:CONTENT_SEARCH_KEY_STATIONINFO_SEV_ACCOMPANIMENT];
    MBRootContainerViewController* root = [MBRootContainerViewController currentlyVisibleInstance];

    MBMenuItem* sevItem = [MBServiceListCollectionViewController createMenuItemErsatzverkehrWithStation:root.station];
    MBServiceListTableViewController* vclist = [[MBServiceListTableViewController alloc] initWithItem:sevItem station:root.station];
    res.service = sevItem.services.lastObject;
    vclist.searchResult = res;
    [root.stationContainerNavigationController  pushViewController:vclist animated:true];
}


-(void)layoutSubviews{
    [super layoutSubviews];
    self.background.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    self.voiceOverButton.frame = self.background.frame;
    
    self.shapeImage.frame = CGRectMake(0, 0, self.background.frame.size.width, self.shapeImage.frame.size.height);
        
    [self.image setGravityRight:40];
    [self.image centerViewVerticalInSuperView];

    NSInteger w = self.image.frame.origin.x-20-18;
    CGSize s = [self.headerLabel sizeThatFits:CGSizeMake(w, 100)];
    [self.headerLabel setSize:s];
    [self.headerLabel setGravityTop:25];
    [self.headerLabel setGravityLeft:18];
    
    [self.textLabel setGravityLeft:self.headerLabel.frame.origin.x];
    [self.textLabel setBelow:self.headerLabel withPadding:5];
    s = [self.textLabel sizeThatFits:CGSizeMake(w, 100)];
    [self.textLabel setSize:s];
    
}

@end
