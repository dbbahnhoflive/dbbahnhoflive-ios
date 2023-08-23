// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBMarkerMerger.h"
#import "MBMapFlyout.h"
#import "MBStation.h"
#import "MBTimetableViewController.h"
#import "MBRootContainerViewController.h"
#import "TimetableManager.h"
#import "MBTutorialManager.h"
#import "MBOPNVStation.h"
#import "MBMarker.h"
#import "UIImage+MBImage.h"

@interface MBMarkerMerger ()

@end

@implementation MBMarkerMerger

#define MAX_NUMBER_OF_ENTRIES 20

+(MBMarker*)markerForSearchStation:(MBStationFromSearch*)searchStation{
    if(searchStation.isOPNVStation){
        MBMarker *marker = [MBMarker markerWithPosition:searchStation.coordinate andType:MBMarkerType_OEPNV_SELECTABLE];
        if(UIAccessibilityIsVoiceOverRunning()){
            marker.title = searchStation.title;
        }
        marker.zoomLevel = DEFAULT_ZOOM_LEVEL_WITHOUT_INDOOR;
        marker.icon = [UIImage db_imageNamed:@"app_karte_haltestelle"];
        marker.appearAnimation = kGMSMarkerAnimationPop;
        NSMutableDictionary* dict = [@{
                            @"name":searchStation.title,
                            @"title":searchStation.title,
                            } mutableCopy];
        
        if(searchStation.distanceInKm){
            dict[@"distanceInKm"] = searchStation.distanceInKm;
        }
        if(searchStation.eva_ids){
            dict[@"eva_ids"] = searchStation.eva_ids;
        }        
        marker.userData = dict;
        return marker;
    }
    
    NSDictionary *fakeDict = searchStation.dictRepresentation;
            
    MBStation* station = [[MBStation alloc] initWithId:searchStation.stationId name:searchStation.title evaIds:searchStation.eva_ids location:searchStation.location];
                    
    MBMarker *marker = (MBMarker *)[station markerForStation];
    marker.zoomLevel = DEFAULT_ZOOM_LEVEL_WITHOUT_INDOOR;
    marker.markerType = MBMarkerType_STATION_SELECTABLE;
    marker.userData = @{@"name":fakeDict[@"title"],
                                @"title":fakeDict[@"title"],
                                @"eva_ids":fakeDict[@"eva_ids"],
                                @"distanceInKm":fakeDict[@"distanceInKm"],
                                @"id": fakeDict[@"id"],
                                @"location": fakeDict[@"location"],
                                };
    //marker.category = @"Bahnhöfe";
    //marker.secondaryCategory = @"Fernverkehr";
    return marker;
}


+(NSArray*)oepnvStationsToMBMarkerList:(NSArray<MBOPNVStation*>*)oepnvStations{
    NSMutableArray *trainMarkers = [NSMutableArray new];
    for (MBOPNVStation *station in oepnvStations) {
        MBMarker *marker = [MBMarker markerWithPosition:station.coordinate andType:MBMarkerType_OEPNV_SELECTABLE];
        if(UIAccessibilityIsVoiceOverRunning()){
            marker.title = station.name;
        }
        marker.zoomLevel = DEFAULT_ZOOM_LEVEL_WITHOUT_INDOOR;
        marker.icon = [UIImage db_imageNamed:@"app_karte_haltestelle"];
        marker.appearAnimation = kGMSMarkerAnimationPop;
        NSMutableDictionary* dict = [@{@"distanceInKm":@(station.distanceInKM),
                            @"name":station.name,
                            @"title":station.name,
                            } mutableCopy];
        
        if(station.extId){
            dict[@"eva_ids"] = @[ station.extId ];
        }
        marker.userData = dict;
        
        [trainMarkers addObject:marker];
        if(trainMarkers.count == MAX_NUMBER_OF_ENTRIES){
            break;
        }
    }
    return trainMarkers;
}




@end
