// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBCouponTableViewCell.h"
#import "MBLabel.h"
#import "MBCouponCategory.h"
#import "MBUrlOpening.h"
#import "MBUIHelper.h"
#import "MBTrackingManager.h"

@interface MBCouponTableViewCell()

@property (nonatomic, strong) MBLabel* contentDetailsLabel;
@property (nonatomic, strong) UIImageView *contentImage;
@property (nonatomic, strong) UIButton *contentLinkButton;

@end

@implementation MBCouponTableViewCell


- (void) configureCell
{
    [super configureCell];


    
    self.contentImage = [[UIImageView alloc] init];
    self.contentImage.contentMode = UIViewContentModeScaleAspectFit;
    [self.bottomView addSubview:self.contentImage];
    
    self.contentDetailsLabel = [[MBLabel alloc] init];
    self.contentDetailsLabel.numberOfLines = 0;
    self.contentDetailsLabel.textAlignment = NSTextAlignmentLeft;
    self.contentDetailsLabel.font = [UIFont db_RegularFourteen];;
    self.contentDetailsLabel.textColor = [UIColor db_333333];
    [self.bottomView addSubview:self.contentDetailsLabel];
    
    UIButton* button = [[UIButton alloc] init];
    self.contentLinkButton = button;
    [self.bottomView addSubview:button];
    [button setTitle:@"Mehr Informationen" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(didTapOnButton:) forControlEvents:UIControlEventTouchUpInside];
    button.backgroundColor = [UIColor db_GrayButton];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont db_BoldEighteen]];
    button.height = 60;
    button.layer.cornerRadius = button.frame.size.height / 2.0;
    [button configureDefaultShadow];
}

-(void)didTapOnButton:(id)sender{
    [MBTrackingManager trackActionsWithStationInfo:@[@"d1",@"tap",@"rabatt_coupons",@"link"]];
    [MBUrlOpening openURL:[NSURL URLWithString:self.newsItem.link]];
}


-(void)layoutSubviews{
    [super layoutSubviews];
    
    [self.cellIcon setGravityLeft:35];
    [self.cellIcon centerViewVerticalInSuperView];
    self.cellTitle.frame = CGRectMake(0, 18, 0, 20);
    [self.cellTitle setRight:self.cellIcon withPadding:26];
    NSInteger w = self.topView.frame.size.width-16-self.cellTitle.originX;
    [self.cellTitle setWidth:w];
    self.cellSubTitle.frame = CGRectMake(self.cellTitle.originX, CGRectGetMaxY(self.cellTitle.frame)+2, w, 20);
    
    CGSize size = [self.contentDetailsLabel sizeThatFits:CGSizeMake(self.frame.size.width-2*8-2*20, 5000)];
    self.contentDetailsLabel.frame = CGRectMake(20, 30, ceilf(size.width), ceilf(size.height));
    NSInteger bottomHeight = CGRectGetMaxY(self.contentDetailsLabel.frame)+20;
    if(self.contentImage.image){
        //is this too large?
        NSInteger maxW = ceilf(size.width);
        if(self.contentImage.frame.size.width > maxW){
            [self.contentImage setSize:CGSizeMake(maxW, (self.contentImage.image.size.height/self.contentImage.image.size.width)*maxW)];
        }
        [self.contentImage centerViewHorizontalInSuperView];
        [self.contentImage setBelow:self.contentDetailsLabel withPadding:20];
        bottomHeight = CGRectGetMaxY(self.contentImage.frame)+20;
    }
    if(!self.contentLinkButton.hidden){
        self.contentLinkButton.width = self.bottomView.frame.size.width-16*2;
        [self.contentLinkButton setGravityTop:bottomHeight];
        [self.contentLinkButton centerViewHorizontalInSuperView];
        bottomHeight = CGRectGetMaxY(self.contentLinkButton.frame)+20;
    }

    self.bottomView.frame = CGRectMake(0,  CGRectGetMaxY(self.topView.frame)+4, self.frame.size.width-2*8, bottomHeight);

}

-(NSInteger)expandableHeight{
    return self.bottomView.frame.size.height+4;
}


-(void)setNewsItem:(MBNews *)newsItem{
    _newsItem = newsItem;
    self.cellTitle.text = newsItem.title;
    self.cellSubTitle.text = newsItem.content;
    self.contentDetailsLabel.text = newsItem.content;
    self.cellIcon.image = [MBCouponCategory image];
    [self.cellIcon setSize:self.cellIcon.image.size];
    self.contentImage.image = newsItem.image;
    [self.contentImage setSize:self.contentImage.image.size];
    self.contentLinkButton.hidden = !self.newsItem.hasLink;
    [self setNeedsLayout];
}

@end
