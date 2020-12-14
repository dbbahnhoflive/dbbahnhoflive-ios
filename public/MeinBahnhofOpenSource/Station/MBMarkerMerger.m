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

@interface MBMarkerMerger ()

@end

@implementation MBMarkerMerger

#define MAX_NUMBER_OF_ENTRIES 20

+(MBMarker*)markerForSearchStation:(MBPTSStationFromSearch*)ptsstation{
    if(ptsstation.isOPNVStation){
        MBMarker *marker = [MBMarker markerWithPosition:ptsstation.coordinate andType:OEPNV_SELECTABLE];
        marker.zoomLevel = DEFAULT_ZOOM_LEVEL_WITHOUT_INDOOR;
        marker.icon = [UIImage db_imageNamed:@"app_karte_haltestelle"];
        marker.appearAnimation = kGMSMarkerAnimationPop;
        NSMutableDictionary* dict = [@{
                            @"name":ptsstation.title,
                            @"title":ptsstation.title,
                            } mutableCopy];
        
        if(ptsstation.distanceInKm){
            dict[@"distanceInKm"] = ptsstation.distanceInKm;
        }
        if(ptsstation.eva_ids){
            dict[@"eva_ids"] = ptsstation.eva_ids;
        }        
        marker.userData = dict;
        return marker;
    }
    
    NSDictionary *fakeDict = ptsstation.dictRepresentation;
            
    MBStation* station = [[MBStation alloc] initWithId:ptsstation.stationId name:ptsstation.title evaIds:ptsstation.eva_ids location:ptsstation.location];
                    
    MBMarker *marker = (MBMarker *)[station markerForStation];
    marker.zoomLevel = DEFAULT_ZOOM_LEVEL_WITHOUT_INDOOR;
    marker.markerType = STATION_SELECTABLE;
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
        MBMarker *marker = [MBMarker markerWithPosition:station.coordinate andType:OEPNV_SELECTABLE];
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
