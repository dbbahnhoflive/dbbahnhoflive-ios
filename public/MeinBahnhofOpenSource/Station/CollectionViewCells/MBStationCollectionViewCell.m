// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBStationCollectionViewCell.h"
#import "UIColor+DBColor.h"
@interface MBStationCollectionViewCell()

@end

@implementation MBStationCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    self.backgroundColor = [UIColor whiteColor];

    self.layer.shadowColor = [[UIColor db_dadada] CGColor];
    self.layer.shadowOffset = CGSizeMake(3.0, 3.0);
    self.layer.shadowRadius = 3.0;
    self.layer.shadowOpacity = 1.0;
    
    return self;
}

@end
