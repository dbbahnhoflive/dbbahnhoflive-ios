// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>

@interface MBEinkaufsbahnhofCategory : NSObject

@property(nonatomic,strong) NSNumber* number;
@property(nonatomic,strong) NSString* name;
@property(nonatomic,strong) NSArray* shops;

-(NSString*)iconFilename;
-(UIImage*)icon;
+(UIImage*)menuIconForCategoryTitle:(NSString*)title;
+(NSString*)categoryNameForCatTitle:(NSString*)title;
+(MBEinkaufsbahnhofCategory*)createCategoryWithName:(NSString*)name number:(NSNumber*)number;

@end
