// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBCacheManager.h"

@interface MBCacheManager()

@end

#define MBCACHE_VERSION 318
#define SETTING_MBCACHE_VERSION @"mbcachemanager.version"

@implementation MBCacheManager

+ (instancetype)sharedManager
{
    static MBCacheManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

-(instancetype)init{
    self = [super init];
    if(self){
        NSLog(@"setup cache manager with directory %@",[self applicationDocumentsDirectory]);
        NSUserDefaults* def = NSUserDefaults.standardUserDefaults;
        if([def integerForKey:SETTING_MBCACHE_VERSION] != MBCACHE_VERSION){
            [self deleteCache];
            NSLog(@"cache version changed, clear cache dir");
            [def setInteger:MBCACHE_VERSION forKey:SETTING_MBCACHE_VERSION];
        }
    }
    return self;
}

-(void)deleteCache{
    [[NSFileManager defaultManager] removeItemAtPath:[self applicationDocumentsDirectory] error:nil];
    NSLog(@"cache deleted");
}

//cache for 24h = 60*60*24
#define CACHE_TIME_RIS_1_DAY (60*60*24)
#define CACHE_TIME_RIS_1H (60*60*1)
#define CACHE_TIME_RIS_OCCUPANCY (60*15)
#define CACHE_TIME_RIMAP (60*60*1)
#define CACHE_TIME_PARKING (60*60*1)
#define CACHE_TIME_PARKING_CAPACITY (60*15)
#define CACHE_TIME_EINKAUFSBAHNHOF (60*60*24)
#define CACHE_TIME_TRAVELCENTER (60*60*24)
#define CACHE_TIME_NEWS (60*5)

-(NSTimeInterval)cacheTimeForType:(MBCacheResponseType)type{
    switch (type) {
        case MBCacheResponseTypeInvalid:
            return 0;
        case MBCacheResponseRISStationData:
        case MBCacheResponseRISStationServices:
        case MBCacheResponseRISLocker:
        case MBCacheResponseRISPlatforms:
        case MBCacheResponseRISGroups:
        case MBCacheResponseRISStopPlacesByKeyForStada:
            return CACHE_TIME_RIS_1H;
        case MBCacheResponseRISTransportAdminstrator:
            return CACHE_TIME_RIS_1_DAY;
        case MBCacheResponseRISOccupancy:
            return CACHE_TIME_RIS_OCCUPANCY;
        case MBCacheResponseRISStopPlacesForEva:
            return CACHE_TIME_RIS_1_DAY;
        case MBCacheResponseRIMapStatus07API:
        case MBCacheResponseRIMapPOIs07Api:
        case MBCacheResponseRIMapSEV07API:
            return CACHE_TIME_RIMAP;
        case MBCacheResponseParking:
            return CACHE_TIME_PARKING;
        case MBCacheResponseParkingCapacity:
            return CACHE_TIME_PARKING_CAPACITY;
        case MBCacheResponseEinkaufsbahnhof:
            return CACHE_TIME_EINKAUFSBAHNHOF;
        case MBCacheResponseEinkaufsbahnhofOverview:
            return CACHE_TIME_EINKAUFSBAHNHOF;
        case MBCacheResponseNews:
            return CACHE_TIME_NEWS;
    }
    return 0;
}

- (NSURL *) applicationDocumentsDirectoryURL
{
    NSArray * urls = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
    NSURL* url = [urls.firstObject URLByAppendingPathComponent:@"MBCacheManager"];
    return url;
}

- (NSString *) applicationDocumentsDirectory
{
    NSString* path = [self applicationDocumentsDirectoryURL].path;
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    return path;
}

-(NSString*)cacheFileForStation:(NSNumber*)station type:(MBCacheResponseType)type{
    NSString* filename = @"undefined.json";
    switch (type) {
        case MBCacheResponseRISStationData:
            filename = @"ris_station.json";
            break;
        case MBCacheResponseRISStationServices:
            filename = @"ris_station_services.json";
            break;
        case MBCacheResponseRISStopPlacesForEva:
            filename = @"ris_stopplaces_foreva.json";
            break;
        case MBCacheResponseRISStopPlacesByKeyForStada:
            filename = @"ris_stopplaces_bykey_forstada.json";
            break;
        case MBCacheResponseRISTransportAdminstrator:
            filename = @"ris_transport_administrator.json";
            break;
        case MBCacheResponseRISPlatforms:
            filename = @"ris_platform.json";
            break;
        case MBCacheResponseRISOccupancy:
            filename = @"ris_occupancy.json";
            break;
        case MBCacheResponseRISGroups:
            filename = @"ris_groups.json";
            break;
        case MBCacheResponseRIMapStatus07API:
            filename = @"rimapstatus07.json";
            break;
        case MBCacheResponseRIMapPOIs07Api:
            filename = @"rimappois07.json";
            break;
        case MBCacheResponseRIMapSEV07API:
            filename = @"rimap_sev.json";
            break;
        case MBCacheResponseParking:
            filename = @"parking_v2.json";
            break;
        case MBCacheResponseParkingCapacity:
            filename = @"parking_capacity.json";
            break;
        case MBCacheResponseEinkaufsbahnhof:
            filename = @"einkauf.json";
            break;
        case MBCacheResponseEinkaufsbahnhofOverview:
            filename = @"einkauf_overview.json";
            break;
        case MBCacheResponseNews:
            filename = @"news.json";
            break;
        case MBCacheResponseTypeInvalid:
            return nil;
            break;
        case MBCacheResponseRISLocker:
            filename = @"locker.json";
            break;
    }
    filename = [station.stringValue stringByAppendingFormat:@"_%@",filename];
    NSString* path = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:filename];
    return path;
}

