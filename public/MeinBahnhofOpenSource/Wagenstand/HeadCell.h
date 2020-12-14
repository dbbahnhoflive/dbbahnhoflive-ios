// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "Waggon.h"
#import "Train.h"

@interface HeadCell : UITableViewCell

@property (nonatomic, strong) UIImageView *trainIconView;
@property (nonatomic, strong) Waggon *waggon;
@property (nonatomic, strong) Train *train;

@property (nonatomic, assign) BOOL head;

- (void) setWaggon:(Waggon *)waggon lastPosition:(BOOL)lastPosition;

@end
