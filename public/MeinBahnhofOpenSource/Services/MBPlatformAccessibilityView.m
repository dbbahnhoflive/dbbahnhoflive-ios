// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: -
//

#import "MBPlatformAccessibilityView.h"
#import "MBPlatformAccessibility.h"
#import "MBTimetableFilterViewController.h"
#import "MBRootContainerViewController.h"
#import "MBStation.h"
#import "MBFilterButton.h"
#import "MBPlatformAccessibilityInfoOverlayViewController.h"
#import "MBFacilityStatusViewController.h"
#import "MBLinkButton.h"
#import "MBUIHelper.h"
#import "MBStatusImageView.h"

@interface MBPlatformAccessibilityView()<MBTimetableFilterViewControllerDelegate>
@property(nonatomic,strong) MBStation* station;
@property(nonatomic,strong) NSArray* trackList;
@property(nonatomic,strong) NSString* currentlySelectedPlatform;
@property(nonatomic,strong) MBFilterButton* filterButton;

@property(nonatomic,strong) UILabel* infoLabel;
@property(nonatomic,strong) UIImageView* infoImage;

@property(nonatomic,strong) UILabel* platformLabel;
@property(nonatomic,strong) NSMutableArray* platformViews;
@property(nonatomic,strong) UIView* footerViews;
@property(nonatomic) NSInteger configurableViewsY;

@property(nonatomic,strong) NSString* initialSelectedPlatform;

@end

@implementation MBPlatformAccessibilityView

-(instancetype)initWithFrame:(CGRect)frame station:(MBStation*)station platform:(NSString * _Nullable)platform{
    self = [super initWithFrame:frame];
    if(self){
        self.station = station;
        self.initialSelectedPlatform = platform;
        [self createView];
    }
    return self;
}

