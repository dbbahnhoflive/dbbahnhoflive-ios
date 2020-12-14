// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBTimeTableFilterViewCell.h"
#import "MBSwitch.h"

@interface MBTimeTableFilterViewCell()

@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UIButton *filterButton;
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

    self.filterButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.filterButton setImage:[UIImage db_imageNamed:@"app_filter"] forState:UIControlStateNormal];
    [self.filterButton addTarget:self action:@selector(handleFilter:) forControlEvents:UIControlEventTouchUpInside];
    self.filterButton.backgroundColor = [UIColor whiteColor];
    self.filterButton.imageView.contentMode = UIViewContentModeCenter;
    
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
        [self.filterButton setImage:[UIImage db_imageNamed:@"app_filter_aktiv"] forState:UIControlStateNormal];
    } else {
        [self.filterButton setImage:[UIImage db_imageNamed:@"app_filter"] forState:UIControlStateNormal];
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

    CGSize buttonSize = [[self.filterButton imageForState:UIControlStateNormal] size];
    buttonSize.height = 42.0;
    buttonSize.width = 42.0;
    self.filterButton.frame = CGRectMake(self.frame.size.width - buttonSize.width - 16.0, (self.frame.size.height-buttonSize.height) / 2.0, buttonSize.width, buttonSize.height);
    self.filterButton.layer.cornerRadius = buttonSize.height / 2.0;
    self.filterButton.layer.shadowColor = [[UIColor db_dadada] CGColor];
    self.filterButton.layer.shadowRadius = 2.0;
    self.filterButton.imageEdgeInsets = UIEdgeInsetsMake(2.0, 0.0, 0.0, 0.0);
    CGRect backRect = self.filterButton.bounds;
    backRect.size.height += 4.0;
    backRect.size.width += 4.0;
    backRect.origin.y += 2.0;
    backRect.origin.x -= 2.0;

    self.filterButton.layer.shadowPath = [[UIBezierPath bezierPathWithRoundedRect:backRect cornerRadius:backRect.size.height / 2.0] CGPath];
    self.filterButton.layer.shadowOpacity = 1.0;
    CGFloat switchWidth = self.filterButton.frame.origin.x - 16.0 - 40.0;
    self.abfahrtSwitch.frame = CGRectMake(16.0, self.filterButton.frame.origin.y, switchWidth, buttonSize.height);
}

@end
