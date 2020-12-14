// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBStationTabView.h"

@interface MBStationTabView()

@property (nonatomic, strong) UIImageView *tabimageView;
@property (nonatomic, strong) UIColor *inactiveColor;
@property (nonatomic, strong) UIColor *activeColor;
@property (nonatomic, strong) UIColor *disabledColor;
@end

@implementation MBStationTabView

- (instancetype)initWithFrame:(CGRect)frame templateImage:(UIImage *)image tabIndex:(NSUInteger)index title:(NSString *)title{
    self = [super initWithFrame:frame];
    
    [self addTarget:self action:@selector(handleTap) forControlEvents:UIControlEventTouchUpInside];
    self.accessibilityLabel = title;
    
    self.inactiveColor = [UIColor db_333333];
    self.activeColor = [UIColor db_mainColor];
    self.disabledColor = [UIColor db_cccccc];
    
    self.index = index;
    self.enabled = YES;
    
    self.tabimageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.tabimageView.image = image;
    self.tabimageView.contentMode = UIViewContentModeCenter;
    self.tabimageView.tintColor = self.inactiveColor;
    [self addSubview:self.tabimageView];
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.tabimageView.frame = self.bounds;
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    //_enabled = enabled;
    if (self.enabled) {
        self.tabimageView.tintColor = self.selected ? self.activeColor : self.inactiveColor;
    } else {
        self.tabimageView.tintColor = self.disabledColor;
    }
}

- (void)handleTap {
    if (self.enabled) {
        if (nil != self.delegate) {
            if ([self.delegate respondsToSelector:@selector(didSelectTabAtIndex:)]) {
                [self.delegate didSelectTabAtIndex:self.index];
            }
        }
    }
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    //_selected = selected;
    if(self.enabled){
        if (self.selected) {
            self.tabimageView.tintColor = self.activeColor;
        } else {
            self.tabimageView.tintColor = self.inactiveColor;
        }
    } else {
        self.tabimageView.tintColor = self.disabledColor;
    }
}

@end
