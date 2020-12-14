// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "RIMapMetaData.h"

@implementation RIMapMetaData

-(instancetype)init{
    self = [super init];
    if(self){
        self.coordinate = kCLLocationCoordinate2DInvalid;
    }
    return self;
}

@end
