// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "RIMapSEV.h"
#import "NSDictionary+MBDictionary.h"
@implementation RIMapSEV

-(instancetype)initWithDict:(NSDictionary *)dict{
    self = [super init];
    if(self){
        _text = [dict db_stringForKey:@"text"];
        if(_text.length == 0){
            _text = SEV_TEXT_FALLBACK;
        }
        _coordinate = kCLLocationCoordinate2DInvalid;
        NSDictionary* geometry = [dict db_dictForKey:@"geometry"];
        if([[geometry db_stringForKey:@"type"] isEqualToString:@"Point"]){
            NSArray<NSNumber*>* coordinates = [geometry db_arrayForKey:@"coordinates"];
            if(coordinates.count == 2 && [coordinates.firstObject isKindOfClass:NSNumber.class]
               && [coordinates.lastObject isKindOfClass:NSNumber.class]){
                _coordinate = CLLocationCoordinate2DMake(coordinates.lastObject.doubleValue, coordinates.firstObject.doubleValue);
            }
        }
        _walkDescription = [dict db_stringForKey:@"walkDescription"];
        if(_walkDescription.length == 0 && CLLocationCoordinate2DIsValid(_coordinate)){
            _walkDescription = SEV_WALK_FALLBACK;
        } else {
            //this SEV is not valid, missing coordinate AND missing walkdescription cant be displayed
        }
    }
    return self;
}

-(NSString *)description{
    return [NSString stringWithFormat:@"RIMapSEV<%@>",self.text];
}

-(BOOL)isValid{
    return
    (self.walkDescription.length > 0
    || CLLocationCoordinate2DIsValid(self.coordinate));
}

+(NSArray<NSArray<RIMapSEV *> *> *)groupSEVByWalkDescription:(NSArray<RIMapSEV *> *)inputList{
    if(inputList.count <= 1){
        return @[ inputList ];
    }
    NSMutableArray<NSMutableArray<RIMapSEV*>*>* res = [NSMutableArray arrayWithCapacity:3];
    /*
    //debug test, dont group, put every SEV in its own list
    for(RIMapSEV* sev in inputList){
        [res addObject:@[ sev ]];
    }
    return res;
    */
    for(RIMapSEV* sev in inputList){
        NSMutableArray<RIMapSEV*>* storedList = [self findListWithSEVWalkDescription:sev.walkDescription inList:res];
        if(storedList){
            [storedList addObject:sev];
        } else {
            NSMutableArray<RIMapSEV*>* anotherList = [NSMutableArray arrayWithCapacity:3];
            [anotherList addObject:sev];
            [res addObject:anotherList];
        }
    }
    return res;
}
+(NSMutableArray<RIMapSEV*>* _Nullable)findListWithSEVWalkDescription:(NSString*)walkDescription inList:(NSMutableArray<NSMutableArray<RIMapSEV*>*>*)list{
    for(NSMutableArray* aList in list){
        for(RIMapSEV* sev in aList){
            if([sev.walkDescription isEqualToString:walkDescription]){
                return aList;
            }
        }
    }
    return nil;
}

@end