-(void)createView{
    //self.backgroundColor = UIColor.redColor;
    self.trackList = [MBPlatformAccessibility getPlatformList:self.station.platformAccessibility];
    
    self.infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 32, self.frame.size.width-50, 20)];
    self.infoLabel.font = UIFont.db_BoldSixteen;
    self.infoLabel.textColor = UIColor.db_333333;
    self.infoLabel.text = @"Ausstattung für Barrierefreiheit";
    self.infoLabel.isAccessibilityElement = NO;
    [self addSubview:self.infoLabel];
    self.infoImage = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"occupancy_information"]];
    [self addSubview:self.infoImage];
    [self.infoImage centerViewVerticalWithView:self.infoLabel];
    [self.infoImage setGravityRight:16];
    self.infoImage.isAccessibilityElement = NO;
    UIButton* infoButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 32-10, self.frame.size.width, 20+20)];
    [infoButton addTarget:self action:@selector(infoBtnPressed) forControlEvents:UIControlEventTouchUpInside];
    infoButton.accessibilityLabel = @"Ausstattung für Barrierefreiheit";
    infoButton.accessibilityHint = @"Für Anzeige von Details doppeltippen.";
    [self addSubview:infoButton];
    
    [self addShadowAt:CGRectGetMaxY(self.infoLabel.frame)+16 toView:self];
    
    self.platformLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, CGRectGetMaxY(self.infoLabel.frame)+16+5+30, self.frame.size.width-15-15-50, 20)];
    self.platformLabel.font = UIFont.db_BoldSixteen;
    self.platformLabel.textColor = UIColor.db_333333;
    self.platformLabel.text = @"Kein Gleis ausgewählt";
    self.platformLabel.accessibilityTraits |= UIAccessibilityTraitHeader;
    [self addSubview:self.platformLabel];
    
    if(self.trackList.count == 0){
        self.platformLabel.text = @"Keine Daten verfügbar";
        self.size = CGSizeMake(self.frame.size.width, CGRectGetMaxY(self.platformLabel.frame));
        return;
    }
    
    self.platformViews = [NSMutableArray arrayWithCapacity:15*2];
    
    MBFilterButton* filterButton = [[MBFilterButton alloc] init];
    self.filterButton = filterButton;
    [filterButton addTarget:self action:@selector(handleFilter:) forControlEvents:UIControlEventTouchUpInside];
    filterButton.accessibilityLabel = @"Filter für Gleis";
    filterButton.accessibilityHint = @"Zur Auswahl eines Gleises doppeltippen";
    [self addSubview:filterButton];
    [filterButton setGravityTop:self.platformLabel.frame.origin.y-15];
    [filterButton setGravityRight:15];
    
    UIView* dividerLine = [[UIView alloc] initWithFrame:CGRectMake(7, CGRectGetMaxY(self.platformLabel.frame)+20, self.frame.size.width-2*7, 1)];
    dividerLine.backgroundColor = [UIColor db_light_lineColor];
    [self addSubview:dividerLine];
    
    self.configurableViewsY = CGRectGetMaxY(dividerLine.frame)+20;
    NSLog(@"configurableViewsY=%ld",(long)self.configurableViewsY);
    UILabel* hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, _configurableViewsY, self.frame.size.width, 20)];
    hintLabel.font = [UIFont db_ItalicSixteen];
    hintLabel.textColor = UIColor.db_333333;
    hintLabel.text = @"Bitte wählen Sie ein Gleis aus.";
    [self addSubview:hintLabel];
    [self.platformViews addObject:hintLabel];
    
    UIView* footerViews = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(hintLabel.frame)+20, self.frame.size.width, 0)];
    self.footerViews = footerViews;
    
    [self addShadowAt:0 toView:footerViews];
    UILabel* facilityHintLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, self.frame.size.width-2*15, 20)];
    facilityHintLabel.numberOfLines = 0;
    facilityHintLabel.font = UIFont.db_RegularFourteen;
    facilityHintLabel.textColor = UIColor.db_333333;
    facilityHintLabel.text = @"Bitte beachten Sie, dass die Stufenfreiheit vor Ort durch Aufzugsanlagen oder Rampen ermöglicht werden kann. Eine Übersicht der Aufzugsanlagen und deren aktuelle Verfügbarkeit finden Sie hier:";
    CGSize size = [facilityHintLabel sizeThatFits:CGSizeMake(facilityHintLabel.frame.size.width, 1000)];
    [facilityHintLabel setSize:size];
    [self.footerViews addSubview:facilityHintLabel];
    
    MBLinkButton* btn = [MBLinkButton boldButtonWithRedLink];
    [btn setLabelText:@"Übersicht Aufzüge"];
    [btn setGravityLeft:15];
    [btn setGravityTop:CGRectGetMaxY(facilityHintLabel.frame)+10];
    btn.accessibilityLabel = @"Zur Übersicht der Aufzüge wechseln";
    [btn addTarget:self action:@selector(facilityBtnPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.footerViews addSubview:btn];
    [self.footerViews setHeight:CGRectGetMaxY(btn.frame)];
    [self addSubview:footerViews];

    if(self.initialSelectedPlatform && [self.trackList containsObject:self.initialSelectedPlatform]){
        [self selectTrack:self.initialSelectedPlatform];
    } else {
        if(self.trackList.count == 1){
            [self selectTrack:self.trackList.firstObject];
        } else {
            self.size = CGSizeMake(self.frame.size.width, CGRectGetMaxY(footerViews.frame));
        }
    }
}

-(void)addShadowAt:(NSInteger)y toView:(UIView*)view{
    UIView* shadowView = [[UIView alloc] initWithFrame:CGRectMake(0, y, self.frame.size.width, 5)];
    shadowView.backgroundColor = [UIColor whiteColor];
    shadowView.layer.shadowColor = [UIColor blackColor].CGColor;
    shadowView.layer.shadowOffset = CGSizeMake(0,1);
    shadowView.layer.shadowOpacity = 0.3;
    shadowView.layer.shadowRadius = 2;
    [view addSubview:shadowView];
    UIView* whiteView = [[UIView alloc] initWithFrame:CGRectMake(0, y-5, self.frame.size.width, 7)];
    whiteView.backgroundColor = UIColor.whiteColor;
    [view addSubview:whiteView];
}

-(void)facilityBtnPressed{
    MBFacilityStatusViewController *vc = [MBFacilityStatusViewController new];
    vc.station = _station;
    [self.viewController.navigationController pushViewController:vc animated:YES];
}

-(void)infoBtnPressed{
    MBPlatformAccessibilityInfoOverlayViewController* vc = [[MBPlatformAccessibilityInfoOverlayViewController alloc] init];
    [MBRootContainerViewController presentViewControllerAsOverlay:vc];
}