-(MBCacheState)cacheStateForStationId:(NSNumber*)stationId type:(MBCacheResponseType)type{
    NSString* file = [self cacheFileForStation:stationId type:type];
    NSError* error = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:file error:&error];
    if(attributes.fileModificationDate){
        NSDate* modifyDate = attributes.fileModificationDate;
        NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
        if(((now-modifyDate.timeIntervalSinceReferenceDate)) > [self cacheTimeForType:type]){
            return MBCacheStateOutdated;
        } else {
            return MBCacheStateValid;
        }
    } else {
        return MBCacheStateNone;
    }
}

-(NSDictionary*)cachedResponseForStationId:(NSNumber*)stationId type:(MBCacheResponseType)type{
    NSString* file = [self cacheFileForStation:stationId type:type];
    if(![[NSFileManager defaultManager] fileExistsAtPath:file]){
        return nil;
    }
    NSData* data = [NSData dataWithContentsOfFile:file];
    NSDictionary *cache = nil;
    if(data){
        cache = [NSJSONSerialization JSONObjectWithData:data
                                        options:0
                                          error:nil];
        data = nil;
    }
    NSDictionary* cacheEntry = cache[@"cachedata"];
    cache = nil;
    if(cacheEntry){
        return cacheEntry[@"data"];
    }
    return nil;
}

-(void)storeResponse:(NSDictionary*)responseObject forStationId:(NSNumber*)stationId type:(MBCacheResponseType)type{
    NSString* file = [self cacheFileForStation:stationId type:type];
    NSMutableDictionary *cache = [NSMutableDictionary dictionaryWithCapacity:5];
    [cache setObject:@{ @"date":@([NSDate timeIntervalSinceReferenceDate]), @"data":responseObject } forKey:@"cachedata"];
    if([NSJSONSerialization isValidJSONObject:cache]){
        NSData *dataFromDict = [NSJSONSerialization dataWithJSONObject:cache
                                                               options:0//NSJSONWritingPrettyPrinted
                                                                 error:nil];
        BOOL success = [dataFromDict writeToFile:file atomically:YES];
        NSLog(@"stored cache at %@ with status %d",file,success);
    } else {
        NSLog(@"ERROR: could not store cachedata as json");
    }
}



@end
