// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBSettingsTableViewCell.h"

@interface MBSettingsTableViewCell()

@property(nonatomic,strong) UIView* backgroundTopWhite;
@property(nonatomic,strong) UIView* backgroundBottomWhite;

@end

@implementation MBSettingsTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self){
        self.backgroundBottomWhite = [[UIView alloc] init];
        self.backgroundBottomWhite.backgroundColor = [UIColor whiteColor];
        self.backgroundBottomWhite.layer.shadowOffset = CGSizeMake(1.0, 2.0);
        self.backgroundBottomWhite.layer.shadowColor = [[UIColor db_dadada] CGColor];
        self.backgroundBottomWhite.layer.shadowRadius = 1.5;
        self.backgroundBottomWhite.layer.shadowOpacity = 1.0;
        [self.contentView addSubview:self.backgroundBottomWhite];
        
        self.backgroundTopWhite = [[UIView alloc] init];
        self.backgroundTopWhite.backgroundColor = [UIColor whiteColor];
        self.backgroundTopWhite.layer.shadowOffset = CGSizeMake(1.0, 2.0);
        self.backgroundTopWhite.layer.shadowColor = [[UIColor db_dadada] CGColor];
        self.backgroundTopWhite.layer.shadowRadius = 1.5;
        self.backgroundTopWhite.layer.shadowOpacity = 1.0;
        [self.contentView addSubview:self.backgroundTopWhite];
        
        self.mainIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        self.mainIcon.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:self.mainIcon];
        
        self.mainTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.mainTitleLabel.numberOfLines = 2;
        self.mainTitleLabel.font = [UIFont db_BoldSeventeen];
        self.mainTitleLabel.textColor = [UIColor db_333333];
        [self.contentView addSubview:self.mainTitleLabel];
        
        self.subTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.subTitleLabel.font = [UIFont db_RegularFourteen];
        self.subTitleLabel.textColor = [UIColor db_333333];
        [self.contentView addSubview:self.subTitleLabel];
        
        self.aSwitch = [[UISwitch alloc] init];
        [self.contentView addSubview:self.aSwitch];
    }
    return self;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    self.backgroundTopWhite.frame = CGRectMake(8, 0, self.sizeWidth-2*8, 80);
    self.backgroundBottomWhite.frame = CGRectMake(8, 80, self.sizeWidth-2*8, 72);

    [self.mainIcon setGravityLeft:40];
    [self.mainIcon setGravityTop:(int)((80-self.mainIcon.sizeHeight)/2)];
    
    self.mainTitleLabel.frame = CGRectMake(116, 0, self.sizeWidth-116-16, 80);
    self.subTitleLabel.frame = CGRectMake(16, 80, self.sizeWidth-16-90, 72);
    
    [self.aSwitch setGravityRight:16];
    [self.aSwitch setGravityBottom:24];
}

-(void)setShowDetails:(BOOL)showDetails{
    self.backgroundBottomWhite.hidden = !showDetails;
    self.aSwitch.hidden = !showDetails;
    self.subTitleLabel.hidden = !showDetails;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
