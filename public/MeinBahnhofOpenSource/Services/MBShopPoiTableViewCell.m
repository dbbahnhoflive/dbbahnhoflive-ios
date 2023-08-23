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
@property (nonatomic, strong) UILabel *opencloseLabel;
@property (nonatomic, strong) MBStatusImageView *opencloseImage;

@end

@implementation MBShopPoiTableViewCell

- (void) configureCell
{
    [super configureCell];
    
    self.opencloseImage = [MBStatusImageView new];

    self.opencloseLabel = [UILabel new];
    
    self.opencloseLabel.textAlignment = NSTextAlignmentLeft;
    self.opencloseLabel.font = [UIFont db_RegularFourteen];
    self.opencloseLabel.isAccessibilityElement = NO;
    
    [self.topView addSubview:self.opencloseLabel];
    [self.topView addSubview:self.opencloseImage];

    self.contactAddonView = [UIView new];
    self.contactAddonView.backgroundColor = [UIColor whiteColor];
    [self.contactAddonView configureDefaultShadow];
    [self.backView addSubview:self.contactAddonView];

}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if(self.opencloseImage.hidden){
        [self.cellTitle centerViewVerticalWithView:self.cellIcon];
    } else {
        [self.cellTitle setY:13];
    }
    NSInteger bottomViewHeight = 0;
    if (nil != self.shopDetailView) {
        [self.shopDetailView layoutForSize:self.frame.size.width];
        [(MBContactInfoView *)[self.contactAddonView.subviews lastObject] updateButtonConstraints];
        bottomViewHeight = self.shopDetailView.frame.size.height;
    }
    self.bottomView.frame = CGRectMake(0, 80+4, self.backView.sizeWidth, bottomViewHeight);

    NSInteger y = CGRectGetMaxY(self.cellTitle.frame)+2;
    self.opencloseImage.frame = CGRectMake(CGRectGetMaxX(self.cellIcon.frame)+30, y, 24, 24);
    self.opencloseLabel.frame = CGRectMake(CGRectGetMaxX(self.opencloseImage.frame)+4,y,self.backView.sizeWidth-(CGRectGetMaxX(self.opencloseImage.frame)+4),24);

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

-(void)configureVoiceOver{
    [super configureVoiceOver];
    if(!self.opencloseLabel.hidden){
        self.cellTitle.accessibilityLabel = [NSString stringWithFormat:@"%@, %@.",self.cellTitle.text,self.opencloseLabel.text];
    }
}

-(void)setPoiItem:(RIMapPoi *)poiItem{
    _poiItem = poiItem;
    ShopOpenState openState = POI_UNKNOWN;
    self.cellTitle.text = poiItem.name;
    self.cellIcon.image = [MBPXRShopCategory menuIconForCategoryTitle:[RIMapPoi mapPXRToShopCategory:poiItem]];//until PXR delivers icons for shops we use the category icon
    openState = poiItem.hasOpeningInfo ? (poiItem.isOpen ? POI_OPEN : POI_CLOSED ) : POI_UNKNOWN;
    self.cellTitle.numberOfLines = 1;
    [self configureCellForItemWithOpenState:openState];
}

-(void)configureCellForItemWithOpenState:(ShopOpenState)openState{
    self.opencloseImage.hidden = NO;
    self.opencloseLabel.hidden = NO;
    if (openState == POI_OPEN) {
        self.opencloseLabel.text = @"Geöffnet";
        self.opencloseLabel.textColor = [UIColor db_green];
        [self.opencloseImage setStatusActive];
    } else if(openState == POI_CLOSED) {
        self.opencloseLabel.text = @"Geschlossen";
        self.opencloseLabel.textColor = [UIColor db_mainColor];
        [self.opencloseImage setStatusInactive];
    } else {
        self.opencloseImage.hidden = YES;
        self.opencloseLabel.hidden = YES;
    }
    [self.opencloseLabel sizeToFit];
    
    [self configureVoiceOver];
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
