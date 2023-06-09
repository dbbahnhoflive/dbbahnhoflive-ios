// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBTrainJourneyStopTableViewCell.h"
#import "MBUIHelper.h"

@interface MBTrainJourneyStopTableViewCell()
@property(nonatomic,strong) UILabel* stationLabel;
@property(nonatomic,strong) UILabel* platformLabel;
@property(nonatomic,strong) UILabel* arrivalLabel;
@property(nonatomic,strong) UILabel* departureLabel;
@property(nonatomic,strong) UILabel* arrivalNewLabel;
@property(nonatomic,strong) UILabel* departureNewLabel;
@property(nonatomic,strong) UIView* bottomLine;
@property(nonatomic,strong) UIView* journeyLineBackground;
@property(nonatomic,strong) UIView* journeyLineActive;
@property(nonatomic,strong) UIView* journeyDot;
@property(nonatomic,strong) UIView* journeyDotBackground;
@property(nonatomic,strong) UIImageView* warningImage;
@property(nonatomic,strong) UILabel* warningLabel;
@property(nonatomic) BOOL layoutWithStationNameOnly;

@property(nonatomic) BOOL isFirst;
@property(nonatomic) BOOL isLast;

@property(nonatomic,weak) MBTrainJourneyStop* stop;

@end

@implementation MBTrainJourneyStopTableViewCell

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
    self.stationLabel = [UILabel new];
    self.stationLabel.textColor = UIColor.db_333333;
    self.stationLabel.font = UIFont.db_RegularFourteen;
    [self.contentView addSubview:self.stationLabel];

    self.platformLabel = [UILabel new];
    self.platformLabel.textAlignment = NSTextAlignmentRight;
    self.platformLabel.font = UIFont.db_RegularFourteen;
    [self.contentView addSubview:self.platformLabel];

    self.warningImage = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_warndreieck"]];
    [self.contentView addSubview:self.warningImage];
    self.warningImage.hidden = true;
    
    self.warningLabel = [UILabel new];
    [self.contentView addSubview:self.warningLabel];
    self.warningLabel.font = UIFont.db_RegularTen;
    self.warningLabel.textColor = UIColor.db_mainColor;
    
    self.arrivalLabel = [UILabel new];
    self.departureLabel = [UILabel new];
    self.arrivalNewLabel = [UILabel new];
    self.departureNewLabel = [UILabel new];
    [self.contentView addSubview:self.arrivalLabel];
    [self.contentView addSubview:self.departureLabel];
    [self.contentView addSubview:self.arrivalNewLabel];
    [self.contentView addSubview:self.departureNewLabel];

    self.journeyLineBackground = [[UIView alloc] initWithFrame:CGRectMake(17, 0, 2, self.frame.size.height)];
    self.journeyLineBackground.backgroundColor = self.journeyColorFuture;
    [self.contentView addSubview:self.journeyLineBackground];
    self.journeyLineActive = [[UIView alloc] initWithFrame:CGRectMake(_journeyLineBackground.frame.origin.x, 0, _journeyLineBackground.frame.size.width, self.frame.size.height)];
    self.journeyLineActive.backgroundColor = self.journeyColorCurrentOrPast;
    [self.contentView addSubview:self.journeyLineActive];

    self.journeyDotBackground = [[UIView alloc] initWithFrame:CGRectMake(11, 30, 14, 14)];
    self.journeyDotBackground.layer.cornerRadius = 7;
    self.journeyDotBackground.backgroundColor = UIColor.db_f3f5f7;
    [self.contentView addSubview:self.journeyDotBackground];
    self.journeyDot = [[UIView alloc] initWithFrame:CGRectMake(13, 20+12, 10, 10)];
    self.journeyDot.layer.cornerRadius = 5;
    [self.contentView addSubview:self.journeyDot];

    //self.bottomLine = [UIView new];
    //self.bottomLine.backgroundColor = UIColor.db_light_lineColor;
    //[self.contentView addSubview:self.bottomLine];
    

}

