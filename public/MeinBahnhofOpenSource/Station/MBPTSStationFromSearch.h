// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class MBOPNVStation;

//Please note: this object is used for the search results from PTS and hafas and it can an DB-station or an opnv-station

@interface MBPTSStationFromSearch : NSObject

@property(nonatomic,strong) NSNumber* stationId;
@property(nonatomic,strong) NSString* title;
@property(nonatomic,strong) NSArray<NSString*>* eva_ids;
@property(nonatomic) CLLocationCoordinate2D coordinate;
@property(nonatomic,strong) NSNumber* distanceInKm;

@property(nonatomic) BOOL isOPNVStation;

-(instancetype)initWithDict:(NSDictionary*)dict;
-(instancetype)initWithHafasStation:(MBOPNVStation*)hafasStation;

-(NSArray<NSNumber*>*)location;
-(NSDictionary*)dictRepresentation;



@end
