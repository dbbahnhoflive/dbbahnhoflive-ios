// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MBPXRShopCategory : NSObject

@property(nonatomic,strong) NSString* title;
@property(nonatomic,strong) NSMutableArray* items;

+(NSString*)categoryNameForCatTitle:(NSString*)title;
+(UIImage*)menuIconForCategoryTitle:(NSString*)title;

@end
