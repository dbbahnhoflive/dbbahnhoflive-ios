// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBStationGreenTeaserCollectionViewCell.h"
#import "MBExternalLinkButton.h"
#import "MBUrlOpening.h"
#import "MBUIHelper.h"
#import "MBTrackingManager.h"

@interface MBStationGreenTeaserCollectionViewCell()
@property(nonatomic,strong) UILabel* mainLabel;
@property(nonatomic,strong) UIView* whiteBox;
@property(nonatomic,strong) UILabel* subLabel;
@property(nonatomic,strong) UILabel* textLabel;
@property(nonatomic,strong) UILabel* numberLabel;
@property(nonatomic,strong) UIButton* navigationButton;

@end

@implementation MBStationGreenTeaserCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self){
        self.backgroundColor = [UIColor dbColorWithRGB:0x78BD14];
        
        self.mainLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.mainLabel.text = @"Das ist grün";
        self.mainLabel.textColor = [UIColor whiteColor];
        self.mainLabel.font = [UIFont dbHeadBlackWithSize:30];
        [self.contentView addSubview:self.mainLabel];
        
        self.whiteBox = [[UIView alloc] initWithFrame:CGRectZero];
        self.whiteBox.backgroundColor = [UIColor whiteColor];
        [self.contentView addSubview:self.whiteBox];

        self.subLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.subLabel.text = @"Grüner Halt. Fürs Klima.";
        self.subLabel.textColor = [UIColor db_333333];
        self.subLabel.font = [UIFont dbHeadLightWithSize:17];
        [self.whiteBox addSubview:self.subLabel];

        self.textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.textLabel.text = @"Ökostrom am Bahnhof.";
        self.textLabel.textColor = [UIColor db_333333];
        self.textLabel.font = [UIFont dbHeadBlackWithSize:17];
        [self.whiteBox addSubview:self.textLabel];

        self.numberLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.numberLabel.text = @"Nr. 147";
        self.numberLabel.textColor = self.backgroundColor;
        self.numberLabel.font = self.mainLabel.font;
        [self.whiteBox addSubview:self.numberLabel];
        
        self.navigationButton = [MBExternalLinkButton createButton];
        [self.navigationButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.whiteBox addSubview:self.navigationButton];

        
    }
    return self;
}

-(void)buttonTapped:(id)sender{
    [MBTrackingManager trackActionsWithStationInfo:@[@"h1",@"tap",@"oekostrom-teaser"]];
    [MBUrlOpening openURL:[NSURL URLWithString:@"https://gruen.deutschebahn.com/de/projekte/oekostrombahnhof"]];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.mainLabel.frame = CGRectMake(24, 13, self.frame.size.width-2*24, 30);
    self.whiteBox.frame = CGRectMake(8, 50, self.frame.size.width-2*8, 114);
    self.subLabel.frame = CGRectMake(16, 19, self.frame.size.width, 20);
    self.textLabel.frame = CGRectMake(16, 40, self.frame.size.width, 26);
    [self.numberLabel sizeToFit];
    [self.numberLabel setGravityRight:16];
    [self.numberLabel setGravityBottom:8];
    [self.navigationButton setGravityTop:20];
    [self.navigationButton setGravityRight:16];
}

@end