-(UIColor*)journeyColorCurrentOrPast{
    return [UIColor db_mainColor];
}
-(UIColor*)journeyColorFuture{
    return [UIColor dbColorWithRGB:0x9BA0AA];
}
-(UIColor*)journeyColorCurrentStation{
    return UIColor.db_333333;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    [self.platformLabel setGravityRight:15];

    NSInteger y = (_layoutWithStationNameOnly || _isFirst || _isLast) ? 26 : 15;
    [self.stationLabel sizeToFit];
    [self.warningLabel sizeToFit];
    
    [self.platformLabel setGravityTop:y];

    [self.arrivalLabel sizeToFit];
    [self.arrivalLabel setGravityLeft:31];
    [self.arrivalLabel setGravityTop:y];
    [self.departureLabel sizeToFit];
    [self.departureLabel setGravityLeft:self.arrivalLabel.frame.origin.x];
    if(self.arrivalLabel.text.length > 0){
        [self.departureLabel setBelow:self.arrivalLabel withPadding:6];
    } else {
        //move departure up
        [self.departureLabel setGravityTop:y];
    }
    [self.arrivalNewLabel sizeToFit];
    [self.departureNewLabel sizeToFit];

    [self.arrivalNewLabel setRight:self.arrivalLabel withPadding:7];
    [self.departureNewLabel setRight:self.departureLabel withPadding:7];
    [self.arrivalNewLabel setGravityTop:self.arrivalLabel.frame.origin.y];
    [self.departureNewLabel setGravityTop:self.departureLabel.frame.origin.y];

    NSInteger spaceRight = (self.frame.size.width-self.platformLabel.frame.origin.x)+10;
    NSInteger x = MAX(MAX(CGRectGetMaxX(self.arrivalNewLabel.frame),CGRectGetMaxX(self.departureNewLabel.frame))+8,134);
    if(_layoutWithStationNameOnly){
        x = 45;
    }
    self.stationLabel.frame = CGRectMake(x, y, self.frame.size.width-x-spaceRight, self.stationLabel.frame.size.height);
    [self.warningImage setGravityLeft:x-5];
    [self.warningImage setBelow:self.stationLabel withPadding:1];
    if(self.warningImage.hidden){
        [self.warningLabel setGravityLeft:x+1];
    } else {
        [self.warningLabel setRight:self.warningImage withPadding:2];
    }
    [self.warningLabel setBelow:self.stationLabel withPadding:7];
    [self.warningLabel setWidth:self.frame.size.width-self.warningLabel.frame.origin.x-spaceRight];

    if(!_isFirst && !_isLast){
        [self.journeyLineBackground setGravityTop:0];
        [self.journeyLineBackground setHeight:self.frame.size.height];
    } else if(_isFirst){
        //journey line starts at dot position
        [self.journeyLineBackground setGravityTop:self.journeyDot.frame.origin.y];
        [self.journeyLineBackground setHeight:self.frame.size.height-self.journeyLineBackground.frame.origin.y];
    } else if(_isLast){
        //journey line ends at dot position
        [self.journeyLineBackground setGravityTop:0];
        [self.journeyLineBackground setHeight:self.journeyDot.frame.origin.y];
    }
    
    //calculate active journey line
    self.journeyLineActive.frame = self.journeyLineBackground.frame;
    if(self.layoutWithStationNameOnly || self.stop.journeyProgress == -1){
        self.journeyLineActive.hidden = true;
    } else {
        self.journeyLineActive.hidden = false;
        if(self.stop.journeyProgress < 100){
            //value from [0..100[
            if(!_isFirst && !_isLast){
                if(self.stop.journeyProgress <= 50){
                    [self.journeyLineActive setHeight: self.journeyLineActive.frame.size.height*0.5 + (self.journeyLineActive.frame.size.height/2)*(self.stop.journeyProgress/50.0)];
                } else {
                    NSInteger p = self.stop.journeyProgress -50;
                    [self.journeyLineActive setHeight:(self.journeyLineActive.frame.size.height/2)*(p/50.0)];
                }
            } else if(_isFirst){
                if(self.stop.journeyProgress <= 50){
                    [self.journeyLineActive setHeight:self.journeyLineActive.frame.size.height*(self.stop.journeyProgress/50.0)];
                } else {
                    self.journeyLineActive.hidden = true;
                }
            } else if(_isLast){
                NSInteger p = self.stop.journeyProgress -50;
                [self.journeyLineActive setHeight:self.journeyLineActive.frame.size.height*(p/50.0)];
            }
        }
    }
    self.bottomLine.frame = CGRectMake(0, self.frame.size.height-2, self.frame.size.width, 2);
}

