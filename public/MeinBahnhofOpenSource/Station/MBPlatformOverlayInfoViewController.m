// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBPlatformOverlayInfoViewController.h"
#import "UIView+Frame.h"
#import "MBPlatformAccessibility.h"
#import "UIColor+DBColor.h"
#import "UIFont+DBFont.h"
#import "MBTrainJourneyViewController.h"
#import "MBLinkButton.h"
#import "MBContentSearchResult.h"
#import "MBRootContainerViewController.h"
#import "MBPlatformAccessibilityView.h"
@interface MBPlatformOverlayInfoViewController ()

@end

@implementation MBPlatformOverlayInfoViewController

#define spacing 16

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Gleisinformationen";
    
    NSInteger y = spacing;
    
    [self.station addLevelInformationToPlatformAccessibility];
    NSArray<MBPlatformAccessibility*>* tracksToShow = self.station.platformForTrackInfo;
    
    NSMutableDictionary<NSString*,NSMutableArray<MBPlatformAccessibility*>*>* tracksPerLevel = [NSMutableDictionary new];
    NSString* levelUnknown = @"Unbekanntes Stockwerk";
    NSArray<NSString*>* levelList = UIAccessibilityIsVoiceOverRunning() ? [RIMapPoi levelList] : [RIMapPoi levelListShort];
    levelList = [levelList arrayByAddingObject:levelUnknown];
    for(NSString* level in levelList){
        NSMutableArray<NSString*>* trackNumbersOnThisLevel = [NSMutableArray new];
        NSMutableArray* tracksOnThisLevel = [NSMutableArray new];
        for(MBPlatformAccessibility* p in tracksToShow){
            BOOL add = false;
            if(p.level){
                if([p.level isEqualToString:level]){
                    add = true;
                }
            } else if(level == levelUnknown){
                add = true;
            }
            if(add){
                NSString* num = p.name;
                if(![trackNumbersOnThisLevel containsObject:num]){
                    [tracksOnThisLevel addObject:p];
                    [trackNumbersOnThisLevel addObject:num];
                }
            }
        }
        if(tracksOnThisLevel.count > 0){
            //sort them by the track number
            [MBPlatformAccessibility sortArray:tracksOnThisLevel];
            tracksPerLevel[level] = tracksOnThisLevel;
        }
    }
    
    NSLog(@"result: %@",tracksPerLevel);

    //first text line
    BOOL voActive = UIAccessibilityIsVoiceOverRunning();
    NSString* train = [self.event.stop formattedTransportType:self.event.lineIdentifier];
    NSString* time = @"";
    NSInteger delay = 0;
    if(self.event.departure){
        time = [MBTrainJourneyViewController timeStringForDate:self.trainJourneyStop.departureTimeSchedule];
        delay = (long)[self.trainJourneyStop.departureTime timeIntervalSinceDate:self.trainJourneyStop.departureTimeSchedule]/60;
    } else {
        time = [MBTrainJourneyViewController timeStringForDate:self.trainJourneyStop.arrivalTimeSchedule];
        delay = (long)[self.trainJourneyStop.arrivalTime timeIntervalSinceDate:self.trainJourneyStop.arrivalTimeSchedule]/60;
    }
    NSString* delayString = @"";
    if(delay != 0){
        if(delay > 0){
            delayString = [NSString stringWithFormat:@" +%ld",(long)delay];
        } else {
            delayString = [NSString stringWithFormat:@" %ld",(long)delay];
        }
    }
    NSString* voExtra1 = @"";
    NSString* voExtra2 = @"";
    NSString* divider = @" |";
    if(voActive){
        voExtra1 = self.event.departure ? @"Abfahrt " : @"Ankunft ";
        voExtra2 = @" Uhr";
        divider = @",";
        if(delayString.length > 0){
            delayString = [delayString stringByAppendingString:@" Minuten"];
        }
    }
    NSString* trainText = [NSString stringWithFormat:@"%@%@%@%@%@ %@",voExtra1,time,voExtra2,delayString,divider,train];
    NSRange coloredRange = NSMakeRange(voExtra1.length+time.length+voExtra2.length, delayString.length);
    UIColor* timeColor = UIColor.db_mainColor;
    if(delay <= 5){
        timeColor = UIColor.db_green;
    }

    //second text line
    NSString* track = self.trainJourneyStop.platform;
    NSString* level = [self.station levelForPlatform:track];
    NSString* trackText = [NSString stringWithFormat:@"Gleis %@",track];
    if(level){
        trackText = [trackText stringByAppendingFormat:@" im %@",level];
    }
    
    //third line
    NSString* linkedTrack = [self.station linkedPlatformForPlatform:track];
    if(linkedTrack){
        linkedTrack = [NSString stringWithFormat:@"Gegenüberliegend Gleis %@",linkedTrack];
    }
    
    //create the UI-elements
    UILabel* trainInfo = [self generateHeaderLabel:trainText atY:y];
    if(coloredRange.length > 0){
        NSMutableAttributedString* s = [[NSMutableAttributedString alloc] initWithString:trainText attributes:@{ NSFontAttributeName:trainInfo.font, NSForegroundColorAttributeName:trainInfo.textColor }];
        [s setAttributes:@{ NSFontAttributeName:trainInfo.font, NSForegroundColorAttributeName:timeColor } range:coloredRange];
        trainInfo.attributedText = s;
    }
    y += trainInfo.frame.size.height+10;
    UILabel* trackInfo = [self generateTextLabel:trackText atY:y];
    y += trackInfo.frame.size.height+5;
    if(linkedTrack){
        UILabel* trackInfo = [self generateTextLabel:linkedTrack atY:y];
        trackInfo.textColor = UIColor.db_878c96;
        y += trackInfo.frame.size.height;
    }
    y += 15;

    UILabel* headerLabel = [UILabel new];
    headerLabel.text = @"Informationen zu den Gleisen vor Ort";
    headerLabel.font = [UIFont db_BoldFourteen];
    headerLabel.textColor = UIColor.db_333333;
    headerLabel.accessibilityTraits |= UIAccessibilityTraitHeader;
    [headerLabel sizeToFit];
    [headerLabel setGravityTop:y];
    [headerLabel setGravityLeft:spacing];
    y = CGRectGetMaxY(headerLabel.frame)+5;
    [self.contentScrollView addSubview:headerLabel];

    BOOL hasSingleUnknownLevel = tracksPerLevel.count == 1 && [tracksPerLevel.allKeys.firstObject isEqualToString:levelUnknown];
    for(NSString* level in levelList){
        NSArray<MBPlatformAccessibility*>* tracks = tracksPerLevel[level];
        if(tracks.count > 0){
            //for each level that contains tracks list it:
            y += 5;
            if(hasSingleUnknownLevel){
                //we hide the "Unknown platform" header in this case
            } else {
                UILabel* levelLabel = [self generateHeaderLabel:level atY:y];
                y = CGRectGetMaxY(levelLabel.frame)+5;
            }
            for(MBPlatformAccessibility* track in tracks){
                NSMutableString* trackList = [NSMutableString new];
                [trackList appendString:@"Gleis "];
                [trackList appendString:track.name];
                if(track.headPlatform){
                    [trackList appendString:@" (Kopfgleis)"];
                }
                //append the linked tracks
                for(MBPlatformAccessibility* linked in track.linkedMBPlatformAccessibility){
                    if(voActive){
                        if(linked == track.linkedMBPlatformAccessibility.firstObject){
                            [trackList appendString:@", gegenüberliegend "];
                        } else {
                            [trackList appendString:@", "];
                        }
                    } else {
                        [trackList appendString:@" | "];
                    }
                    if(voActive){
                        [trackList appendString:@"Gleis "];
                    }
                    [trackList appendString:linked.name];
                    if(linked.headPlatform){
                        [trackList appendString:@" (Kopfgleis)"];
                    }
                }
                UILabel* trackLabel = [self generateTextLabel:trackList atY:y];
                y = CGRectGetMaxY(trackLabel.frame)+5;
            }
        }
    }
    y += spacing;
    
    BOOL stationHasFacility = self.station.facilityStatusPOIs.count > 0;
    NSString* textFacility = @"Bitte beachten Sie, dass ein Bahnsteigwechsel ggf. über eine andere Ebene erfolgt und die Nutzung von Treppen oder Aufzugsanlagen erfordert.";
    if(stationHasFacility){
        textFacility = [textFacility stringByAppendingString:@" Eine Übersicht der Aufzugsanlagen und deren aktuelle Verfügbarkeit finden Sie hier:"];
    }
    UILabel* linkToFacilityInfo = [self generateMultiLineTextLabel:textFacility atY:y];
    y = CGRectGetMaxY(linkToFacilityInfo.frame);

    if(stationHasFacility){
        y += 10;
        UIButton* facilityButton = [self addLinkButton:@"Übersicht Aufzüge" atY:y selector:@selector(didTapOnFacilityLink:)];
        y = CGRectGetMaxY(facilityButton.frame);
    }
    y += spacing;

    UILabel* linkToAcc = [self generateMultiLineTextLabel:@"Weitere Informationen zur Barrierefreiheit finden Sie hier:" atY:y];
    y = CGRectGetMaxY(linkToAcc.frame)+10;

    UIButton* accButton = [self addLinkButton:@"Informationen zur Barrierefreiheit" atY:y selector:@selector(didTapOnAccLink:)];
    y = CGRectGetMaxY(accButton.frame);
    
    y += spacing*2;
    [self updateContentScrollViewContentHeight:y];
}

