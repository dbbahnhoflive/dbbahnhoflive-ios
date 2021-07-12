// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBTimeTableFilterViewCell.h"
#import "MBSwitch.h"
#import "MBFilterButton.h"

@interface MBTimeTableFilterViewCell()

@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) MBFilterButton *filterButton;
@property (nonatomic, strong) MBSwitch *abfahrtSwitch;

@end

#define FILTER_TEXT_HIDDEN @"Zum Ändern der Filtereinstellung doppeltippen"
#define FILTER_TEXT_VISIBLE @"Zum Zurücksetzen der Filter doppeltippen"


@implementation MBTimeTableFilterViewCell

- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self configureCell];
    }
    return self;
}

- (void) configureCell
{
    self.backgroundColor = [UIColor clearColor];

    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.backView = [[UIView alloc] init];
    self.backView.backgroundColor = [UIColor whiteColor];

    self.filterButton = [[MBFilterButton alloc] init];
    [self.filterButton addTarget:self action:@selector(handleFilter:) forControlEvents:UIControlEventTouchUpInside];
    
    self.filterButton.accessibilityLabel = @"Filter für Zugtyp und Gleis";
    self.filterButton.accessibilityHint = FILTER_TEXT_HIDDEN;
    self.filterButton.accessibilityLanguage = @"de-DE";

    
    self.abfahrtSwitch = [[MBSwitch alloc] initWithFrame:CGRectZero onTitle:@"Abfahrt" offTitle:@"Ankunft" onState:YES];
    self.abfahrtSwitch.backgroundColor = [UIColor db_333333];

    [self.abfahrtSwitch addTarget:self action:@selector(handleSwitch:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.contentView addSubview:self.backView];
    [self.backView addSubview:self.filterButton];
    [self.backView addSubview:self.abfahrtSwitch];
    
    if (self.filterOnly) {
        self.abfahrtSwitch.hidden = YES;
    }

}

-(void)switchToDeparture{
    self.abfahrtSwitch.on = YES;
}
-(void)switchToArrival{
    self.abfahrtSwitch.on = NO;
}

- (void)setFilterOnly:(BOOL)filterOnly {
    _filterOnly = filterOnly;
    self.abfahrtSwitch.hidden = filterOnly;
}

- (void)handleFilter:(UIButton *)button {
    if (nil != _delegate) {
        [_delegate filterCellWantsToFilter];
    }
}


-(void)setFilterActive:(BOOL)filterActive{
    _filterActive = filterActive;
    if(filterActive){
        [self.filterButton setStateActive:YES];
    } else {
        [self.filterButton setStateActive:NO];
    }
}

-(void)setFilterHidden:(BOOL)hidden{
    [self.filterButton setHidden:hidden];
}

- (void)handleSwitch:(MBSwitch *)control {
    if (nil != _delegate) {
        if ([_delegate respondsToSelector:@selector(filterCell:setsAbfahrt:)]) {
            [_delegate filterCell:self setsAbfahrt:[control isOn]];
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat bottomSlack = 8.0;
    self.backView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height-bottomSlack);
    self.backView.layer.shadowOffset = CGSizeMake(1.0, 2.0);
    self.backView.layer.shadowColor = [[UIColor db_dadada] CGColor];
    self.backView.layer.shadowRadius = 1.5;
    self.backView.layer.shadowOpacity = 1.0;

    [self.filterButton setGravityLeft:self.frame.size.width - self.filterButton.frame.size.width - 16.0];
    [self.filterButton setGravityTop:(self.frame.size.height-self.filterButton.frame.size.height) / 2.0];
    
    CGFloat switchWidth = self.filterButton.frame.origin.x - 16.0 - 40.0;
    self.abfahrtSwitch.frame = CGRectMake(16.0, self.filterButton.frame.origin.y, switchWidth, self.filterButton.frame.size.height);
}

@end
