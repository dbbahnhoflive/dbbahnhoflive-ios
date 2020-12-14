 // SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
 //
 // SPDX-License-Identifier: Apache-2.0
 //


#import "SectionIndicatorView.h"
#import "IndicatorWaggonView.h"
#import "UIScrollView+MBScrollView.h"

@interface SectionIndicatorView()

@property (nonatomic, strong) UIView *sectionContainer;
@property (nonatomic, strong) UIView *sectionLabelContainer;
@property (nonatomic, strong) UIView *sectionHighlightContainer;

@property (nonatomic, strong) NSMutableArray *sectionViews;
@property (nonatomic, strong) NSMutableArray *waggonViews;

@property (nonatomic, strong) UIScrollView *horizontalScrollView;

@property (nonatomic, assign) BOOL initialized;
@property (nonatomic, assign) NSInteger activeWaggonIndex;
@property (nonatomic, strong) NSString *activeSectionCode;

@end

@implementation SectionIndicatorView

static const NSInteger normalWaggonLength = 30;
static const NSInteger shortWaggonLength = 20;
static const NSInteger waggonHeight = 15;

- (instancetype) initWithWagenstand:(Wagenstand*)wagenstand andFrame:(CGRect)frame;
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        
        self.wagenstand = wagenstand;
        
        self.sectionViews = [NSMutableArray array];
        self.waggonViews = [NSMutableArray array];
        self.activeWaggonIndex = -1;
    
        self.sectionContainer = [[UIView alloc] init];
        self.horizontalScrollView = [[UIScrollView alloc] init];
        self.sectionLabelContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.sizeWidth, 30)];
        
        [self.horizontalScrollView addSubview:self.sectionLabelContainer];
        
        UIView *insideContainerView = [[UIView alloc] init];
        UIView *previousWaggon = nil;
        NSString *currentSection = nil;
        
        for (int i = 0; i < self.wagenstand.waggons.count; i++) {
            
            Waggon *waggon = self.wagenstand.waggons[i];
            /*Waggon *nextWaggon;
            if (i+1 < self.wagenstand.waggons.count) {
                nextWaggon = self.wagenstand.waggons[i+1];
            }*/
            
            NSString *section = [waggon.sections lastObject];
            UILabel *sectionLabel;
            
            if ((!currentSection || ![section isEqualToString:currentSection])) {
                currentSection = section;
                sectionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
                sectionLabel.backgroundColor = [UIColor whiteColor];
                sectionLabel.textColor = [UIColor db_lightGrayTextColor];
                sectionLabel.font = [UIFont db_HelveticaBoldFourteen];
                sectionLabel.textAlignment = NSTextAlignmentCenter;
                sectionLabel.text = section;
                sectionLabel.userInteractionEnabled = YES;
                sectionLabel.isAccessibilityElement = NO;
                
                UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnSection:)];
                [sectionLabel addGestureRecognizer:tapGestureRecognizer];
                
                [self.sectionViews addObject:sectionLabel];
            } else {
                [self.sectionViews addObject:[[UILabel alloc] init]];
            }
            
            NSInteger lengthOfWaggon = waggon.length;
            NSInteger waggonDimension = shortWaggonLength;
            
            if (lengthOfWaggon > 1.0) {
                waggonDimension = normalWaggonLength;
            }
            
            if(waggon.isTrainBackWithDirection || waggon.isTrainHeadWithDirection){
                waggonDimension = 24;
            } else if(waggon.isTrainBothWays){
                waggonDimension = 34;//??
            }
            
            CGRect frame = CGRectMake(0,0, waggonDimension, waggonHeight);
            IndicatorWaggonView *composedWaggonView = [[IndicatorWaggonView alloc] initWithFrame:frame andWaggon:waggon];
            
            [insideContainerView addSubview:composedWaggonView];
            [self.waggonViews addObject:composedWaggonView];
            
            [composedWaggonView setRight:previousWaggon withPadding:1];
            [composedWaggonView setBelow:self.sectionLabelContainer withPadding:3];
            
            if (sectionLabel) {
                [insideContainerView addSubview:sectionLabel];
                sectionLabel.x = composedWaggonView.originX;
            }
            
            previousWaggon = composedWaggonView;
        }
        
        [insideContainerView resizeToFitSubviews];
        
        insideContainerView.x = ISIPAD ? 160 : 10;
        insideContainerView.width = insideContainerView.sizeWidth+(ISIPAD ? 160 : 10);
        
        [self.horizontalScrollView addSubview:insideContainerView];
        
        
        [self addSubview:self.sectionContainer];
        [self.sectionContainer addSubview:self.horizontalScrollView];
        
        [self.sectionContainer resizeHeight];
        
        [self.horizontalScrollView setShowsHorizontalScrollIndicator:NO];
        [self.horizontalScrollView setShowsVerticalScrollIndicator:NO];
        //[self.horizontalScrollView setContentInset:UIEdgeInsetsMake(0,40,0,40)];
        //[self.horizontalScrollView setContentOffset:CGPointMake(-40, 0)];
        
        //Waggon *firstWaggon = [self.wagenstand.waggons firstObject];
        NSString *firstSection = [[self.sectionViews firstObject] text];//[firstWaggon.sections lastObject];
        [self setActiveSection:firstSection atIndex:0 animateTo:NO];
    }
    return self;
}

