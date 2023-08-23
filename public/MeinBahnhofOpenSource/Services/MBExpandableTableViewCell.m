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
        self.cellTitle.frame = CGRectMake(x, y-2, size.width, size.height);
    } else {
        self.cellTitle.frame = CGRectMake(x, y, self.backView.sizeWidth-(CGRectGetMaxX(self.cellIcon.frame)+33)-8, 24);
        y = CGRectGetMaxY(self.cellTitle.frame)+2;
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.cellIcon.image = nil;
    self.expanded = NO;

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
}

@end
