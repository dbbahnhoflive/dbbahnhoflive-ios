// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "Train.h"

@interface WagenstandHeaderTrainCell : UIView

@property (nonatomic, assign) BOOL expanded;

- (instancetype) initCellWithTrain:(Train*)train andFrame:(CGRect)frame splitTrain:(BOOL)splitTrain;

@end
