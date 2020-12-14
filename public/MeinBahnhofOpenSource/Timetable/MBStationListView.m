// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBStationListView.h"
@interface MBStationListView()

@property(nonatomic,strong) UIScrollView* scrollView;
@property(nonatomic,strong) NSMutableArray<UIView*>* scrollViewSubviews;
@property(nonatomic,strong) NSMutableArray<UIView*>* labels;
@property(nonatomic,strong) NSMutableArray<UIView*>* dots;

@property(nonatomic,strong) UIView* line;

@end

@implementation MBStationListView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [self addSubview:self.scrollView];
        
        self.scrollViewSubviews = [NSMutableArray arrayWithCapacity:50*3];
        self.labels = [NSMutableArray arrayWithCapacity:50];
        self.dots = [NSMutableArray arrayWithCapacity:50];
        
        self.line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 2)];
        
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

-(void)setStations:(NSArray<NSString *> *)stations{
    _stations = stations;
    
    [self.scrollViewSubviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.scrollViewSubviews removeAllObjects];
    [self.labels removeAllObjects];
    [self.dots removeAllObjects];
    
    BOOL first = YES;
    for(NSString* station in stations){
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.text = station;
        label.font = first ? [UIFont db_BoldFourteen] : [UIFont db_RegularFourteen];
        label.textColor = first ? [UIColor db_333333] : [UIColor colorWithRed:155./255. green:160./255. blue:170./255. alpha:1.];
        [label sizeToFit];
        [self.labels addObject:label];
        
        if(!first){
            self.line.backgroundColor = label.textColor;
        }
        
        UIView* dot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14, 14)];
        dot.backgroundColor = self.backgroundColor;
        dot.layer.masksToBounds = YES;
        dot.layer.cornerRadius = 7;
        UIView* innerdot = [[UIView alloc] initWithFrame:CGRectMake(2, 2, 10, 10)];
        innerdot.backgroundColor = label.textColor;
        innerdot.layer.masksToBounds = YES;
        innerdot.layer.cornerRadius = 5;
        [dot addSubview:innerdot];
        [self.dots addObject:dot];
        
        first = NO;
    }
    
    [self.scrollViewSubviews addObjectsFromArray:self.labels];
    [self.scrollViewSubviews addObjectsFromArray:self.dots];
    for(UIView* v in self.scrollViewSubviews){
        [self.scrollView addSubview:v];
    }
    
    [self setNeedsLayout];
}

-(void)layoutSubviews{
    [super layoutSubviews];
    self.scrollView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    
    int x = 25;
    int i = 0;
    for(UIView* label in self.labels){
        [label setY:48];
        [label setX:x];
        
        UIView* dot = [self.dots objectAtIndex:i];
        [dot setY:30];
        [dot setX:((int)(CGRectGetMidX(label.frame)-dot.size.width/2.))];
        
        x += label.sizeWidth+22;
        i++;
    }
    
    [self.scrollView insertSubview:self.line atIndex:0];
    [self.line setX:CGRectGetMidX(self.dots.firstObject.frame)];
    [self.line setY:ceilf(CGRectGetMidY(self.dots.firstObject.frame)-self.line.size.height/2.)];
    [self.line setWidth:CGRectGetMidX(self.dots.lastObject.frame)-CGRectGetMidX(self.dots.firstObject.frame)];
    
    [self.scrollView setContentSize:CGSizeMake(x, self.scrollView.sizeHeight)];
}

@end
