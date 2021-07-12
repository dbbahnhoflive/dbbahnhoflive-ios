// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBTimeTableViewCell.h"
#import "Stop.h"
#import "MBTimetableViewController.h"
@interface MBTimeTableViewCell()

@property (nonatomic, strong) UIView *backView;
// always visible view contains time and station etc.
@property (nonatomic, strong) UIView *topView;
// only visible in expanded view, contains via stations and warning info and Wagenreihung button
@property (nonatomic, strong) UIView *bottomView;

// background view for wagenstand button
@property (nonatomic, strong) UIView *wagenStandButtonBackView;

@end

@implementation MBTimeTableViewCell

@synthesize expanded = _expanded;

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
    self.wagenStandButtonBackView = [[UIView alloc] init];
    self.backView = [[UIView alloc] init];
    self.topView = [[UIView alloc] init];
    self.bottomView = [[UIView alloc] init];
    self.bottomView.backgroundColor = [UIColor whiteColor];
    self.topView.backgroundColor = [UIColor whiteColor];
    self.timeLabel = [[UILabel alloc] init];
    self.platformLabel = [[UILabel alloc] init];
    self.trainLabel = [[UILabel alloc] init];
    self.stationLabel = [[UILabel alloc] init];
    self.expectedTimeLabel = [[UILabel alloc] init];
    
    self.viaListView = [[MBStationListView alloc] initWithFrame:CGRectZero];
