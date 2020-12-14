// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

typedef enum
{
    Left,
    Right,
    Top,
    Bottom
} Gravity;

@interface UIView (Frame)

@property (nonatomic, assign) CGFloat x, y, width, height;
@property (nonatomic, assign) CGSize size;

- (void) makeSizeMatchSuperview;

- (void) setAbove:(UIView*)referenceView withPadding:(CGFloat)padding;
- (void) setBelow:(UIView*)referenceView withPadding:(CGFloat)padding;
- (void) setRight:(UIView*)referenceView withPadding:(CGFloat)padding;
- (void) setLeft:(UIView*)referenceView withPadding:(CGFloat)padding;

//additional frame setters

- (void)setLeft:(CGFloat)left right:(CGFloat)right;
- (void)setWidth:(CGFloat)width right:(CGFloat)right;
- (void)setTop:(CGFloat)top bottom:(CGFloat)bottom;
- (void)setHeight:(CGFloat)height bottom:(CGFloat)bottom;

// center in parent
- (void)centerViewInSuperView;
- (void)centerViewInBounds;
- (void)centerViewHorizontalInSuperView;
- (void)centerViewVerticalInSuperView;
- (void)centerViewVerticalWithView:(UIView*)anotherView;
- (void)centerViewHorizontalWithView:(UIView*)anotherView;

- (void)setGravity:(Gravity)gravity withMargin:(float)margin;
- (void)setGravityLeft:(float)margin;
- (void)setGravityRight:(float)margin;
- (void)setGravityTop:(float)margin;
- (void)setGravityBottom:(float)margin;

// property accessors
- (float)originX;
- (float)originY;
- (float)sizeWidth;
- (float)sizeHeight;
- (float)neededSpaceHeight;
- (float)neededSpaceWidth;

-(void)resizeToFitSubviews;
-(void)resizeHeight;

@end

