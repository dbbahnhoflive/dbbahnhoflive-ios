// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>

@protocol MBStationTabViewDelegate <NSObject>

- (void)didSelectTabAtIndex:(NSUInteger)index;

@end

@interface MBStationTabView : UIButton

//@property (nonatomic) BOOL selected;
//@property (nonatomic) BOOL enabled;
@property (nonatomic) NSUInteger index;
@property (nonatomic, weak) id<MBStationTabViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame templateImage:(UIImage *)image tabIndex:(NSUInteger)index title:(NSString*)title;

@end
