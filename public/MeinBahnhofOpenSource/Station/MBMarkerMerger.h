// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "MBOPNVStation.h"
#import "MBStationFromSearch.h"

@class MBMarker;

@interface MBMarkerMerger : NSObject

+(NSArray*)oepnvStationsToMBMarkerList:(NSArray<MBOPNVStation*>*)oepnvStations;

+(MBMarker*)markerForSearchStation:(MBStationFromSearch*)station;


@end
