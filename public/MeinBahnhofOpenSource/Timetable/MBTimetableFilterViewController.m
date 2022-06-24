// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBTimetableFilterViewController.h"
#import "MBUIHelper.h"

#import "TimetableManager.h"
#import "HafasRequestManager.h"
#import "HafasTimetable.h"

#import "MBSwitch.h"

#define kHeaderTime @"Zeit"
#define kHeaderPlatform @"Gleis"

@interface MBTimetableFilterViewController ()<UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) UIView *pickerContainer;
@property (nonatomic, strong) UIPickerView *platformPicker;
@property (nonatomic, strong) UIPickerView *transportTypePicker;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) UIView *buttonBackView;
@property (nonatomic, strong) MBSwitch* filterSwitch;
@property (nonatomic, strong) UIView* filterSegmentedView;
@property (nonatomic, strong) UILabel* timeLabel;

@property (nonatomic, strong) NSArray* filterTrainTypes;
@property (nonatomic, strong) NSArray* filterPlatforms;

@end

@implementation MBTimetableFilterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if(self.platforms){
        self.titleLabel.text = @"Gleis";
    } else {
        self.titleLabel.text = @"Verkehrsmittel";
    }
    
    self.pickerContainer = [[UIView alloc] init];
    self.platformPicker = [[UIPickerView alloc] init];
    self.platformPicker.delegate = self;
    self.platformPicker.dataSource = self;
    self.platformPicker.hidden = YES;//changed by filterSwitch
    
    if(!self.platforms){
        self.transportTypePicker = [[UIPickerView alloc] init];
        self.transportTypePicker.delegate = self;
        self.transportTypePicker.dataSource = self;
        self.transportTypePicker.hidden = NO;//changed by filterSwitch
    } else {
        self.platformPicker.hidden = NO;
    }
    self.pickerContainer.backgroundColor = [UIColor whiteColor];
    self.transportTypePicker.backgroundColor = self.platformPicker.backgroundColor = [UIColor whiteColor];
    
    if(!self.platforms){
        self.filterSwitch = [[MBSwitch alloc] initWithFrame:CGRectZero onTitle:@"Zugtyp" offTitle:kHeaderPlatform onState:YES];
        self.filterSwitch.backgroundColor = [UIColor db_333333];
        [self.filterSwitch addTarget:self action:@selector(handleSwitch:) forControlEvents:UIControlEventTouchUpInside];
    }
    self.filterSegmentedView = [[UIView alloc] init];
    self.filterSegmentedView.backgroundColor = [UIColor whiteColor];
    
    UIView *backView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.frame.size.width, DEFAULT_CONFIRM_AREA_HEIGHT)];
    backView.backgroundColor = [UIColor whiteColor];
    backView.layer.shadowOffset = CGSizeMake(0.0, -2.0);
    backView.layer.shadowColor = [[UIColor db_dadada] CGColor];
    backView.layer.shadowRadius = 1.5;
    backView.layer.shadowOpacity = 1.0;
    [self.pickerContainer addSubview:backView];
    self.buttonBackView = backView;
    
    if(self.availableDataUntilTime){
        self.timeLabel = [UILabel new];
        self.timeLabel.textAlignment = NSTextAlignmentCenter;
        self.timeLabel.font = [UIFont db_RegularFourteen];
        self.timeLabel.textColor = [UIColor db_878c96];
        self.timeLabel.numberOfLines = 0;
        [self.pickerContainer addSubview:self.timeLabel];
    }
    
    self.confirmButton = [[UIButton alloc] init];
    [self.confirmButton setTitle:@"Übernehmen" forState:UIControlStateNormal];
    self.confirmButton.accessibilityLanguage = @"de-DE";
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.confirmButton setBackgroundColor:[UIColor db_GrayButton]];
    [self.confirmButton.titleLabel setFont:[UIFont db_BoldEighteen]];
    [self.confirmButton addTarget:self action:@selector(confirmFilterSelection:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.pickerContainer addSubview:self.platformPicker];
    if(!self.platforms){
        [self.pickerContainer addSubview:self.transportTypePicker];
    }
    [self.filterSegmentedView addSubview:self.filterSwitch];
    [self.pickerContainer addSubview:self.filterSegmentedView];
    [self.pickerContainer addSubview:self.confirmButton];
    
    [self.contentView addSubview:self.pickerContainer];
    
    if(self.platforms){
        self.filterPlatforms = self.platforms;
        [self.platformPicker reloadAllComponents];
    } else if (self.useHafas) {
        self.filterTrainTypes = [self.hafasTimetable availableTransportTypes];
        self.filterSwitch.hidden = YES;
    } else {
        self.filterPlatforms = [[[TimetableManager sharedManager] timetable] availablePlatformsForDeparture:self.departure];
        self.filterTrainTypes = [[[TimetableManager sharedManager] timetable] availableTransportTypesForDeparture:self.departure];
        [self.platformPicker reloadAllComponents];
    }
    [self.transportTypePicker reloadAllComponents];
    [self preselectInitialValues];
    [self updateTimeText];
}

-(void)updateTimeText{
    if(self.platformPicker.hidden){
        [self showTimeForTrainTypes];
    } else {
        [self showTimeForPlatforms];
    }
}

-(void)showTimeForTrainTypes{
    if(self.useHafas){
        self.timeLabel.text = [NSString stringWithFormat:@"Verkehrsmittel %@",self.availableDataUntilTime];
    } else {
        self.timeLabel.text = [NSString stringWithFormat:@"Verkehrende Zugtypen %@",self.availableDataUntilTime];
    }
}
-(void)showTimeForPlatforms{
    self.timeLabel.text = [NSString stringWithFormat:@"Bediente Gleise %@",self.availableDataUntilTime];
}


