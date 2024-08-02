// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBExpandableTableViewCell.h"
#import "UIColor+DBColor.h"
#import "UIFont+DBFont.h"
#import "UIView+Frame.h"

@implementation MBExpandableTableViewCell

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
    self.topView = [UIView new];
    self.topView.backgroundColor = [UIColor whiteColor];
    [self.topView configureDefaultShadow];
    
    [self.contentView addSubview:self.topView];
    
    self.bottomView = [UIView new];
    self.bottomView.userInteractionEnabled = true;
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self.bottomView addGestureRecognizer:tap];
    self.bottomView.backgroundColor = [UIColor whiteColor];
    [self.bottomView configureDefaultShadow];
    
    [self.contentView addSubview:self.bottomView];
    
    self.cellIcon = [[UIImageView alloc] init];
    [self.topView addSubview:self.cellIcon];
    
    self.cellTitle = [[MBLabel alloc] init];
    self.cellTitle.textAlignment = NSTextAlignmentLeft;
    self.cellTitle.font = [UIFont db_BoldSixteen];
    self.cellTitle.textColor = [UIColor db_333333];
    [self.topView addSubview:self.cellTitle];
    
    self.cellSubTitle = [[MBLabel alloc] init];
    self.cellSubTitle.textAlignment = NSTextAlignmentLeft;
    self.cellSubTitle.font = [UIFont db_RegularFourteen];;
    self.cellSubTitle.textColor = [UIColor db_333333];
    [self.topView addSubview:self.cellSubTitle];
    
    self.backView = [UIView new];
    [self.contentView addSubview:self.backView];
    [self.backView addSubview:self.topView];
    [self.backView addSubview:self.bottomView];
    
    self.isAccessibilityElement = NO;
    self.topView.isAccessibilityElement = NO;
    
    self.opencloseImage = [MBStatusImageView new];

    self.opencloseLabel = [UILabel new];
    
    self.opencloseLabel.textAlignment = NSTextAlignmentLeft;
    self.opencloseLabel.font = [UIFont db_RegularFourteen];
    self.opencloseLabel.isAccessibilityElement = NO;
    
    [self.topView addSubview:self.opencloseLabel];
    [self.topView addSubview:self.opencloseImage];

    self.opencloseImage.hidden = true;
    self.opencloseLabel.hidden = true;
}

-(void)tap:(UITapGestureRecognizer*)tap{
    //no action: we installed a tap gesture on the bottom view to ensure that taps on this area don't trigger the "didSelectCell" and close an expanded view
}

-(void)configureCellForItemWithOpenState:(ShopOpenState)openState{
    [self configureCellForItemWithOpenState:openState openText:@"Geöffnet" closeText:@"Geschlossen"];
}

-(void)configureCellForItemWithOpenState:(ShopOpenState)openState openText:(NSString*)openText closeText:(NSString*)closeText{
    self.opencloseImage.hidden = NO;
    self.opencloseLabel.hidden = NO;
    if (openState == POI_OPEN) {
        self.cellTitle.numberOfLines = 1;
        self.opencloseLabel.text = openText;
        self.opencloseLabel.textColor = [UIColor db_green];
        [self.opencloseImage setStatusActive];
    } else if(openState == POI_CLOSED) {
        self.cellTitle.numberOfLines = 1;
        self.opencloseLabel.text = closeText;
        self.opencloseLabel.textColor = [UIColor db_mainColor];
        [self.opencloseImage setStatusInactive];
    } else {
        self.cellTitle.numberOfLines = 2;
        self.opencloseImage.hidden = YES;
        self.opencloseLabel.hidden = YES;
    }
    [self.opencloseLabel sizeToFit];
    
    [self configureVoiceOver];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.backView.frame = CGRectMake(8,8,self.sizeWidth-2*8, self.sizeHeight-2*8);
    self.topView.frame = CGRectMake(0, 0, self.backView.sizeWidth, 80);
    self.cellIcon.frame = CGRectMake(36, 20, 40, 40);
    NSInteger y = 23;
    NSInteger x = CGRectGetMaxX(self.cellIcon.frame)+33;
    if(self.displayMultilineTitle){
        CGSize size = [self.cellTitle sizeThatFits:CGSizeMake(self.backView.sizeWidth-x-25, 2*24)];
        self.cellTitle.frame = CGRectMake(x, y, size.width, size.height);
    } else {
        self.cellTitle.frame = CGRectMake(x, y, self.backView.sizeWidth-(CGRectGetMaxX(self.cellIcon.frame)+33)-8, 24);
    }
    if(self.opencloseImage.hidden){
        [self.cellTitle centerViewVerticalWithView:self.cellIcon];
    } else {
        [self.cellTitle setY:15];
    }
    y = CGRectGetMaxY(self.cellTitle.frame)+2;
    self.opencloseImage.frame = CGRectMake(CGRectGetMaxX(self.cellIcon.frame)+30, y, 24, 24);
    self.opencloseLabel.frame = CGRectMake(CGRectGetMaxX(self.opencloseImage.frame)+4,y,self.backView.sizeWidth-(CGRectGetMaxX(self.opencloseImage.frame)+4),24);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.cellIcon.image = nil;
    self.expanded = NO;
    self.opencloseImage.hidden = true;
    self.opencloseLabel.hidden = true;
}

- (void)setExpanded:(BOOL)expanded {
    _expanded = expanded;
    [self updateStateAfterExpandChange];
}

-(void)updateStateAfterExpandChange{
    self.bottomView.hidden = !self.expanded;
}


-(void)configureVoiceOver{
    self.cellTitle.accessibilityLabel = self.cellTitle.text;
    if(self.expanded){
        self.cellTitle.accessibilityTraits = UIAccessibilityTraitButton|UIAccessibilityTraitSelected;
    } else {
        self.cellTitle.accessibilityTraits = UIAccessibilityTraitButton;
    }
    if(!self.opencloseLabel.hidden){
        self.cellTitle.accessibilityLabel = [NSString stringWithFormat:@"%@, %@.",self.cellTitle.text,self.opencloseLabel.text];
    }
}

@end
