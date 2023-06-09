// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBParkingInfoView.h"
#import "MBUIHelper.h"

@interface MBParkingInfoView() 

@property (nonatomic, strong) MBParkingInfo *item;
@property (nonatomic, strong) UIButton *overviewButton;
@property (nonatomic, strong) UIButton *tarifButton;
@property (nonatomic, strong) UIButton *navigationButton;
@property (nonatomic, strong) NSArray *buttons;
@end

@implementation MBParkingInfoView 

#define PARKING_BUTTON_SIZE 72
#define PARKING_BUTTON_SPACING_TOP 16


- (instancetype)initWithParkingItem:(MBParkingInfo *)item {
    self = [super initWithFrame:CGRectMake(0,0,0,2*PARKING_BUTTON_SPACING_TOP+PARKING_BUTTON_SIZE)];
    if(self){
        self.item = item;
        [self setup];
    }
    return self;
}

- (void)setup {
    
    self.layer.shadowOffset = CGSizeMake(1.0, 2.0);
    self.layer.shadowColor = [[UIColor db_dadada] CGColor];
    self.layer.shadowRadius = 1.5;
    self.layer.shadowOpacity = 1.0;

    self.backgroundColor = [UIColor whiteColor];
    
    NSMutableArray *buttons = [NSMutableArray new];
    
    self.navigationButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, PARKING_BUTTON_SIZE,PARKING_BUTTON_SIZE)];
    [self.navigationButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self setupLayerForButton:self.navigationButton];
    [self.navigationButton setImage:[UIImage db_imageNamed:@"app_extern_link"] forState:UIControlStateNormal];
    [self addSubview:self.navigationButton];
    [buttons addObject:self.navigationButton];
    self.navigationButton.accessibilityLabel = @"Externer Link: Route öffnen";
    
    self.overviewButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, PARKING_BUTTON_SIZE,PARKING_BUTTON_SIZE)];
    [self.overviewButton setImage:[UIImage db_imageNamed:@"app_details"] forState:UIControlStateNormal];
    [self setupLayerForButton:self.overviewButton];
    [self.overviewButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.overviewButton];
    [buttons addObject:self.overviewButton];
    self.overviewButton.accessibilityLabel = @"Details öffnen";

    self.tarifButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, PARKING_BUTTON_SIZE,PARKING_BUTTON_SIZE)];
    [self setupLayerForButton:self.tarifButton];
    [self.tarifButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.tarifButton setImage:[UIImage db_imageNamed:@"app_preis"] forState:UIControlStateNormal];
    [self addSubview:self.tarifButton];
    self.tarifButton.accessibilityLabel = @"Tarifinformationen öffnen";
    [buttons addObject:self.tarifButton];
    self.buttons = buttons;
}

- (void)setupLayerForButton:(UIButton *)button {
    button.backgroundColor = [UIColor whiteColor];
    button.layer.shadowOffset = CGSizeMake(1.0, 2.0);
    button.layer.shadowColor = [[UIColor db_dadada] CGColor];
    button.layer.shadowRadius = 1.5;
    button.layer.shadowOpacity = 1.0;
}

- (void)buttonTapped:(UIButton *)sender {
    if ([sender isEqual:self.navigationButton]) {
        [self.delegate didStartNavigationForParking:self.item];
    } else if ([sender isEqual:self.overviewButton]) {
        [self.delegate didOpenOverviewForParking:self.item];
    } else if ([sender isEqual:self.tarifButton]) {
        [self.delegate didOpenTarifForParking:self.item];
    }
}

-(void)layoutSubviews{
    [super layoutSubviews];

    self.navigationButton.layer.cornerRadius = self.navigationButton.frame.size.height / 2.0;
    self.overviewButton.layer.cornerRadius = self.overviewButton.frame.size.height / 2.0;
    self.tarifButton.layer.cornerRadius = self.tarifButton.frame.size.height / 2.0;

    // make it so, that buttons are centered as a group
    CGFloat distance = 16.0;
    CGFloat completeWidth = PARKING_BUTTON_SIZE * self.buttons.count + distance * (self.buttons.count - 1);
    CGFloat leftSlack = (self.frame.size.width - completeWidth) / 2.0;
    
    UIView* v = self.buttons.firstObject;
    [v setGravityLeft:leftSlack];
    [v setGravityTop:PARKING_BUTTON_SPACING_TOP];
    for(NSInteger i=1; i<self.buttons.count; i++){
        UIView* v2 = self.buttons[i];
        [v2 setRight:v withPadding:distance];
        [v2 setGravityTop:PARKING_BUTTON_SPACING_TOP];
        v = v2;
    }
}

@end
