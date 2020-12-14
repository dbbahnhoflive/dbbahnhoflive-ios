// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import "HafasRequestManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBOPNVStation : NSObject

@property(nonatomic,strong,readonly) NSString* extId;
@property(nonatomic,strong,readonly) NSString* name;
@property(nonatomic,strong,readonly) NSString* stationId;

+ (instancetype)stationWithId:(NSString*)idString name:(NSString*)name;
- (instancetype)initWithDict:(NSDictionary*)dict;
-(BOOL)hasProducts;
-(NSArray<NSNumber*>*)departingProducts;
-(NSArray<NSString*>*)productLinesForProduct:(NSInteger)index;
-(void)removeDuplicateLinesFrom:(MBOPNVStation*)otherStation;

-(BOOL)isFilteredProduct:(HAFASProductCategory)cat withLine:(NSString*)lineId;

-(CLLocationCoordinate2D)coordinate;
-(double)distanceInKM;
-(NSInteger)distanceInM;

-(NSArray<NSString*>*)lineCodesForProduct:(HAFASProductCategory)product;

-(BOOL)hasProductsInRangeICEtoS;

@end

NS_ASSUME_NONNULL_END
