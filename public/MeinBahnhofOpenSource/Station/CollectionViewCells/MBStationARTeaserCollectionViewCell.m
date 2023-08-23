// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBStationARTeaserCollectionViewCell.h"
#import "MBARAppTeaserView.h"
#import "UIView+Frame.h"

@interface MBStationARTeaserCollectionViewCell()
@property(nonatomic,strong) MBARAppTeaserView* content;
@end

@implementation MBStationARTeaserCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self){
        self.backgroundColor = [UIColor whiteColor];
        self.content = [MBARAppTeaserView new];
        [self.contentView addSubview:self.content];
    }
    return self;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    self.content.frame = CGRectMake(0, 0, self.sizeWidth, self.sizeHeight);
}


@end
