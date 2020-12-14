// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "VenueExtraField.h"
#import "RIMapPoi.h"
#import "MBEinkaufsbahnhofStore.h"

@interface MBShopDetailCellView : UIView

@property (nonatomic, strong) RIMapPoi *poi;
@property (nonatomic, strong) MBEinkaufsbahnhofStore *store;

- (instancetype)initWithPXR:(RIMapPoi *)poi;
- (instancetype)initWithStore:(MBEinkaufsbahnhofStore *)poi;

-(BOOL)hasContactLinks;
-(VenueExtraField*)contactLinks;

-(NSInteger)layoutForSize:(NSInteger)frameWidth;
+(NSString*)displayStringOpenTimesForStore:(MBEinkaufsbahnhofStore*)store;

@end
