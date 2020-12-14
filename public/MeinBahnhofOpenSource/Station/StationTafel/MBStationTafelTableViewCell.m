// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBStationTafelTableViewCell.h"

@interface MBStationTafelTableViewCell()

@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *expectedTimeLabel;
@property (nonatomic, strong) UILabel *destinationLabel;
@property (nonatomic, strong) UILabel *platformLabel;
@property (nonatomic, strong) UILabel *trainLabel;
@property (nonatomic, strong) UIImageView *warningLabel;

@end

@implementation MBStationTafelTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    [self configureCell];
    return self;
}

- (void)configureCell {
    self.timeLabel = [UILabel new];
    self.expectedTimeLabel = [UILabel new];
    self.destinationLabel = [UILabel new];
    self.platformLabel = [UILabel new];
    self.trainLabel = [UILabel new];
    self.warningLabel =  [UIImageView new];
    
    self.timeLabel.font = [UIFont db_BoldSixteen];
    self.timeLabel.textColor = [UIColor db_333333];
    
    self.expectedTimeLabel.font = [UIFont db_RegularFourteen];
    self.expectedTimeLabel.textColor = [UIColor db_333333];

    self.destinationLabel.font = [UIFont db_RegularSixteen];
    self.destinationLabel.textColor = [UIColor db_333333];
    
    self.trainLabel.font = [UIFont db_RegularFourteen];
    self.trainLabel.textColor = [UIColor db_787d87];
    self.trainLabel.allowsDefaultTighteningForTruncation = YES;
    
    self.platformLabel.font = self.trainLabel.font;
    self.platformLabel.textColor = self.trainLabel.textColor;
    self.platformLabel.allowsDefaultTighteningForTruncation = YES;
    
    self.warningLabel.contentMode = UIViewContentModeCenter;
    self.warningLabel.image = [UIImage db_imageNamed:@"app_warndreieck"];
    
    [self.contentView addSubview:self.timeLabel];
    [self.contentView addSubview:self.expectedTimeLabel];
    [self.contentView addSubview:self.destinationLabel];
    [self.contentView addSubview:self.trainLabel];
    [self.contentView addSubview:self.platformLabel];
    [self.contentView addSubview:self.warningLabel];
    
}

- (NSString *)accessibilityLabel
{
    if(_hafas){
        NSString* line = self.trainLabel.text;
        line = [line stringByReplacingOccurrencesOfString:@"STR" withString:VOICEOVER_FOR_STR];

        return [NSString stringWithFormat:@"%@ nach %@, %@ Uhr; %@",
                line,
                self.destinationLabel.text,
                self.timeLabel.text,
                (![self.expectedTimeLabel.text isEqualToString:self.timeLabel.text] ? [NSString stringWithFormat:@"Erwartet %@",self.expectedTimeLabel.text] : @"")
                ];
    }
    NSString* gleis = [NSString stringWithFormat:@"Gleis %@", [_event actualPlatform]];
    NSString* train = [self.stop formattedTransportType:_event.lineIdentifier];

    return [NSString stringWithFormat:@"%@ nach %@, %@ Uhr, %@, %@.",
            train,
            self.destinationLabel.text,
            self.timeLabel.text,
            (![self.expectedTimeLabel.text isEqualToString:self.timeLabel.text] ? [NSString stringWithFormat:@"Erwartet %@",self.expectedTimeLabel.text] : @""),
            gleis
            ];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat leftSlack = 16.0;
    self.timeLabel.frame = CGRectMake(leftSlack, 4.0, 50.0, 21.0);
    self.expectedTimeLabel.frame = CGRectMake(leftSlack, self.timeLabel.frame.origin.y + self.timeLabel.frame.size.height + 2.0, 50.0, 19.0);
    self.destinationLabel.frame = CGRectMake(self.timeLabel.frame.origin.x + self.timeLabel.frame.size.width + 8.0, 4.0, self.size.width - leftSlack - (self.timeLabel.frame.origin.x + self.timeLabel.frame.size.width), 21.0);
    self.trainLabel.frame = CGRectMake(self.destinationLabel.frame.origin.x, self.expectedTimeLabel.frame.origin.y, self.destinationLabel.frame.size.width-40, 19.0);

    [self.trainLabel setWidth:[self.trainLabel sizeThatFits:CGSizeMake(self.trainLabel.sizeWidth, self.trainLabel.sizeHeight)].width];

    self.warningLabel.frame = CGRectMake(CGRectGetMaxX(self.trainLabel.frame)+10.0, self.expectedTimeLabel.frame.origin.y, 20.0, 20.0);

    [self.platformLabel sizeToFit];
    self.platformLabel.frame = CGRectMake(self.size.width-leftSlack-self.platformLabel.sizeWidth, self.trainLabel.frame.origin.y, self.platformLabel.sizeWidth, 19);
}

- (void)setStop:(Stop *)stop {
    _stop = stop;
    self.event = [stop eventForDeparture:YES];
}

- (void)setHafas:(HafasDeparture *)hafas {
    _hafas = hafas;
    // ignore seconds in the time
    self.timeLabel.text = [hafas.time substringToIndex:5];
    self.destinationLabel.text = hafas.direction;
//    self.trainLabel.text = hafas.name;
    self.trainLabel.text = hafas.name;
    self.warningLabel.hidden = YES;
    self.expectedTimeLabel.text = [hafas expectedDeparture];
    if([hafas delayInMinutes] >= 5){
        self.expectedTimeLabel.textColor = [UIColor db_mainColor];
    } else {
        self.expectedTimeLabel.textColor = [UIColor db_38a63d];
    }
    self.expectedTimeLabel.hidden = NO;
    [self setNeedsLayout];
}

- (void)setEvent:(Event *)event {
    _event = event;
    self.timeLabel.text = [event formattedTime];
    self.expectedTimeLabel.text = [event formattedExpectedTime];
    if([event roundedDelay] >= 5){
        self.expectedTimeLabel.textColor = [UIColor db_mainColor];
    } else {
        self.expectedTimeLabel.textColor = [UIColor db_38a63d];
    }
    //hide time when train is canceled
    self.expectedTimeLabel.hidden = event.eventIsCanceled;

    self.destinationLabel.text = [event actualStation];
    self.trainLabel.text = [self.stop formattedTransportType:event.lineIdentifier];
    self.platformLabel.text = [NSString stringWithFormat:@"Gl. %@", [event actualPlatform]];
    
    [event updateComposedIrisWithStop:self.stop];
    
    self.warningLabel.hidden = event.composedIrisMessage.length == 0;
    if(!self.warningLabel.hidden){
        //what icon do we need?
        if(event.hasOnlySplitMessage){
            self.warningLabel.image = [UIImage db_imageNamed:@"app_warndreieck_dunkelgrau"];
        } else {
            self.warningLabel.image = [UIImage db_imageNamed:@"app_warndreieck"];
            if(event.shouldShowRedWarnIcon){
                self.warningLabel.hidden = NO;
            } else {
                self.warningLabel.hidden = YES;
            }
        }
    }
    [self setNeedsLayout];

}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.warningLabel.hidden = true;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
