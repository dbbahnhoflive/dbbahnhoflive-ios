// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MBISO8601DurationParser : NSObject

+ (instancetype)shared;

-(NSString* _Nullable)parseString:(NSString*)string forVoiceOver:(BOOL)voiceOver;


@end

NS_ASSUME_NONNULL_END