//    self.accessoryView = self.bottomView;
    
    self.messageDetailContainer = [[UIView alloc] init];
    self.messageTextLabel = [[UILabel alloc] init];
    
    self.wagenstandButton = [MBButtonWithData buttonWithType:UIButtonTypeCustom];
    [self.wagenstandButton setImage:[UIImage db_imageNamed:@"app_wagenreihung_weiss"] forState:UIControlStateNormal];
    [self.wagenstandButton setTitle:@"Zur Wagenreihung" forState:UIControlStateNormal];
    self.wagenstandButton.titleLabel.font = [UIFont db_BoldSixteen];
    self.wagenstandButton.titleLabel.textColor = [UIColor whiteColor];
    self.wagenstandButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.wagenstandButton.backgroundColor = [UIColor db_GrayButton];

    self.wagenstandIcon = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_wagenreihung_grau"]];
    self.messageIcon = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_warndreieck"]];
    self.messageIconDetail = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_warndreieck"]];
    
    [self.timeLabel setFont:[UIFont db_BoldSixteen]];
    [self.expectedTimeLabel setFont:[UIFont db_RegularFourteen]];
    [self.platformLabel setFont:[UIFont db_RegularFourteen]];
    [self.trainLabel setFont:[UIFont db_RegularFourteen]];
    [self.stationLabel setFont:[UIFont db_RegularSixteen]];
    [self.messageTextLabel setFont:[UIFont db_HelveticaTwelve]];
    
    [self.expectedTimeLabel setTextColor:[UIColor db_38a63d]];
    [self.platformLabel setTextColor:[UIColor db_787d87]];
    [self.trainLabel setTextColor:[UIColor db_787d87]];
    [self.stationLabel setTextColor:[UIColor db_333333]];
    [self.timeLabel setTextColor:[UIColor db_333333]];
    [self.messageTextLabel setTextColor:[UIColor db_mainColor]];
    
    self.messageTextLabel.numberOfLines = 0;
    self.stationLabel.numberOfLines = 0;
    
    self.messageTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    self.messageDetailContainer.hidden = YES;
    self.messageIcon.hidden = YES;
    
    self.messageDetailContainer.backgroundColor = [UIColor whiteColor];
    
    [self.contentView addSubview:self.backView];
    [self.backView addSubview:self.topView];
    [self.backView addSubview:self.bottomView];
    
    [self.topView addSubview:self.timeLabel];
    [self.topView addSubview:self.expectedTimeLabel];
    [self.topView addSubview:self.trainLabel];
    [self.topView addSubview:self.platformLabel];
    [self.topView addSubview:self.stationLabel];
    [self.topView addSubview:self.messageIcon];
    [self.topView addSubview:self.wagenstandIcon];
    
    [self.bottomView addSubview:self.viaListView];

    [self.messageDetailContainer addSubview:self.messageIconDetail];
    [self.messageDetailContainer addSubview:self.messageTextLabel];
    
    [self.wagenStandButtonBackView addSubview:self.wagenstandButton];
    [self.bottomView addSubview:self.wagenStandButtonBackView];
    [self.bottomView addSubview:self.messageDetailContainer];

    self.accessibilityTraits = self.accessibilityTraits|UIAccessibilityTraitButton;
    self.accessibilityHint = @"Zur Anzeige von Details doppeltippen.";
    self.accessibilityLanguage = @"de-DE";
    self.timeLabel.accessibilityLanguage = @"de-DE";
    self.expectedTimeLabel.accessibilityLanguage = @"de-DE";
    self.platformLabel.accessibilityLanguage = @"de-DE";
    self.trainLabel.accessibilityLanguage = @"de-DE";
    self.stationLabel.accessibilityLanguage = @"de-DE";
    self.messageTextLabel.accessibilityLanguage = @"de-DE";
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat leftSlack = 8.0;
//    CGFloat bottomSlack = 8.0;
    self.backView.frame = CGRectMake(leftSlack, 0, self.frame.size.width-2.0*leftSlack, self.frame.size.height);
    self.topView.frame = CGRectMake(0, 0, self.backView.frame.size.width, 80.0);
    self.topView.layer.shadowOffset = CGSizeMake(1.0, 2.0);
    self.topView.layer.shadowColor = [[UIColor db_dadada] CGColor];
    self.topView.layer.shadowRadius = 1.5;
    self.topView.layer.shadowOpacity = 1.0;
    
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
    
    [self.wagenstandIcon setHidden:!self.event.trainRecordAvailable];
    wagenstandFrame.size.width = self.wagenstandIcon.isHidden ? 0.0 : self.wagenstandIcon.frame.size.width;
    CGFloat messageXOffset = self.wagenstandIcon.isHidden ? 0.0 : 8.0;
    self.wagenstandIcon.frame = wagenstandFrame;
    self.messageIcon.frame = CGRectMake(self.wagenstandIcon.frame.origin.x+self.wagenstandIcon.frame.size.width+messageXOffset, self.wagenstandIcon.frame.origin.y + 2.0, self.messageIcon.image.size.width,self.messageIcon.image.size.height);
    
    [self.viaListView setFrame:CGRectMake(0, 0, self.bottomView.frame.size.width, 92.0)];
    self.bottomView.hidden = !_expanded;
    
    [self.messageDetailContainer setBelow:self.viaListView withPadding:5];

    
    CGFloat wagenStandButtonWidth = floor(0.8 * self.bottomView.frame.size.width);
    [self.wagenstandButton setFrame:CGRectMake((self.bottomView.frame.size.width - wagenStandButtonWidth) / 2.0, 16.0, wagenStandButtonWidth, 60.0)];

    self.wagenStandButtonBackView.frame = CGRectMake(0, self.wagenstandButton.frame.origin.y - 16.0, self.bottomView.frame.size.width, self.wagenstandButton.frame.size.height + 32.0);

    self.wagenStandButtonBackView.backgroundColor = [UIColor whiteColor];
    
    CGRect backRect = self.wagenStandButtonBackView.bounds;
    backRect.size.height += 4.0;
    backRect.origin.y += 2.0;
    backRect.size.width += 1.0;
    
    self.wagenStandButtonBackView.layer.shadowPath = [[UIBezierPath bezierPathWithRect:backRect] CGPath];
    self.wagenStandButtonBackView.layer.shadowColor = [[UIColor db_dadada] CGColor];
    self.wagenStandButtonBackView.layer.shadowRadius = 1.5;
    self.wagenStandButtonBackView.layer.shadowOpacity = 1.0;

    // edge insets order: top, left, bottom, right
    self.wagenstandButton.titleEdgeInsets = UIEdgeInsetsMake(0,
                                                             -2.0 * (self.wagenstandButton.imageView.frame.size.width + 10.0),
                                                             0,
                                                             0);
    self.wagenstandButton.imageEdgeInsets = UIEdgeInsetsMake(0, self.wagenstandButton.titleLabel.frame.origin.x+self.wagenstandButton.titleLabel.frame.size.width+10.0, 0, 0);
    
    self.wagenstandButton.layer.cornerRadius = self.wagenstandButton.frame.size.height / 2.0;
    self.wagenstandButton.layer.shadowOffset = CGSizeMake(3.0, 3.0);
    
    self.wagenstandButton.layer.shadowColor = [[UIColor db_dadada] CGColor];
    self.wagenstandButton.layer.shadowRadius = 2.5;
    self.wagenstandButton.layer.shadowOpacity = 1.0;

    CGRect messageFrame = self.messageDetailContainer.frame;
    messageFrame.size.width = self.backView.frame.size.width - 24.0;
    messageFrame.origin.x = (self.backView.frame.size.width - messageFrame.size.width) / 2.0;
    self.messageDetailContainer.frame = messageFrame;

    
    CGRect boundingRect = [self.messageTextLabel.attributedText boundingRectWithSize:CGSizeMake(messageFrame.size.width-(self.messageIconDetail.frame.origin.x+self.messageIconDetail.frame.size.width+8.0),                                                                                               CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
    
    CGSize fittingSizeForMessageLabel = boundingRect.size;
    
    CGRect textLabelFrame = CGRectMake(self.messageIconDetail.frame.origin.x+self.messageIconDetail.frame.size.width+8.0, self.messageIconDetail.frame.origin.y + 3.0, fittingSizeForMessageLabel.width, fittingSizeForMessageLabel.height);
    self.messageTextLabel.frame = textLabelFrame;

    if (fittingSizeForMessageLabel.height == 0) {
        self.messageDetailContainer.height = 0;
    } else {
        [self.messageDetailContainer resizeHeight];
        self.messageDetailContainer.height = self.messageDetailContainer.sizeHeight+4.0;
    }
    [self.messageIconDetail setGravityLeft:kLeftPadding+3];
    [self.messageIconDetail setGravityTop:kTopPadding];


    UIView *viewAboveButton = fittingSizeForMessageLabel.height > 10 ? self.messageDetailContainer : self.viaListView;
    
    [self.wagenStandButtonBackView setBelow:viewAboveButton withPadding:15.0];
    self.wagenStandButtonBackView.hidden = !self.event.trainRecordAvailable;
    
    // only via stations
    CGFloat bottomHeight = self.viaListView.frame.size.height;
    // Wagenreihung
    bottomHeight = self.event.trainRecordAvailable ? bottomHeight + self.wagenStandButtonBackView.frame.size.height + 15.0 : bottomHeight;
    // message label
    bottomHeight = self.messageDetailContainer.frame.size.height > 0 ? bottomHeight + self.messageDetailContainer.frame.size.height + 5.0 : bottomHeight;
    
    [self.bottomView setFrame:CGRectMake(0, self.topView.frame.origin.y+self.topView.frame.size.height+1.0, self.backView.frame.size.width, bottomHeight)];

}

- (NSString *)accessibilityLabel
{
    return [MBTimeTableViewCell voiceOverForEvent:_event expanded:self.expanded viaStation:self.viaListView.stations];
}
+(NSString*)voiceOverForEvent:(Event*)event{
    return [MBTimeTableViewCell voiceOverForEvent:event expanded:NO viaStation:nil];
}
+(NSString*)voiceOverForEvent:(Event*)event expanded:(BOOL)expanded viaStation:(NSArray*)viaStationList{
    NSString* viaStations = @"";
    if(expanded){
        viaStations = [viaStationList componentsJoinedByString:@", "];
        viaStations = [@", über " stringByAppendingString:viaStations];
    }
    NSString* train = [event.stop formattedTransportType:event.lineIdentifier];
    if([train containsString:@"ICE"]){
        train = [train stringByReplacingOccurrencesOfString:@"ICE" withString:@"I C E"];
    } else if([train hasPrefix:@"STR"]){
        train = [train stringByReplacingOccurrencesOfString:@"STR" withString:VOICEOVER_FOR_STR];
    }
    NSString* gleis = [NSString stringWithFormat:@"Gleis %@",event.actualPlatform];
    NSString* msg = event.composedIrisMessage;
    if(!msg){
        msg = @"";
    }
    NSString* trainOrder = @"";
    if(event.trainRecordAvailable || [MBTimetableViewController stopShouldHaveTrainRecord:event.stop]){
        trainOrder = @"Informationen zur Wagenreihung verfügbar.";
    }
    NSString* res = [NSString stringWithFormat:@"%@ %@ %@. %@ Uhr, %@, %@; %@%@.%@",
                train,
                event.departure ? @"nach" : @"von",
                event.actualStation,
                event.formattedTime,
                ([event.formattedTime isEqualToString:event.formattedExpectedTime] ? @"" : [NSString stringWithFormat:@"Erwartet %@ Uhr",event.formattedExpectedTime]),
                gleis,
                msg,
                viaStations,
                trainOrder
            ];
    //NSLog(@"voiceover: %@",res);
    return res;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    _expanded = NO;
    _messageTextLabel.attributedText = nil;
    _wagenstandIcon.frame = CGRectMake(0, 0, _wagenstandIcon.image.size.width, _wagenstandIcon.image.size.height);
}

- (CGSize)sizeForLabel:(UILabel *)label
{
    CGSize size = [label.text sizeWithAttributes:@{NSFontAttributeName: label.font}];
    size = CGSizeMake(ceilf(size.width), ceilf(size.height));
    return size;
}

- (void) setExpanded:(BOOL)expanded forIndexPath:(NSIndexPath*)indexPath;
{
    _expanded = expanded;
    if(expanded){
        NSLog(@"open details for stop %@",self.event.stop.stopId);
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