-(void)didTapOnFacilityLink:(id)sender{
    [self hideOverlayWithCompletion:^{
        MBContentSearchResult* res = [MBContentSearchResult searchResultWithKeywords:CONTENT_SEARCH_KEY_STATIONINFO_ELEVATOR];
        MBRootContainerViewController* root = [MBRootContainerViewController currentlyVisibleInstance];
        [root handleSearchResult:res];
    }];
}
-(void)didTapOnAccLink:(id)sender{
    [self hideOverlayWithCompletion:^{
        NSString* platform = self.trainJourneyStop.platform;
        NSDictionary* serviceConfiguration = @{ MB_SERVICE_ACCESSIBILITY_CONFIG_KEY_PLATFORM: platform};
        MBContentSearchResult* res = [MBContentSearchResult searchResultWithKeywords:CONTENT_SEARCH_KEY_STATIONINFO_ACCESSIBILITY];
        res.metaData = serviceConfiguration;
        MBRootContainerViewController* root = [MBRootContainerViewController currentlyVisibleInstance];
        [root handleSearchResult:res];
    }];
}

-(MBLinkButton*)addLinkButton:(NSString*)text atY:(NSInteger)y selector:(SEL)selector{
    MBLinkButton* facilityButton = [MBLinkButton boldButtonWithRedLink];
    [facilityButton setLabelText:text];
    [facilityButton addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    [self.contentScrollView addSubview:facilityButton];
    [facilityButton setGravityLeft:spacing];
    [facilityButton setGravityTop:y];
    return facilityButton;
}

-(UILabel*)generateHeaderLabel:(NSString*)level atY:(NSInteger)y{
    UILabel* levelLabel = [UILabel new];
    levelLabel.text = level;
    levelLabel.font = [UIFont db_RegularSixteen];
    levelLabel.textColor = UIColor.db_333333;
    levelLabel.accessibilityTraits |= UIAccessibilityTraitHeader;
    [levelLabel sizeToFit];
    [self.contentScrollView addSubview:levelLabel];
    [levelLabel setGravityLeft:spacing];
    [levelLabel setGravityTop:y];
    return levelLabel;
}
-(UILabel*)generateTextLabel:(NSString*)text atY:(NSInteger)y{
    UILabel* trackLabel = [UILabel new];
    trackLabel.text = text;
    trackLabel.numberOfLines = 0;
    trackLabel.font = [UIFont db_RegularFourteen];
    trackLabel.textColor = UIColor.db_333333;
    CGSize size = [trackLabel sizeThatFits:CGSizeMake(self.view.frame.size.width-2*spacing, NSIntegerMax)];
    trackLabel.size = CGSizeMake(ceilf(size.width), ceilf(size.height));
    [self.contentScrollView addSubview:trackLabel];
    [trackLabel setGravityTop:y];
    [trackLabel setGravityLeft:spacing];
    return trackLabel;
}
-(UILabel*)generateMultiLineTextLabel:(NSString*)text atY:(NSInteger)y{
    UILabel* linkToFacilityInfo = [self generateTextLabel:text atY:y];
    linkToFacilityInfo.numberOfLines = 0;
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:3];
    NSAttributedString* attr = [[NSAttributedString alloc] initWithString:linkToFacilityInfo.text attributes:@{ NSForegroundColorAttributeName:linkToFacilityInfo.textColor, NSFontAttributeName: linkToFacilityInfo.font, NSParagraphStyleAttributeName: style }];
    linkToFacilityInfo.attributedText = attr;

    CGSize size = [linkToFacilityInfo sizeThatFits:CGSizeMake(self.view.sizeWidth-2*spacing, NSIntegerMax)];
    [linkToFacilityInfo setSize:CGSizeMake(ceilf(size.width), ceilf(size.height))];
    return linkToFacilityInfo;
}


@end
