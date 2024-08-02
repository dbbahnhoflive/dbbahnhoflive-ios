// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBShopPoiTableViewCell.h"
#import "UIColor+DBColor.h"
#import "UIFont+DBFont.h"
#import "UIImage+MBImage.h"
#import "UIView+Frame.h"
#import "MBContactInfoView.h"
#import "MBStatusImageView.h"

@interface MBShopPoiTableViewCell()<MBDetailViewDelegate>

@end

@implementation MBShopPoiTableViewCell

- (void) configureCell
{
    [super configureCell];

    self.contactAddonView = [UIView new];
    self.contactAddonView.backgroundColor = [UIColor whiteColor];
    [self.contactAddonView configureDefaultShadow];
    [self.backView addSubview:self.contactAddonView];

}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    NSInteger bottomViewHeight = 0;
    if (nil != self.shopDetailView) {
        [self.shopDetailView layoutForSize:self.frame.size.width];
        [(MBContactInfoView *)[self.contactAddonView.subviews lastObject] updateButtonConstraints];
        bottomViewHeight = self.shopDetailView.frame.size.height;
    }
    self.bottomView.frame = CGRectMake(0, 80+4, self.backView.sizeWidth, bottomViewHeight);


    if(self.contactAddonView.subviews > 0){
        self.contactAddonView.frame = CGRectMake(0, CGRectGetMaxY(self.bottomView.frame)+4, self.backView.sizeWidth, 105 );
        UIView* btns = self.contactAddonView.subviews.lastObject;
        btns.frame = CGRectMake(0, 0, self.contactAddonView.sizeWidth, self.contactAddonView.sizeHeight);
    } else {
        self.contactAddonView.frame = CGRectZero;
    }

}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.opencloseImage.image = nil;
    self.opencloseLabel.text = nil;
    [_shopDetailView removeFromSuperview];
    self.shopDetailView = nil;
    [self.contactAddonView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _poiItem = nil;

}

-(void)updateStateAfterExpandChange{
    [super updateStateAfterExpandChange];
    if(self.contactAddonView.subviews.count > 0 && self.expanded){
        self.contactAddonView.hidden = NO;
    } else {
        self.contactAddonView.hidden = YES;
    }
    [self configureVoiceOver];
}

- (void)setShopDetailView:(MBShopDetailCellView *)shopDetailView {
    [_shopDetailView removeFromSuperview];
    _shopDetailView = shopDetailView;
    if (nil != shopDetailView) {
        [self.bottomView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.bottomView addSubview:_shopDetailView];
        // handle contact info, if available
        if (shopDetailView.hasContactLinks) {
            [[[self.contactAddonView subviews] lastObject] removeFromSuperview];
            MBContactInfoView *contact = [[MBContactInfoView alloc] initWithExtraField:shopDetailView.contactLinks];
            contact.delegate = self;
            [self.contactAddonView addSubview:contact];
            
        }
    }
    [self configureVoiceOver];
}

-(void)setPoiItem:(RIMapPoi *)poiItem{
    _poiItem = poiItem;
    ShopOpenState openState = POI_UNKNOWN;
    self.cellTitle.text = poiItem.name;
    self.cellIcon.image = [MBPXRShopCategory menuIconForCategoryTitle:[RIMapPoi mapPXRToShopCategory:poiItem]];//until PXR delivers icons for shops we use the category icon
    openState = poiItem.hasOpeningInfo ? (poiItem.isOpen ? POI_OPEN : POI_CLOSED ) : POI_UNKNOWN;
    [self configureCellForItemWithOpenState:openState];
}



#pragma mark MBDetailViewDelegate
- (void) didOpenUrl:(NSURL*)url {
    [self.delegate didOpenUrl:url];
}
- (void) didTapOnPhoneLink:(NSString*)phoneNumber {
    [self.delegate didTapOnPhoneLink:phoneNumber];
}
- (void) didTapOnEmailLink:(NSString*)mailAddress {
    [self.delegate didTapOnEmailLink:mailAddress];
}

@end
