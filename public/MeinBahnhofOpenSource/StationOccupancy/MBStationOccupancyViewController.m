// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBStationOccupancyViewController.h"
#import "MBStationOccupancyDayView.h"
#import "MBStationOccupancyDropdownMenuView.h"

@interface MBStationOccupancyViewController ()<UIScrollViewDelegate,MBStationOccupancyDayViewDelegate,MBStationOccupancyDropdownMenuViewDelegate>
@property(nonatomic,strong) UIScrollView* scrollView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property(nonatomic,strong) NSArray<MBStationOccupancyDayView*>* dayViews;
@end


@implementation MBStationOccupancyViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor clearColor];
    self.view.clipsToBounds = NO;

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.clipsToBounds = NO;
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    
    self.pageControl = [[UIPageControl alloc] init];
    self.pageControl.numberOfPages = 7;
    self.pageControl.accessibilityLabel = @"Besucheraufkommen";
    self.pageControl.transform = CGAffineTransformMakeScale(0.6, 0.6);//scale down
    self.pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    self.pageControl.currentPageIndicatorTintColor = [UIColor db_mainColor];
    [self.pageControl addTarget:self action:@selector(pageControlChanged:) forControlEvents:UIControlEventValueChanged];

    [self.view addSubview:self.scrollView];
    [self.view addSubview:self.pageControl];

    NSMutableArray* dayViews = [NSMutableArray arrayWithCapacity:self.pageControl.numberOfPages];
    for(NSInteger i=0; i<self.pageControl.numberOfPages; i++){
        MBStationOccupancyDayView* dayView = [[MBStationOccupancyDayView alloc] initWithWeekday:i isToday:i==self.currentWeekday];
        dayView.delegate = self;
        dayView.tag = i;
        [self.scrollView addSubview:dayView];
        [dayViews addObject:dayView];
    }
    self.dayViews = dayViews;

    self.pageControl.currentPage = [self currentWeekday];
}

-(void)loadData{
    for(MBStationOccupancyDayView* dayView in self.dayViews){
        [dayView loadData:self.station.occupancy];
    }
}

-(NSInteger)currentWeekday{
    NSInteger iosWeekday = [NSCalendar.currentCalendar component:NSCalendarUnitWeekday fromDate:NSDate.date];
    //this is from 1..7 where 1 is sunday, we transfer it to 0..6 where 0 is monday
    NSInteger weekday = iosWeekday-2;
    if(weekday < 0){
        weekday = 6;
    }
    return weekday;
}

-(void)openDropdownFromView:(UIView *)btn inDayView:(nonnull MBStationOccupancyDayView *)view{
    //- push a dropdownview on the stationviewcontroller
    NSInteger weekday = view.tag;
    
    MBStationOccupancyDropdownMenuView* menu = [[MBStationOccupancyDropdownMenuView alloc] initWithWeekday:weekday today:[self currentWeekday]];
    menu.delegate = self;
    //we add the menu in the collectionview that contains this view to allow the dropdown to extend below the current view
    UIView* targetview = self.view.superview.superview;//self.view;
    CGRect r = [targetview convertRect:btn.frame fromView:view];
    [targetview addSubview:menu];
    [menu setGravityLeft:r.origin.x];
    [menu setGravityTop:r.origin.y];
    
    self.scrollView.scrollEnabled = NO;
}
-(void)changeDayTo:(NSInteger)index fromDropdown:(MBStationOccupancyDropdownMenuView *)dropdown{
    self.scrollView.scrollEnabled = YES;
    [dropdown removeFromSuperview];
    [self.scrollView setContentOffset:CGPointMake(self.scrollView.frame.size.width*index, 0) animated:YES];
}
-(void)closeDropDown:(MBStationOccupancyDropdownMenuView *)dropdown{
    self.scrollView.scrollEnabled = YES;
    [dropdown removeFromSuperview];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    [self.pageControl setSize:CGSizeMake(self.view.frame.size.width, 25)];
    [self.pageControl setGravityBottom:0];
    [self.pageControl centerViewHorizontalInSuperView];
    self.scrollView.frame = CGRectMake(-8, 0, self.view.frame.size.width+2*8, self.view.frame.size.height-25);
    self.scrollView.contentSize = CGSizeMake(7*(self.scrollView.frame.size.width), self.scrollView.frame.size.height);
    
    NSInteger x = 8;
    for(MBStationOccupancyDayView* day in self.dayViews){
        day.frame = CGRectMake(x, 0, self.scrollView.frame.size.width-2*8, self.scrollView.frame.size.height);
        x += self.scrollView.frame.size.width;
    }
    [self pageControlChanged:self.pageControl];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger nextPage = round(scrollView.contentOffset.x / scrollView.sizeWidth);
    self.pageControl.currentPage = nextPage;
}

-(void)pageControlChanged:(id)sender{
    self.scrollView.contentOffset = CGPointMake(_scrollView.frame.size.width*self.pageControl.currentPage, 0);
}


@end
