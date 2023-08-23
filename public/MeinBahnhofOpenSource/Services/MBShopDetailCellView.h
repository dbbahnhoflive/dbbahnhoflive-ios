// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "VenueExtraField.h"
#import "RIMapPoi.h"

@interface MBShopDetailCellView : UIView

@property (nonatomic, strong) RIMapPoi *poi;

- (instancetype)initWithPXR:(RIMapPoi *)poi;

-(BOOL)hasContactLinks;
-(VenueExtraField*)contactLinks;

-(NSInteger)layoutForSize:(NSInteger)frameWidth;

@end
