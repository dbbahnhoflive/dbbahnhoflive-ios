// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBSwitch.h"

@interface MBSwitch()

@property (nonatomic, strong) UIView *onView;
@property (nonatomic, strong) UIView *offView;

@property (nonatomic, strong) UILabel *onLabel;
@property (nonatomic, strong) UILabel *offLabel;

@property (nonatomic, strong) NSString *onTitle;
@property (nonatomic, strong) NSString *offTitle;

@property (nonatomic, strong) NSNumber *willTurnOn;

@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;

// additional view for selection indication in case there is no shadow
@property (nonatomic, strong) UIView *onSelectionView;
@property (nonatomic, strong) UIView *offSelectionView;
@property (nonatomic, strong) UIView *bottomView;

@end

@implementation MBSwitch

- (instancetype)initWithFrame:(CGRect)frame onTitle:(NSString *)onTitle offTitle:(NSString *)offTitle onState:(BOOL)onState {
    self = [super initWithFrame:frame];
    self.onTitle = onTitle;
    self.offTitle = offTitle;
    self.willTurnOn = nil;
    [self configureSwitch];
    self.on = onState;
    return self;
}

- (void)configureSwitch {
    
    self.onSelectionView = [[UIView alloc] initWithFrame:CGRectZero];
    self.offSelectionView = [[UIView alloc] initWithFrame:CGRectZero];
    self.bottomView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.onView = [[UIView alloc] initWithFrame:CGRectZero];
    self.offView = [[UIView alloc] initWithFrame:CGRectZero];
    self.onView.userInteractionEnabled = NO;
    self.offView.userInteractionEnabled = NO;
    
    [self.onView addSubview:self.onSelectionView];
    [self.offView addSubview:self.offSelectionView];
    [self addSubview:self.bottomView];
    
    self.onLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.offLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    
    self.onLabel.accessibilityTraits = UIAccessibilityTraitHeader|UIAccessibilityTraitButton;
    self.offLabel.accessibilityTraits = UIAccessibilityTraitHeader|UIAccessibilityTraitButton;

    self.onLabel.text = self.onTitle;
    self.onLabel.textAlignment = NSTextAlignmentCenter;
    self.offLabel.text = self.offTitle;
    self.offLabel.textAlignment = NSTextAlignmentCenter;
    if([self.offTitle isEqualToString:@"ÖPNV"]){
        self.offLabel.accessibilityLabel = @"Ö P N V";
    }
    
    [self addSubview:self.onView];
    [self addSubview:self.offView];
    
    [self.offView addSubview:self.offLabel];
    [self.onView addSubview:self.onLabel];
    
}

- (void)onStateForLabel:(UILabel *)label view:(UIView *)view xDistance:(CGFloat)xDistance selectionView: (UIView *)selectionView {
    if (nil != selectionView) {
        selectionView.backgroundColor = [UIColor db_mainColor];
    }
    if (!_noShadow) {
        view.layer.shadowColor = [[UIColor db_dadada] CGColor];
        view.layer.shadowOffset = CGSizeMake(xDistance, 3.0);
        view.layer.shadowRadius = 3.0;
        view.layer.shadowOpacity = 1.0;
    } else {
        view.layer.shadowOpacity = 0.0;
    }
    if (nil == _activeTextColor) {
        label.textColor = [UIColor db_333333];
    } else {
        label.textColor = _activeTextColor;
    }
    if (nil == _activeLabelFont) {
        label.font = [UIFont db_BoldSeventeen];
    } else {
        label.font = _activeLabelFont;
    }
    view.backgroundColor = [UIColor whiteColor];
    
    label.accessibilityTraits = UIAccessibilityTraitHeader|UIAccessibilityTraitButton|UIAccessibilityTraitSelected;

}

