// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBTriangleView.h"

@implementation MBTriangleView

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        self.backgroundColor = [UIColor whiteColor];
        UIBezierPath* trianglePath = [UIBezierPath bezierPath];
        [trianglePath moveToPoint:CGPointMake(0, self.frame.size.height)];
        [trianglePath addLineToPoint:CGPointMake(self.frame.size.width,self.frame.size.height)];
        [trianglePath addLineToPoint:CGPointMake(self.frame.size.width/2, 0)];
        [trianglePath closePath];
        CAShapeLayer *triangleMaskLayer = [CAShapeLayer layer];
        [triangleMaskLayer setPath:trianglePath.CGPath];
        self.layer.mask = triangleMaskLayer;
    }
    return self;
}

@end
