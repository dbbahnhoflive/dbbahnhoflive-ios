// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "NSDictionary+MBDictionary.h"

@implementation NSDictionary (MBDictionary)

-(NSDictionary *)db_dictForKey:(NSString *)key{
    if(![self isKindOfClass:NSDictionary.class])
        return nil;
    id something = self[key];
    if([something isKindOfClass:NSDictionary.class])
        return something;
    return nil;
}

-(NSArray *)db_arrayForKey:(NSString *)key{
    if(![self isKindOfClass:NSDictionary.class])
        return nil;
    id something = self[key];
    if([something isKindOfClass:NSArray.class])
        return something;
    return nil;
}

-(NSNumber *)db_numberForKey:(NSString *)key{
    if(![self isKindOfClass:NSDictionary.class])
        return nil;
    id something = self[key];
    if([something isKindOfClass:NSNumber.class])
        return something;
    return nil;
}
-(BOOL)db_boolForKey:(NSString *)key{
    NSNumber* num = [self db_numberForKey:key];
    if(num){
        return [num boolValue];
    }
    return false;
}


-(NSNumber *)db_stringForKey:(NSString *)key{
    if(![self isKindOfClass:NSDictionary.class])
        return nil;
    id something = self[key];
    if([something isKindOfClass:NSString.class])
        return something;
    return nil;
}

@end
