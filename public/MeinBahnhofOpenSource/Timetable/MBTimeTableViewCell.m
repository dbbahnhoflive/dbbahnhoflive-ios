// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBTimeTableViewCell.h"
#import "Stop.h"
#import "MBUIHelper.h"

@interface MBTimeTableViewCell()

@property (nonatomic, strong) UIImageView *wagenstandIcon;

@property (nonatomic, strong) UIView *backView;
// always visible view contains time and station etc.
@property (nonatomic, strong) UIView *topView;


@end

@implementation MBTimeTableViewCell


- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self configureCell];
    }
    return self;
}

- (void) configureCell
{
    self.backgroundColor = [UIColor clearColor];
    self.backView = [[UIView alloc] init];
    self.topView = [[UIView alloc] init];
    self.topView.backgroundColor = [UIColor whiteColor];
    self.timeLabel = [[UILabel alloc] init];
    self.platformLabel = [[UILabel alloc] init];
    self.trainLabel = [[UILabel alloc] init];
    self.stationLabel = [[UILabel alloc] init];
    self.expectedTimeLabel = [[UILabel alloc] init];
            
    self.wagenstandIcon = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_wagenreihung_grau"]];
    self.messageIcon = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_warndreieck"]];
    
    [self.timeLabel setFont:[UIFont db_BoldSixteen]];
    [self.expectedTimeLabel setFont:[UIFont db_RegularFourteen]];
    [self.platformLabel setFont:[UIFont db_RegularFourteen]];
    [self.trainLabel setFont:[UIFont db_RegularFourteen]];
    [self.stationLabel setFont:[UIFont db_RegularSixteen]];
    
    [self.expectedTimeLabel setTextColor:[UIColor db_green]];
    [self.platformLabel setTextColor:[UIColor db_787d87]];
    [self.trainLabel setTextColor:[UIColor db_787d87]];
    [self.stationLabel setTextColor:[UIColor db_333333]];
    [self.timeLabel setTextColor:[UIColor db_333333]];
    
    self.stationLabel.numberOfLines = 0;
    self.messageIcon.hidden = YES;
    
    [self.contentView addSubview:self.backView];
    [self.backView addSubview:self.topView];
    
    [self.topView addSubview:self.timeLabel];
    [self.topView addSubview:self.expectedTimeLabel];
    [self.topView addSubview:self.trainLabel];
    [self.topView addSubview:self.platformLabel];
    [self.topView addSubview:self.stationLabel];
    [self.topView addSubview:self.messageIcon];
    [self.topView addSubview:self.wagenstandIcon];


    self.accessibilityTraits = self.accessibilityTraits|UIAccessibilityTraitButton;
    self.accessibilityHint = @"Zur Anzeige von Details doppeltippen.";
    self.accessibilityLanguage = @"de-DE";
    self.timeLabel.accessibilityLanguage = @"de-DE";
    self.expectedTimeLabel.accessibilityLanguage = @"de-DE";
    self.platformLabel.accessibilityLanguage = @"de-DE";
    self.trainLabel.accessibilityLanguage = @"de-DE";
    self.stationLabel.accessibilityLanguage = @"de-DE";
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat leftSlack = 8.0;
    self.backView.frame = CGRectMake(leftSlack, 0, self.frame.size.width-2.0*leftSlack, self.frame.size.height);
    self.topView.frame = CGRectMake(0, 0, self.backView.frame.size.width, 80.0);
    [self.topView configureDefaultShadow];
    
    self.timeLabel.frame = CGRectMake(kLeftPadding, 16.0, 70, 20);
    self.stationLabel.frame = CGRectMake(self.timeLabel.frame.origin.x+self.timeLabel.frame.size.width+kInnerPadding, self.timeLabel.frame.origin.y, self.frame.size.width-self.timeLabel.frame.size.width-kInnerPadding-kLeftPadding*2, 20);
    self.expectedTimeLabel.frame = CGRectMake(self.timeLabel.frame.origin.x, self.timeLabel.frame.origin.y+self.timeLabel.frame.size.height+kInnerPadding, 70, 15);
    self.trainLabel.frame = CGRectMake(self.stationLabel.frame.origin.x, self.expectedTimeLabel.frame.origin.y, 90, 15);
    
    [self.trainLabel sizeToFit];
    [self.platformLabel sizeToFit];
    [self.platformLabel setGravityTop:self.trainLabel.frame.origin.y];
    [self.platformLabel setGravityRight:kLeftPadding];

    CGRect wagenstandFrame = self.wagenstandIcon.frame;
    wagenstandFrame.origin.x = self.trainLabel.frame.origin.x + self.trainLabel.frame.size.width + 8.0;
    wagenstandFrame.origin.y = self.trainLabel.frame.origin.y - 4.0;
    
    BOOL trainRecordAvailable = [Stop stopShouldHaveTrainRecord:self.event.stop];
    [self.wagenstandIcon setHidden:!trainRecordAvailable];
    wagenstandFrame.size.width = self.wagenstandIcon.isHidden ? 0.0 : self.wagenstandIcon.frame.size.width;
    CGFloat messageXOffset = self.wagenstandIcon.isHidden ? 0.0 : 8.0;
    self.wagenstandIcon.frame = wagenstandFrame;
    self.messageIcon.frame = CGRectMake(self.wagenstandIcon.frame.origin.x+self.wagenstandIcon.frame.size.width+messageXOffset, self.wagenstandIcon.frame.origin.y + 2.0, self.messageIcon.image.size.width,self.messageIcon.image.size.height);

}

- (NSString *)accessibilityLabel
{
    return [_event voiceOverString];
}


- (void)prepareForReuse
{
    [super prepareForReuse];
    _wagenstandIcon.frame = CGRectMake(0, 0, _wagenstandIcon.image.size.width, _wagenstandIcon.image.size.height);
    _stopId = nil;
}

- (CGSize)sizeForLabel:(UILabel *)label
{
    CGSize size = [label.text sizeWithAttributes:@{NSFontAttributeName: label.font}];
    size = CGSizeMake(ceilf(size.width), ceilf(size.height));
    return size;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

-(void)accessibilityElementDidBecomeFocused{
    //NSLog(@"TimeTableCell did get focus: %@",self.stationLabel);
    [self.delegate cellWasSelectedViaVoiceOver:self];
}
-(void)accessibilityElementDidLoseFocus{
    //NSLog(@"TimeTableCell did loose focus: %@",self.stationLabel);
    [self.delegate cellWasDeselectedViaVoiceOver:self];
}

@end