-(void)prepareForReuse{
    [super prepareForReuse];
    self.stationLabel.text = @"";
    self.platformLabel.text = @"";
    self.arrivalLabel.text = @"";
    self.departureLabel.text = @"";
    self.arrivalNewLabel.text = @"";
    self.departureNewLabel.text = @"";
    self.warningImage.hidden = YES;
    self.warningLabel.text = @"";
}

-(NSString *)accessibilityLabel{
    NSString* warnings = @"";
    if(self.warningLabel.text.length > 0){
        warnings = [@"Hinweis: " stringByAppendingString:self.warningLabel.text];
    }
    NSString* arrivalDelta = @"";
    NSString* departureDelta = @"";
    NSInteger p = self.stop.journeyProgress;
    if(self.arrivalNewLabel.text.length > 0 && ![self.arrivalNewLabel.text isEqualToString:self.arrivalLabel.text]){
        arrivalDelta = [NSString stringWithFormat:@", heute %@ %@ Uhr",((p == -1 || (p > 50 && p < 100)) ? @"voraussichtlich" : @""),self.arrivalNewLabel.text];
    }
    if(self.departureNewLabel.text.length > 0 && ![self.departureNewLabel.text isEqualToString:self.departureLabel.text]){
        departureDelta = [NSString stringWithFormat:@", heute %@ %@ Uhr",((p == 100 || (p > 0 && p <= 50)) ? @"" : @"voraussichtlich"),self.departureNewLabel.text];
    }

    NSString* arrivalText = @"";
    if(self.arrivalLabel.text.length > 0){
        arrivalText = [NSString stringWithFormat:@"Ankunft %@ Uhr %@",self.arrivalLabel.text,
                       arrivalDelta];
    }
    NSString* departureText = @"";
    if(self.departureLabel.text.length > 0){
        departureText = [NSString stringWithFormat:@"Abfahrt %@ Uhr %@",self.departureLabel.text,
                               departureDelta];
    }

    return [NSString stringWithFormat:@"%@, %@; %@; %@; %@",
            self.stationLabel.text,
            (self.platformLabel.text.length > 0 ? self.platformLabel.accessibilityLabel : @""),
            warnings,
            arrivalText,
            departureText
            ];
}

-(void)configureDeltaStringPlaned:(NSDate*)planed actual:(NSDate*)actual label:(UILabel*)label{
    label.textColor = UIColor.db_76c030;
    NSInteger delta = (actual.timeIntervalSinceReferenceDate-planed.timeIntervalSinceReferenceDate)/60;
    //delta = 100;
    if(delta != 0){
        if(delta >= 5){
            label.textColor = UIColor.db_mainColor;
        }
    }
}

-(NSString*)timeStringForDate:(NSDate*)date{
    if(!date){
        return @"";
    }
    NSCalendar *calendar  = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour| NSCalendarUnitMinute) fromDate:date];
    NSInteger hour = [components hour];
    NSInteger minutes = [components minute];
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)hour, (long)minutes];
}

