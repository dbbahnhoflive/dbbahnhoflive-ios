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

+ (void)renderTextIntoIconFor:(MBMarker *)marker markerIcon:(UIImage *)markerIcon titleText:(NSString *)titleText zoomForIconWithText:(NSInteger)zoomForIconWithText {
    marker.iconWithoutText = markerIcon;
    marker.zoomForIconWithText = zoomForIconWithText;
    // text
    CGFloat labelWidth = 120;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, labelWidth, 50)];
    label.font = [UIFont db_BoldFourteen];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.textColor = [UIColor blackColor];
    label.text = titleText;
    
    UIColor* shadowColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    
    label.size = [label sizeThatFits:CGSizeMake(labelWidth, 100)];
    UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, labelWidth, 50)];
    label2.font = label.font;
    label2.textAlignment = NSTextAlignmentCenter;
    label2.numberOfLines = 0;
    label2.textColor = shadowColor;
    label2.text = label.text;
    label2.size = [label2 sizeThatFits:CGSizeMake(labelWidth, 100)];
    UILabel *label3 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, labelWidth, 50)];
    label3.font = label.font;
    label3.textAlignment = NSTextAlignmentCenter;
    label3.numberOfLines = 0;
    label3.textColor = shadowColor;
    label3.text = label.text;
    label3.size = [label3 sizeThatFits:CGSizeMake(labelWidth, 100)];
    UILabel *label4 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, labelWidth, 50)];
    label4.font = label.font;
    label4.textAlignment = NSTextAlignmentCenter;
    label4.numberOfLines = 0;
    label4.textColor = shadowColor;
    label4.text = label.text;
    label4.size = [label4 sizeThatFits:CGSizeMake(labelWidth, 100)];
    UILabel *label5 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
    label5.font = label.font;
    label5.textAlignment = NSTextAlignmentCenter;
    label5.numberOfLines = 0;
    label5.textColor = shadowColor;
    label5.text = label.text;
    label5.size = [label5 sizeThatFits:CGSizeMake(labelWidth, 100)];
    
    
    UIImageView* imgView = [[UIImageView alloc] initWithImage:markerIcon];
    UIView *iconView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MAX(imgView.frame.size.width, label.frame.size.width+2), imgView.frame.size.height+label.frame.size.height+2)];
    [iconView addSubview:imgView];
    
    CGRect f = label.frame;
    f.origin.x = 1;
    f.origin.y = imgView.frame.size.height+1;
    label.frame= f;
    
    f.origin.x--;
    f.origin.y--;
    label2.frame = f;
    f.origin.x += 2;
    label3.frame = f;
    f.origin.y += 2;
    label4.frame = f;
    f.origin.x -= 2;
    label5.frame = f;
    
    f = imgView.frame;
    f.origin.x = (int)((iconView.frame.size.width-f.size.width)/2.0);
    imgView.frame = f;
    
    [iconView addSubview:label5];
    [iconView addSubview:label4];
    [iconView addSubview:label3];
    [iconView addSubview:label2];
    [iconView addSubview:label];
    
    UIGraphicsBeginImageContextWithOptions(iconView.bounds.size, NO, [[UIScreen mainScreen] scale]);
    [iconView.layer renderInContext:UIGraphicsGetCurrentContext()];
    marker.iconWithText = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

@end
