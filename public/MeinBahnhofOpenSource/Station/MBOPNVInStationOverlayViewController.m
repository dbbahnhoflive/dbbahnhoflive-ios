// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBOPNVInStationOverlayViewController.h"
#import "HafasRequestManager.h"
#import "HafasTimetable.h"
#import "MBTimetableViewController.h"
#import "MBButtonWithData.h"
#import "MBStationNavigationViewController.h"
#import "MBButtonWithAction.h"
#import "MBOPNVStation.h"
#import "MBMarkerMerger.h"
#import "MBMarker.h"
#import "MBUIHelper.h"
#import "MBTrackingManager.h"

@interface MBOPNVInStationOverlayViewController ()
@property(nonatomic,strong) UIScrollView* contentScrollView;

@end

@implementation MBOPNVInStationOverlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSMutableAttributedString* headerText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"ÖPNV Anschlüsse Umkr. %d m",NEAREST_STATIONS_LIMIT_IN_M]];
    [headerText setAttributes:@{NSFontAttributeName:[UIFont db_BoldSeventeen]} range:NSMakeRange(0, @"ÖPNV Anschlüsse".length)];
    [headerText setAttributes:@{NSFontAttributeName:[UIFont db_RegularSeventeen]} range:NSMakeRange(@"ÖPNV Anschlüsse".length, headerText.length-@"ÖPNV Anschlüsse".length)];
    self.titleLabel.attributedText = headerText;
    self.titleLabel.accessibilityLabel = [NSString stringWithFormat:@"ÖPNV Anschlüsse im Umkreis von %d meter",NEAREST_STATIONS_LIMIT_IN_M];

    self.contentScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.headerView.sizeHeight, self.contentView.sizeWidth, self.contentView.sizeHeight-self.headerView.sizeHeight)];
    
    NSInteger y = 10;
    
    NSMutableArray<MBOPNVStation*>* opnvStations = [NSMutableArray arrayWithCapacity:self.nearestStations.count];
    for(MBOPNVStation* station in self.nearestStations){
        if(station.hasProducts){
            [opnvStations addObject:station];
        }
    }
    
    //step1: find out which station are inside the DB station and which is the main one.
    //       The main one will be first in the inStation array.
    NSMutableArray<MBOPNVStation*>* inStation = [NSMutableArray arrayWithCapacity:3];
    for(int i=0; i<opnvStations.count; i++){
        MBOPNVStation* station = opnvStations[i];
        if(station.extId && [self.station.stationEvaIds containsObject:station.extId]){
            //NSLog(@"im Bahnhof: %@",station[@"name"]);
            [opnvStations removeObjectAtIndex:i];
            if([self.station.stationEvaIds.firstObject isEqualToString:station.extId]){
                //this is the "main" station
                [inStation insertObject:station atIndex:0];
            } else {
                [inStation addObject:station];
            }
            i--;
        }
    }
    
    //step2: filter out duplicate lines inside the DB station
    if(inStation.count > 1){
        //remove duplicates in all the other "non-main" DB stations
        [self filterDuplicateLinesFrom:@[inStation.firstObject] inStations:[inStation subarrayWithRange:NSMakeRange(1, inStation.count-1)]];
        [self removeEmptyStations:inStation];
    }
    
    //step3: filter out duplicate lines from stations around in the DB stations
    [self filterDuplicateLinesFrom:opnvStations inStations:inStation];
    [self removeEmptyStations:inStation];
    
    if(inStation.count > 0){
        //first section: stations that are in the DB station (same eva id)
        //y = [self addSectionHeader:@"" y:y];
    }
    
    NSArray<MBOPNVStation*>* finalArray = [inStation arrayByAddingObjectsFromArray:opnvStations];
    //for the map in the departure view: transform all remaining stations into MBMarkers
    NSArray* mapMarkers = [MBMarkerMerger oepnvStationsToMBMarkerList:finalArray];
    //remove distance value, we don't want to show the distance to the main station on the map
    //add a link to our station
    NSInteger k = 0;
    for(MBMarker* marker in mapMarkers){
        NSMutableDictionary* userData = [marker.userData mutableCopy];
        [userData removeObjectForKey:@"distanceInKm"];
        [userData setObject:finalArray[k++] forKey:@"MBOPNVStation"];
        marker.userData = userData;
    }
    
    NSInteger count = 0;
    for(MBOPNVStation* station in finalArray){
        if(!station.hasProducts){
            //skip
        } else {
            if(count > 0){
                [self addLine:y];
                y += 5;
            }
            
            UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(30, y, self.view.sizeWidth-30-80, 30)];
            label.font = [UIFont db_BoldSeventeen];
            label.text = station.name;
            label.accessibilityTraits = UIAccessibilityTraitStaticText|UIAccessibilityTraitHeader;
            [self.contentScrollView addSubview:label];
            
            NSInteger subitemY = CGRectGetMaxY(label.frame);
            
            MBButtonWithAction* linkBtn = [[MBButtonWithAction alloc] initWithFrame:CGRectMake(0, y, 70, 70)];
            __weak UIViewController* vcWeak = self;
            linkBtn.actionBlock = ^{
                //move the selected station at the first place
                NSMutableArray* mapMarkersWithCurrentInFront = [mapMarkers mutableCopy];
                for(int i=0; i<mapMarkersWithCurrentInFront.count; i++){
                    MBMarker* marker = mapMarkersWithCurrentInFront[i];
                    
                    BOOL isMarkerForStation = NO;
                    NSArray* eva_ids = marker.userData[@"eva_ids"];
                    if([eva_ids.firstObject isEqualToString:station.extId]){
                        isMarkerForStation = YES;
                    }
                    
                    if(isMarkerForStation){
                        if(i != 0){
                            [mapMarkersWithCurrentInFront removeObjectAtIndex:i];
                            [mapMarkersWithCurrentInFront insertObject:marker atIndex:0];
                        }
                        break;
                    }
                }
                
                MBTimetableViewController *timeVC = [[MBTimetableViewController alloc] initWithFernverkehr:NO];                
                timeVC.mapMarkers = mapMarkersWithCurrentInFront;
                timeVC.hafasTimetable = [[HafasTimetable alloc] init];
                timeVC.hafasTimetable.opnvStationForFiltering = station;
                timeVC.hafasTimetable.includedSTrains = YES;
                timeVC.hafasTimetable.needsInitialRequest = YES;
                timeVC.oepnvOnly = YES;
                timeVC.trackingTitle = TRACK_KEY_TIMETABLE;
                timeVC.hafasStation = station;
                [vcWeak.navigationController pushViewController:timeVC animated:YES];
            };
            [linkBtn setBackgroundColor:[UIColor clearColor]];
            [linkBtn setImage:[UIImage db_imageNamed:@"MapInternalLinkButton"] forState:UIControlStateNormal];
            linkBtn.accessibilityLabel = @"Details aufrufen";
            [self.contentScrollView addSubview:linkBtn];
            [linkBtn setGravityRight:5];
            //NSLog(@"departing: %@ with %@",productsAtStopDeparting,productsLinesAtStopDeparting);
            NSInteger productIndex = 0;
            for(NSNumber* productCode in station.departingProducts){
                HAFASProductCategory cat = productCode.unsignedIntegerValue;
                NSString* iconName = nil;
                NSString* catVoiceOver = nil;
                switch(cat){
                    case HAFASProductCategoryS:
                        iconName = @"app_sbahn_klein";
                        catVoiceOver = @"S-Bahn: ";
                        break;
                    case HAFASProductCategoryBUS:
                        iconName = @"app_bus_klein";
                        catVoiceOver = @"Bus: ";
                        break;
                    case HAFASProductCategoryTRAM:
                        iconName = @"app_tram_klein";
                        catVoiceOver = [VOICEOVER_FOR_STR stringByAppendingString:@": "];
                        break;
                    case HAFASProductCategoryU:
                        iconName = @"app_ubahn_klein";
                        catVoiceOver = @"U-Bahn: ";
                        break;
                    case HAFASProductCategorySHIP:
                        iconName = @"app_faehre_klein";
                        catVoiceOver = @"Fähre: ";
                        break;
                    case HAFASProductCategoryCAL:
                        iconName = @"app_callabike_klein";
                        catVoiceOver = @"";//?
                        break;
                    default:
                        iconName = @"app_haltestelle";//placeholder
                        catVoiceOver = @"";
                        break;
                }
                UIImageView* icon = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:iconName]];
                [self.contentScrollView addSubview:icon];
                [icon setGravityTop:subitemY];
                [icon setGravityLeft:28];
                UILabel* lineLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(icon.frame)+4, subitemY+3, self.view.sizeWidth-(CGRectGetMaxX(icon.frame)+4)-80, 500)];
                [self.contentScrollView addSubview:lineLabel];
                lineLabel.numberOfLines = 0;
                lineLabel.font = [UIFont db_RegularFourteen];
                lineLabel.textColor = [UIColor db_333333];
                lineLabel.text = [self lineString:[station productLinesForProduct:productIndex] forCat:cat];
                NSString* finalLineString = lineLabel.text;
                if(cat == HAFASProductCategoryTRAM){
                    finalLineString = [finalLineString stringByReplacingOccurrencesOfString:@"STR" withString:VOICEOVER_FOR_STR];
                }
                lineLabel.accessibilityLabel = [catVoiceOver stringByAppendingString:finalLineString];
                lineLabel.size = [lineLabel sizeThatFits:lineLabel.size];
                subitemY = MAX(CGRectGetMaxY(icon.frame),CGRectGetMaxY(lineLabel.frame));
                productIndex++;
            }
            
            if(subitemY < y+72){
                subitemY = y+72;//ensure the size for the touch button
            }
            y = subitemY;
            y += 5;
        }//endof station.hasProducts
        count++;
        if(count == inStation.count && opnvStations.count > 0){
            //second section: all other stations
            [self addLine:y];
            y += 20;
            y = [self addSectionHeader:@"Stationen & Haltestellen" y:y];
        }
    }
    [self addLine:y];
    y += 20;
    self.contentScrollView.contentSize = CGSizeMake(self.contentScrollView.sizeWidth, y);
    [self.contentView addSubview:self.contentScrollView];
}



