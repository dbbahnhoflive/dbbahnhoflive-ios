// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBPoiFilterContentView.h"
#import "POIFilterTableCell.h"
#import "MBUIHelper.h"
#import "DBSwitch.h"

#define POIFilterCellClassIdentifier @"POIFilterCellClass"

@interface MBPoiFilterContentView()<UITableViewDelegate,UITableViewDataSource>

@property(nonatomic,strong) UITableView* filterTableView;
@property (nonatomic, strong) UISwitch *allToggleSwitch;

@end

@implementation MBPoiFilterContentView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(instancetype)initWithFrame:(CGRect)frame items:(NSArray *)items parent:(POIFilterItem *)parent{
    self = [super initWithFrame:frame];
    if(self){
        self.parentCategory = parent;
        self.categories = items;
        self.filterTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) style:UITableViewStylePlain];
        self.filterTableView.contentInset = UIEdgeInsetsMake(0, 0, 16, 0);//space at bottom
        self.filterTableView.delegate = self;
        self.filterTableView.dataSource = self;
        self.filterTableView.backgroundColor = [UIColor clearColor];
        [self.filterTableView registerClass:[POIFilterTableCell class] forCellReuseIdentifier:POIFilterCellClassIdentifier];
        [self.filterTableView setTableHeaderView:[self headerAllFilterToggleView:((POIFilterItem*)self.categories.firstObject).subItems != nil]];
        if(!((POIFilterItem*)self.categories.firstObject).subItems){
            self.filterTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
            self.filterTableView.separatorColor = [UIColor db_HeaderColor];
        } else {
            self.filterTableView.separatorStyle = UITableViewCellSeparatorStyleNone;//[UIColor whiteColor];
        }
        [self addSubview:self.filterTableView];
    }
    return self;
}

#pragma -
#pragma HeaderView

- (UIView*) headerAllFilterToggleView:(BOOL)isCategoryView
{
    UIView *headerViewContainer = [[UIView alloc] initWithFrame:CGRectMake(0,0, self.sizeWidth,60)];
    headerViewContainer.backgroundColor = [UIColor clearColor];

    UIButton* headerButton = [[UIButton alloc] initWithFrame:headerViewContainer.frame];
    headerButton.backgroundColor = [UIColor whiteColor];
    [headerButton addTarget:self action:@selector(headerButton:) forControlEvents:UIControlEventTouchUpInside];
    [headerViewContainer addSubview:headerButton];

    self.allToggleSwitch = [[DBSwitch alloc] init];
    self.allToggleSwitch.accessibilityLabel = @"Alle anzeigen";
    [self.allToggleSwitch setOn:[self isAllSelected]];
    
    UILabel *allLabel = [[UILabel alloc] init];
    allLabel.text = @"Alle anzeigen";
    allLabel.isAccessibilityElement = false;
    allLabel.font = [UIFont db_RegularSeventeen];
    allLabel.textColor = [UIColor db_333333];
    [allLabel sizeToFit];
    
    [headerViewContainer addSubview:self.allToggleSwitch];
    [headerViewContainer addSubview:allLabel];
    
    [allLabel centerViewVerticalInSuperView];
    [allLabel setGravityLeft:20];
    
    [self.allToggleSwitch setGravityRight:20];
    [self.allToggleSwitch centerViewVerticalInSuperView];
    
    if(!isCategoryView){
        UIView *divider = [[UIView alloc] initWithFrame:CGRectMake(15,headerViewContainer.sizeHeight-0.5,headerViewContainer.sizeWidth, 0.5)];
        [divider setBackgroundColor:[UIColor db_HeaderColor]];
        [headerViewContainer addSubview:divider];
        [divider setGravityBottom:0];
    }
    
    [self.allToggleSwitch addTarget:self action:@selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
    
    return headerViewContainer;
}
-(void)headerButton:(UIButton*)btn{
    _allToggleSwitch.on = !_allToggleSwitch.on;
    [self toggleSwitch:_allToggleSwitch];
}

- (void) toggleSwitch:(UISwitch*)sender
{
    for (POIFilterItem *filterItem in self.categories) {
        filterItem.active = sender.on;
        for (POIFilterItem *subItem in filterItem.subItems) {
            subItem.active = sender.on;
        }
    }
    [self.delegate poiContent:self didToggleAll:sender.on];
}


#pragma UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    cell.backgroundColor = [UIColor clearColor];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    POIFilterTableCell *filterCell = [tableView dequeueReusableCellWithIdentifier:POIFilterCellClassIdentifier forIndexPath:indexPath];
    filterCell.item = self.categories[indexPath.item];
    [filterCell setLastCell:indexPath.row == self.categories.count-1];
    return filterCell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.categories.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    //
    POIFilterItem *category = self.categories[indexPath.item];
    if (category.subItems) {
        // right indicator
        [self.delegate poiContent:self didSelectCategory:category];
    } else {
        category.active = !category.active;
        
        [self.allToggleSwitch setOn:[self isAllSelected]];
        
        [tableView reloadRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
                         withRowAnimation: UITableViewRowAnimationNone];
        [self.delegate poiContent:self didChangeCategory:category];
        
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (BOOL) isAllSelected
{
    for (POIFilterItem *filterItem in self.categories) {
        if (filterItem.subItems) {
            for (POIFilterItem *subItem in filterItem.subItems) {
                if (!subItem.active) {
                    return NO;
                }
            }
        } else {
            if (!filterItem.active) {
                return NO;
            }
        }
    }
    return YES;
}

-(void)reloadData{
    [self.filterTableView reloadData];
    [self.allToggleSwitch setOn:[self isAllSelected]];
}


@end
