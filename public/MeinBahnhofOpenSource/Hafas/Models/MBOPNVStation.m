// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBOPNVStation.h"
#import "HafasRequestManager.h"

@interface MBOPNVStation ()

@property(nonatomic,strong) NSDictionary* data;


@property(nonatomic,strong) NSMutableArray<NSNumber*>* productsAtStopDeparting;
@property(nonatomic,strong) NSMutableArray<NSMutableArray<NSString*>*>* productsLinesAtStopDeparting;

@property(nonatomic,strong) NSMutableArray<NSNumber*>* filteredProducts;
@property(nonatomic,strong) NSMutableArray<NSMutableArray<NSString*>*>* filteredLinesForFilteredProducts;



@end

@implementation MBOPNVStation

- (instancetype)initWithDict:(NSDictionary*)dict
{
    self = [super init];
    if (self) {
        self.data = dict;
        _name = dict[@"name"];
        _stationId = dict[@"id"];
        _extId = dict[@"extId"];
        [self processProducts];
        self.filteredProducts = [NSMutableArray arrayWithCapacity:5];
        self.filteredLinesForFilteredProducts = [NSMutableArray arrayWithCapacity:20];
    }
    return self;
}

+(instancetype)stationWithId:(NSString *)idString name:(NSString *)name{
    MBOPNVStation* res = [[MBOPNVStation alloc] initWithDict:@{@"id":idString, @"name":name}];
    return res;
}

-(void)removeDuplicateLinesFrom:(MBOPNVStation*)otherStation{
    if(otherStation == self){
        NSLog(@"ERROR: removeDuplicateLinesFrom called with self");
        return;
    }
    //NSLog(@"removeDuplicateLinesFrom in %@ with %@",self.name,otherStation.name);
    NSInteger i=0;
    for(NSNumber* productOther in otherStation.productsAtStopDeparting){
        NSArray<NSString*>* linesOther = otherStation.productsLinesAtStopDeparting[i];
        NSInteger k=0;
        for(NSNumber* product in self.productsAtStopDeparting){
            if([product isEqualToNumber:productOther]){
                NSMutableArray<NSString*>* lines = self.productsLinesAtStopDeparting[k];
                //compare the line ids
                for(NSString* line in linesOther){
                    if([lines containsObject:line]){
                        //the other station has a line that we need to filter out in self.
                        //we move the line from productsLinesAtStopDeparting to filteredLinesForFilteredProducts
                        [lines removeObject:line];
                        //NSLog(@"removed a line: %@",line);
                        NSMutableArray<NSString*>* filteredLines = [self filteredLinesForProduct:product];
                        if(!filteredLines){
                            //this product was not yet filtered, create the entry
                            [self.filteredProducts addObject:product];
                            [self.filteredLinesForFilteredProducts addObject:[NSMutableArray arrayWithCapacity:20]];
                            filteredLines = [self filteredLinesForProduct:product];
                            if(!filteredLines){
                                NSLog(@"ERROR: created line array for filteredLines not found");
                            }
                        }
                        [filteredLines addObject:line];
                    }
                }
            }
            k++;
        }
        i++;
    }
    //cleanup: remove products for empty lines array
    for(i=self.productsAtStopDeparting.count-1; i>=0; i--){
        NSArray<NSString*>* lines = self.productsLinesAtStopDeparting[i];
        if(lines.count == 0){
            [self.productsLinesAtStopDeparting removeObjectAtIndex:i];
            [self.productsAtStopDeparting removeObjectAtIndex:i];
        }
    }
}
-(NSMutableArray<NSString*>*)filteredLinesForProduct:(NSNumber*)product{
    NSInteger i=0;
    for(NSNumber* p in self.filteredProducts){
        if([p isEqualToNumber:product]){
            return self.filteredLinesForFilteredProducts[i];
        }
    }
    //not found
    return nil;
}

-(void)processProducts{
    //get the products at this station, we only expect ranges in S-Call
    self.productsAtStopDeparting = [NSMutableArray arrayWithCapacity:6];
    self.productsLinesAtStopDeparting = [NSMutableArray arrayWithCapacity:6];
    //NOTE: group callable is not included here!
    for(NSUInteger product = HAFASProductCategoryS; product < HAFASProductCategoryCAL; product = product<<1){
        //NSLog(@"iterate over products %lu",(unsigned long)product);
        NSMutableArray* lineCodes = [[self lineCodesForProduct:product] mutableCopy];
        if(lineCodes.count > 0){
            [self.productsAtStopDeparting addObject:[NSNumber numberWithUnsignedInteger:product]];
            [self.productsLinesAtStopDeparting addObject:lineCodes];
        }
    }
}

