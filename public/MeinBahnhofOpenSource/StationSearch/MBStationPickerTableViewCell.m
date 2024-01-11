// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBStationPickerTableViewCell.h"
#import <MapKit/MapKit.h>
#import "MBFavoriteStationManager.h"
#import "HafasDeparture.h"
#import "HafasRequestManager.h"
#import "HafasTimetable.h"
#import "TimetableManager.h"
#import "MBTimeTableViewCell.h"
#import "MBUIHelper.h"
#import "MBFavoriteButton.h"
#import "MBVoiceOverHelper.h"

@interface MBStationPickerTableViewCell ()

@property(nonatomic,strong) UIView* whiteBackground;
@property(nonatomic,strong) UIView* departureContainer;
@property(nonatomic,strong) UIImageView* stationTypeImageView;
@property(nonatomic,strong) MBFavoriteButton* favButton;
@property (nonatomic, strong) UILabel *stationTitleLabel;

@property (nonatomic,strong) UIImageView* stationDistanceIcon;
@property (nonatomic, strong) UILabel *stationDistanceLabel;
@property(nonatomic,strong) NSMutableArray<NSDictionary*>* abfahrtLabels;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UILabel* infoLabelDepartureNotAvailable;

@property (nonatomic, strong) TimetableManager *localTimeTableManager;
@property (nonatomic, strong) HafasRequestManager *localHafasManager;


@end

