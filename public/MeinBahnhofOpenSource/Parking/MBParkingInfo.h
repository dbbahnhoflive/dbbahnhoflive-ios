// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <CoreLocation/CoreLocation.h>

@class MBMarker;

@interface MBParkingInfo : NSObject

+(MBParkingInfo*)parkingInfoFromServerDict:(NSDictionary*)dict;


@property(nonatomic,strong) NSNumber* allocationCategory;//filled via separate api

//helper
-(CLLocationCoordinate2D)location;
-(NSString*)iconForType;
-(MBMarker*)markerForParkingWithSelectable:(BOOL)isSelectable;
-(UIImage*)iconForAllocation;
-(NSString*)textForAllocation;
- (NSString *)shortTextForAllocation;

-(NSString*)equipment;

//-(NSString*)textForStatus;
-(NSString*)maximumParkingTime;
-(NSString*)name;
-(BOOL)isParkHaus;

-(BOOL)hasPrognosis;

-(BOOL)isOutOfOrder;
-(NSString*)outOfOrderText;

-(NSArray<NSArray<NSString*>*>*)tarifPricesList;

-(NSString*)tarifFreeParkTime;


-(NSString*)tarifNotes;
-(NSString*)tarifDiscount;
-(NSString*)tarifSpecial;

-(NSString*)paymentTypes;

-(BOOL)hasParkingReservation;

-(NSString*)accessDescription;
-(NSString*)accessDetailsDay;
-(NSString*)accessDetailsNight;
-(NSString*)openingTimes;
-(NSString*)typeOfParking;
-(NSString*)distanceToStation;
-(NSString*)technology;//??

-(NSString*)numberOfParkingSpaces;
-(NSString*)numberOfParkingSpacesHandicapped;
-(NSString*)numberOfParkingSpacesParentChild;
-(NSString*)numberOfParkingSpacesWoman;


-(NSString*)operatorCompany;

-(NSString*)idValue;

@end
