// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBFacilityTableViewCell.h"
#import "FacilityStatusManager.h"
#import "MBUIHelper.h"

@interface MBFacilityTableViewCell()

@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UIImageView *facilityImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) UIImageView *statusImageView;
@property (nonatomic, strong) UIImageView *bookmarkImageView;
@property (nonatomic, strong) UISwitch *merkenSwitch;
@property (nonatomic, strong) UILabel *merkenLabel;

@end

@implementation MBFacilityTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    [self configureCell];
    return self;
}

- (void)setStatus:(FacilityStatus *)status {
    _status = status;
    [self.merkenSwitch setOn:[[FacilityStatusManager client] isPushActiveForFacility:status.equipmentNumber.description]];

    self.bookmarkImageView.hidden = !self.merkenSwitch.on;

    NSString* statusString = nil;
    self.descriptionLabel.text = status.shortDescription;
    if (status.state == ACTIVE) {
        self.statusImageView.image = [UIImage db_imageNamed:@"app_check"];
        statusString = @"Status: Aktiv";
        self.descriptionLabel.textColor = [UIColor db_76c030];
    } else if(status.state == UNKNOWN){
        self.statusImageView.image = [UIImage db_imageNamed:@"app_unbekannt"];
        statusString = @"Status: Unbekannt";
        self.descriptionLabel.textColor = [UIColor db_787d87];
    } else {
        self.statusImageView.image = [UIImage db_imageNamed:@"app_kreuz"];
        statusString = @"Status: Defekt";
        self.descriptionLabel.textColor = [UIColor db_mainColor];
    }
    NSString* voiceOverString = [NSString stringWithFormat:@"%@. %@. Aufzug in Merkliste speichern %@. Zum Umschalten doppeltippen.",status.shortDescription, statusString, self.bookmarkImageView.hidden ? @"Aus" : @"Ein"];
    self.descriptionLabel.accessibilityLabel = voiceOverString;

    [self.statusImageView sizeToFit];
    [self.descriptionLabel sizeToFit];
    NSString *stationName = [[FacilityStatusManager client] stationNameForStationNumber:status.stationNumber.description];
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
    self.topView.layer.shadowOffset = CGSizeMake(1.0, 2.0);
    self.topView.layer.shadowColor = [[UIColor db_dadada] CGColor];
    self.topView.layer.shadowRadius = 1.5;
    self.topView.layer.shadowOpacity = 1.0;

    [self.contentView addSubview:self.topView];
    
    self.facilityImageView = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"rimap_aufzug_grau"]];
    self.facilityImageView.contentMode = UIViewContentModeCenter;
    [self.facilityImageView sizeToFit];
    [self.topView addSubview:self.facilityImageView];
    
    self.nameLabel = [UILabel new];
    self.nameLabel.font = [UIFont db_BoldSixteen];
    self.nameLabel.textColor = [UIColor db_333333];
    [self.topView addSubview:self.nameLabel];
    
    self.descriptionLabel = [UILabel new];
    self.descriptionLabel.font = [UIFont db_RegularFourteen];
    [self.topView addSubview:self.descriptionLabel];
    
    self.statusImageView = [[UIImageView alloc] init];
    [self.topView addSubview:self.statusImageView];
        
    self.bookmarkImageView = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_bookmark"]];
    [self.topView addSubview:self.bookmarkImageView];

    self.bottomView = [UIView new];
    self.bottomView.backgroundColor = [UIColor whiteColor];
    self.bottomView.layer.shadowOffset = CGSizeMake(1.0, 2.0);
    self.bottomView.layer.shadowColor = [[UIColor db_dadada] CGColor];
    self.bottomView.layer.shadowRadius = 1.5;
    self.bottomView.layer.shadowOpacity = 1.0;
    [self.contentView addSubview:self.bottomView];
    
    
    self.merkenLabel = [UILabel new];
    self.merkenLabel.font = [UIFont db_RegularFourteen];
    self.merkenLabel.textColor = [UIColor db_333333];
    self.merkenLabel.numberOfLines = 2;
    self.merkenLabel.text = @"Aufzug der Merkliste\nhinzugefügt";
    [self.bottomView addSubview:self.merkenLabel];
    self.merkenLabel.isAccessibilityElement = NO;
    
    self.merkenSwitch = [UISwitch new];
    [self.merkenSwitch addTarget:self action:@selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
    [self.bottomView addSubview:self.merkenSwitch];
    
    self.accessibilityTraits = self.accessibilityTraits|UIAccessibilityTraitButton;

}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    self.topView.frame = CGRectMake(8, 8, self.frame.size.width-2*8, 80);
    self.bottomView.frame = CGRectMake(8, CGRectGetMaxY(self.topView.frame)+4, self.frame.size.width-2*8, 70);

    [self.facilityImageView setGravityLeft:35];
    [self.facilityImageView setGravityTop:16];

    NSInteger x = CGRectGetMaxX(self.facilityImageView.frame)+30;
    self.nameLabel.frame = CGRectMake(x, self.facilityImageView.frame.origin.y, self.frame.size.width-x-16, 20);
    [self.statusImageView setGravityLeft:self.nameLabel.frame.origin.x-3];
    [self.statusImageView setGravityTop:CGRectGetMaxY(self.facilityImageView.frame)-self.statusImageView.sizeHeight+2];
    x = CGRectGetMaxX(self.statusImageView.frame)+8;
    self.descriptionLabel.frame = CGRectMake(x, self.statusImageView.frame.origin.y+2, self.frame.size.width-x-16, 20);
    
    [self.bookmarkImageView setGravityTop:-5];
    [self.bookmarkImageView setGravityRight:13];

    self.merkenLabel.frame = CGRectMake(16, 0, self.frame.size.width, self.bottomView.size.height);
    [self.merkenSwitch setGravityRight:16];
    [self.merkenSwitch centerViewVerticalInSuperView];
}

- (void)toggleSwitch:(UISwitch *)sender {
    if (sender.on) {
        [self.delegate facilityCell:self addsFacility:self.status];
    } else {
        [self.delegate facilityCell:self removesFacility:self.status];
    }
    
    self.bookmarkImageView.hidden = !self.merkenSwitch.on;
}

- (void)setExpanded:(BOOL)expanded {
    _expanded = expanded;
    self.bottomView.hidden = !expanded;
    
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.expanded = NO;
}

@end
