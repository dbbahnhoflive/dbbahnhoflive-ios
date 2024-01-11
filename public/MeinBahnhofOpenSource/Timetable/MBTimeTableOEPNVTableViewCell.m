// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBTimeTableOEPNVTableViewCell.h"
#import "HafasStopLocation.h"
#import "MBUIHelper.h"
#import "MBVoiceOverHelper.h"

@interface MBTimeTableOEPNVTableViewCell()
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *lineLabel;
@property (nonatomic, strong) UILabel *destLabel;
@property (nonatomic, strong) UILabel *expectedTimeLabel;
@property (nonatomic, strong) UIImageView *messageIcon;
@property (nonatomic, strong) UILabel *platformLabel;


@end

@implementation MBTimeTableOEPNVTableViewCell

- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self configureCell];
    }
    return self;
}

- (void)configureCell {
    self.backgroundColor = [UIColor clearColor];
    // setup subviews
    self.topView = [UIView new];
    [self.topView configureDefaultShadow];
    self.topView.backgroundColor = [UIColor whiteColor];

    self.timeLabel = [UILabel new];
    self.timeLabel.textColor = [UIColor db_333333];
    self.timeLabel.font = [UIFont db_BoldSixteen];
    
    self.lineLabel = [UILabel new];
    self.lineLabel.textColor = [UIColor db_787d87];
    self.lineLabel.font = [UIFont db_RegularFourteen];
    
    self.destLabel = [UILabel new];
    self.destLabel.textColor = [UIColor db_333333];
    self.destLabel.font = [UIFont db_RegularSixteen];
    
    self.expectedTimeLabel = [[UILabel alloc] init];
    self.expectedTimeLabel.textColor = [UIColor db_333333];
    self.expectedTimeLabel.font = [UIFont db_RegularFourteen];
    
    self.messageIcon = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_warndreieck"]];
    [self.topView addSubview:self.messageIcon];
    
    self.platformLabel = [[UILabel alloc] init];
    [self.platformLabel setFont:[UIFont db_RegularFourteen]];
    [self.platformLabel setTextColor:[UIColor db_787d87]];

    [self.topView addSubview:self.timeLabel];
    [self.topView addSubview:self.lineLabel];
    [self.topView addSubview:self.destLabel];
    [self.topView addSubview:self.expectedTimeLabel];
    [self.topView addSubview:self.platformLabel];

    [self.contentView addSubview:self.topView];

    self.accessibilityTraits = self.accessibilityTraits|UIAccessibilityTraitButton;
    self.accessibilityHint = @"Zur Anzeige von Details doppeltippen.";

}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.topView.frame = CGRectMake(8, 8, self.frame.size.width-2*8, 80);
    self.timeLabel.frame = CGRectMake(16, 16, 100, 20);
    self.expectedTimeLabel.frame = CGRectMake(16, CGRectGetMaxY(self.timeLabel.frame)+8, 100, 20);
    self.destLabel.frame = CGRectMake(70, 16, self.frame.size.width-70-3*8, 20);
    self.lineLabel.frame = CGRectMake(self.destLabel.frame.origin.x, self.expectedTimeLabel.frame.origin.y, self.frame.size.width-self.destLabel.frame.origin.x-3*8, 20);
    [self.lineLabel setWidth:ceilf([self.lineLabel sizeThatFits:self.lineLabel.frame.size].width)];
    [self.messageIcon setRight:self.lineLabel withPadding:8];
    [self.messageIcon centerViewVerticalWithView:self.lineLabel];
    
    [self.platformLabel sizeToFit];
    [self.platformLabel setGravityTop:self.lineLabel.frame.origin.y];
    [self.platformLabel setGravityRight:16];

}

- (void)prepareForReuse
{
    [super prepareForReuse];
}

- (void)setHafas:(HafasDeparture *)hafas {
    _hafas = hafas;
    // ignore seconds in time
    self.timeLabel.text = [hafas.time substringToIndex:5];
    [self.timeLabel sizeToFit];
    self.lineLabel.text = hafas.name;
    [self.lineLabel sizeToFit];
    self.destLabel.text = hafas.direction;
    self.messageIcon.hidden = !hafas.partCancelled && !hafas.trackChanged;
//    [self.destLabel sizeToFit];//NO, this leads to autolayout failure!
    self.expectedTimeLabel.text = [hafas expectedDeparture];
    if([hafas delayInMinutes] >= 5){
        self.expectedTimeLabel.textColor = [UIColor db_mainColor];
    } else {
        self.expectedTimeLabel.textColor = [UIColor db_green];
    }
    self.platformLabel.text = @"";
    if(hafas.displayTrack.length > 0){
        self.platformLabel.text = [NSString stringWithFormat:@"Gl. %@",hafas.displayTrack];
    }
    if(hafas.trackChanged){
        self.platformLabel.textColor = [UIColor db_mainColor];
    } else {
        self.platformLabel.textColor = [UIColor db_787d87];
    }

    
}

- (NSString *)accessibilityLabel
{
    
    NSString* line = self.lineLabel.text;
    line = [line stringByReplacingOccurrencesOfString:@"STR" withString:VOICEOVER_FOR_STR];

    NSString* trackInfo = @"";
    if(self.hafas.displayTrack.length > 0){
        if(self.hafas.trackChanged){
            trackInfo = [NSString stringWithFormat:@"Heute abweichend Gleis %@",self.hafas.displayTrack];
        } else {
            trackInfo = [NSString stringWithFormat:@"Gleis %@",self.hafas.displayTrack];
        }
    }
    
    NSString* res = [NSString stringWithFormat:@"%@ nach %@. %@, %@. %@",
            line,
            self.destLabel.text,
            [MBVoiceOverHelper timeForVoiceOver:self.timeLabel.text],
            ([self.timeLabel.text isEqualToString:self.expectedTimeLabel.text] ? @"" : [NSString stringWithFormat:@"Erwartet %@",[MBVoiceOverHelper timeForVoiceOver:self.expectedTimeLabel.text]]),
            trackInfo
            ];
    if(_hafas.partCancelled){
        res = [res stringByAppendingFormat:@" %@",STOP_MISSING_TEXT];
    }
    return res;
}


@end
