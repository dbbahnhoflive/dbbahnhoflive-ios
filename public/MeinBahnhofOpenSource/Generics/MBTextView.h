// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "NSString+MBString.h"

@protocol MBTextViewDelegate <UITextViewDelegate>

- (void) didInteractWithURL:(NSURL*)url;

@end

@interface MBTextView : UITextView <UITextViewDelegate>

@property (nonatomic, weak) id<MBTextViewDelegate>delegado;
@property (nonatomic, strong) NSString *htmlString;


@end
