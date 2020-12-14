// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (MBDictionary)

-(nullable NSArray*)db_arrayForKey:(NSString*)key;
-(nullable NSDictionary*)db_dictForKey:(NSString*)key;
-(nullable NSString*)db_stringForKey:(NSString*)key;
-(nullable NSNumber*)db_numberForKey:(NSString*)key;
-(BOOL)db_boolForKey:(NSString*)key;


@end

NS_ASSUME_NONNULL_END
