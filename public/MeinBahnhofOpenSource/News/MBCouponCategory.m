// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBCouponCategory.h"
#import "MBUIHelper.h"

@implementation MBCouponCategory

-(NSString *)title{
    return @"Rabatt Coupons";
}
+(UIImage *)image{
    return [UIImage db_imageNamed:@"coupon"];
}


@end
