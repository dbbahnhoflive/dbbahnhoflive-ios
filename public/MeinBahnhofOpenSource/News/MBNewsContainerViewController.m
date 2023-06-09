// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBNewsContainerViewController.h"
#import "MBNewsContainerView.h"
#import "MBUIHelper.h"


@interface MBNewsContainerViewController ()<UIScrollViewDelegate>
@property(nonatomic,strong) UIScrollView* scrollView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property(nonatomic,strong) NSMutableArray* newsViews;
@end

@implementation MBNewsContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor clearColor];
    self.view.clipsToBounds = NO;
    
    self.newsViews = [NSMutableArray arrayWithCapacity:10];
    
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.clipsToBounds = NO;
    self.scrollView.delegate = self;
    [self.view addSubview:self.scrollView];
    self.scrollView.pagingEnabled = YES;
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:self.scrollView];
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    
    self.pageControl = [[UIPageControl alloc] init];
    self.pageControl.numberOfPages = 0;
    self.pageControl.accessibilityLabel = @"Aktuelle Informationen";
    self.pageControl.transform = CGAffineTransformMakeScale(0.6, 0.6);//scale down
    self.pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    self.pageControl.currentPageIndicatorTintColor = [UIColor db_mainColor];
    [self.pageControl addTarget:self action:@selector(pageControlChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.pageControl];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    [self.pageControl setGravityBottom:0];
    [self.pageControl setSize:CGSizeMake(self.view.frame.size.width, 25)];
    
    self.scrollView.frame = CGRectMake(-8, 0, self.view.frame.size.width+2*8, self.view.frame.size.height-25);
    self.scrollView.contentSize = CGSizeMake(_newsList.count*(self.scrollView.frame.size.width), self.scrollView.frame.size.height);
    
    
}

-(void)layoutScrollViewContent{
    [self.newsViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSInteger x = 8;
    for(MBNews* news in _newsList){
        MBNewsContainerView* newsView = [[MBNewsContainerView alloc] initWithFrame:CGRectMake(x, 0, self.scrollView.frame.size.width-2*8, self.scrollView.frame.size.height) news:news];
        newsView.containerVC = self;
        [self.scrollView addSubview:newsView];
        [self.newsViews addObject:newsView];
        newsView.news = news;
        x += self.scrollView.frame.size.width;
    }
}

-(void)setNewsList:(NSArray *)newsList{
    /*
    //use test data
    if(newsList.count > 0){
        NSMutableArray* testData = [NSMutableArray array];
        for(NSInteger x = 0; x<20; x++){
            [testData addObject:newsList.firstObject];
        }
        newsList = testData;
    }*/
    _newsList = newsList;
    
    self.pageControl.numberOfPages = newsList.count;
    self.pageControl.hidden = self.pageControl.numberOfPages <= 1;
    [self layoutScrollViewContent];
    [self.view setNeedsLayout];
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
