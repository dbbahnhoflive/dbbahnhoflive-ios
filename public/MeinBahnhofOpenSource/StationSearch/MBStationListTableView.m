// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBStationListTableView.h"
#import "MBTriangleView.h"

@implementation MBStationListTableView

-(instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style{
    self = [super initWithFrame:frame style:style];
    if(self){
        self.triangleView = [[MBTriangleView alloc] initWithFrame:CGRectMake(0, 0, 16, 8)];
        [self addSubview:self.triangleView];
    }
    return self;
}

@end
