// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>

@interface MBPXRShopCategory : NSObject

@property(nonatomic,strong) NSString* title;
@property(nonatomic,strong) NSMutableArray* items;

@end