-(void)handleFilter:(MBFilterButton*)sender{
    MBTimetableFilterViewController* filterView = [MBTimetableFilterViewController new];
    filterView.delegate = self;
    filterView.platforms = self.trackList;
    filterView.initialSelectedPlatform = self.currentlySelectedPlatform;
    [MBRootContainerViewController presentViewControllerAsOverlay:filterView];
}
-(void)filterView:(MBTimetableFilterViewController *)filterView didSelectTrainType:(NSString *)type track:(NSString *)track{
    [self selectTrack:track];
}
-(void)selectTrack:(NSString*)track{
    self.currentlySelectedPlatform = track;
    [self.filterButton setStateActive:YES];
    MBPlatformAccessibility* p = nil;
    for(MBPlatformAccessibility* platform in self.station.platformAccessibility){
        if([platform.name isEqualToString:track]){
            p = platform;
            break;
        }
    }
    NSLog(@"selected platform %@",p);
    [self configureViewForPlatform:p];
}
-(void)configureViewForPlatform:(MBPlatformAccessibility*)platform{
    self.platformLabel.text = [NSString stringWithFormat:@"Gleis %@",platform.name];
    
    [self.platformViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.platformViews removeAllObjects];

    NSInteger y = self.configurableViewsY;
    NSInteger index = 0;
    NSArray<MBPlatformAccessibilityFeature*>* featureList = platform.availableFeatures;
    for(MBPlatformAccessibilityFeature* feature in featureList){
        index++;
        UILabel* hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, y, self.frame.size.width-2*15, 20)];
        hintLabel.isAccessibilityElement = false;
        hintLabel.numberOfLines = 0;
        hintLabel.font = UIFont.db_RegularSixteen;
        hintLabel.textColor = UIColor.db_333333;
        hintLabel.text = feature.displayText;
        hintLabel.size = [hintLabel sizeThatFits:CGSizeMake(hintLabel.frame.size.width, 60)];
        
        NSString* voText = hintLabel.text;
        if([voText containsString:@">="]){
            voText = [voText stringByReplacingOccurrencesOfString:@">=" withString:@"größer gleich"];
        }
        
        [self addSubview:hintLabel];
        [self.platformViews addObject:hintLabel];
        
        MBStatusImageView *statusImageView = [MBStatusImageView new];
        statusImageView.isAccessibilityElement = false;
        [self addSubview:statusImageView];
        [self.platformViews addObject:statusImageView];
        
        UILabel* statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width-2*15, 20)];
        statusLabel.isAccessibilityElement = false;
        statusLabel.numberOfLines = 0;
        statusLabel.font = UIFont.db_RegularSixteen;
        [self addSubview:statusLabel];
        [self.platformViews addObject:statusLabel];

        switch(feature.accType){
            case MBPlatformAccessibilityType_AVAILABLE:
                [statusImageView setStatusActive];
                statusLabel.text = @"vorhanden";
                statusLabel.textColor = [UIColor db_green];
                break;
            case MBPlatformAccessibilityType_NOT_AVAILABLE:
                [statusImageView setStatusInactive];
                statusLabel.text = @"nicht vorhanden";
                statusLabel.textColor = [UIColor db_mainColor];
                break;
            default:
                [statusImageView setStatusUnknown];
                statusLabel.text = @"unbekannt";
                statusLabel.textColor = [UIColor db_787d87];
                break;
        }
        voText = [voText stringByAppendingFormat:@": %@",statusLabel.text];
        UIView* voView = [[UIView alloc] initWithFrame:CGRectMake(0, y, self.frame.size.width, 55)];
        voView.isAccessibilityElement = true;
        voView.accessibilityLabel = voText;
        [self addSubview:voView];
        [self.platformViews addObject:voView];

        [statusLabel sizeToFit];
        [statusImageView setGravityLeft:hintLabel.frame.origin.x];
        [statusImageView setBelow:hintLabel withPadding:4];
        [statusLabel setGravityLeft:CGRectGetMaxX(statusImageView.frame)+6];
        [statusLabel setGravityTop:statusImageView.frame.origin.y+2];
        
        y += 60;

        if(index < featureList.count){
            UIView* line = [[UIView alloc] initWithFrame:CGRectMake(7, y, self.frame.size.width-2*7, 1)];
            line.backgroundColor = [UIColor db_light_lineColor];
            [self addSubview:line];
            [self.platformViews addObject:line];
            y += 20;
        }
    }
    [self.footerViews setGravityTop:y];
    y = CGRectGetMaxY(self.footerViews.frame);
    
    y += 40;
    self.size = CGSizeMake(self.frame.size.width, y);
    //resize parent (we know that this view is the last one in the parent)
    if([self.superview isKindOfClass:UIScrollView.class]){
        UIScrollView* sv = (UIScrollView*) self.superview;
        [sv setContentSize:CGSizeMake(sv.frame.size.width, CGRectGetMaxY(self.frame))];
    }
    
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.platformLabel);
}

@end
