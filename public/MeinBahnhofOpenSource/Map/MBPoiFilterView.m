// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBPoiFilterView.h"
#import "MBPoiFilterContentView.h"
#import "MBLargeButton.h"

#define kPadding 20.f

#define kHeaderSize 50.f

@interface MBPoiFilterView()<MBPoiFilterContentViewDelegate>

@property (nonatomic, strong) NSArray *categories;

@property(nonatomic,strong) UIView* backgroundView;
@property(nonatomic,strong) UIView* contentView;
@property(nonatomic,strong) UIView* headerView;

@property(nonatomic,strong) UILabel* titleLabel;
@property(nonatomic,strong) UIButton* filterBackButton;

@property(nonatomic,strong) UIView* confirmView;

@property(nonatomic,strong) NSMutableArray<MBPoiFilterContentView*>* filterTableViews;

@end

@implementation MBPoiFilterView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(instancetype)initWithFrame:(CGRect)frame categories:(NSArray *)categories{
    self = [super initWithFrame:frame];
    if(self){
        self.categories = categories;
        
        self.filterTableViews = [NSMutableArray arrayWithCapacity:3];
        
        self.backgroundColor = [UIColor clearColor];
        self.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        self.backgroundView.backgroundColor = [UIColor blackColor];
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        [self.backgroundView addGestureRecognizer:tap];
        [self addSubview:self.backgroundView];
        
        UIView* headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, kHeaderSize)];
        headerView.backgroundColor = [UIColor db_HeaderColor];
        self.headerView = headerView;
        headerView.layer.shadowOffset = CGSizeMake(0, -2);
        headerView.layer.shadowColor = [UIColor blackColor].CGColor;
        headerView.layer.shadowOpacity = 0.4;
        
        UIButton* closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        [closeBtn setImage:[UIImage db_imageNamed:@"app_schliessen"] forState:UIControlStateNormal];
        [closeBtn addTarget:self action:@selector(closeCancel) forControlEvents:UIControlEventTouchUpInside];
        [_headerView addSubview:closeBtn];
        [closeBtn setGravityRight:0];
        
        NSInteger height = [self heightForContentViewWithCategories:categories];
        
        self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height-height, self.frame.size.width, height)];
        self.contentView.backgroundColor = [UIColor whiteColor];
        [self addSubview:self.contentView];
        
        self.confirmView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, DEFAULT_CONFIRM_AREA_HEIGHT)];
        self.confirmView.backgroundColor = [UIColor whiteColor];
        [self addSubview:_confirmView];
        self.confirmView.layer.shadowOffset = CGSizeMake(0, -2);
        self.confirmView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.confirmView.layer.shadowOpacity = 0.2;
        
        MBLargeButton* confirmButton = [[MBLargeButton alloc] initWithFrame:CGRectMake(16, 16, self.frame.size.width-2*16, 60)];
        [confirmButton setTitle:@"Übernehmen" forState:UIControlStateNormal];
        [confirmButton addTarget:self action:@selector(tapSave:) forControlEvents:UIControlEventTouchUpInside];

        [self.confirmView addSubview:confirmButton];

        self.filterBackButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, 30, 30)];
        [self.filterBackButton setImage:[UIImage db_imageNamed:@"MapFilterBack"] forState:UIControlStateNormal];
        [self.filterBackButton addTarget:self action:@selector(filterBackButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [headerView addSubview:self.filterBackButton];
        self.titleLabel = [[UILabel alloc] init];
        
        [self.titleLabel setFont:[UIFont db_BoldSeventeen]];
        [self.titleLabel setTextColor:[UIColor db_333333]];
        [headerView addSubview:self.titleLabel];
        
        MBPoiFilterContentView* content = [[MBPoiFilterContentView alloc] initWithFrame:CGRectMake(0, headerView.size.height, self.frame.size.width, self.contentView.size.height-headerView.sizeHeight-DEFAULT_CONFIRM_AREA_HEIGHT) items:categories parent:nil];
        [self.contentView addSubview:content];
        content.delegate = self;
        [self.filterTableViews addObject:content];

        [self.contentView addSubview:headerView];

        [self.confirmView setGravityBottom:0];
        
        [self configureHeader];
    }
    return self;
}

-(NSArray *)currentFilterCategories{
    return self.categories;
}

