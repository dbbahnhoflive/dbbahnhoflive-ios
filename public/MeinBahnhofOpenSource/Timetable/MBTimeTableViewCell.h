// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>

#import "Event.h"

#define kCellHeight 81
#define kInnerPadding 5
#define kTopPadding 5
#define kLeftPadding 20

@class MBTimeTableViewCell;

@protocol MBTimeTableViewCellDelegate <NSObject>

- (void)cellWasSelectedViaVoiceOver:(MBTimeTableViewCell*)cell;
- (void)cellWasDeselectedViaVoiceOver:(MBTimeTableViewCell*)cell;

@end

@interface MBTimeTableViewCell : UITableViewCell

@property(nonatomic,weak) id<MBTimeTableViewCellDelegate> delegate;

@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *trainLabel;
@property (nonatomic, strong) UILabel *platformLabel;

@property (nonatomic, strong) UILabel *stationLabel;
@property (nonatomic, strong) UILabel *expectedTimeLabel;

@property (nonatomic, strong) UIImageView *messageIcon;


@property (nonatomic, strong) Event *event;
@property (nonatomic, strong) NSString *currentStation;

@property (nonatomic, strong) NSString* stopId;
+(NSString*)voiceOverForEvent:(Event*)event;

@end
