// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBServiceCell.h"
#import "MBService.h"

#import "MBContactInfoView.h"
#import "RIMapPoi.h"
#import "MBEinkaufsbahnhofStore.h"
#import "MBEinkaufsbahnhofCategory.h"

#define kTopPadding 20
#define kLeftPadding 36

@interface MBServiceCell()<MBDetailViewDelegate>

@property (nonatomic, strong) MBLabel *cellTitle;
@property (nonatomic, strong) UIImageView *cellIcon;
@property (nonatomic, strong) UILabel *opencloseLabel;
@property (nonatomic, strong) UIImageView *opencloseImage;


// back view is a bit smaller than the cell
@property (nonatomic, strong) UIView *backView;
// always visible view contains title and opening info and has a shadow
@property (nonatomic, strong) UIView *topView;
// only visible in expanded view, contains detail information
@property (nonatomic, strong) UIView *bottomView;

@end

@implementation MBServiceCell

- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self configureCell];
    }
    return self;
}

- (void) configureCell
{
    
    self.backgroundColor = [UIColor clearColor];

    self.backView = [UIView new];
    
    self.topView = [UIView new];
    self.topView.backgroundColor = [UIColor whiteColor];

    self.bottomView = [UIView new];
    self.bottomView.backgroundColor = [UIColor whiteColor];
    
    self.cellTitle = [[MBLabel alloc] init];
    
    self.cellIcon = [[UIImageView alloc] init];
    
    self.opencloseImage = [UIImageView new];

    self.opencloseLabel = [UILabel new];
    
    self.cellTitle.textAlignment = NSTextAlignmentLeft;
    self.cellTitle.font = [UIFont db_BoldSixteen];
    self.cellTitle.textColor = [UIColor db_333333];
    self.opencloseLabel.textAlignment = NSTextAlignmentLeft;
    self.opencloseLabel.font = [UIFont db_RegularFourteen];
    self.opencloseLabel.isAccessibilityElement = NO;
    
    [self.topView addSubview:self.cellIcon];
    [self.topView addSubview:self.cellTitle];
    [self.topView addSubview:self.opencloseLabel];
    [self.topView addSubview:self.opencloseImage];

    self.topView.layer.shadowOffset = CGSizeMake(1.0, 2.0);
    self.topView.layer.shadowColor = [[UIColor db_dadada] CGColor];
    self.topView.layer.shadowRadius = 1.5;
    self.topView.layer.shadowOpacity = 1.0;

    self.bottomView.layer.shadowOffset = CGSizeMake(1.0, 2.0);
    self.bottomView.layer.shadowColor = [[UIColor db_dadada] CGColor];
    self.bottomView.layer.shadowRadius = 1.5;
    self.bottomView.layer.shadowOpacity = 1.0;

    self.contactAddonView = [UIView new];
    self.contactAddonView.backgroundColor = [UIColor whiteColor];
    self.contactAddonView.layer.shadowOffset = CGSizeMake(1.0, 2.0);
    self.contactAddonView.layer.shadowColor = [[UIColor db_dadada] CGColor];
    self.contactAddonView.layer.shadowRadius = 1.5;
    self.contactAddonView.layer.shadowOpacity = 1.0;
    
    [self.contentView addSubview:self.backView];
    [self.backView addSubview:self.topView];
    [self.backView addSubview:self.bottomView];
    [self.backView addSubview:self.contactAddonView];
    
    self.isAccessibilityElement = NO;
    self.topView.isAccessibilityElement = NO;
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


- (void)setStaticServiceView:(MBStaticServiceView *)staticServiceView {
    [_staticServiceView removeFromSuperview];
    _staticServiceView = staticServiceView;
    if (nil != staticServiceView) {
        [self.bottomView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.bottomView addSubview:_staticServiceView];
    }
}

-(void)setItem:(id)item andCategory:(id)category{
    self.itemCategory = category;
    [self setItem:item];
}

- (void)setItem:(id)item {
    _item = item;
    ShopOpenState openState = POI_UNKNOWN;
    
    if([self.item isKindOfClass:[MBEinkaufsbahnhofStore class]]){
        MBEinkaufsbahnhofStore* venue = (MBEinkaufsbahnhofStore*)self.item;
        self.cellTitle.text = venue.name;
        MBEinkaufsbahnhofCategory* cat = (MBEinkaufsbahnhofCategory*)_itemCategory;
        self.cellIcon.image = cat.icon;
        openState = venue.isOpen;
    } else if([self.item isKindOfClass:[RIMapPoi class]]){
        RIMapPoi* venue = (RIMapPoi*) self.item;
        self.cellTitle.text = venue.name;
        self.cellIcon.image = [MBEinkaufsbahnhofCategory menuIconForCategoryTitle:[RIMapPoi mapPXRToShopCategory:venue]];//until PXR delivers icons for shops we use the category icon
        openState = venue.hasOpeningInfo ? (venue.isOpen ? POI_OPEN : POI_CLOSED ) : POI_UNKNOWN;
    } else {
        MBService *service = (MBService *)self.item;
        self.cellTitle.text = service.title;
        self.cellIcon.image = [service iconForType];
    }
    self.opencloseImage.hidden = NO;
    self.opencloseLabel.hidden = NO;
    if (openState == POI_OPEN) {
        self.opencloseLabel.text = @"Geöffnet";
        self.opencloseLabel.textColor = [UIColor db_76c030];
        self.opencloseImage.image = [UIImage db_imageNamed:@"app_check"];
    } else if(openState == POI_CLOSED) {
        self.opencloseLabel.text = @"Geschlossen";
        self.opencloseLabel.textColor = [UIColor db_mainColor];
        self.opencloseImage.image = [UIImage db_imageNamed:@"app_kreuz"];
    } else {
        self.opencloseImage.hidden = YES;
        self.opencloseLabel.hidden = YES;
    }
    //[self.cellTitle sizeToFit];
    [self.opencloseLabel sizeToFit];
    
    [self configureVoiceOver];
}

-(void)updateStateAfterExpandChange{
    self.bottomView.hidden = !self.expanded;
    if(self.contactAddonView.subviews.count > 0 && self.expanded){
        self.contactAddonView.hidden = NO;
    } else {
        self.contactAddonView.hidden = YES;
    }
    [self configureVoiceOver];
    
}

-(void)configureVoiceOver{
    if(!self.opencloseLabel.hidden){
        self.cellTitle.accessibilityLabel = [NSString stringWithFormat:@"%@, %@.",self.cellTitle.text,self.opencloseLabel.text];
    } else {
        self.cellTitle.accessibilityLabel = self.cellTitle.text;
    }
    if(self.expanded){
        self.cellTitle.accessibilityTraits = UIAccessibilityTraitButton|UIAccessibilityTraitSelected;
    } else {
        self.cellTitle.accessibilityTraits = UIAccessibilityTraitButton;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    NSInteger bottomViewHeight = 0;
    if (nil != self.staticServiceView) {
        [self.staticServiceView layoutForSize:self.frame.size.width];
        bottomViewHeight = self.staticServiceView.frame.size.height;
    }
    if (nil != self.shopDetailView) {
        [self.shopDetailView layoutForSize:self.frame.size.width];
        [(MBContactInfoView *)[self.contactAddonView.subviews lastObject] updateButtonConstraints];
        bottomViewHeight = self.shopDetailView.frame.size.height;
    }

    self.backView.frame = CGRectMake(8,8,self.sizeWidth-2*8, self.sizeHeight-2*8);
    self.topView.frame = CGRectMake(0, 0, self.backView.sizeWidth, 80);
    self.cellIcon.frame = CGRectMake(36, 20, 40, 40);
    NSInteger y = 13;
    if(self.opencloseImage.hidden){
        y += 10;
    }
    self.cellTitle.frame = CGRectMake(CGRectGetMaxX(self.cellIcon.frame)+33, y, self.backView.sizeWidth-(CGRectGetMaxX(self.cellIcon.frame)+33)-8, 24);
    y = CGRectGetMaxY(self.cellTitle.frame)+2;
    self.opencloseImage.frame = CGRectMake(CGRectGetMaxX(self.cellIcon.frame)+30, y, 24, 24);
    self.opencloseLabel.frame = CGRectMake(CGRectGetMaxX(self.opencloseImage.frame)+4,y,self.backView.sizeWidth-(CGRectGetMaxX(self.opencloseImage.frame)+4),24);
    
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
    self.cellIcon.image = nil;
    self.opencloseImage.image = nil;
    self.opencloseLabel.text = nil;
    self.expanded = NO;
    [_shopDetailView removeFromSuperview];
    [_staticServiceView removeFromSuperview];
    self.shopDetailView = nil;
    self.staticServiceView = nil;
    [self.contactAddonView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
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