@implementation MBStationPickerTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self setup];
}
-(instancetype)init{
    self = [super init];
    [self setup];
    return self;
}
-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    [self setup];
    return self;
}
-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    [self setup];
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setup{
    self.isAccessibilityElement = NO;
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = YES;
        
    self.whiteBackground = [[UIView alloc] initWithFrame:CGRectZero];
    self.whiteBackground.backgroundColor = [UIColor whiteColor];
    [self.contentView addSubview:self.whiteBackground];
    
    self.departureContainer = [[UIView alloc] initWithFrame:CGRectZero];
    self.departureContainer.backgroundColor = [UIColor dbColorWithRGB:0xF0F3F5];
    [self.contentView addSubview:self.departureContainer];
    self.departureContainer.hidden = YES;
    self.departureContainer.isAccessibilityElement = NO;
    
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(departureTapped:)];
    [self.departureContainer addGestureRecognizer:tapGesture];
    
    CGFloat originTop = 16.0;
    CGFloat originLeft = 16.0;
    self.abfahrtLabels = [NSMutableArray new];
    for (int i = 0; i < 3; i++) {
        //NOTE: the labels are layouted later, origins here are not used!
        NSMutableDictionary *abfahrtDict = [NSMutableDictionary new];
        UILabel *timeLabel = [[UILabel alloc] init];
        timeLabel.font = [UIFont db_BoldSixteen];
        timeLabel.textColor = [UIColor db_333333];
        timeLabel.text = @"PHOL";
        timeLabel.hidden = YES;
        [timeLabel sizeToFit];
        [self.departureContainer addSubview:timeLabel];
        [abfahrtDict setObject:timeLabel forKey:@"timeLabel"];
        [timeLabel setGravityTop:originTop];
        [timeLabel setGravityLeft:originLeft];
        
        UILabel *expTimeLabel = [[UILabel alloc] init];
        expTimeLabel.font = [UIFont db_RegularFourteen];
        expTimeLabel.textColor = [UIColor db_333333];
        expTimeLabel.text = @"PHOL";
        expTimeLabel.hidden = YES;
        [expTimeLabel sizeToFit];
        [self.departureContainer addSubview:expTimeLabel];
        [abfahrtDict setObject:expTimeLabel forKey:@"expectedTimeLabel"];
        [expTimeLabel setBelow:timeLabel withPadding:8.0];
        [expTimeLabel setGravityLeft:originLeft];
        
        UILabel *destLabel = [UILabel new];
        destLabel.font = [UIFont db_RegularSixteen];
        destLabel.textColor = [UIColor db_333333];
        destLabel.text = @"PLACEHOLDER";
        [destLabel sizeToFit];
        destLabel.hidden = YES;
        [self.departureContainer addSubview:destLabel];
        [abfahrtDict setObject:destLabel forKey:@"destLabel"];
        [destLabel setGravityTop:originTop];
        [destLabel setRight:timeLabel withPadding:30.0];
        UILabel *lineLabel = [UILabel new];
        lineLabel.font = [UIFont db_RegularFourteen];
        lineLabel.textColor = [UIColor db_787d87];
        lineLabel.text = @"Placeholder";
        [lineLabel sizeToFit];
        lineLabel.hidden = YES;
        [self.departureContainer addSubview:lineLabel];
        [abfahrtDict setObject:lineLabel forKey:@"lineLabel"];
        [lineLabel setBelow:timeLabel withPadding:8.0];
        [lineLabel setGravityLeft:destLabel.frame.origin.x-2];
        
        UILabel *platformLabel = [UILabel new];
        platformLabel.font = [UIFont db_RegularFourteen];
        platformLabel.textColor = [UIColor db_787d87];
        platformLabel.text = @"Placeholder";
        platformLabel.textAlignment = NSTextAlignmentRight;
        [platformLabel sizeToFit];
        platformLabel.hidden = YES;
        [self.departureContainer addSubview:platformLabel];
        [abfahrtDict setObject:platformLabel forKey:@"platformLabel"];
        [platformLabel setBelow:timeLabel withPadding:8.0];
        [platformLabel setGravityRight:originLeft];
        
        UIImageView* warnIcon = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_warndreieck"]];
        warnIcon.hidden = YES;
        [self.departureContainer addSubview:warnIcon];
        [abfahrtDict setObject:warnIcon forKey:@"warnIcon"];
        
        [self.abfahrtLabels addObject:abfahrtDict];
        
        timeLabel.isAccessibilityElement = NO;
        lineLabel.isAccessibilityElement = NO;
        destLabel.isAccessibilityElement = NO;
        warnIcon.isAccessibilityElement = NO;
        platformLabel.isAccessibilityElement = NO;
        expTimeLabel.isAccessibilityElement = NO;
        UILabel* accessibilityView = [[UILabel alloc] initWithFrame:CGRectMake(0, originTop, self.frame.size.width, 45)];
        accessibilityView.autoresizingMask = UIViewAutoresizingNone;
        accessibilityView.hidden = YES;
        accessibilityView.isAccessibilityElement = YES;
        [self.departureContainer addSubview:accessibilityView];
        //this label never has a text, only an acc-label
        [abfahrtDict setObject:accessibilityView forKey:@"accLabel"];
        
        originTop += (timeLabel.frame.size.height + 8.0 + lineLabel.frame.size.height + 16.0);
    }
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.departureContainer addSubview:self.spinner];
    [self.spinner startAnimating];
    
    self.stationTypeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
    self.stationTypeImageView.contentMode = UIViewContentModeScaleAspectFit;
    //self.stationTypeImageView.backgroundColor = [UIColor grayColor];
    [self.contentView addSubview:self.stationTypeImageView];
    
    
    self.stationTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.stationTitleLabel.accessibilityIdentifier = @"stationTitleLabel";
    self.stationTitleLabel.text = @"";
    [self.stationTitleLabel setFont:[UIFont db_RegularSeventeen]];
    //self.stationTitleLabel.font = [UIFontMetrics.defaultMetrics scaledFontForFont:[UIFont db_RegularSeventeen]];
    [self.stationTitleLabel setTextColor:[UIColor db_333333]];
    self.stationTitleLabel.accessibilityTraits = UIAccessibilityTraitStaticText|UIAccessibilityTraitButton;
    
    self.favButton = [MBFavoriteButton new];
    [self.favButton addTarget:self action:@selector(favBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.favButton];

    [self.contentView addSubview:self.stationTitleLabel];
    
    self.stationDistanceIcon = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_fussweg"]];
    [self.contentView addSubview:self.stationDistanceIcon];
    
    self.stationDistanceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.stationDistanceLabel.text = @"";
    [self.stationDistanceLabel setFont:[UIFont db_RegularSeventeen]];
    [self.stationDistanceLabel setTextColor:[UIColor db_333333]];
    self.stationDistanceLabel.accessibilityTraits = UIAccessibilityTraitStaticText;
    [self.contentView addSubview:self.stationDistanceLabel];

    self.stationDistanceIcon.hidden = YES;
    self.stationDistanceLabel.hidden = YES;
    
    
    
    UILongPressGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self addGestureRecognizer:longPress];
}

