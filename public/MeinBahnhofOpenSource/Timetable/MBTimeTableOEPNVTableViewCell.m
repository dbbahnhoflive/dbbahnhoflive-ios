// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBTimeTableOEPNVTableViewCell.h"
#import "MBStationListView.h"
#import "HafasStopLocation.h"
#import "MBUIHelper.h"

@interface MBTimeTableOEPNVTableViewCell()
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *lineLabel;
@property (nonatomic, strong) UILabel *destLabel;
@property (nonatomic, strong) UILabel *expectedTimeLabel;

@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) MBStationListView *viaListView;

@property (nonatomic,strong) UIActivityIndicatorView* act;

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
    self.topView.layer.shadowOffset = CGSizeMake(1.0, 2.0);
    self.topView.layer.shadowColor = [[UIColor db_dadada] CGColor];
    self.topView.layer.shadowRadius = 1.5;
    self.topView.layer.shadowOpacity = 1.0;
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
    self.expectedTimeLabel.font = [UIFont db_RegularFourteen];;

    [self.topView addSubview:self.timeLabel];
    [self.topView addSubview:self.lineLabel];
    [self.topView addSubview:self.destLabel];
    [self.topView addSubview:self.expectedTimeLabel];
    
    [self.contentView addSubview:self.topView];

    self.bottomView = [UIView new];
    self.bottomView.hidden = YES;
    self.bottomView.layer.shadowOffset = self.topView.layer.shadowOffset;
    self.bottomView.layer.shadowColor = self.topView.layer.shadowColor;
    self.bottomView.layer.shadowRadius = self.topView.layer.shadowRadius;
    self.bottomView.layer.shadowOpacity = self.topView.layer.shadowOpacity;

    [self.contentView addSubview:self.bottomView];
    
    self.act = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.act stopAnimating];
    [self.bottomView addSubview:self.act];

    self.viaListView = [[MBStationListView alloc] initWithFrame:CGRectZero];;
    [self.bottomView addSubview:self.viaListView];
    
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.topView.frame = CGRectMake(8, 8, self.frame.size.width-2*8, 80);
    self.timeLabel.frame = CGRectMake(16, 16, 100, 20);
    self.expectedTimeLabel.frame = CGRectMake(16, CGRectGetMaxY(self.timeLabel.frame)+8, 100, 20);
    self.destLabel.frame = CGRectMake(70, 16, self.frame.size.width-70-3*8, 20);
    self.lineLabel.frame = CGRectMake(self.destLabel.frame.origin.x, self.expectedTimeLabel.frame.origin.y, self.frame.size.width-self.destLabel.frame.origin.x-3*8, 20);
    
    self.bottomView.hidden = !_expanded;
    [self.bottomView setFrame:CGRectMake(8, self.topView.frame.origin.y+self.topView.frame.size.height+1.0, self.frame.size.width-2*8, self.viaListView.frame.size.height)];
    
    [self.act centerViewInSuperView];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    _expanded = NO;
}

- (void)setHafas:(HafasDeparture *)hafas {
    _hafas = hafas;
    // ignore seconds in time
    self.timeLabel.text = [hafas.time substringToIndex:5];
    [self.timeLabel sizeToFit];
    self.lineLabel.text = hafas.name;
    [self.lineLabel sizeToFit];
    self.destLabel.text = hafas.direction;
//    [self.destLabel sizeToFit];//NO, this leads to autolayout failure!
    self.expectedTimeLabel.text = [hafas expectedDeparture];
    if([hafas delayInMinutes] >= 5){
        self.expectedTimeLabel.textColor = [UIColor db_mainColor];
    } else {
        self.expectedTimeLabel.textColor = [UIColor db_76c030];
    }
//    [self.expectedTimeLabel sizeToFit];
    //[self.delayLabel setWidth:40];//needs to be fixed for layout
    if(hafas.stopLocationTitles){
        [self.act stopAnimating];
        self.viaListView.hidden = NO;
        self.viaListView.stations = hafas.stopLocationTitles;
    } else {
        [self.act startAnimating];
        self.viaListView.hidden = YES;
        self.viaListView.stations = @[];
    }
    [self.viaListView setFrame:CGRectMake(0, 0, self.bottomView.frame.size.width, 92.0)];
}

- (NSString *)accessibilityLabel
{
    
    NSString *viaStations = [self.viaListView.stations componentsJoinedByString:@", "];
    NSString* line = self.lineLabel.text;
    line = [line stringByReplacingOccurrencesOfString:@"STR" withString:VOICEOVER_FOR_STR];

    return [NSString stringWithFormat:@"%@ nach %@. %@ Uhr, %@, %@",
            line,
            self.destLabel.text,
            self.timeLabel.text,
            ([self.timeLabel.text isEqualToString:self.expectedTimeLabel.text] ? @"" : [NSString stringWithFormat:@"Erwartet %@",self.expectedTimeLabel.text]),
            (viaStations.length > 0 ? [NSString stringWithFormat:@"über %@",viaStations] : @"")
            ];
}


@end
