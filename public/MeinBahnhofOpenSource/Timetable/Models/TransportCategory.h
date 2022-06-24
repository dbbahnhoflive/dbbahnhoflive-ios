// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>

@interface TransportCategory : NSObject

@property (nonatomic, strong) NSString* transportCategoryType;
@property (nonatomic, strong) NSString* transportCategoryNumber;

@property (nonatomic, strong) NSString* transportCategoryOriginalNumber;

@property (nonatomic, strong) NSString* transportCategoryGenericNumber;

@end