-(void)longPress:(UILongPressGestureRecognizer*)sender{
    if(sender.state == UIGestureRecognizerStateBegan){
        NSLog(@"long press in %@",self);
        [self.delegate stationPickerCellDidLongPress:self];
    }
}
-(void)departureTapped:(UITapGestureRecognizer*)sender{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        [self.delegate stationPickerCellDidTapDeparture:self];
    }
}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    self.whiteBackground.frame = CGRectMake(0, 0, self.size.width, self.size.height-2);
    [self.stationTypeImageView setGravityTop:14];
    [self.stationTypeImageView setGravityLeft:14];
    
    self.stationTitleLabel.frame = CGRectMake(44, 0, self.frame.size.width-44-50, 14*2+20);

    [self.stationDistanceIcon setGravityLeft:15];
    [self.stationDistanceIcon setGravityBottom:15];
    [self.stationDistanceLabel setRight:self.stationDistanceIcon withPadding:15];
    [self.stationDistanceLabel setGravityBottom:15];
    
    [self.favButton setGravityTop:4];
    [self.favButton setGravityRight:6-3];
    
    self.departureContainer.frame = CGRectMake(0, 50, self.frame.size.width, MBStationPickerTableViewCell.departureContainerHeight);
    
    [self.spinner centerViewVerticalInSuperView];
    [self.spinner centerViewHorizontalInSuperView];

}

+(NSInteger)departureContainerHeight{
    return ISIPAD ? 210 : 194;
}

-(void)favBtnPressed:(UIButton*)btn{
    if(!self.station)
        return;
    if([[MBFavoriteStationManager client] isFavorite:self.station]){
        [[MBFavoriteStationManager client] removeStation:self.station];
        [self updateFavButtonStatus:false];
        [self.delegate stationPickerCell:self changedFavStatus:NO];
    } else {
        [[MBFavoriteStationManager client] addStation:self.station];
        [self updateFavButtonStatus:true];
        [self.delegate stationPickerCell:self changedFavStatus:YES];
    }
}

-(void)updateFavButtonStatus:(BOOL)isFavorite{
    if(isFavorite){
        self.favButton.isFavorite = true;
        self.favButton.accessibilityLabel = @"Favorit: aktiv";
        self.favButton.accessibilityHint = @"Zum Entfernen aus Favoriten doppeltippen";
    } else {
        self.favButton.isFavorite = false;
        self.favButton.accessibilityLabel = @"Favorit: inaktiv";
        self.favButton.accessibilityHint = @"Zum Hinzufügen zu Favoriten doppeltippen";
    }
}

-(void)setStation:(MBStationFromSearch*)station{
    _station = station;
    self.stationTitleLabel.text = station.title;
    if(station.isOPNVStation){
        self.stationTitleLabel.accessibilityLabel = [NSString stringWithFormat:@"%@, Ö P N V Haltestelle",station.title];
    } else {
        self.stationTitleLabel.accessibilityLabel = station.title;
    }
    NSNumber* distanceKM = station.distanceInKm;
    MKDistanceFormatter* df = [[MKDistanceFormatter alloc] init];
    df.locale = [NSLocale currentLocale];
    df.unitStyle = MKDistanceFormatterUnitStyleAbbreviated;
    self.stationDistanceLabel.text = [df stringFromDistance:distanceKM.doubleValue*1000];
    [self.stationDistanceLabel sizeToFit];
    BOOL isOEPNV = station.isOPNVStation;
    if([[MBFavoriteStationManager client] isFavorite:station]){
        [self updateFavButtonStatus:true];
    } else {
        [self updateFavButtonStatus:false];
    }
    self.stationTypeImage = [UIImage db_imageNamed:(isOEPNV ? @"app_haltestelle" : @"DBMapPin")];
    [self setNeedsLayout];
}

-(void)setShowDetails:(BOOL)showDetails{
    _showDetails = showDetails;
    self.departureContainer.hidden = !showDetails;
    if(showDetails){
        [self updateDepartures];
    } else {
        [self.spinner stopAnimating];
    }
}
-(void)setShowDistance:(BOOL)showDistance{
    _showDistance = showDistance;
    self.stationDistanceLabel.hidden = !showDistance;
    self.stationDistanceIcon.hidden = self.stationDistanceLabel.hidden;
}

-(void)setStationTypeImage:(UIImage *)stationTypeImage{
    self.stationTypeImageView.image = stationTypeImage;
}


-(void)refreshTimetableForStation{
    NSArray *eva_ids = self.station.eva_ids;
    if(nil == eva_ids || eva_ids.count == 0){
        [self.spinner stopAnimating];
        return;
    }
    [self.spinner startAnimating];
    if (nil == self.localTimeTableManager) {
        self.localTimeTableManager = [[TimetableManager alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveTimetableUpdate:)
                                                     name:NOTIF_TIMETABLE_UPDATE
                                                   object:nil];
    }
    [self.localTimeTableManager reloadTimetableWithEvaIds:eva_ids];
}

