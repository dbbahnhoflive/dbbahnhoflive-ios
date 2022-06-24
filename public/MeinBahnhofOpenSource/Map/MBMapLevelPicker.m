// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBMapLevelPicker.h"
#import "MBUIHelper.h"

@interface MBMapLevelPicker()

@property (nonatomic, strong) UIButton *pickerUp;
@property (nonatomic, strong) UIButton *pickerDown;
@property (nonatomic, strong) UILabel *currentLevelLabel;
@property (nonatomic, strong) NSArray* levelIndicatorImages;

@property (nonatomic, assign) NSInteger currentLevelIndex;

@end

@implementation MBMapLevelPicker

@synthesize levels = _levels;

- (instancetype) initWithLevels:(NSArray*)levels
{
    if (self = [super initWithFrame:CGRectMake(0,0, 60, 140)]) {
        
        UIImageView* back = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"MapLevelPickerBackground"]];
        if(![UIImage db_imageNamed:@"MapLevelPickerBackground"]){
            self.backgroundColor = [UIColor whiteColor];
        }
        back.frame = CGRectMake(0, 0, self.sizeWidth, self.sizeHeight);
        [self addSubview:back];
        
        self.pickerUp = [UIButton buttonWithType:UIButtonTypeCustom];
        self.pickerUp.frame = CGRectMake(10, 10, 40, 40);
        
        UIImage *arrowDown = [UIImage db_imageNamed:@"MapLevelDown"];
        UIImage *arrowUp = [UIImage db_imageNamed:@"MapLevelUp"];
        
        [self.pickerUp setImage:arrowUp forState:UIControlStateNormal];
        
        self.currentLevelLabel = [[UILabel alloc] init];
        self.currentLevelLabel.frame = CGRectMake(10, 50, 40, 40);
        self.currentLevelLabel.font = [UIFont db_RegularSeventeen];
        self.currentLevelLabel.textColor = [UIColor yellowColor];
        [self.currentLevelLabel setTextAlignment:NSTextAlignmentCenter];
        self.currentLevelLabel.hidden = YES;
        
        self.pickerDown = [UIButton buttonWithType:UIButtonTypeCustom];
        self.pickerDown.frame = CGRectMake(10, 90, 40, 40);
        [self.pickerDown setImage:arrowDown forState:UIControlStateNormal];
        
        [self.pickerDown addTarget:self action:@selector(didTapOnPicker:) forControlEvents:UIControlEventTouchUpInside];
        [self.pickerUp addTarget:self action:@selector(didTapOnPicker:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:self.pickerUp];
        [self addSubview:self.currentLevelLabel];
        [self addSubview:self.pickerDown];
        
        [self setLevels:levels];
    }
    return self;
}

- (void) checkPickerState
{
    NSInteger firstLevel = ((LevelplanWrapper*)[_levels firstObject]).levelNumber;
    NSInteger lastLevel = ((LevelplanWrapper*)[_levels lastObject]).levelNumber;
    
    self.pickerDown.enabled = self.currentLevelIndex > firstLevel;
    self.pickerUp.enabled = self.currentLevelIndex < lastLevel;
    //NSLog(@"picker changed, down=%d, up=%d, current %ld, levels %@",self.pickerDown.enabled,self.pickerUp.enabled,(long)self.currentLevelIndex,_levels);
}

- (void) didTapOnPicker:(id)sender
{
    if (sender == self.pickerDown) {
        self.currentLevelIndex--;
    } else if (sender == self.pickerUp) {
        self.currentLevelIndex++;
    }
    
    for (LevelplanWrapper *levelplan in self.levels) {
        if (self.currentLevelIndex == levelplan.levelNumber) {
            self.currentLevel = levelplan;
            [self updateLevelLabel:self.currentLevel];
            
            if ([self.delegate respondsToSelector:@selector(userDidSelectLevel:onPicker:)]) {
                [self.delegate userDidSelectLevel:levelplan onPicker:self];
            }
            
        }
    }
}

- (void)setLevels:(NSArray *)levels
{
    _levels = levels;
    
    LevelplanWrapper* initialLevel = (LevelplanWrapper*)[_levels firstObject];
    for(LevelplanWrapper* level in _levels){
        if(level.levelNumber == 0){
            initialLevel = level;
            break;
        }
    }
    
    self.currentLevelIndex = initialLevel.levelNumber;
    self.currentLevel = initialLevel;
    [self updateLevelLabel:self.currentLevel];
}

- (void) setCurrentLevelByLevelNumber:(NSInteger)levelNumber forced:(BOOL)forced;
{
    if (self.levels.count == 0) {
        return;
    }
    
    for (LevelplanWrapper *level in self.levels) {
        if (levelNumber == level.levelNumber && (self.currentLevel != level || forced)) {
            self.currentLevelIndex = level.levelNumber;
            self.currentLevel = level;
                            
            [self updateLevelLabel:self.currentLevel];
        }
    }
}

- (void) updateLevelLabel:(LevelplanWrapper*)newLevel
{
    self.currentLevel = newLevel;
    self.currentLevelLabel.text = [NSString stringWithFormat:@"%ld", (long)newLevel.levelNumber];
    [self checkPickerState];
    
    for(UIImageView* img in self.levelIndicatorImages){
        [img removeFromSuperview];
    }
    NSMutableArray* indicatorImages = [NSMutableArray arrayWithCapacity:self.levels.count];
    NSInteger height = 6*self.levels.count + 8;//we have one layer that is 2px larger
    NSInteger y = 55+height/2;
    //we paint images from bottom to the top
    for(LevelplanWrapper* level in _levels){
        BOOL isCentralLevel = NO;
        NSString* imgName = @"Ebenenswitch_Inaktiv_Small";
        if(level.levelNumber == 0){
            imgName = @"Ebenenswitch_Inaktiv";
            isCentralLevel = YES;
        }
        if(level.levelNumber == newLevel.levelNumber){
            imgName = @"Ebenenswitch_Aktiv_Small";
            if(level.levelNumber == 0){
                imgName = @"Ebenenswitch_Aktiv";
                isCentralLevel = YES;
            }
        }
        UIImageView* img = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:imgName]];
        [indicatorImages addObject:img];
        
        [self addSubview:img];
        [img centerViewHorizontalInSuperView];
        if(isCentralLevel){
            y -= 6;
        }
        [img setY:y];
        if(isCentralLevel){
            y -= 2;
        } else {
            y -= 6;
        }
    }
    [self bringSubviewToFront:self.currentLevelLabel];
    self.levelIndicatorImages = indicatorImages;
    
    
    if ([self.delegate respondsToSelector:@selector(picker:didChangeToLevel:)]) {
        [self.delegate picker:self didChangeToLevel:self.currentLevel];
    }
    
}

@end
