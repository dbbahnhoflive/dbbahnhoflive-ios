// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBMarker.h"

@implementation MBMarker

+ (instancetype)markerWithPosition:(CLLocationCoordinate2D)position andType:(enum MarkerType)type
{
    MBMarker *marker = [self markerWithPosition:position];
    marker.markerType = type;
    return marker;
}

- (id)copyWithZone:(NSZone *)zone
{
    MBMarker *copy = [[[self class] allocWithZone:zone] init];
    
    if (copy) {
        [copy setCategory:[self.category copyWithZone:zone]];
        [copy setSecondaryCategory:[self.secondaryCategory copyWithZone:zone]];
        
        // Set primitives
        [copy setMarkerType:self.markerType];
        [copy setOutdoor:self.outdoor];
        [copy setPosition:self.position];
        [copy setUserData:[self.userData copyWithZone:zone]];
        [copy setIcon:[[UIImage allocWithZone:zone] initWithCGImage:self.icon.CGImage scale:2.0 orientation:UIImageOrientationUp]];
    }
    return copy;
}

-(NSString *)description{
    return [[super description] stringByAppendingFormat:@" type=%lu",(unsigned long)self.markerType];
}

-(void)setIcon:(UIImage *)icon{
    if(icon == self.iconNormal || icon == self.iconLarge){
        [super setIcon:icon];
        return;
    }

    //store the image in two sizes by modifying the scale factor    
    CGFloat scale = 0.5;
    if(self.markerType == MOBILITY){
        scale = 0.75;
    } else if(self.markerType == STATION || self.markerType == USER){
        scale = 1.;
    }
    self.iconNormal = [UIImage imageWithCGImage:icon.CGImage scale:UIScreen.mainScreen.scale*(1./scale) orientation:UIImageOrientationUp];
    scale = 1;
    if(self.markerType == MOBILITY){
        scale = 1.1;
    }
    self.iconLarge = [UIImage imageWithCGImage:icon.CGImage scale:UIScreen.mainScreen.scale*(1./scale) orientation:UIImageOrientationUp];
    
    [super setIcon:self.iconNormal];
}

@end