-(void)updateDepartures{
    NSArray *eva_ids = self.station.eva_ids;
    NSLog(@"updateDepartures: %@",eva_ids);
    if (!self.station.isOPNVStation) {
        //DB-Station, may need eva update
        if([MBStationFromSearch needToUpdateEvaIdsForStation:self.station]){
            [self.station updateEvaIds:^(BOOL success) {
                [self refreshTimetableForStation];
            }];
        } else {
            [self refreshTimetableForStation];
        }
    } else if (eva_ids.count > 0) {
        [self.spinner startAnimating];
        // may be Hafas
        if (nil == self.localHafasManager) {
            self.localHafasManager = [[HafasRequestManager alloc] init];
        }
        //NSLog(@"load departures for %@ in %@ with %@",hafas_id,self,self.localHafasManager);
        //NSLog(@"DEPARTURE, load for map flyout");
        
        NSString* idString = eva_ids.firstObject;
        HafasTimetable* timetable = [[HafasTimetable alloc] init];
        timetable.includeLongDistanceTrains = false;
        [self.localHafasManager loadDeparturesForStopId:idString timetable:timetable withCompletion:^(HafasTimetable *timetable) {
            [self setupViewsForHafas:timetable];
        }];
    } else {
        [self.spinner stopAnimating];
    }
}


- (void)setupViewsForHafas:(HafasTimetable*)timetable {
    [self.spinner stopAnimating];

    NSMutableArray<HafasDeparture*> *departures = [timetable.departureStops mutableCopy];
    // show only some
    NSInteger maxElements = self.abfahrtLabels.count;
    if (departures.count > maxElements) {
        NSRange range = NSMakeRange(maxElements, departures.count - maxElements);
        [departures removeObjectsInRange:range];
    }
    [self.infoLabelDepartureNotAvailable removeFromSuperview];
    self.infoLabelDepartureNotAvailable = nil;
    if (departures.count == 0) {
        // show error info label
        UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        infoLabel.numberOfLines = 0;
        infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
        NSDictionary *abfahrtDict = [self.abfahrtLabels objectAtIndex:0];
        UILabel *timeLabel = [abfahrtDict objectForKey:@"timeLabel"];
        CGRect infoFrame = timeLabel.frame;
        infoFrame.size.width = self.frame.size.width - 32.0;
        infoLabel.frame = infoFrame;
        infoLabel.text = @"Für diese Haltestelle liegen zur Zeit keine Informationen vor.";
        [self.departureContainer addSubview:infoLabel];
        [infoLabel sizeToFit];
        self.infoLabelDepartureNotAvailable = infoLabel;
        
        for(NSDictionary* abfahrtDict in self.abfahrtLabels){
            UILabel *timeLabel = [abfahrtDict objectForKey:@"timeLabel"];
            UILabel *expectedTimeLabel = [abfahrtDict objectForKey:@"expectedTimeLabel"];
            UILabel *lineLabel = [abfahrtDict objectForKey:@"lineLabel"];
            UILabel *platformLabel = [abfahrtDict objectForKey:@"platformLabel"];
            UILabel *destLabel = [abfahrtDict objectForKey:@"destLabel"];
            UILabel *accLabel = [abfahrtDict objectForKey:@"accLabel"];
            UIImageView* warnIcon = [abfahrtDict objectForKey:@"warnIcon"];
            timeLabel.text = @"";
            platformLabel.text = @"";
            expectedTimeLabel.text = @"";
            lineLabel.text = @"";
            destLabel.text = @"";
            accLabel.text = @"";
            warnIcon.hidden = YES;
        }
    }
    for (HafasDeparture *departure in departures) {
        NSDictionary *abfahrtDict = [self.abfahrtLabels objectAtIndex:[departures indexOfObject:departure]];
        UILabel *timeLabel = [abfahrtDict objectForKey:@"timeLabel"];
        // substring gets rid of seconds
        timeLabel.text = [[departure valueForKey:@"time"] substringToIndex:5];
        [timeLabel sizeToFit];
        timeLabel.hidden = NO;
        UILabel *expectedTimeLabel = [abfahrtDict objectForKey:@"expectedTimeLabel"];
        // substring gets rid of seconds
        expectedTimeLabel.text = [departure.expectedDeparture substringToIndex:5];
        if([departure delayInMinutes] >= 5){
            expectedTimeLabel.textColor = [UIColor db_mainColor];
        } else {
            expectedTimeLabel.textColor = [UIColor db_green];
        }
        [expectedTimeLabel sizeToFit];
        expectedTimeLabel.hidden = NO;
        [expectedTimeLabel setBelow:timeLabel withPadding:8.0];
        UILabel *lineLabel = [abfahrtDict objectForKey:@"lineLabel"];
        lineLabel.text = [departure valueForKey:@"name"];
        [lineLabel sizeToFit];
        [lineLabel setBelow:timeLabel withPadding:8.0];
        lineLabel.hidden = NO;
        UILabel *destLabel = [abfahrtDict objectForKey:@"destLabel"];
        destLabel.text = [departure valueForKey:@"direction"];
        destLabel.numberOfLines = 1;
        destLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [destLabel sizeToFit];
        [destLabel setRight:timeLabel withPadding:30.0];
        CGFloat labelWidth = self.frame.size.width - timeLabel.frame.origin.x - timeLabel.frame.size.width - 30.0 - timeLabel.frame.origin.x;
        destLabel.width = labelWidth;
        destLabel.hidden = NO;
        UILabel *platformLabel = [abfahrtDict objectForKey:@"platformLabel"];
        platformLabel.hidden = YES;
        
        UIImageView* warnIcon = [abfahrtDict objectForKey:@"warnIcon"];
        warnIcon.hidden = YES;//could add a warnicon here...
        
        NSString* line = lineLabel.text;
        line = [line stringByReplacingOccurrencesOfString:@"STR" withString:VOICEOVER_FOR_STR];
        
        UILabel *accLabel = [abfahrtDict objectForKey:@"accLabel"];
        accLabel.accessibilityLabel = [NSString stringWithFormat:@"%@ nach %@. %@, %@",
                                       line,
                                       destLabel.text,
                                       [MBVoiceOverHelper timeForVoiceOver:timeLabel.text],
                                       ([timeLabel.text isEqualToString:expectedTimeLabel.text]? @"." : [NSString stringWithFormat:@"erwartet %@",[MBVoiceOverHelper timeForVoiceOver:expectedTimeLabel.text]])];
        accLabel.hidden = NO;
    }
}

