// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBVoiceOverHelper.h"

@implementation MBVoiceOverHelper

+(NSString *)timeForVoiceOver:(NSString *)h_m{
    if(h_m.length == 5){ //hh:mm
        NSString* h = [h_m substringToIndex:2];
        NSString* m = [h_m substringFromIndex:3];
        if([m isEqualToString:@"00"]){
            return [NSString stringWithFormat:@"%@ Uhr",h];
        }
        if([m hasPrefix:@"0"]){
            //instead of "zero x" we just read x
            m = [m substringFromIndex:1];
            return [NSString stringWithFormat:@"%@ Uhr %@",h,m];
        }
        return [NSString stringWithFormat:@"%@ Uhr %@",h,m];
    } else {
        NSLog(@"WARNING: unexpected format used in timeForVoiceOver: %@",h_m);
        return h_m;
    }
}

@end
