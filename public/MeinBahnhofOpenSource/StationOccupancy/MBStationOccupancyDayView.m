// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBStationOccupancyDayView.h"
#import "MBStationOccupancyViewController.h"
#import "MBStationOccupancyDiagramView.h"
#import "MBStationOccupancyOverlayViewController.h"
#import "MBRootContainerViewController.h"
#import "MBUIHelper.h"

@interface MBStationOccupancyDayView()
@property(nonatomic,strong) UILabel* headerLabel;
@property(nonatomic,strong) UILabel* occupancyHeaderLabel;
@property(nonatomic,strong) UILabel* occupancyLabel;
@property(nonatomic,strong) UIButton* infoBtn;
@property(nonatomic,strong) UIButton* clickBtn;
@property(nonatomic,strong) UIButton* dayDropdownBtn;
@property(nonatomic,strong) UIView* topLine;
@property(nonatomic,strong) MBStationOccupancyDiagramView* diagram;
@end

@implementation MBStationOccupancyDayView

+(NSArray *)weekdays{
    return @[@"Montags",@"Dienstags",@"Mittwochs",@"Donnerstags",@"Freitags",@"Samstags",@"Sonntags"];
}
+(NSString *)weekdayToday{
    return @"Heute";
}

-(instancetype)initWithWeekday:(NSInteger)weekday isToday:(BOOL)isToday{
    self = [super initWithFrame:CGRectZero];
    if(self){
        self.clipsToBounds = NO;
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 2;
        self.layer.shadowColor = [[UIColor db_dadada] CGColor];
        self.layer.shadowOffset = CGSizeMake(3.0, 3.0);
        self.layer.shadowRadius = 3.0;
        self.layer.shadowOpacity = 1.0;
        
        self.headerLabel = [UILabel new];
        self.headerLabel.font = [UIFont db_BoldSeventeen];
        self.headerLabel.text = @"Besucheraufkommen";
        self.headerLabel.textColor = UIColor.blackColor;
        [self.headerLabel sizeToFit];
        [self addSubview:self.headerLabel];

        UIButton* infoBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 26, 26)];
        self.infoBtn = infoBtn;
        infoBtn.accessibilityLabel = @"Weitere Informationen";
        [infoBtn setImage:[UIImage db_imageNamed:@"occupancy_information"] forState:UIControlStateNormal];
        [infoBtn addTarget:self action:@selector(infobtnPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:infoBtn];
        
        self.topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)];
        self.topLine.backgroundColor = [UIColor dbColorWithRGB:0xE7E7E7];
        [self addSubview:self.topLine];
        
        if(isToday){
            self.occupancyHeaderLabel = [UILabel new];
            self.occupancyHeaderLabel.font = [UIFont db_RegularTen];
            self.occupancyHeaderLabel.text = @"Aktuell:";
            self.occupancyHeaderLabel.isAccessibilityElement = NO;
            self.occupancyHeaderLabel.textColor = UIColor.blackColor;
            [self.occupancyHeaderLabel sizeToFit];
            [self addSubview:self.occupancyHeaderLabel];

            self.occupancyLabel = [UILabel new];
            self.occupancyLabel.isAccessibilityElement = NO;
            self.occupancyLabel.font = [UIFont db_BoldTen];
            self.occupancyLabel.numberOfLines = 0;
            self.occupancyLabel.textColor = UIColor.blackColor;
            [self addSubview:self.occupancyLabel];
        }
        
        self.diagram = [MBStationOccupancyDiagramView new];
        self.diagram.currentWeekday = weekday;
        [self addSubview:self.diagram];

        self.dayDropdownBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 140, 36)];
        self.dayDropdownBtn.layer.borderColor = [UIColor db_dadada].CGColor;
        self.dayDropdownBtn.layer.borderWidth = 2;
        self.dayDropdownBtn.layer.cornerRadius = 15;
        self.dayDropdownBtn.backgroundColor = [UIColor clearColor];
        self.dayDropdownBtn.isAccessibilityElement = NO;
        [self.dayDropdownBtn addTarget:self action:@selector(daySelected:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.dayDropdownBtn setTitleColor:isToday ? [UIColor dbColorWithRGB:0x76C030] : UIColor.blackColor forState:UIControlStateNormal];
        if(isToday){
            [self.dayDropdownBtn setTitle:MBStationOccupancyDayView.weekdayToday forState:UIControlStateNormal];
        } else {
            [self.dayDropdownBtn setTitle:MBStationOccupancyDayView.weekdays[weekday] forState:UIControlStateNormal];
        }
        self.dayDropdownBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        self.dayDropdownBtn.contentEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 0);
        self.dayDropdownBtn.titleLabel.font = [UIFont db_BoldFourteen];
        
        UIImageView* arrow = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"occupancy_arrow_down"]];
        [self.dayDropdownBtn addSubview:arrow];
        [arrow setGravityTop:14];
        [arrow setGravityRight:16];
        
        [self addSubview:self.dayDropdownBtn];

        UIButton* clickBtn = [UIButton new];
        [clickBtn addTarget:self action:@selector(infobtnPressed:) forControlEvents:UIControlEventTouchUpInside];
        clickBtn.isAccessibilityElement = NO;
        self.clickBtn = clickBtn;
        [self insertSubview:clickBtn belowSubview:self.dayDropdownBtn];
    }
    return self;
}