-(void)setupViewsForDBStation{
    [self.spinner stopAnimating];

    NSArray *allStops = [[self.localTimeTableManager timetable] departureStops];
    if(allStops.count > 0){
        self.infoLabelDepartureNotAvailable.hidden = YES;
    } else {
        if(!self.infoLabelDepartureNotAvailable){
            // show error info label
            UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            infoLabel.numberOfLines = 0;
            infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
            NSDictionary *abfahrtDict = [self.abfahrtLabels objectAtIndex:0];
            UILabel *timeLabel = [abfahrtDict objectForKey:@"timeLabel"];
            CGRect infoFrame = timeLabel.frame;
            infoFrame.size.width = self.frame.size.width - 32.0;
            infoLabel.frame = infoFrame;
            infoLabel.text = @"Daten nicht verfügbar.";
            [self.departureContainer addSubview:infoLabel];
            [infoLabel sizeToFit];
            self.infoLabelDepartureNotAvailable = infoLabel;
        }
        self.infoLabelDepartureNotAvailable.hidden = NO;
    }
    
    // show only some
    NSInteger maxElements = self.abfahrtLabels.count;
    NSUInteger index = 0;
    for (Stop *stop in allStops) {
        Event *event = [stop eventForDeparture:YES];
        if (maxElements > 0) {
            maxElements -= 1;
            // fill in data for "maxElements" stops
            NSDictionary *abfahrtDict = [self.abfahrtLabels objectAtIndex:index];
            UILabel *timeLabel = [abfahrtDict objectForKey:@"timeLabel"];
            timeLabel.text = stop.departureEvent.formattedTime;
            [timeLabel sizeToFit];
            timeLabel.hidden = NO;
            UILabel *expectedTimeLabel = [abfahrtDict objectForKey:@"expectedTimeLabel"];
            expectedTimeLabel.text = stop.departureEvent.formattedExpectedTime;
            [expectedTimeLabel sizeToFit];
            expectedTimeLabel.hidden = NO;
            if(stop.departureEvent.roundedDelay >= 5){
                expectedTimeLabel.textColor = [UIColor db_mainColor];
            } else {
                expectedTimeLabel.textColor = [UIColor db_green];
            }
            [expectedTimeLabel setBelow:timeLabel withPadding:8.0];
            expectedTimeLabel.hidden = event.eventIsCanceled;
            UILabel *platformLabel = [abfahrtDict objectForKey:@"platformLabel"];
            platformLabel.text = [NSString stringWithFormat:@"Gl. %@",event.actualPlatform];
            [platformLabel sizeToFit];
            [platformLabel setGravityRight:timeLabel.frame.origin.x];
            platformLabel.hidden = NO;
            platformLabel.textColor = [UIColor db_787d87];
            if(stop.departureEvent.changedPlatform){
                platformLabel.textColor = [UIColor db_mainColor];
            }
            
            UILabel *lineLabel = [abfahrtDict objectForKey:@"lineLabel"];
            NSString* trainCat = [stop formattedTransportType:event.lineIdentifier];
            lineLabel.text = trainCat;
            [lineLabel sizeToFit];
            [lineLabel setBelow:timeLabel withPadding:8.0];
            lineLabel.size = [lineLabel sizeThatFits:CGSizeMake(self.sizeWidth-16-lineLabel.frame.origin.x, lineLabel.sizeHeight)];
            
            lineLabel.hidden = NO;
            UILabel *destLabel = [abfahrtDict objectForKey:@"destLabel"];
            destLabel.numberOfLines = 1;
            destLabel.text = event.actualStation;
            [destLabel sizeToFit];
            [destLabel setRight:timeLabel withPadding:30.0];
            CGFloat labelWidth = self.frame.size.width - timeLabel.frame.origin.x - timeLabel.frame.size.width - 30.0 - timeLabel.frame.origin.x;
            destLabel.width = labelWidth;
            destLabel.hidden = NO;
            
            UIImageView* warnIcon = [abfahrtDict objectForKey:@"warnIcon"];
            warnIcon.hidden = event.composedIrisMessage.length == 0;
            if(!warnIcon.hidden){
                //what icon do we need?
                if(event.hasOnlySplitMessage){
                    warnIcon.image = [UIImage db_imageNamed:@"app_warndreieck_dunkelgrau"];
                } else {
                    warnIcon.image = [UIImage db_imageNamed:@"app_warndreieck"];
                    if(event.shouldShowRedWarnIcon){
                        warnIcon.hidden = NO;
                    } else {
                        warnIcon.hidden = YES;
                    }
                }
                [warnIcon setRight:lineLabel withPadding:8];
                [warnIcon setBelow:destLabel withPadding:6];
            }
            
            index += 1;
            //empty label with voiceover text
            UILabel *accLabel = [abfahrtDict objectForKey:@"accLabel"];
            accLabel.accessibilityLabel = [event voiceOverStringWithStation:nil];
            [accLabel setGravityLeft:timeLabel.frame.origin.x];
            [accLabel setGravityTop:timeLabel.frame.origin.y];
            [accLabel setSize:CGSizeMake(self.size.width-2*timeLabel.frame.origin.x, 45)];
            accLabel.hidden = NO;
            //NSLog(@"setting label %@",accLabel);
        } else {
            break;
        }
    }
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self);
}

