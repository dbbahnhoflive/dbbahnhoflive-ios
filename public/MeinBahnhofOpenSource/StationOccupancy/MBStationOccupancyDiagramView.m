// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBStationOccupancyDiagramView.h"
#import "UIFont+DBFont.h"
#import "UIView+Frame.h"

@interface MBStationOccupancyDiagramView()
@property(nonatomic,strong) NSMutableArray<UIView*>* hourBars;
@property(nonatomic,strong) NSMutableArray<UIView*>* hourLines;
@property(nonatomic,strong) NSMutableArray<UILabel*>* hourLabels;
@property(nonatomic,strong) UIView* topLine;
@property(nonatomic,strong) UIView* middleLine;
@property(nonatomic,strong) UIView* bottomLine;
@property(nonatomic,strong) UIView* currentDay;
@property(nonatomic,strong) UIView* barClipView;
@end

@implementation MBStationOccupancyDiagramView

#define kBarRounding 2

-(instancetype)init{
    self = [super init];
    if(self){
        self.backgroundColor = [UIColor whiteColor];
        
        self.hourBars = [NSMutableArray arrayWithCapacity:24];
        self.hourLines = [NSMutableArray arrayWithCapacity:24];
        self.hourLabels = [NSMutableArray arrayWithCapacity:8];
        
        self.topLine = [UIView new];
        [self addSubview:self.topLine];
        self.middleLine = [UIView new];
        [self addSubview:self.middleLine];
        self.bottomLine = [UIView new];
        [self addSubview:self.bottomLine];
        self.topLine.backgroundColor = self.middleLine.backgroundColor = self.bottomLine.backgroundColor = [UIColor dbColorWithRGB:0xAFB4BB];

        NSArray* times = @[@"1:00",@"4:00",@"7:00",@"10:00",@"13:00",@"16:00",@"19:00",@"22:00"];
        for(NSString* time in times){
            UILabel* hourLabel = [UILabel new];
            hourLabel.isAccessibilityElement = NO;
            hourLabel.text = time;
            hourLabel.font = [UIFont db_BoldTen];
            hourLabel.textColor = UIColor.blackColor;
            [hourLabel sizeToFit];
            [self.hourLabels addObject:hourLabel];
            [self addSubview:hourLabel];
        }
        
        self.barClipView = [UIView new];
        self.barClipView.clipsToBounds = YES;
        self.barClipView.backgroundColor = UIColor.clearColor;

        for(NSInteger i=0; i<24; i++){
            UIView* bar = [UIView new];
            bar.backgroundColor = [UIColor dbColorWithRGB:0xC8CDD2];
            bar.layer.cornerRadius = kBarRounding;
            [self.barClipView addSubview:bar];
            [self.hourBars addObject:bar];
            
            UIView* lines = [UIView new];
            lines.backgroundColor = [UIColor dbColorWithRGB:0xAFB4BB];
            [self addSubview:lines];
            [self.hourLines addObject:lines];
        }

        [self addSubview:self.barClipView];
        self.currentDay = [UIView new];
        self.currentDay.backgroundColor = [UIColor dbColorWithRGB:0x347DE0];
        self.currentDay.layer.cornerRadius = kBarRounding;
        [self.barClipView addSubview:self.currentDay];
        
    }
    return self;
}

-(void)setOccupancy:(MBStationOccupancy *)occupancy{
    _occupancy = occupancy;
    if(occupancy.currentCount > 0 && self.currentWeekday == self.occupancy.currentDay){
        self.isAccessibilityElement = YES;
        self.accessibilityLabel = [NSString stringWithFormat:@"Aktuell: %ld bis %ld Uhr, %ld Prozent.",_occupancy.currentHour,_occupancy.currentHour+1,(long)((_occupancy.currentCount/255.)*100.)];
    } else {
        self.isAccessibilityElement = NO;
    }
    [self setNeedsLayout];
}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    self.topLine.frame = CGRectMake(0, 2, self.frame.size.width, 1);
    self.middleLine.frame = CGRectMake(0, 35, self.frame.size.width, 1);
    self.bottomLine.frame = CGRectMake(0, 66, self.frame.size.width, 1);

    //draw bars
    NSArray* hourPoints = nil;
    if(self.currentWeekday < self.occupancy.averageCounts.count){
        hourPoints = self.occupancy.averageCounts[self.currentWeekday];
    }
    NSInteger labelIndex = 0;
    NSInteger index = 0;
    NSInteger x = 1;
    NSInteger currentX = 0;
    NSNumber* currentValue = nil;
    UIView* currentHourBar = nil;
    double maxHeight = 66.;
    NSInteger barW = (self.frame.size.width-23*2)/24;
    
    self.barClipView.frame = CGRectMake(0, 0, self.frame.size.width, maxHeight);
    
    for(UIView* bar in self.hourBars){
        NSNumber* value = @0;
        if(hourPoints && index < hourPoints.count){
            value = hourPoints[index];
        }
        NSInteger barH = maxHeight*(value.integerValue/255.);
        barH += barW;
        bar.frame = CGRectMake(x, 0, barW, barH);
        [bar setGravityBottom:-barW];
        if(index == self.occupancy.currentHour){
            currentX = x;
            currentValue = value;
            currentHourBar = bar;
        }
        x += barW;
        
        UIView* line = self.hourLines[index];
        line.frame = CGRectMake(x, self.frame.size.height-18, 1, (index%3)==0 ? 6 : 4);
        if((index%3)==0){
            UIView* label = self.hourLabels[labelIndex++];
            [label centerViewHorizontalWithView:line];
            [label setBelow:self.bottomLine withPadding:5];
        }
        x += 2;
        index++;
    }
    
    if(self.currentWeekday == self.occupancy.currentDay){
        //self.currentDayClipView.frame = CGRectMake(currentX, 1, barW, maxHeight);
        NSInteger barH = maxHeight*(self.occupancy.currentCount/255.);
        barH += barW;//we move the view outside of the clipview to get a flat bottom
        self.currentDay.frame = CGRectMake(currentX, 0, barW, barH);
        //self.currentDay.layer.cornerRadius = (self.currentDay.sizeWidth/2);
        [self.currentDay setGravityBottom:-barW];//-barW];
        self.currentDay.hidden = NO;
        if(self.occupancy.currentCount > currentValue.integerValue){
            currentHourBar.alpha = 0.2;
            [self.barClipView bringSubviewToFront:currentHourBar];
        } else {
            currentHourBar.alpha = 1;
            [self.barClipView bringSubviewToFront:self.currentDay];
        }
    } else {
        self.currentDay.hidden = YES;
    }
}

@end