-(void)setStop:(MBTrainJourneyStop *)stop isFirst:(BOOL)isFirst isLast:(BOOL)isLast isCurrentStation:(BOOL)isCurrentStation{
    self.stop = stop;
    self.layoutWithStationNameOnly = false;
    self.stationLabel.text = stop.stationName;
//    self.stationLabel.text = @"Lorem impsum lorem ipsum lorem ipsum";
    
    self.arrivalLabel.text = [self timeStringForDate:stop.arrivalTimeSchedule];
    self.departureLabel.text = [self timeStringForDate:stop.departureTimeSchedule];

    self.arrivalNewLabel.text = [self timeStringForDate:stop.arrivalTime];
    self.departureNewLabel.text = [self timeStringForDate:stop.departureTime];

    [self configureDeltaStringPlaned:stop.arrivalTimeSchedule actual:stop.arrivalTime label:self.arrivalNewLabel];
    [self configureDeltaStringPlaned:stop.departureTimeSchedule actual:stop.departureTime label:self.departureNewLabel];

    if(stop.platform.length > 0){
        self.platformLabel.text = [NSString stringWithFormat:@"Gl. %@",stop.platform];
        self.platformLabel.accessibilityLabel = [NSString stringWithFormat:@"Gleis %@",stop.platform];
    } else {
        self.platformLabel.text = @"";
        self.platformLabel.accessibilityLabel = @"";
    }
    if(stop.platformChange){
        self.platformLabel.textColor = UIColor.db_mainColor;
    } else {
        self.platformLabel.textColor = UIColor.db_787d87;
    }
    [self.platformLabel sizeToFit];
    
    if(stop.additional){
        self.warningImage.hidden = true;
        self.warningLabel.text = @"Zusätzlicher Halt";
        self.warningLabel.textColor = UIColor.db_333333;
        self.warningImage.image = [UIImage db_imageNamed:@"app_warndreieck_dunkelgrau"];
    } else if(stop.platformChange){
        self.warningImage.hidden = false;
        self.warningLabel.text = @"Gleisänderung";
        self.warningLabel.textColor = UIColor.db_mainColor;
        self.warningImage.image = [UIImage db_imageNamed:@"app_warndreieck"];
    }

    [self setupForIsFirst:isFirst isLast:isLast isCurrentStation:isCurrentStation];
    //change journey colors depending on progress
    if(stop.journeyProgress == 100 || (stop.journeyProgress >= 0 && stop.journeyProgress <= 50)){
        self.journeyDot.backgroundColor = self.journeyColorCurrentOrPast;
    } else {
        self.journeyDot.backgroundColor = self.journeyColorFuture;
    }

    
    [self setNeedsLayout];
}

-(void)setStopWithString:(NSString *)stationTitle isFirst:(BOOL)isFirst isLast:(BOOL)isLast isCurrentStation:(BOOL)isCurrentStation{
    self.layoutWithStationNameOnly = true;
    self.stationLabel.text = stationTitle;
    [self setupForIsFirst:isFirst isLast:isLast isCurrentStation:isCurrentStation];
    [self setNeedsLayout];
}

-(void)setupForIsFirst:(BOOL)isFirst isLast:(BOOL)isLast isCurrentStation:(BOOL)isCurrentStation{
    self.isFirst = isFirst;
    self.isLast = isLast;
    self.journeyLineBackground.hidden = isFirst && isLast;
    UIFont* font = UIFont.db_RegularSixteen;
    if(isCurrentStation){
        font = UIFont.db_BoldSixteen;
        self.journeyDot.backgroundColor = self.journeyColorCurrentStation;
    } else {
        self.journeyDot.backgroundColor = self.journeyColorFuture;
    }
    self.stationLabel.font = font;
    self.arrivalLabel.font = font;
    self.departureLabel.font = font;
    self.arrivalNewLabel.font = font;
    self.departureNewLabel.font = font;
    self.platformLabel.font = UIFont.db_RegularFourteen;
    
}

@end