-(void)animateInitialView{
    CGFloat y = self.contentView.frame.origin.y;
    [self.contentView setY:self.frame.size.height];
    self.backgroundView.alpha = 0.;
    [self.confirmView setY:self.frame.size.height];
    [UIView animateWithDuration:0.3 animations:^{
        [self.contentView setY:y];
        self.backgroundView.alpha = 0.7;
        [self.confirmView setGravityBottom:0];
    }];
}

-(NSInteger)heightForContentViewWithCategories:(NSArray*)categories{
    NSInteger height = kHeaderSize+60*categories.count+60 + DEFAULT_CONFIRM_AREA_HEIGHT;
    if(height > self.sizeHeight-108){//108 is the space between the top of the screen and the header navigation bar
        return self.sizeHeight-108;
    }
    return height;
}

-(void)tap:(UITapGestureRecognizer*)sender{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        [self closeCancel];
    }
}
-(void)closeCancel{
    [UIView animateWithDuration:0.3 animations:^{
        [self.contentView setY:self.frame.size.height];
        self.backgroundView.alpha = 0.;
        [self.confirmView setY:self.frame.size.height];;
    } completion:^(BOOL finished) {
        [self.delegate poiFilterWantsClose:self];
    }];
}
-(void)tapSave:(UIButton*)sender{
    [UIView animateWithDuration:0.3 animations:^{
        [self.contentView setY:self.frame.size.height];
        self.backgroundView.alpha = 0.;
        [self.confirmView setY:self.frame.size.height];
    } completion:^(BOOL finished) {
        [self.delegate poiFilterDidChangeFilter:self];
        [self.delegate poiFilterWantsClose:self];
    }];
}

-(void)configureHeader{
    if(self.filterTableViews.count <= 1){
        self.titleLabel.frame = CGRectMake(20, 0, self.frame.size.width, 50);
        self.titleLabel.text = @"Filter Einstellungen";
        self.filterBackButton.alpha = 0;
    } else {
        self.filterBackButton.alpha = 1;
        self.titleLabel.frame = CGRectMake(50-12, 0, self.frame.size.width, 50);
        self.titleLabel.text = self.filterTableViews.lastObject.parentCategory.title;
    }

}

-(void)filterBackButtonPressed{
    if(self.filterTableViews.count <= 1){
        //should not happen
    } else {
        //more than one
        MBPoiFilterContentView* lastView = self.filterTableViews.lastObject;
        [lastView removeFromSuperview];
        [self.filterTableViews removeLastObject];
        
        MBPoiFilterContentView* previousView = self.filterTableViews.lastObject;
        NSInteger height = [self heightForContentViewWithCategories:previousView.categories];

        previousView.alpha = 0;
        previousView.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            [self.contentView setHeight:height];
            [self.contentView setGravityBottom:0];
            previousView.alpha = 1;
        }];
        
        [self updateAllSwitches];
    }
    [self configureHeader];

}

- (void) poiContent:(MBPoiFilterContentView*)view didChangeCategory:(POIFilterItem*)item{
    //[self updateFilterValues];
}

-(void)poiContent:(MBPoiFilterContentView *)view didSelectCategory:(POIFilterItem *)item{
    MBPoiFilterContentView* lastView = self.filterTableViews.lastObject;
    
    NSInteger height = [self heightForContentViewWithCategories:item.subItems];

    MBPoiFilterContentView* content = [[MBPoiFilterContentView alloc] initWithFrame:CGRectMake(0, kHeaderSize, self.frame.size.width, self.contentView.size.height-kHeaderSize-DEFAULT_CONFIRM_AREA_HEIGHT) items:item.subItems parent:item];
    [self.contentView addSubview:content];
    content.delegate = self;
    [self.filterTableViews addObject:content];
    content.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{
        lastView.alpha = 0;
        [self configureHeader];
        [self.contentView setHeight:height];
        [self.contentView setGravityBottom:0];
        [self.headerView setGravityTop:0];
    } completion:^(BOOL finished) {
        content.alpha = 1;
    }];
}
-(void)poiContent:(MBPoiFilterContentView *)view didToggleAll:(BOOL)selected{
    [self updateAllSwitches];
}

//- (void) updateFilterValues
//{

//    [self.delegate poiFilterDidChangeFilter:self];
//}

-(void)updateAllSwitches{
    for(MBPoiFilterContentView* content in self.filterTableViews){
        [content reloadData];
    }
    //[self updateFilterValues];
}


@end
