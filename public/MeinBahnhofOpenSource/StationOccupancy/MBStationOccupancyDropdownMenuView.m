// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBStationOccupancyDropdownMenuView.h"
#import "MBStationOccupancyDayView.h"
#import "MBUIHelper.h"

@interface MBStationOccupancyDropdownMenuView()
@end

@implementation MBStationOccupancyDropdownMenuView

-(instancetype)initWithWeekday:(NSInteger)weekday today:(NSInteger)today{
    self = [super initWithFrame:CGRectMake(0, 0, 140, 221)];
    if(self){
        BOOL isToday = weekday == today;
        self.clipsToBounds = YES;
        self.layer.borderColor = [UIColor db_dadada].CGColor;
        self.layer.borderWidth = 2;
        self.layer.cornerRadius = 15;
        self.backgroundColor = [UIColor whiteColor];
        
        UIButton* closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 36)];
        [closeBtn setTitleColor:isToday ? [UIColor dbColorWithRGB:0x76C030] : UIColor.blackColor forState:UIControlStateNormal];
        if(isToday){
            [closeBtn setTitle:MBStationOccupancyDayView.weekdayToday forState:UIControlStateNormal];
        } else {
            [closeBtn setTitle:MBStationOccupancyDayView.weekdays[weekday] forState:UIControlStateNormal];
        }
        closeBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        closeBtn.contentEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 0);
        closeBtn.titleLabel.font = [UIFont db_BoldFourteen];
        [closeBtn addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:closeBtn];
        
        UIImageView* arrow = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"occupancy_arrow_down"]];
        [closeBtn addSubview:arrow];
        [arrow setGravityTop:14];
        [arrow setGravityRight:16];
        
        UIView* line = [[UIView alloc] initWithFrame:CGRectMake(0, 34, self.frame.size.width, 1)];
        line.backgroundColor = [UIColor db_dadada];
        [self addSubview:line];
        
        NSInteger y = CGRectGetMaxY(line.frame)+4;
        for(NSInteger index=0; index<7; index++){
            UIButton* dayBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, y, self.frame.size.width, 25)];
            dayBtn.tag = index;
            [dayBtn setTitleColor:index == today ? [UIColor dbColorWithRGB:0x76C030] : UIColor.blackColor forState:UIControlStateNormal];
            if(index == today){
                [dayBtn setTitle:MBStationOccupancyDayView.weekdayToday forState:UIControlStateNormal];
            } else {
                [dayBtn setTitle:MBStationOccupancyDayView.weekdays[index] forState:UIControlStateNormal];
            }
            if(index == weekday){
                dayBtn.enabled = NO;
                dayBtn.alpha = 0.3;
            }
            dayBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            dayBtn.contentEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 0);
            dayBtn.titleLabel.font = [UIFont db_BoldFourteen];
            [dayBtn addTarget:self action:@selector(day:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:dayBtn];
            y += dayBtn.frame.size.height;
        }
    }
    return self;
}

-(void)close:(id)sender{
    [self.delegate closeDropDown:self];
}
-(void)day:(UIButton*)sender{
    [self.delegate changeDayTo:sender.tag fromDropdown:self];
}

@end
