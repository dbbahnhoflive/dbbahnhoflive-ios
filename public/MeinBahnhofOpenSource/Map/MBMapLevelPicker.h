// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "LevelplanWrapper.h"

@class MBMapLevelPicker;

@protocol MBMapLevelPickerDelegate <NSObject>

- (void) picker:(MBMapLevelPicker*)picker didChangeToLevel:(LevelplanWrapper*)level;
- (void) userDidSelectLevel:(LevelplanWrapper*)level onPicker:(MBMapLevelPicker*)picker;

@end

@interface MBMapLevelPicker : UIView

@property (nonatomic, strong) LevelplanWrapper *currentLevel;
@property (nonatomic, strong) NSArray *levels;

@property (nonatomic, weak) id<MBMapLevelPickerDelegate> delegate;

- (instancetype) initWithLevels:(NSArray*)levels;

- (void) setCurrentLevelByLevelNumber:(NSInteger)levelNumber forced:(BOOL)forced;

@end
