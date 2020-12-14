// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBFavoriteStationManager.h"

@interface MBFavoriteStationManager()

@property(nonatomic,strong) NSMutableArray* favoriteStations;

@end

@implementation MBFavoriteStationManager

+ (id)client
{
    static MBFavoriteStationManager *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[self alloc] init];
    });
    return sharedClient;
}
-(instancetype)init{
    self = [super init];
    if(self)
    {
        self.favoriteStations = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"FAVORITE_STATIONS"] mutableCopy];
        
        if(self.favoriteStations){
            //can be removed on a future update, tansform and cleanup old data
            
            //transform data: old storage: used the id field for the evaId in hafas-stations
            NSMutableArray* newFavorites = [NSMutableArray arrayWithCapacity:self.favoriteStations.count];
            for(NSDictionary* dict in self.favoriteStations){
                NSMutableDictionary* resultingDict = [dict mutableCopy];
                if(dict[@"hafas_id"] != nil){
                    //this was on opnv-station: the id field contains the eva_id
                    NSString* idNum = dict[@"id"];
                    if([idNum isKindOfClass:NSNumber.class]){
                        idNum = [((NSNumber*)idNum) stringValue];
                    } else if([idNum isKindOfClass:NSString.class]){
                        //ensure that we clip leading 0
                        idNum = [NSString stringWithFormat:@"%lld",idNum.longLongValue];
                    } else {
                        idNum = nil;
                    }
                    if(idNum){
                        resultingDict[@"eva_ids"] = @[ idNum ];
                        resultingDict[@"id"] = nil;
                        resultingDict[@"hafas_id"] = nil;
                        resultingDict[@"isOPNVStation"] = [NSNumber numberWithBool:YES];
                    } else {
                        //failure: we have no valid id for this station, ignore it
                        NSLog(@"failure: can't convert old station: %@",dict);
                        resultingDict = nil;
                    }
                } else {
                    resultingDict[@"isOPNVStation"] = [NSNumber numberWithBool:NO];
                }
                if(resultingDict){
                    [newFavorites addObject:resultingDict];
                }
            }
            self.favoriteStations = newFavorites;
            [self storeFavorites];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FAVORITE_STATIONS"];
        } else {
            //new storage:
            self.favoriteStations = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"FAVORITE_STATIONS_V2"] mutableCopy];
        }
        
        if(!self.favoriteStations){
            self.favoriteStations = [NSMutableArray arrayWithCapacity:10];
        }
    }
    return self;
}
-(void)storeFavorites{
    NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
    [def setObject:self.favoriteStations forKey:@"FAVORITE_STATIONS_V2"];
}
-(void)addStation:(MBPTSStationFromSearch*)dict{
    //NSLog(@"addStation: %@",dict.dictRepresentation);
    if(![self isFavorite:dict] && [self hasValidId:dict]){
        [self.favoriteStations insertObject:dict.dictRepresentation atIndex:0];
        [self storeFavorites];
        //NSLog(@"added station");
    } else {
        NSLog(@"station not added! %@",dict.dictRepresentation);
    }
}

-(BOOL)hasValidId:(MBPTSStationFromSearch*)station{
    return station.stationId != nil || station.eva_ids.count > 0;
}

-(void)removeStation:(MBPTSStationFromSearch*)dict{
    //NSLog(@"removeStation: %@",dict.dictRepresentation);
    for(int i=0; i<self.favoriteStations.count; i++){
        NSDictionary* station = self.favoriteStations[i];
        if(dict.stationId && [station[@"id"] isEqualToNumber:dict.stationId]){
            [self.favoriteStations removeObjectAtIndex:i];
            [self storeFavorites];
            return;
        } else if(dict.eva_ids.count > 0 && station[@"eva_ids"]){
            NSArray* eva_ids = station[@"eva_ids"];
            if([self sameEvaId:dict.eva_ids.firstObject anotherEvaId:eva_ids.firstObject]){
                [self.favoriteStations removeObjectAtIndex:i];
                [self storeFavorites];
                return;
            }
        }
    }
    NSLog(@"station not removed!");
}
-(BOOL)isFavorite:(MBPTSStationFromSearch*)dict{
    for(NSDictionary* station in self.favoriteStations){
        if(dict.stationId && [station[@"id"] isEqualToNumber:dict.stationId]){
            //NSLog(@"isFavorite, yes with stationId: %@",dict.dictRepresentation);
            return YES;
        } else if(dict.eva_ids.count > 0 && station[@"eva_ids"]){
            NSArray* eva_ids = station[@"eva_ids"];
            if([self sameEvaId:dict.eva_ids.firstObject anotherEvaId:eva_ids.firstObject]){
                //NSLog(@"isFavorite, yes with eva_ids: %@",dict.dictRepresentation);
                return YES;
            }
        }
    }
    //NSLog(@"isFavorite, no: %@",dict.dictRepresentation);
    return NO;
}

-(BOOL)sameEvaId:(NSString*)eva1 anotherEvaId:(NSString*)eva2{
    return [eva1 isEqualToString:eva2]
    || eva1.longLongValue == eva2.longLongValue;//some eva have a leading 0
}

-(NSArray<MBPTSStationFromSearch*>*)favoriteStationsList{
    NSMutableArray* list = [NSMutableArray arrayWithCapacity:self.favoriteStations.count];
    for(NSDictionary* dict in self.favoriteStations){
        MBPTSStationFromSearch* station = [[MBPTSStationFromSearch alloc] initWithDict:dict];
        [list addObject:station];
    }
    return list;
}

@end
