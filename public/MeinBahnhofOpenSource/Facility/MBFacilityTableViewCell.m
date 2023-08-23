// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBFacilityTableViewCell.h"
#import "FacilityStatusManager.h"
#import "MBUIHelper.h"
#import "DBSwitch.h"
#import "MBFavoriteButton.h"
#import "MBStatusImageView.h"

@interface MBFacilityTableViewCell()

@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UIView *bottomViewTop;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) MBStatusImageView *statusImageView;
@property (nonatomic, strong) MBFavoriteButton *favoriteButton;
@property (nonatomic, strong) UISwitch *pushSwitch;
@property (nonatomic, strong) UILabel *pushLabel;

@end

@implementation MBFacilityTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    [self configureCell];
    return self;
}

- (void)setStatus:(FacilityStatus *)status {
    _status = status;
    BOOL isSystemPushActive = FacilityStatusManager.client.isSystemPushActive;
    BOOL isFavorite = [FacilityStatusManager.client isFavoriteFacility:status.equipmentNumberString];
    BOOL isPushActive = [FacilityStatusManager.client isPushActiveForFacility:status.equipmentNumberString];
    
    self.expanded = isFavorite;

    if(FacilityStatusManager.client.isGlobalPushActive && isSystemPushActive){
        self.pushSwitch.on = isPushActive;
    } else {
        self.pushSwitch.on = false;
    }
    self.favoriteButton.isFavorite = isFavorite;

    NSString* statusString = nil;
    self.descriptionLabel.text = status.shortDescription;
    if (status.state == FacilityStateActive) {
        [self.statusImageView setStatusActive];
        statusString = @"Status: Aktiv";
        self.descriptionLabel.textColor = [UIColor db_green];
    } else if(status.state == FacilityStateUnknown){
        [self.statusImageView setStatusUnknown];
        statusString = @"Status: Unbekannt";
        self.descriptionLabel.textColor = [UIColor db_787d87];
    } else {
        [self.statusImageView setStatusInactive];
        statusString = @"Status: Defekt";
        self.descriptionLabel.textColor = [UIColor db_mainColor];
    }
    NSMutableString* voiceOverString = [NSMutableString stringWithFormat:@"%@ . %@. Aufzug in Merkliste: %@.",status.shortDescription, statusString, isFavorite ? @"Ein" : @"Aus"];
    if(isFavorite){
        [voiceOverString appendFormat:@" Mitteilungen zur Verfügbarkeit erhalten: %@.",self.pushSwitch.on ? @"Ein" : @"Aus"];
    }
    [voiceOverString appendString:@" Zur Anzeige von Optionen doppeltippen."];
    self.descriptionLabel.accessibilityLabel = voiceOverString;

    [self.descriptionLabel sizeToFit];
    NSString *stationName = [FacilityStatusManager.client stationNameForStationNumber:status.stationNumber.description];
    if (nil == stationName) {
        stationName = self.currentStationName;
    }
    [self.nameLabel setText:stationName];
    [self.nameLabel sizeToFit];
    [self setNeedsLayout];

}


