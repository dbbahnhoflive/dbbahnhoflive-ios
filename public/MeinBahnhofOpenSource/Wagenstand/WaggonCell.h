// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "Waggon.h"
#import "SymbolTagView.h"

@interface WaggonCell : UITableViewCell

@property (nonatomic, strong) Waggon *waggon;

+(CGFloat)widthOfLegendPartForWidth:(CGFloat)totalWidth;

@end
