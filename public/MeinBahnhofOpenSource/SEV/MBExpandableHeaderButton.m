// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBExpandableHeaderButton.h"
#import "UIColor+DBColor.h"
#import "UIFont+DBFont.h"
#import "UIView+Frame.h"

@interface MBExpandableHeaderButton()
@property(nonatomic,strong) UILabel* textLabel;
@property(nonatomic,strong) UIImageView* arrowIcon;
@end

@implementation MBExpandableHeaderButton

- (instancetype)initWithText:(NSString*)text
{
    self = [super initWithFrame:CGRectMake(0, 0, 320, 60)];
    if (self) {
        self.backgroundColor = [UIColor dbColorWithRGB:0xF1F3F5];
        self.textLabel = [UILabel new];
        self.textLabel.text = text;
        self.textLabel.textColor = UIColor.blackColor;
        self.textLabel.font = UIFont.db_BoldFourteen;
        [self.textLabel sizeToFit];
        self.arrowIcon = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"occupancy_arrow_down"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.arrowIcon.tintColor = UIColor.blackColor;
        [self addSubview:self.textLabel];
        [self addSubview:self.arrowIcon];
        self.isExpanded = false;
    }
    return self;
}

-(void)setIsExpanded:(BOOL)isExpanded{
    _isExpanded = isExpanded;
    self.arrowIcon.transform = !isExpanded ? CGAffineTransformMakeRotation(M_PI/2) : CGAffineTransformIdentity;
    NSString* change = self.isExpanded ? @"Erweitert. Zum Reduzieren doppeltippen" : @"Reduziert. Zum Erweitern doppeltippen";
    self.accessibilityHint = change;
}

-(NSString *)accessibilityLabel{
    return [NSString stringWithFormat:@"%@",self.textLabel.text];
}

-(void)layoutSubviews{
    [super layoutSubviews];
    [self.textLabel centerViewVerticalInSuperView];
    [self.arrowIcon centerViewVerticalInSuperView];
    [self.textLabel setGravityLeft:20];
    [self.arrowIcon setGravityRight:20];
}

@end
