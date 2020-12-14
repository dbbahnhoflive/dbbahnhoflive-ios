// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, MBErrorActionType)  {
    MBERrorActionTypeUndefined,
    MBErrorActionTypeRequestLocation,
    MBErrorActionTypeReload,
} ;

@class MBSearchErrorView;

@protocol MBSearchErrorViewDelegate
-(void)searchErrorDidPressActionButton:(MBSearchErrorView*)errorView withAction:(MBErrorActionType)action;
@end

@interface MBSearchErrorView : UIView

-(void)setHeaderText:(NSString*)headerText bodyText:(NSString*)bodyText;
-(void)setHeaderText:(NSString *)headerText bodyText:(NSString *)bodyText actionText:(NSString*)actionText actionType:(MBErrorActionType)actionType;

@property(nonatomic,weak) id<MBSearchErrorViewDelegate> delegate;
@end
