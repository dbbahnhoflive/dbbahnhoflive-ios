// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBStationCollectionViewCell.h"
#import "UIColor+DBColor.h"
#import "UIView+Frame.h"
@interface MBStationCollectionViewCell()

@end

@implementation MBStationCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    self.backgroundColor = [UIColor whiteColor];
    [self configureH1Shadow];
    
    return self;
}

@end
