// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "HafasCacheManager.h"
#import <MapKit/MapKit.h>

@interface HafasCacheManager()

// This class caches stationRequests in the settings and departure/journey-requests in memory.

@property(nonatomic,strong) NSMutableDictionary* stationRequestCache;
@property(nonatomic,strong) NSMutableDictionary* departureRequestCache;
@property(nonatomic,strong) NSMutableDictionary* journeyRequestCache;

@property(nonatomic,strong) NSLock* stationDictionaryLock;
@property(nonatomic,strong) NSLock* departureDictionaryLock;
@property(nonatomic,strong) NSLock* journeyDictionaryLock;

@property(nonatomic, strong) NSUserDefaults *cacheStore;

@end

@implementation HafasCacheManager

+ (HafasCacheManager*)sharedManager
{
    static HafasCacheManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

-(instancetype)init
{
    self = [super init];
    if(self){
        self.cacheStore = NSUserDefaults.standardUserDefaults;

        self.stationRequestCache = [[NSMutableDictionary alloc] initWithCapacity:50];
        
        // Try to restore cache from NSUserDefaults
        NSDictionary *oldStationRequestCache = [self.cacheStore objectForKey:CACHE_KEY_NEARBY_STATIONS];
        if (oldStationRequestCache) {
            self.stationRequestCache = [oldStationRequestCache mutableCopy];
        }
        
        self.departureRequestCache = [[NSMutableDictionary alloc] initWithCapacity:50];
        self.journeyRequestCache = [[NSMutableDictionary alloc] initWithCapacity:50];
        
        self.stationDictionaryLock = [[NSLock alloc] init];
        self.departureDictionaryLock = [[NSLock alloc] init];
        self.journeyDictionaryLock = [[NSLock alloc] init];
    }
    return self;
}

- (void) freeCaches
{
    [self.stationDictionaryLock lock];
    [self.stationRequestCache removeAllObjects];
    [self.stationDictionaryLock unlock];

    [self.departureDictionaryLock lock];
    [self.departureRequestCache removeAllObjects];
    [self.departureDictionaryLock unlock];
    
    [self.journeyDictionaryLock lock];
    [self.journeyRequestCache removeAllObjects];
    [self.journeyDictionaryLock unlock];
}

- (NSDictionary *)cachedDepartureRequest:(NSString *)cacheUrl
{
    [self.departureDictionaryLock lock];
    NSDictionary* dict = self.departureRequestCache[cacheUrl];
    [self.departureDictionaryLock unlock];
    return dict;
}

- (void)storeDepartureRequest:(NSDictionary *)dict url:(NSString *)url
{
    [self.departureDictionaryLock lock];
    if(dict){
        [self.departureRequestCache setObject:dict forKey:url];
    } else {
        [self.departureRequestCache removeObjectForKey:url];
    }
    
    //optional: cleanup cache by removing everything that is 5min old
    [self cleanupCache:self.departureRequestCache withTime:CACHE_TIME_DEPARTURE_REQUEST];
    
    [self.departureDictionaryLock unlock];
}

- (void)cleanupCache:(NSMutableDictionary*)cache withTime:(NSTimeInterval)time
{
    NSArray* keys = cache.allKeys;
    NSDate* now = [NSDate date];
    for(NSString* key in keys){
        NSDictionary* cacheEntry = cache[key];
        NSDate* cacheDate = cacheEntry[@"date"];
        if((-[cacheDate timeIntervalSinceDate:now]) > time){
            // NSLog(@"cleaning cache");
            [cache removeObjectForKey:key];
        }
    }

}

- (NSDictionary *)cachedStationRequest:(NSString *)cacheUrl
{
    [self.stationDictionaryLock lock];
    NSDictionary* dict =  self.stationRequestCache[cacheUrl];
    [self.stationDictionaryLock unlock];
    return dict;
}

-(NSDictionary *)cachedRequestForNearbyStation:(CLLocationCoordinate2D)coordinate
{
    [self.stationDictionaryLock lock];
    for (id key in self.stationRequestCache) {
        NSDictionary *cachedDict = self.stationRequestCache[key];
        CLLocationCoordinate2D cachedCoordinate = CLLocationCoordinate2DMake(
                                                                             [cachedDict[@"latitude"] doubleValue],
                                                                             [cachedDict[@"longitude"] doubleValue]
                                                                             );
        
        if ([HafasCacheManager distanceBetween:cachedCoordinate and:coordinate] <= CACHE_MIN_DISTANCE_TO_CURRENT_POSITION) {
            [self.stationDictionaryLock unlock];
            return cachedDict;
        }
    }
    
    [self.stationDictionaryLock unlock];
    return nil;
}

+ (double) distanceBetween:(CLLocationCoordinate2D)coordinate and:(CLLocationCoordinate2D)otherCoordinate
{
    MKMapPoint point1 = MKMapPointForCoordinate(coordinate);
    MKMapPoint point2 = MKMapPointForCoordinate(otherCoordinate);
    CLLocationDistance distance = MKMetersBetweenMapPoints(point1, point2);
    return distance;
}

- (void)storeStationRequestNearby:(NSDictionary *)dict coordinate:(NSString *)url
{
    [self.stationDictionaryLock lock];
    
    if(dict){
        [self.stationRequestCache setObject:dict forKey:url];
    } else {
        [self.stationRequestCache removeObjectForKey:url];
    }
    
    //cleanup cache by removing everything that is 24h old
    [self cleanupCache:self.stationRequestCache withTime:CACHE_TIME_STATION_REQUEST];
    [self.cacheStore setObject:self.stationRequestCache forKey:CACHE_KEY_NEARBY_STATIONS];
    
    [self.stationDictionaryLock unlock];
}

- (NSDictionary *)cachedJourneyRequest:(NSString *)cacheUrl
{
    [self.journeyDictionaryLock lock];
    NSDictionary* dict =  self.journeyRequestCache[cacheUrl];
    [self.journeyDictionaryLock unlock];
    return dict;
}

- (void)storeJourneyRequest:(NSDictionary *)dict url:(NSString *)url
{
    [self.journeyDictionaryLock lock];
    if(dict){
        [self.journeyRequestCache setObject:dict forKey:url];
    } else {
        [self.journeyRequestCache removeObjectForKey:url];
    }
    [self cleanupCache:self.journeyRequestCache withTime:CACHE_TIME_JOURNEY_REQUEST];

    [self.journeyDictionaryLock unlock];
}
@end
