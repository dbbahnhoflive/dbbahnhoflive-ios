// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBMapPoiDetailScrollView.h"

@implementation MBMapPoiDetailScrollView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event{
    CGPoint parentLocation = [self convertPoint:point toView:[self superview]];
    //we react to the width of the superview here, not our width (which is smaller)
    CGRect responseRect = CGRectMake(0, self.frame.origin.y, self.superview.frame.size.width, self.frame.size.height);
    return CGRectContainsPoint(responseRect, parentLocation);
}

@end
