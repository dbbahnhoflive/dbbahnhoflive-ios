// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "HafasTimetable.h"
#import "HafasRequestManager.h"
#import "MBOPNVStation.h"

@interface HafasTimetable()
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property(nonatomic,strong) NSDate* loadingDate;
@end

@implementation HafasTimetable

-(instancetype)init{
    self = [super init];
    if(self){
        self.requestDuration = 120;
    }
    return self;
}

- (NSDateFormatter *)dateFormatter {
    if (nil == _dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.timeStyle = NSDateFormatterShortStyle;
        _dateFormatter.dateStyle = NSDateFormatterNoStyle;
    }
    return _dateFormatter;
}

-(NSDate *)lastRequestedDate{
    return [self.loadingDate dateByAddingTimeInterval:self.requestDuration*60];
}

- (void)initializeTimetableFromArray:(NSArray<NSDictionary*> *)departures mergeData:(BOOL)merge date:(NSDate *)loadingDate {
    self.loadingDate = loadingDate;
    __block NSMutableArray *addedDepartures = [NSMutableArray new];
    [departures enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *depDict = obj;
        if (nil != depDict) {
            NSError *jsonError = nil;
            HafasDeparture *departure = [MTLJSONAdapter modelOfClass:[HafasDeparture class] fromJSONDictionary:depDict error:&jsonError];
            if (!jsonError) {
                
                [departure cleanupName];
                
                
                BOOL filterOutDeparture = NO;
                if(self.opnvStationForFiltering && departure.productCategory != HAFASProductCategoryNONE && departure.productName){
                    if([self.opnvStationForFiltering isFilteredProduct:departure.productCategory withLine:departure.productName]){
                        filterOutDeparture = YES;
                    }
                }
                if(!filterOutDeparture){
                    [addedDepartures addObject:departure];
                }
            } else {
                //NSLog(@"Error creating HafasDeparture: %@", [jsonError localizedDescription]);
            }
        }
    }];
    
    self.departureStops = addedDepartures;
}

- (NSArray*) availableTransportTypes
{
    NSMutableArray *transportTypesArray = [NSMutableArray array];
    for (NSDictionary *stop in self.departureStops) {
        NSString *cat = [stop valueForKey:@"trainCategory"];
        cat = [cat uppercaseString];
        if (cat != nil) {
            if (![transportTypesArray containsObject:cat]) {
                [transportTypesArray addObject:cat];
            }
        }
    }
    
    transportTypesArray = [[transportTypesArray sortedArrayUsingComparator:^(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];
    }] mutableCopy];
    
    [transportTypesArray insertObject:@"Alle" atIndex:0];
    
    return transportTypesArray;
}


@end