-(void)removeEmptyStations:(NSMutableArray<MBOPNVStation*>*)list{
    for(NSInteger i=list.count-1; i>=0; i--){
        if(!list[i].hasProducts){
            [list removeObjectAtIndex:i];
        }
    }
}

-(void)filterDuplicateLinesFrom:(NSArray<MBOPNVStation*>*)sourceList inStations:(NSArray<MBOPNVStation*>*)modifiedList{
    for(MBOPNVStation* sourceStation in sourceList){
        for(MBOPNVStation* modifiedStation in modifiedList){
            [modifiedStation removeDuplicateLinesFrom:sourceStation];
        }
    }
}

-(void)addLine:(NSInteger)y{
    UIView* line = [[UIView alloc] initWithFrame:CGRectMake(15, y, self.view.sizeWidth, 1)];
    line.backgroundColor = [UIColor db_light_lineColor];
    [self.contentScrollView addSubview:line];
}

-(NSInteger)addSectionHeader:(NSString*)title y:(NSInteger)y{
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(15, y, self.view.sizeWidth-2*15, 30)];
    label.font = [UIFont db_RegularSixteen];
    label.textColor = [UIColor db_333333];
    label.text = title;
    label.accessibilityTraits = UIAccessibilityTraitStaticText|UIAccessibilityTraitHeader;
    [self.contentScrollView addSubview:label];
    return CGRectGetMaxY(label.frame)+2;
}

-(NSString*)lineString:(NSArray*)lines forCat:(HAFASProductCategory)cat{
    NSMutableString* res = [[NSMutableString alloc] init];
    for(NSString* line in lines){
        /*if(cat == HAFASProductCategoryS){
            [res appendString:@"S"];
        } else if(cat == HAFASProductCategoryU){
            [res appendString:@"U"];
        }*/
        [res appendString:line];
        if(line != lines.lastObject){
            [res appendString:@", "];
        }
    }
    return res;
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (nil != self.navigationController) {
        if ([self.navigationController isKindOfClass:[MBStationNavigationViewController class]]) {
            MBStationNavigationViewController* nav = (MBStationNavigationViewController*) self.navigationController;
            [nav setShowRedBar:NO];
            [nav hideNavbar:YES];
        }
    }
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    //resize view for content
    int totalHeight = MIN(self.view.sizeHeight-40, self.contentScrollView.contentSize.height+self.headerView.sizeHeight);
    [self.contentView setHeight:totalHeight];
    [self.contentView setGravityBottom:0];
    self.contentScrollView.frame = CGRectMake(0, self.headerView.sizeHeight, self.contentView.sizeWidth, self.contentView.sizeHeight-self.headerView.sizeHeight);
    
}


@end