-(NSArray<NSNumber*>*)departingProducts{
    return self.productsAtStopDeparting;
}
-(NSArray<NSString*>*)productLinesForProduct:(NSInteger)index{
    return self.productsLinesAtStopDeparting[index];
}

-(BOOL)hasProducts{
    return [self departingProducts].count > 0;
}

-(BOOL)isFilteredProduct:(HAFASProductCategory)cat withLine:(NSString*)lineId{
    NSInteger i=0;
    //NSLog(@"isFilteredProduct: %lu withLine: %@ in %@",(unsigned long)cat,lineId,self.filteredProducts);
    for(NSNumber* product in self.filteredProducts){
        if(product.integerValue == cat){
            NSArray* lines = self.filteredLinesForFilteredProducts[i];
            //NSLog(@"found product by cat, lines: %@",lines);
            if([lines containsObject:lineId]){
                //NSLog(@"YES; FILTER IT!");
                return YES;
            }
        }
    }
    //NSLog(@"not filtered, is this product expected here? %@ with %@ ",self.productsAtStopDeparting,self.productsLinesAtStopDeparting);
    for(NSArray* lines in self.productsLinesAtStopDeparting){
        if([lines containsObject:lineId]){
            //we expected this product and its not filtered
            return NO;
        }
    }
    //NSLog(@"not expected product filtered!");
    return YES;
}

-(CLLocationCoordinate2D)coordinate{
    double lon = [[self.data valueForKey:@"lon"] doubleValue];
    double lat = [[self.data valueForKey:@"lat"] doubleValue];
    if(![self.data valueForKey:@"lon"] || ![self.data valueForKey:@"lat"]){
        return kCLLocationCoordinate2DInvalid;
    }
    CLLocationCoordinate2D position = CLLocationCoordinate2DMake(lat, lon);
    return position;
}

-(double)distanceInKM{
    double distanceInKm = [[self.data valueForKey:@"dist"] doubleValue] / 1000.0;
    return distanceInKm;
}
-(NSInteger)distanceInM{
    NSInteger dist = [self.data[@"dist"] integerValue];
    return dist;
}


-(NSArray<NSString*>*)lineCodesForProduct:(HAFASProductCategory)product{
    NSMutableArray* lineCodes = [NSMutableArray arrayWithCapacity:20];
    NSArray* productsAtStop = self.data[@"productAtStop"];
    if([productsAtStop isKindOfClass:NSArray.class]){
        for(NSDictionary* dict in productsAtStop){
            if([dict isKindOfClass:NSDictionary.class]){
                NSString* catCode = dict[@"cls"];
                if([catCode isKindOfClass:NSString.class]){
                    if(catCode.integerValue == product){
                        NSString* lineId = dict[@"name"];//was "lineId"
                        if([lineId isKindOfClass:NSString.class] && lineId.length > 0){
                            [lineCodes addObject:lineId];
                        }
                    }
                }
            }
        }
    }
    [lineCodes sortUsingComparator:^NSComparisonResult(NSString* _Nonnull obj1, NSString* _Nonnull obj2) {
        return [obj1 compare:obj2 options:NSCaseInsensitiveSearch|NSNumericSearch];
    }];
    return lineCodes;
}

-(BOOL)hasProductsInRangeICEtoS{
    //filter out hafas-stations that contain a product 0-4 (ICE...s-train)
    //NOTE that this works only with a response from the requestStopsForSearchterm:
    /*if(([self.data[@"products"] integerValue] & HAFAS_NONLOCAL_BITMASK) != 0){
        return YES;
    }*/
    
    
    
    for(NSNumber* product in self.productsAtStopDeparting){
        if(product.unsignedIntValue == HAFASProductCategoryS
           || product.unsignedIntValue == HAFASProductCategoryICE
           || product.unsignedIntValue == HAFASProductCategoryIC
           || product.unsignedIntValue == HAFASProductCategoryIR
           || product.unsignedIntValue == HAFASProductCategoryREGIO
           ){
            return YES;
        }
    }
    
    return NO;
}


@end