-(void)loadData:(MBStationOccupancy*)occupancy{
    self.diagram.occupancy = occupancy;
//    self.occupancyLabel.text = occupancy.currentLevelString;
    self.occupancyHeaderLabel.hidden = NO;
    NSString* text = @"";
    switch(occupancy.currentLevel){
        case 1:
            text = @"Weniger Besucher als üblich";
            break;
        case 2:
            text = @"Übliches Besucheraufkommen";
            break;
        case 3:
            text = @"Mehr Besucher als üblich";
            break;
        case 0:
        default:
            text = @"Es liegt keine\naktuelle Information vor.";
            self.occupancyHeaderLabel.hidden = YES;
            break;
    }
    self.occupancyLabel.text = text;

    self.diagram.isAccessibilityElement = YES;
    self.diagram.accessibilityLabel = [NSString stringWithFormat:@"Aktuell: %ld bis %ld Uhr, %@",occupancy.currentHour,occupancy.currentHour+1,text];
}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    self.clickBtn.frame = CGRectMake(0, 0, self.sizeWidth, self.sizeHeight);
    
    [self.headerLabel setGravityLeft:15];
    [self.headerLabel setGravityTop:17-5];
    
    [self.topLine setWidth:self.size.width];
    [self.topLine setGravityTop:43];
    
    CGSize size = [self.occupancyLabel sizeThatFits:CGSizeMake(self.frame.size.width-161, 200)];
    [self.occupancyLabel setSize:CGSizeMake(ceil(size.width), ceil(size.height))];
    
    [self.occupancyHeaderLabel setGravityLeft:15];
    [self.occupancyLabel setGravityLeft:15];
    [self.occupancyHeaderLabel setBelow:self.topLine withPadding:18];
    if(self.occupancyHeaderLabel.hidden){
        [self.occupancyLabel setBelow:self.topLine withPadding:18];
    } else {
        [self.occupancyLabel setBelow:self.topLine withPadding:33];
    }
    self.diagram.frame = CGRectMake(15, 127, self.frame.size.width-2*15, 85);
    
    [self.infoBtn setGravityRight:10];
    [self.infoBtn setGravityTop:10];
    
    [self.dayDropdownBtn setGravityTop:60];
    [self.dayDropdownBtn setGravityRight:15];

}

-(void)infobtnPressed:(id)sender{
    MBStationOccupancyOverlayViewController* vc = [[MBStationOccupancyOverlayViewController alloc] init];
    [MBRootContainerViewController presentViewControllerAsOverlay:vc];

}

-(void)daySelected:(UIButton*)btn{
    [self.delegate openDropdownFromView:btn inDayView:self];
}

@end
