// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "MBOverlayViewController.h"

@class MBTimetableFilterViewController;
@class HafasTimetable;

@protocol MBTimetableFilterViewControllerDelegate <NSObject>

-(void)filterView:(MBTimetableFilterViewController*)filterView didSelectTrainType:(NSString*)type track:(NSString*)track;

@end

@interface MBTimetableFilterViewController : MBOverlayViewController

@property (nonatomic,strong) HafasTimetable* hafasTimetable;
@property (nonatomic) BOOL departure;
@property(nonatomic,strong) NSString* initialSelectedPlatform;
@property(nonatomic,strong) NSString* initialSelectedTransportType;
@property (nonatomic) BOOL useHafas;

//when set, used instead of timetable
@property(nonatomic,strong) NSArray<NSString*>* platforms;

@property (nonatomic,weak) id<MBTimetableFilterViewControllerDelegate> delegate;

@end