-(NSInteger)expectedContentHeight{
    [self resizeTimeLabel];
    if(self.timeLabel){
        return 410+5+self.timeLabel.sizeHeight;
    }
    return 410;//switch+picker+button
}

-(void)resizeTimeLabel{
    if(self.timeLabel){
        CGSize size = [self.timeLabel sizeThatFits:CGSizeMake(self.contentView.frame.size.width-2*30, 1000)];
        [self.timeLabel setSize:CGSizeMake(ceilf(size.width), ceilf(size.height))];
    }
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    self.pickerContainer.frame = CGRectMake(0, self.headerView.sizeHeight, self.contentView.frame.size.width, self.contentView.sizeHeight-self.headerView.sizeHeight);
    
    self.filterSwitch.size = CGSizeMake(self.view.sizeWidth-2*65, 40);
    self.filterSegmentedView.size = CGSizeMake(self.pickerContainer.sizeWidth, self.filterSwitch.frame.size.height);
    [self.filterSwitch centerViewHorizontalInSuperView];
    [self.filterSegmentedView setGravityTop:30];
    
    self.transportTypePicker.frame = self.platformPicker.frame = CGRectMake(0,CGRectGetMaxY(self.filterSegmentedView.frame)+10, self.pickerContainer.sizeWidth, 216);
    
    if(self.timeLabel){
        [self resizeTimeLabel];
        [self.timeLabel centerViewHorizontalInSuperView];
        [self.timeLabel setBelow:self.transportTypePicker withPadding:5];
    }
    
    [self.buttonBackView setGravityBottom:0];
    self.confirmButton.size = CGSizeMake(MIN(self.pickerContainer.sizeWidth*0.8, 290), 60);
    self.confirmButton.layer.cornerRadius = self.confirmButton.frame.size.height / 2.0;
    [self.confirmButton setGravityBottom:16];
    [self.confirmButton centerViewHorizontalInSuperView];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    // Set the Width of the Platform Picker here.
    // The width seems to be ignored ind viewDidLayoutSubviews
    self.transportTypePicker.width = self.platformPicker.width = self.contentView.sizeWidth;
    
    [self preselectInitialValues];
}

-(void)preselectInitialValues{
    NSInteger initialIndex = 0;
    for(NSString* track in self.filterPlatforms){
        if([track isEqualToString:self.initialSelectedPlatform]){
            [self.platformPicker selectRow:initialIndex inComponent:0 animated:NO];
            break;
        }
        initialIndex++;
    }
    initialIndex = 0;
    for(NSString* track in self.filterTrainTypes){
        if([track isEqualToString:self.initialSelectedTransportType]){
            [self.transportTypePicker selectRow:initialIndex inComponent:0 animated:NO];
            break;
        }
        initialIndex++;
    }
}

-(void)handleSwitch:(MBSwitch*)sender{
    if(!sender.on){
        self.platformPicker.hidden = NO;
        self.transportTypePicker.hidden = YES;
    } else {
        self.platformPicker.hidden = YES;
        self.transportTypePicker.hidden = NO;
    }
    [self updateTimeText];
}


#pragma -
#pragma UIPickerViewDelegate / DataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView;
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if(pickerView == self.platformPicker){
        return [self.filterPlatforms count];
    } else {
        return [self.filterTrainTypes count];
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if(pickerView == self.platformPicker){
        NSArray *platforms = self.filterPlatforms;
        return platforms[row];
    } else {
        NSArray *trainTypes = self.filterTrainTypes;
        NSString* trainType = trainTypes[row];
        if(UIAccessibilityIsVoiceOverRunning()){
            if([trainType isEqualToString:@"S"]){
                return @"S-Bahn";
            } else if([trainType isEqualToString:@"U"]){
                return @"U-Bahn";
            } else if([trainType isEqualToString:@"ICE"]){
                return @"I C E";
            } else if([trainType isEqualToString:@"STR"]){
                return VOICEOVER_FOR_STR;
            }
        }
        return trainType;
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if ([[self currentlySelectedPlatform] isEqualToString:@"Alle"] && [[self currentlySelectedTransportType] isEqualToString:@"Alle"]) {
        //[self.platformFilterStateIcon setImage:[UIImage db_imageNamed:@"FilterStateDefaultIcon"]
        //                              forState:UIControlStateNormal];
        //self.platformFilterStateIcon.accessibilityValue = @"Filter aus";
    } else {
        // filter
        //[self.platformFilterStateIcon setImage:[UIImage db_imageNamed:@"FilterStateChangedIcon"]
        //                              forState:UIControlStateNormal];
        //self.platformFilterStateIcon.accessibilityValue = [NSString stringWithFormat:@"Filter aktiv. Zugtyp %@. \"Gleis %@\".",[self currentlySelectedTransportType],[self currentlySelectedPlatform]];
    }
}



- (void) confirmFilterSelection:(id)sender
{
    [self.delegate filterView:self didSelectTrainType:[self currentlySelectedTransportType] track:[self currentlySelectedPlatform]];
    [self hideOverlay];
}

- (NSString*) currentlySelectedPlatform
{
    NSUInteger selectedIndex = [self.platformPicker selectedRowInComponent:0];
    NSArray *platforms = self.filterPlatforms;
    NSString *platform = @"";
    if (selectedIndex < platforms.count) {
        platform = platforms[selectedIndex];
    } else {
        platform = [platforms firstObject];
    }
    return platform;
}

- (NSString*) currentlySelectedTransportType
{
    NSUInteger selectedIndex = [self.transportTypePicker selectedRowInComponent:0];
    NSArray *types = self.filterTrainTypes;
    NSString *type = @"";
    if (selectedIndex < types.count) {
        type = types[selectedIndex];
    } else {
        type = [types firstObject];
    }
    return type;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
