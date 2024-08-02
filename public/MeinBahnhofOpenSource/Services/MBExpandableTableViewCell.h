// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <UIKit/UIKit.h>
#import "MBDetailViewDelegate.h"
#import "MBLabel.h"
#import "MBStatusImageView.h"
#import "RIMapPoi.h"

@interface MBExpandableTableViewCell : UITableViewCell
@property (nonatomic) BOOL displayMultilineTitle;

@property (nonatomic, assign) BOOL expanded;
-(void)updateStateAfterExpandChange;

- (void) configureCell;
-(void)configureVoiceOver;

@property (nonatomic, weak) id<MBDetailViewDelegate> delegate;// only used in shops?

@property (nonatomic, strong) MBLabel* cellTitle;
@property (nonatomic, strong) MBLabel* cellSubTitle;
@property (nonatomic, strong) UIImageView *cellIcon;

//optional in second line:
@property (nonatomic, strong) UILabel *opencloseLabel;
@property (nonatomic, strong) MBStatusImageView *opencloseImage;
-(void)configureCellForItemWithOpenState:(ShopOpenState)openState;
-(void)configureCellForItemWithOpenState:(ShopOpenState)openState openText:(NSString*)openText closeText:(NSString*)closeText;

// back view is a bit smaller than the cell
@property (nonatomic, strong) UIView *backView;
// always visible view contains title and opening info and has a shadow
@property (nonatomic, strong) UIView *topView;
// only visible in expanded view, contains detail information
@property (nonatomic, strong) UIView *bottomView;

@end
