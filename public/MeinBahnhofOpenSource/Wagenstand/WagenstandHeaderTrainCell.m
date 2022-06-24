// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "WagenstandHeaderTrainCell.h"
#import "MBUIHelper.h"

@interface WagenstandHeaderTrainCell()

@property (nonatomic, strong) UILabel *trainNumberLabel;
@property (nonatomic, strong) UILabel *trainSectionLabel;
@property (nonatomic, strong) UILabel *trainDestinationLabel;
@property (nonatomic, strong) UILabel *viaLabel;

@end

@implementation WagenstandHeaderTrainCell

- (instancetype) initCellWithTrain:(Train*)train andFrame:(CGRect)frame splitTrain:(BOOL)splitTrain
{
    if (self = [super initWithFrame:frame]) {
        self.trainNumberLabel = [[UILabel alloc] init];
        self.trainNumberLabel.font = [UIFont db_RegularFourteen];
        self.trainNumberLabel.textColor = [UIColor db_787d87];
        self.trainNumberLabel.text = [NSString stringWithFormat:@"%@ %@", train.type, train.number];
        self.trainNumberLabel.numberOfLines = 1;
        [self.trainNumberLabel sizeToFit];
        
        self.trainSectionLabel = [[UILabel alloc] init];
        if (splitTrain) {
            self.trainSectionLabel.font = [UIFont db_RegularFourteen];
            self.trainSectionLabel.textColor = [UIColor db_787d87];
            self.trainSectionLabel.text = [NSString stringWithFormat:@"%@ bis",[train sectionRangeAsString]];
            self.trainSectionLabel.numberOfLines = 1;
            [self.trainSectionLabel sizeToFit];
            
            [self addSubview:self.trainSectionLabel];
        }
        
        self.trainDestinationLabel = [[UILabel alloc] init];
        self.trainDestinationLabel.font = [UIFont db_RegularSeventeen];
        self.trainDestinationLabel.textColor = [UIColor db_333333];
        self.trainDestinationLabel.text = train.destinationStation;
        [self.trainDestinationLabel sizeToFit];
        
        [self addSubview:self.trainDestinationLabel];
        
        self.viaLabel = [[UILabel alloc] init];
        self.viaLabel.font = [UIFont db_RegularTen];
        self.viaLabel.textColor = [UIColor db_333333];
        self.viaLabel.text = [train destinationViaAsString];
        self.viaLabel.numberOfLines = 0;
        self.viaLabel.height = 0;
        
        [self addSubview:self.trainNumberLabel];
        
        [self addSubview:self.trainSectionLabel];
        [self addSubview:self.trainDestinationLabel];
        [self addSubview:self.viaLabel];
        
        [self.trainSectionLabel setBelow:self.trainNumberLabel withPadding:0];
        [self.trainDestinationLabel setBelow:self.trainNumberLabel withPadding:0];
        [self.trainDestinationLabel setRight:self.trainSectionLabel withPadding:((self.trainSectionLabel.text.length > 0) ? 5 : 0)];
        [self.viaLabel setBelow:self.trainDestinationLabel withPadding:0];
        
        [self resizeHeight];
    }
    return self;
}

- (void) setExpanded:(BOOL)expanded
{
    // don't expand if vialabel is empty
    if (self.viaLabel.text.length == 0) {
        return;
    }
    
    _expanded = expanded;
    
    [UIView animateWithDuration:0.3 animations:^{
       
        [self.trainSectionLabel setBelow:self.trainNumberLabel withPadding:0];
        [self.trainDestinationLabel setBelow:self.trainNumberLabel withPadding:0];
        [self.trainDestinationLabel setRight:self.trainSectionLabel withPadding:((self.trainSectionLabel.text.length > 0) ? 5 : 0)];
        [self.viaLabel setBelow:self.trainDestinationLabel withPadding:0];
        
        if (self.expanded) {
            // limit via label's width
            self.viaLabel.size = [self.viaLabel sizeThatFits:CGSizeMake(self.sizeWidth-(self.viaLabel.originX-50), CGFLOAT_MAX)];
        } else {
            self.viaLabel.height = 0;
        }
        
        [self resizeHeight];
    }];
}

@end
