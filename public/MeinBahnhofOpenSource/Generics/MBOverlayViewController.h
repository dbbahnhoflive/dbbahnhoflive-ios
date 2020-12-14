// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>


@interface MBOverlayViewController : UIViewController

@property(nonatomic,strong,readonly) UIView* headerView;
@property(nonatomic,strong,readonly) UILabel* titleLabel;
@property(nonatomic,strong,readonly) UIView* contentView;
@property(nonatomic) BOOL overlayIsPresentedAsChildViewController;

-(void)hideOverlay;
-(NSInteger)expectedContentHeight;
@end
