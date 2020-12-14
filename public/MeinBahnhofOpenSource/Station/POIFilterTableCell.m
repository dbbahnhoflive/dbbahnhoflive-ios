// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "POIFilterTableCell.h"

@interface POIFilterTableCell()

@property (nonatomic, strong) UILabel *categoryTitleLabel;
@property (nonatomic, strong) UIView* whiteBackground;
@property (nonatomic, strong) UIView* shadowBackground;
@property (nonatomic, strong) UIView* shadowBackgroundClipView;
@property (nonatomic, strong) UISwitch *selectIndicatorSwitch;

@end

@implementation POIFilterTableCell

@synthesize item = _item;

- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self  = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.whiteBackground = [[UIView alloc] init];
        self.whiteBackground.backgroundColor = [UIColor whiteColor];
        self.whiteBackground.layer.cornerRadius = 2;
        self.whiteBackground.layer.borderColor = [UIColor db_HeaderColor].CGColor;
        self.whiteBackground.layer.borderWidth = 1;
        
        self.shadowBackground = [[UIView alloc] init];
        self.shadowBackground.backgroundColor = [UIColor clearColor];

        self.shadowBackground.layer.cornerRadius = 2;
        self.shadowBackground.layer.shadowOffset = CGSizeMake(0, 0);
        self.shadowBackground.layer.shadowColor = [UIColor blackColor].CGColor;
        self.shadowBackground.layer.shadowOpacity = 0.1;
        self.shadowBackground.layer.shadowRadius = 1;

        self.shadowBackgroundClipView = [[UIView alloc] init];
        self.shadowBackgroundClipView.backgroundColor = [UIColor clearColor];
        [self.shadowBackgroundClipView addSubview:self.shadowBackground];
        
        [self.contentView addSubview:self.shadowBackgroundClipView];
        
         [self.contentView addSubview:self.whiteBackground];
        
        self.categoryTitleLabel = [[UILabel alloc] init];
        self.categoryTitleLabel.font = [UIFont db_RegularSeventeen];
        self.categoryTitleLabel.textColor = [UIColor db_333333];
                
        self.selectIndicatorSwitch = [[UISwitch alloc] init];
        [self.contentView addSubview:self.selectIndicatorSwitch];
        self.selectIndicatorSwitch.userInteractionEnabled = NO;//temporary until we can forward the event
        
        [self.contentView addSubview:self.categoryTitleLabel];
    }
    return self;
}

-(void)setLastCell:(BOOL)isLastCell{
    //the last cell extends its shadow over the cell size (down)
    if(isLastCell){
        self.shadowBackgroundClipView.clipsToBounds = NO;
        self.shadowBackgroundClipView.layer.masksToBounds = NO;
    } else {
        self.shadowBackgroundClipView.clipsToBounds = YES;
        self.shadowBackgroundClipView.layer.masksToBounds = YES;
    }
}

- (void)setItem:(POIFilterItem *)item
{
    _item = item;
    
    self.categoryTitleLabel.text = _item.title;
    self.selectIndicatorSwitch.on = _item.active;
    
    if (!_item.subItems) {
        self.selectIndicatorSwitch.hidden = NO;
        
        self.whiteBackground.hidden = YES;
        self.shadowBackground.hidden = YES;
        self.shadowBackgroundClipView.hidden = YES;
    } else {
        self.selectIndicatorSwitch.hidden = YES;
        self.whiteBackground.hidden = NO;
        self.shadowBackground.hidden = NO;
        self.shadowBackgroundClipView.hidden = NO;
    }
    
    
    [self.categoryTitleLabel sizeToFit];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    self.whiteBackground.frame = CGRectMake(15, 0, self.frame.size.width-2*15, self.frame.size.height+1);
    self.shadowBackground.frame = self.whiteBackground.frame;
    self.shadowBackground.layer.shadowPath = [[UIBezierPath
                                              bezierPathWithRect:self.shadowBackground.bounds] CGPath];

    self.shadowBackgroundClipView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        
    [self.selectIndicatorSwitch centerViewVerticalInSuperView];
    [self.selectIndicatorSwitch setGravity:Right withMargin:20];
    
    if(self.whiteBackground.hidden){
        [self.categoryTitleLabel setGravityLeft:20];
    } else {
        [self.categoryTitleLabel setGravityLeft:15*2];
    }
    [self.categoryTitleLabel centerViewVerticalInSuperView];
}

@end