- (void)didReceiveTimetableUpdate:(NSNotification *)notification {
    if ([notification.object isEqual:self.localTimeTableManager]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupViewsForDBStation];
        });
    }
}

-(void)prepareForReuse{
    [super prepareForReuse];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIF_TIMETABLE_UPDATE object:nil];
    [self.localTimeTableManager resetTimetable];
    self.localTimeTableManager = nil;
    for(NSDictionary* abfahrtDict in self.abfahrtLabels){
        UILabel *timeLabel = [abfahrtDict objectForKey:@"timeLabel"];
        UILabel *expectedTimeLabel = [abfahrtDict objectForKey:@"expectedTimeLabel"];
        UILabel *lineLabel = [abfahrtDict objectForKey:@"lineLabel"];
        UILabel *platformLabel = [abfahrtDict objectForKey:@"platformLabel"];
        UILabel *destLabel = [abfahrtDict objectForKey:@"destLabel"];
        UILabel *accLabel = [abfahrtDict objectForKey:@"accLabel"];
        UIImageView* warnIcon = [abfahrtDict objectForKey:@"warnIcon"];
        timeLabel.text = @"";
        platformLabel.text = @"";
        expectedTimeLabel.text = @"";
        lineLabel.text = @"";
        destLabel.text = @"";
        accLabel.text = @"";
        warnIcon.hidden = YES;
    }
}

@end
