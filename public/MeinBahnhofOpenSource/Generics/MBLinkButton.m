// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBLinkButton.h"

@interface MBLinkButton()

@property (nonatomic, strong) UIImage *leftImage;
@property (nonatomic, assign) double leftInset;


@end

@implementation MBLinkButton

@synthesize labelText = _labelText;
@synthesize value = _value;
@synthesize titleColor = _titleColor;


+ (instancetype) buttonWithLeftImage:(NSString*)imageName
{
    MBLinkButton *button = [super buttonWithType:UIButtonTypeCustom];
    button.leftImage = [UIImage db_imageNamed:imageName];
    button.labelFont = [UIFont db_HelveticaBoldFourteen];
    button.titleColor = [UIColor db_646973];
    button.leftInset = 10;
    return button;
}

+ (instancetype) buttonWithRightImage:(NSString*)imageName
{
    MBLinkButton *button = [super buttonWithType:UIButtonTypeCustom];
    button.leftImage = [UIImage db_imageNamed:imageName];
    button.labelFont = [UIFont db_HelveticaBoldFourteen];
    button.titleColor = [UIColor db_646973];
    button.leftInset = 10;
    
    button.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    button.titleLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    button.imageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    
    return button;
}


+ (instancetype) buttonWithRedLink
{
    MBLinkButton *button = [super buttonWithType:UIButtonTypeCustom];
    button.leftImage = [UIImage db_imageNamed:@"app_links_pfeil"];
    button.labelFont = [UIFont db_RegularFourteen];
    button.titleColor = [UIColor db_333333];
    button.leftInset = 8;
    return button;
}


- (void) setLabelText:(NSString *)labelText
{
    _labelText = labelText;
    [self setTitle:labelText forState:UIControlStateNormal];
    self.titleLabel.font = self.labelFont;
    [self.titleLabel sizeToFit];
    
    CGSize sizeOfLabel = self.titleLabel.size;
    
    self.frame = CGRectMake(0, 0, sizeOfLabel.width+self.leftInset+(self.leftImage.size.width), MAX(sizeOfLabel.height, self.leftImage.size.height));
    
    [self setImage:self.leftImage forState:UIControlStateNormal];

    [self setTitleColor:_titleColor forState:UIControlStateNormal];
    
    self.titleEdgeInsets = UIEdgeInsetsMake(0.0f, self.leftInset, 0.0f, 0.0f);
    [self setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    if (enabled) {
        self.layer.opacity = 1;
    } else {
        self.layer.opacity = 0.5;
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
}

@end