- (void)offStateForLabel:(UILabel *)label view:(UIView *)view selectionView:(UIView *)selectionView {
    if (nil != selectionView) {
        selectionView.backgroundColor = [UIColor clearColor];
    }
    view.layer.shadowOpacity = 0.0;
    if (nil == _inActiveTextColor) {
        label.textColor = [UIColor whiteColor];
    } else {
        label.textColor = _inActiveTextColor;
    }
    if (nil == _inActiveLabelFont) {
        label.font = [UIFont db_RegularSeventeen];
    } else {
        label.font = _inActiveLabelFont;
    }
    view.backgroundColor = [UIColor clearColor];
    
    label.accessibilityTraits = UIAccessibilityTraitHeader|UIAccessibilityTraitButton;

}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setupOnOffViewsForState:self.on];

    [self.onView setFrame:CGRectMake(0, 0, self.frame.size.width / 2.0, self.frame.size.height)];
    [self.offView setFrame:CGRectMake(self.onView.frame.size.width, 0, self.frame.size.width / 2.0, self.frame.size.height)];
    
    CGFloat height = self.frame.size.height;
    CGFloat bottomHeight = self.frame.size.height < 60.0 ? 2.0 : 4.0;
    if (_noShadow) {
        height -= bottomHeight;
        CGRect bottomFrame = self.bounds;
        bottomFrame.origin.y = self.frame.size.height - 1.0;
        bottomFrame.size.height = 1.0;
        self.bottomView.frame = bottomFrame;
        self.bottomView.backgroundColor = [UIColor db_e5e5e5];
        
        CGRect onSelectionFrame = self.onView.bounds;
        onSelectionFrame.origin.y = self.onView.frame.size.height - bottomHeight;
        onSelectionFrame.size.height = bottomHeight;
        self.onSelectionView.frame = onSelectionFrame;

        CGRect offSelectionFrame = self.offView.bounds;
        offSelectionFrame.origin.y = self.offView.frame.size.height - bottomHeight;
        offSelectionFrame.size.height = bottomHeight;
        self.offSelectionView.frame = offSelectionFrame;
    }

    CGRect onLabelRect = self.onView.bounds;
    onLabelRect.size.height = height;
    CGRect offLabelRect = self.offView.bounds;
    offLabelRect.size.height = height;
    
    [self.onLabel setFrame:onLabelRect];
    [self.offLabel setFrame:offLabelRect];
    
    if (!_noRoundedCorners) {
        self.layer.cornerRadius = self.frame.size.height / 2.0;
        self.onView.layer.cornerRadius = self.onView.frame.size.height / 2.0;
        self.offView.layer.cornerRadius = self.offView.frame.size.height / 2.0;
    } else {
        self.layer.cornerRadius = 0.0;
        self.onView.layer.cornerRadius = 0.0;
        self.offView.layer.cornerRadius = 0.0;
    }
}

- (void)setWillTurnOn:(NSNumber *)willTurnOn {
    if (nil != willTurnOn) {
        if (self.tracking == NO) {
            self.on = willTurnOn.boolValue;
        }
        _willTurnOn = nil;
    }
}

- (void)setupOnOffViewsForState:(BOOL)onState {
    if (onState) {
        [self onStateForLabel:self.onLabel view:self.onView xDistance:-3.0 selectionView:self.onSelectionView];
        [self offStateForLabel:self.offLabel view:self.offView selectionView:self.offSelectionView];
    } else {
        [self onStateForLabel:self.offLabel view:self.offView xDistance:3.0 selectionView:self.offSelectionView];
        [self offStateForLabel:self.onLabel view:self.onView selectionView:self.onSelectionView];
    }
}

- (void)setOn:(BOOL)on {
    _on = on;
    [self setupOnOffViewsForState:on];
}

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents {
    self.target = target;
    self.action = action;
}

- (void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    [super sendAction:action to:target forEvent:event];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    BOOL ret = [super beginTrackingWithTouch:touch withEvent:event];
    if (CGRectContainsPoint(self.onLabel.frame, [touch locationInView:self])) {
        self.willTurnOn = @(YES);
    } else {
        self.willTurnOn = @(NO);
    }
    return ret;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    BOOL ret = [super continueTrackingWithTouch:touch withEvent:event];
    if (CGRectContainsPoint(self.onLabel.frame, [touch locationInView:self])) {
        self.willTurnOn = @(YES);
    } else {
        self.willTurnOn = @(NO);
    }
    return ret;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super endTrackingWithTouch:touch withEvent:event];
    if (CGRectContainsPoint(self.onLabel.frame, [touch locationInView:self])) {
        self.willTurnOn = @(YES);
    } else {
        self.willTurnOn = @(NO);
    }
    [self sendAction:self.action to:self.target forEvent:event];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    [super cancelTrackingWithEvent:event];
    self.willTurnOn = nil;
}

@end
