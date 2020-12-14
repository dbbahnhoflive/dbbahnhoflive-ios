// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import <GoogleMaps/GoogleMaps.h>
#import "MBStation.h"

typedef NS_ENUM(NSUInteger, MBStationTeaserType) {
    MBStationTeaserTypePickPack    = 0,
};

@interface MBStationKachel : NSObject

@property (nonatomic, strong) NSString *titleForVoiceOver;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *imageName;
@property (nonatomic, strong) NSString *bubbleText;
@property (nonatomic, strong) UIColor *bubbleColor;
@property (nonatomic) BOOL needsLineAboveText;
@property (nonatomic) BOOL requestFailed;
@property (nonatomic) BOOL showWarnIcon;
@property (nonatomic) BOOL showOnlyImage;
@property (nonatomic) BOOL isGreenTeaser;
@property (nonatomic) BOOL isChatbotTeaser;
@property (nonatomic) BOOL isImageTeaser;
@property (nonatomic) MBStationTeaserType teaserType;//used in combination with isImageTeaser

@property (nonatomic, strong) MBStation *station;
@property (nonatomic, assign) BOOL showBubble;

@end
