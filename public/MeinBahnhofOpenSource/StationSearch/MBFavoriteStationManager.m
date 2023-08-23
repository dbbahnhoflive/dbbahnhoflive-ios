// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBFavoriteStationManager.h"

#define SETTING_FAVORITE_STATIONS @"FAVORITE_STATIONS_V2"

@interface MBFavoriteStationManager()

@property(nonatomic,strong) NSMutableArray<NSDictionary*>* favoriteStations;

@end

@implementation MBFavoriteStationManager

+ (MBFavoriteStationManager*)client
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
        self.favoriteStations = [[NSUserDefaults.standardUserDefaults arrayForKey:SETTING_FAVORITE_STATIONS] mutableCopy];
        if(!self.favoriteStations){
            self.favoriteStations = [NSMutableArray arrayWithCapacity:10];
        }
    }
    return self;
}
-(void)storeFavorites{
    NSUserDefaults* def = NSUserDefaults.standardUserDefaults;
    [def setObject:self.favoriteStations forKey:SETTING_FAVORITE_STATIONS];
}
-(void)addStation:(MBStationFromSearch*)dict{
    //NSLog(@"addStation: %@",dict.dictRepresentation);
    if(![self isFavorite:dict] && [self hasValidId:dict]){
        [self.favoriteStations insertObject:dict.dictRepresentation atIndex:0];
        [self storeFavorites];
        //NSLog(@"added station");
    } else {
        NSLog(@"station not added! %@",dict.dictRepresentation);
    }
}

-(BOOL)hasValidId:(MBStationFromSearch*)station{
    return station.stationId != nil || station.eva_ids.count > 0;
}

-(void)removeStation:(MBStationFromSearch*)dict{
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
-(BOOL)isFavorite:(MBStationFromSearch*)dict{
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

-(NSArray<MBStationFromSearch*>*)favoriteStationsList{
    NSMutableArray* list = [NSMutableArray arrayWithCapacity:self.favoriteStations.count];
    for(NSDictionary* dict in self.favoriteStations){
        MBStationFromSearch* station = [[MBStationFromSearch alloc] initWithDict:dict];
        [list addObject:station];
    }
    [list sortUsingComparator:^NSComparisonResult(MBStationFromSearch* _Nonnull obj1, MBStationFromSearch* _Nonnull obj2) {
        return [obj1.title compare:obj2.title];
    }];
    return list;
}

@end
