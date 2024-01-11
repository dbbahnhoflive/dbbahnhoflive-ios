// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>


@interface MBOverlayViewController : UIViewController

@property(nonatomic,strong,readonly) UIView* headerView;
@property(nonatomic,strong,readonly) UILabel* titleLabel;
@property(nonatomic,strong,readonly) UIView* contentView;
@property(nonatomic,strong,readonly) UIScrollView* contentScrollView;
@property(nonatomic) BOOL overlayIsPresentedAsChildViewController;

-(void)hideOverlayWithCompletion:(void(^)(void))actionBlock;
-(void)updateContentScrollViewContentHeight:(NSInteger)y;
-(BOOL)usesContentScrollView;
-(void)hideOverlay;
-(NSInteger)expectedContentHeight;
@end
