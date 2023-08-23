// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBBackNavigationState.h"

@implementation MBBackNavigationState

-(NSString *)description{
    return [NSString stringWithFormat:@"MBBackNavigationState<%@, %@, %f, %@, isOPNVStation=%d>",_mbId,_title,_position.latitude,_evaIds,_isOPNVStation];
}

/**
 @interface MBBackNavigationState : NSObject

 @property (nonatomic, strong) NSNumber *mbId;//station id (stada)
 @property (nonatomic, strong) NSString *title;
 @property (nonatomic) CLLocationCoordinate2D position;
 @property (nonatomic, strong) NSArray<NSString*>* evaIds;

 @property(nonatomic,strong) Stop* _Nullable stop;
 @property(nonatomic,strong) HafasDeparture* _Nullable hafasDeparture;
*/
@end