- (void)configureCell {
    
    self.backgroundColor = [UIColor clearColor];
    
    self.topView = [UIView new];
    self.topView.backgroundColor = [UIColor whiteColor];
    [self.topView configureDefaultShadow];

    [self.contentView addSubview:self.topView];
    
    self.nameLabel = [UILabel new];
    self.nameLabel.font = [UIFont db_BoldSixteen];
    self.nameLabel.textColor = [UIColor db_333333];
    [self.topView addSubview:self.nameLabel];
    
    self.descriptionLabel = [UILabel new];
    self.descriptionLabel.font = [UIFont db_RegularFourteen];
    self.descriptionLabel.numberOfLines = 2;
    [self.topView addSubview:self.descriptionLabel];
    
    self.statusImageView = [[MBStatusImageView alloc] init];
    [self.topView addSubview:self.statusImageView];
        
    self.favoriteButton = [MBFavoriteButton new];
    self.favoriteButton.isAccessibilityElement = NO;
    [self.topView addSubview:self.favoriteButton];
    [self.favoriteButton addTarget:self action:@selector(favButtonPressed:) forControlEvents:UIControlEventTouchUpInside];


    self.bottomView = [UIView new];
    self.bottomView.backgroundColor = [UIColor whiteColor];
    [self.bottomView configureDefaultShadow];
    [self.contentView addSubview:self.bottomView];
    self.bottomViewTop = [UIView new];
    self.bottomViewTop.backgroundColor = UIColor.whiteColor;
    [self.contentView addSubview:self.bottomViewTop];
    
    self.pushLabel = [UILabel new];
    self.pushLabel.font = [UIFont db_RegularFourteen];
    self.pushLabel.textColor = [UIColor db_333333];
    self.pushLabel.numberOfLines = 2;
    self.pushLabel.text = @"Mitteilung zur Verfügbarkeit erhalten";
    [self.bottomView addSubview:self.pushLabel];
    self.pushLabel.isAccessibilityElement = NO;
    
    self.pushSwitch = [DBSwitch new];
    self.pushSwitch.isAccessibilityElement = NO;
//    self.pushSwitch.accessibilityLabel = @"Mitteilung zur Verfügbarkeit erhalten.";
    [self.pushSwitch addTarget:self action:@selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
    [self.bottomView addSubview:self.pushSwitch];
    
    self.accessibilityTraits = self.accessibilityTraits|UIAccessibilityTraitButton;

}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    self.topView.frame = CGRectMake(8, 8, self.frame.size.width-2*8, 80);
    self.bottomView.frame = CGRectMake(8, CGRectGetMaxY(self.topView.frame), self.frame.size.width-2*8, 56);
    self.bottomViewTop.frame = CGRectMake(self.bottomView.frame.origin.x, self.bottomView.frame.origin.y-2, self.bottomView.frame.size.width, 3);//this view hides the rests of the shadows at the top

    [self.favoriteButton setGravityRight:25];
    [self.favoriteButton centerViewVerticalInSuperView];

    NSInteger x = 24;
    self.nameLabel.frame = CGRectMake(x, 16, self.favoriteButton.frame.origin.x-x-16, 20);
    [self.statusImageView setGravityLeft:self.nameLabel.frame.origin.x-3];
    [self.statusImageView setBelow:self.nameLabel withPadding:4];
    x = CGRectGetMaxX(self.statusImageView.frame)+6;
    [self.descriptionLabel setGravityLeft:x];
    [self.descriptionLabel setGravityTop:self.statusImageView.frame.origin.y+2];
    CGSize size = [self.descriptionLabel sizeThatFits:CGSizeMake(self.favoriteButton.frame.origin.x-x-16, 30)];
    self.descriptionLabel.size = CGSizeMake(ceilf(size.width), ceilf(size.height));
        
    [self.pushSwitch setGravityRight:16];
    [self.pushSwitch centerViewVerticalInSuperView];
    self.pushLabel.frame = CGRectMake(24, 0, self.pushSwitch.frame.origin.x-2*24, self.bottomView.size.height);
}

- (void)toggleSwitch:(UISwitch *)sender {
    [self.delegate facilityCell:self togglesPushSwitch:sender newState:sender.on forFacility:self.status];
}
-(void)favButtonPressed:(MBFavoriteButton*)btn{
    btn.isFavorite = !btn.isFavorite;
    if(btn.isFavorite){
        [self.delegate facilityCell:self addsFacility:self.status];
    } else {
        [self.delegate facilityCell:self removesFacility:self.status]; //this also triggers a push deactivation
        self.pushSwitch.on = false;
    }
}

- (void)setExpanded:(BOOL)expanded {
    _expanded = expanded;
    self.bottomView.hidden = !expanded;
    self.bottomViewTop.hidden = !expanded;
    
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.expanded = NO;
}

@end
