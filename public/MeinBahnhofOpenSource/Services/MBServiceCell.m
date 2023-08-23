// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBServiceCell.h"
#import "MBService.h"

#import "MBContactInfoView.h"
#import "RIMapPoi.h"
#import "MBUIHelper.h"

#define kTopPadding 20
#define kLeftPadding 36

@interface MBServiceCell()



@end

@implementation MBServiceCell


- (void) configureCell
{
    [super configureCell];

}


- (void)setStaticServiceView:(MBStaticServiceView *)staticServiceView {
    [_staticServiceView removeFromSuperview];
    _staticServiceView = staticServiceView;
    if (nil != staticServiceView) {
        [self.bottomView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.bottomView addSubview:_staticServiceView];
    }
}

- (void)setServiceItem:(MBService *)serviceItem{
    _serviceItem = serviceItem;
    self.displayMultilineTitle = true;
    self.cellTitle.numberOfLines = 2;
    self.cellTitle.text = serviceItem.title;
    self.cellIcon.image = [serviceItem iconForType];
    [self configureVoiceOver];
}

-(void)updateStateAfterExpandChange{
    [super updateStateAfterExpandChange];
    [self configureVoiceOver];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    NSInteger bottomViewHeight = 0;
    if (nil != self.staticServiceView) {
        [self.staticServiceView layoutForSize:self.frame.size.width];
        bottomViewHeight = self.staticServiceView.frame.size.height;
    }
    self.bottomView.frame = CGRectMake(0, 80+4, self.backView.sizeWidth, bottomViewHeight);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [_staticServiceView removeFromSuperview];
    self.staticServiceView = nil;
    _serviceItem = nil;
}



@end
