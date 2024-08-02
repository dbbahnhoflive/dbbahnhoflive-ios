// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBStationFromSearch.h"
#import "MBOPNVStation.h"
#import "MBRISStationsRequestManager.h"

@implementation MBStationFromSearch

-(NSString *)description{
    return [NSString stringWithFormat:@"<MBStationFromSearch: %@,%@>",_stationId,_title];
}

-(instancetype)initWithDict:(NSDictionary *)dict{
    self = [super init];
    if(self){
        self.stationId = dict[@"id"];
        self.title = dict[@"title"];
        NSArray<NSNumber*>* pos = dict[@"location"];
        if(pos){
            self.coordinate = CLLocationCoordinate2DMake(pos.firstObject.doubleValue, pos.lastObject.doubleValue);
        } else {
            self.coordinate = kCLLocationCoordinate2DInvalid;
        }
        self.distanceInKm = dict[@"distanceInKm"];
        if(dict[@"eva_ids"]){
            //ensure that we store an array of Strings with no leading 0
            NSArray* evas = dict[@"eva_ids"];
            NSMutableArray* list = [NSMutableArray arrayWithCapacity:evas.count];
            for(NSString* eva in evas){
                [list addObject:[NSString stringWithFormat:@"%lld",eva.longLongValue]];
            }
            self.eva_ids = list;
        }
        self.isOPNVStation = [dict[@"isOPNVStation"] boolValue];
    }
    return self;
}
-(instancetype)initWithHafasStation:(MBOPNVStation *)hafasStation{
    self = [super init];
    if(self){
        if(!hafasStation.hasProductsInRangeICEtoS){
            self.isOPNVStation = YES;
        } else {
            self.isOPNVStation = NO;
        }
        NSLog(@"extId=%@, productsHasTraints=%d, opnv=%d %@",hafasStation.extId,hafasStation.hasProductsInRangeICEtoS,self.isOPNVStation,hafasStation.name);
        if(hafasStation.extId){
            NSString* eva = [NSString stringWithFormat:@"%lld",hafasStation.extId.longLongValue];
            self.eva_ids = @[ eva ];
        }
        self.title = hafasStation.name;
        self.coordinate = hafasStation.coordinate;
        self.distanceInKm = [NSNumber numberWithDouble:hafasStation.distanceInKM];
    }
    return self;
}

- (void)setEva_ids:(NSArray<NSString *> *)eva_ids{
    NSMutableArray* list = [NSMutableArray arrayWithCapacity:eva_ids.count];
    for(NSString* eva in eva_ids){
        [list addObject:[NSString stringWithFormat:@"%lld",eva.longLongValue]];
    }
    _eva_ids = list;
}

- (id)copyWithZone:(NSZone *)zone
{
    MBStationFromSearch *copy = [[[self class] allocWithZone:zone] init];
    copy.stationId = self.stationId;
    copy.coordinate = self.coordinate;
    copy.distanceInKm = self.distanceInKm;
    copy.eva_ids = self.eva_ids;
    copy.stationId = self.stationId;
    copy.title = self.title;
    copy.isOPNVStation = self.isOPNVStation;
    copy.isFreshStationFromSearch = self.isFreshStationFromSearch;
    copy.hasEvaIdsUpdatedViaGroupsApi = self.hasEvaIdsUpdatedViaGroupsApi;
    copy.isInternalLink = self.isInternalLink;
    copy.isGoingBack = self.isGoingBack;
    return copy;
}

-(NSDictionary *)dictRepresentation{
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:6];
    if(_stationId){
        dict[@"id"] = _stationId;
    }
    if(_title){
        dict[@"title"] = _title;
    }
    if(_eva_ids){
        dict[@"eva_ids"] = _eva_ids;
    }
    if(_coordinate.latitude != 0){
        dict[@"location"] = [self location];
    }
    if(_distanceInKm){
        dict[@"distanceInKm"] = _distanceInKm;
    } else {
        dict[@"distanceInKm"] = @0;
    }

    dict[@"isOPNVStation"] = [NSNumber numberWithBool:_isOPNVStation];
    return dict;
}
-(NSArray*)location{
    return @[[NSNumber numberWithDouble:_coordinate.latitude],[NSNumber numberWithDouble:_coordinate.longitude]];
}

+(BOOL)needToUpdateEvaIdsForStation:(MBStationFromSearch *)stationFromSearch {
    return
       stationFromSearch.stationId != nil
    && !stationFromSearch.hasEvaIdsUpdatedViaGroupsApi;
}
-(void)updateEvaIds:(void (^)(BOOL success))completion{
    NSLog(@"update evaIds for station: %@",self.dictRepresentation);
    [[MBRISStationsRequestManager sharedInstance] searchStationByStada:self.stationId.stringValue success:^(MBStationFromSearch *station) {
        NSLog(@"update evaIds for station: got %@, requesting groups",station.eva_ids);
        self.coordinate = station.coordinate;
        [MBRISStationsRequestManager.sharedInstance requestStationGroups:station.eva_ids.firstObject forcedByUser:false success:^(NSArray<NSString *> *response) {
            if(response.count > 0){
                NSLog(@"replace %@ with %@",self.eva_ids,response);
                self.eva_ids = response;
                self.hasEvaIdsUpdatedViaGroupsApi = true;
            }
            completion(true);
        } failureBlock:^(NSError * error) {
            completion(false);
        }];
    } failureBlock:^(NSError * error) {
        completion(false);
    }];

}

@end
