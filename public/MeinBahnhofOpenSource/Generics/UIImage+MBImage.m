// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "UIImage+MBImage.h"

@implementation UIImage (MBImage)


+(UIImage *)db_imageNamed:(NSString *)name{
    UIImage* res = [UIImage imageNamed:name];
    if(!res){
        //missing asset, fallback
        NSLog(@"missing image: %@",name);
        return [UIImage imageNamed:@"notavailable"];
    }
    return res;
}


@end
