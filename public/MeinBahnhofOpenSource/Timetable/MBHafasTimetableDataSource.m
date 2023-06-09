// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBHafasTimetableDataSource.h"
#import "HafasDeparture.h"
#import "HafasTimetable.h"
#import "MBTimeTableOEPNVTableViewCell.h"
#import "MBUIHelper.h"

@implementation MBHafasTimetableDataSource

-(void)setHafasDepartures:(NSArray *)hafasDepartures{
    _hafasDepartures = hafasDepartures;
    if(hafasDepartures.count > 0){
        //NOTE: hafasDeparturesByDay is filled with HafasDeparture and NSString objects (header strings)
        NSMutableArray* entriesByDate = [NSMutableArray arrayWithCapacity:hafasDepartures.count+2];
        NSInteger index = 0;
        for(HafasDeparture* stop in hafasDepartures){
            if(entriesByDate.count == 0){
                //first one
                [entriesByDate addObject:stop];
            } else {
                HafasDeparture* previousStop = hafasDepartures[index-1];
                if([stop.date isEqualToString:previousStop.date]){
                    [entriesByDate addObject:stop];
                } else {
                    //day changed
                    NSDateFormatter* df = [[NSDateFormatter alloc] init];
                    [df setDateFormat:@"yyyy-MM-dd"];
                    NSDate* date = [df dateFromString:stop.date];
                    [df setDateFormat:@"dd. MMMM"];
                    NSString* dateString = [df stringFromDate:date];
                    [entriesByDate addObject:dateString];
                    [entriesByDate addObject:stop];
                }
            }
            index++;
        }
        self.hafasDeparturesByDay = entriesByDate;
    } else {
        self.hafasDeparturesByDay = @[];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *returnedCell;
    if (indexPath.row == 0) {
        // filter cell
        MBTimeTableFilterViewCell *tableCell = [tableView dequeueReusableCellWithIdentifier:@"TimeTableFilterCell" forIndexPath:indexPath];
        tableCell.delegate = self.delegate;
        tableCell.filterOnly = YES;
        tableCell.filterActive = [self.viewController filterIsActive];
        
        NSArray* transportTypes = [self.viewController.hafasTimetable availableTransportTypes];
        if(transportTypes.count <= 2){
            //"Alle" and only one additional... hide the filter
            [tableCell setFilterHidden:YES];
        } else {
            [tableCell setFilterHidden:NO];
        }
        
        returnedCell = tableCell;
    } else {
        NSInteger actualIndex = indexPath.row - 1;
        id item = [self.hafasDeparturesByDay objectAtIndex:actualIndex];
        if([item isKindOfClass:NSString.class]){
            UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:self.cellIdentifierHeader];
            cell.textLabel.font = [UIFont db_BoldSixteen];
            cell.textLabel.textColor = [UIColor db_333333];
            cell.textLabel.text = item;
            return cell;
        }
        MBTimeTableOEPNVTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.hafas = item;
        
        returnedCell = cell;
    }
    return returnedCell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.hafasDeparturesByDay.count + 1;
}

@end
