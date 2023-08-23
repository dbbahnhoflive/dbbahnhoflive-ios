// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "DBSwitch.h"
#import "UIColor+DBColor.h"

@implementation DBSwitch

-(instancetype)init{
    self = [super init];
    if(self){
        [self globalInit];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        [self globalInit];
    }
    return self;
}


-(void)globalInit{
    self.backgroundColor = UIColor.db_switchOff;
    self.layer.cornerRadius = 16.0;
    self.onTintColor = UIColor.db_switchOn;
}

@end
