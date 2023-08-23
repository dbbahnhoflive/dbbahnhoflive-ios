// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//TODO: remove this class, it is no longer used
typedef NS_ENUM(NSUInteger, MBAdContainerType) {
    MBAdContainerTypeEinkaufsbahnhof    = 0,
};

@interface MBAdContainer : NSObject

@property(nonatomic,strong) NSString* voiceOverText;
@property(nonatomic) MBAdContainerType type;
@property(nonatomic,strong) NSString* imageName;
@property(nonatomic) BOOL isSquare;
@property(nonatomic,strong) NSURL* url;
@property(nonatomic,strong) NSArray<NSString*>* trackingAction;

@end

NS_ASSUME_NONNULL_END
