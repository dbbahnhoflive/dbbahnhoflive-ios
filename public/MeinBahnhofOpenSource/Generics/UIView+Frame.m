// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "UIView+Frame.h"
#import "UIColor+DBColor.h"

@implementation UIView (Frame)

@dynamic x;
@dynamic y;
@dynamic width;
@dynamic height;

@dynamic size;

-(void)setX:(CGFloat)x
{
    CGRect frame = self.frame;
    frame.origin.x =x;
    self.frame=frame;
}

-(void)setY:(CGFloat)y
{
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

-(void)setWidth:(CGFloat)width
{
    CGRect frame = self.frame;
    frame.size.width =width;
    self.frame=frame;
}

- (void)setHeight:(CGFloat)height
{
    CGRect frame = self.frame;
    frame.size.height =height;
    self.frame=frame;
}

- (void)setSize:(CGSize)size
{
    CGRect frame = self.frame;
    frame.size.width = size.width;
    frame.size.height = size.height;
    self.frame=frame;
}

- (void) makeSizeMatchSuperview
{
    if (self.superview) {
        CGRect frame = self.frame;
        frame.size = self.superview.frame.size;
        [self setX:0];
        [self setY:0];
    }
}

// relative frame setters

- (void) setRight:(UIView*)referenceView withPadding:(CGFloat)padding
{
    CGFloat offsetX = referenceView.frame.origin.x+referenceView.frame.size.width+padding;
    [self setX:offsetX];
}

- (void) setLeft:(UIView*)referenceView withPadding:(CGFloat)padding
{
    CGFloat offsetX = referenceView.frame.origin.x-(self.frame.size.width+padding);
    [self setX:offsetX];
}

- (void) setBelow:(UIView*)referenceView withPadding:(CGFloat)padding
{
    CGFloat offsetY = referenceView.frame.origin.y+referenceView.frame.size.height+padding;
    [self setY:offsetY];
}

- (void) setAbove:(UIView*)referenceView withPadding:(CGFloat)padding
{
    CGFloat offsetY = referenceView.frame.origin.y-(self.frame.size.height+padding);
    [self setY:offsetY];
}

//additional frame setters

- (void)setLeft:(CGFloat)left right:(CGFloat)right
{
    CGRect frame = self.frame;
    frame.origin.x = left;
    frame.size.width = right - left;
    self.frame = frame;
}

- (void)setWidth:(CGFloat)width right:(CGFloat)right
{
    CGRect frame = self.frame;
    frame.origin.x = right - width;
    frame.size.width = width;
    self.frame = frame;
}

- (void)setTop:(CGFloat)top bottom:(CGFloat)bottom
{
    CGRect frame = self.frame;
    frame.origin.y = top;
    frame.size.height = bottom - top;
    self.frame = frame;
}

- (void)setHeight:(CGFloat)height bottom:(CGFloat)bottom
{
    CGRect frame = self.frame;
    frame.origin.y = bottom - height;
    frame.size.height = height;
    self.frame = frame;
}

-(void)centerViewInSuperView
{
    if (self.superview !=nil) {
        UIView * superview = self.superview;
        [self setX: ceilf(superview.frame.size.width/2 - self.frame.size.width/2)];
        [self setY: ceilf(superview.frame.size.height/2 - self.frame.size.height/2)];
    } else {
        NSLog(@"centerViewInSuperView Missing superview");
    }
}

-(void)centerViewInBounds
{
    if (self.superview !=nil) {
        UIView * superview = self.superview;
        [self setX: ceilf(superview.bounds.size.width/2 - self.frame.size.width/2)];
        [self setY: ceilf(superview.bounds.size.height/2 - self.frame.size.height/2)];
    } else {
        NSLog(@"centerViewInBounds Missing superview");
    }
}

-(void)centerViewHorizontalInSuperView
{
    if (self.superview !=nil) {
        UIView * superview = self.superview;
        [self setX: ceilf(superview.frame.size.width/2 - self.frame.size.width/2)];
    } else {
        NSLog(@"centerViewHorizontalInSuperView Missing superview");
    }
}


-(void)centerViewVerticalWithView:(UIView*)anotherView{
    [self setY:ceilf(anotherView.frame.origin.y + anotherView.frame.size.height/2 - self.frame.size.height/2)];
}
-(void)centerViewHorizontalWithView:(UIView*)anotherView{
    [self setX:ceilf(anotherView.frame.origin.x + anotherView.frame.size.width/2 - self.frame.size.width/2)];
}


-(void)centerViewVerticalInSuperView
{
    if (self.superview !=nil) {
        UIView * superview = self.superview;
        [self setY: ceilf(superview.frame.size.height/2 - self.frame.size.height/2)];
    } else {
        
        NSLog(@"centerViewVerticalInSuperView Missing superview");
    }
}

-(void)setGravityLeft:(float)margin
{
    [self setX: margin];
}

-(void)setGravityRight:(float)margin
{
    UIView * superview = self.superview;
    [self setX: superview.frame.size.width - (self.frame.size.width + margin)];
}

-(void)setGravityTop:(float)margin
{
    [self setY: margin];
}

-(void)setGravityBottom:(float)margin
{
    UIView * superview = self.superview;
    [self setY: superview.frame.size.height - (self.frame.size.height + margin)];
}

-(void)setGravity:(Gravity)gravity withMargin:(float)margin
{
    if (self.superview !=nil) {
        switch (gravity) {
            case Left:
                [self setGravityLeft:margin];
                break;
            case Right:
                [self setGravityRight:margin];
                break;
            case Top:
                [self setGravityTop:margin];
                break;
            case Bottom:
                [self setGravityBottom:margin];
                break;
                
            default:
                break;
        }
    } else {
        NSLog(@"setGravity Missing superview");
    }
}

-(float)originX
{
    return self.frame.origin.x;
}

-(float)originY
{
    return self.frame.origin.y;
}

-(float)sizeWidth
{
    return self.frame.size.width;
}

-(float)sizeHeight
{
    return self.frame.size.height;
}

-(float)neededSpaceHeight
{
    return [self originY]+[self sizeHeight];
}

-(float)neededSpaceWidth
{
    return [self originX]+[self sizeWidth];
}

-(void)resizeToFitSubviews
{
    float w = 0;
    float h = 0;
    
    for (UIView *v in [self subviews]) {
        float fw = v.frame.origin.x + v.frame.size.width;
        float fh = v.frame.origin.y + v.frame.size.height;
        w = MAX(fw, w);
        h = MAX(fh, h);
    }
    // leave width as original
    [self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, w, h)];
}

-(void)resizeHeight
{
    float w = 0;
    float h = 0;
    
    for (UIView *v in [self subviews]) {
        float fw = v.frame.origin.x + v.frame.size.width;
        float fh = v.frame.origin.y + v.frame.size.height;
        w = MAX(fw, w);
        h = MAX(fh, h);
    }
    // leave width as original
    [self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, h)];
}


-(void)configureDefaultShadow{
    self.layer.shadowOffset = CGSizeMake(1.0, 2.0);
    self.layer.shadowColor = [[UIColor db_dadada] CGColor];
    self.layer.shadowRadius = 1.5;
    self.layer.shadowOpacity = 1.0;
}

-(void)configureH1Shadow{
    [self configureDefaultShadow];
}

@end