-(void) setMaskTo:(UIView*)view byRoundingCorners:(UIRectCorner)corners
{
    UIBezierPath* rounded = [UIBezierPath bezierPathWithRoundedRect:view.bounds byRoundingCorners:corners cornerRadii:CGSizeMake(1.5, 1.5)];
    
    CAShapeLayer* shape = [[CAShapeLayer alloc] init];
    [shape setPath:rounded.CGPath];
    
    view.layer.mask = shape;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    if (!self.initialized) {
        self.initialized = YES;
        
        self.sectionContainer.size = CGSizeMake(self.sizeWidth, self.sizeHeight);
        self.horizontalScrollView.size = CGSizeMake(self.sizeWidth, 55);
        self.horizontalScrollView.contentSize = [self.horizontalScrollView calculateContentSizeHorizontally];
        self.horizontalScrollView.contentSize = CGSizeMake(self.horizontalScrollView.contentSize.width/*+40*/,
                                                           self.horizontalScrollView.contentSize.height); // offset

        [self.sectionContainer resizeHeight];
        [self.sectionContainer centerViewVerticalInSuperView];
    }
}

- (void)didTapOnSection:(UITapGestureRecognizer*)sender
{
    if ([sender.view isKindOfClass:UILabel.class]) {
        NSString *section = ((UILabel*)sender.view).text;
        [self.delegate sectionView:self didSelectSection:section];
    }
}

- (UILabel*) setActiveSection:(NSString*)sectionCode;
{
    UILabel *label = nil;
    for (UILabel *sectionLabel in self.sectionViews) {
        if ([sectionCode isEqualToString:sectionLabel.text]) {
            label = sectionLabel;
        }
    }
    return label;
}

- (void) setActiveWaggon:(NSInteger)index;
{
    if (self.activeWaggonIndex != index && self.activeWaggonIndex > -1) {
        IndicatorWaggonView *newHighlightedWaggon = self.waggonViews[index];
        IndicatorWaggonView *oldHighlightedWaggon = self.waggonViews[self.activeWaggonIndex];
        [oldHighlightedWaggon setHighlighted:NO];
        [newHighlightedWaggon setHighlighted:YES];
        
        UILabel *sectionLabel = self.sectionViews[index];
        sectionLabel.backgroundColor = [UIColor whiteColor];
        sectionLabel.textColor = [UIColor db_333333];
        
        UILabel *oldSectionLabel = self.sectionViews[self.activeWaggonIndex];
        oldSectionLabel.backgroundColor = [UIColor whiteColor];
        oldSectionLabel.textColor = [UIColor db_lightGrayTextColor];
        
    } else {
        IndicatorWaggonView *newHighlightedWaggon = self.waggonViews[index];
        [newHighlightedWaggon setHighlighted:YES];
        UILabel *sectionLabel = self.sectionViews[index];
        sectionLabel.backgroundColor = [UIColor whiteColor];
        sectionLabel.textColor = [UIColor db_333333];

    }
    self.activeWaggonIndex = index;
}

- (void) setActiveWaggonAtIndex:(NSInteger)index animateTo:(BOOL)animateTo;
{
    
}

- (void) setActiveSection:(NSString*)section atIndex:(NSInteger)index animateTo:(BOOL)animateTo
{
    UILabel *activeLabel = [self setActiveSection:section];
    
    if (activeLabel && ![section isEqualToString:self.activeSectionCode]) {
        
        NSInteger activeSectionIndex = [self.sectionViews indexOfObject:activeLabel];
        [self setActiveWaggon:activeSectionIndex];
        
        BOOL firstSection = activeSectionIndex == 0;
        
        BOOL lastSection = NO;
        for (UILabel *label in self.sectionViews) {
            if (label.text.length > 0) {
                lastSection = NO;
                if ([label.text isEqualToString:section]) {
                    lastSection = YES;
                } else {
                }
            }
        }
                        
        double offset = 0;
        
        if (firstSection) {
            offset = 0;
        } else if (lastSection) {
            offset = self.horizontalScrollView.contentSize.width-1;
        } else if ((activeLabel.originX)+activeLabel.sizeWidth+60 >= self.horizontalScrollView.sizeWidth) {
            offset = activeLabel.originX+80;
        } else if ((activeLabel.originX) < self.horizontalScrollView.contentOffset.x) {
            offset = activeLabel.originX-80;
        }
                
        [self.horizontalScrollView scrollRectToVisible:CGRectMake(offset,
                                                                  self.horizontalScrollView.originY,
                                                                  self.horizontalScrollView.sizeWidth,
                                                                  self.horizontalScrollView.sizeHeight) animated:YES];
        
        self.activeSectionCode = section;
    }
}

@end
