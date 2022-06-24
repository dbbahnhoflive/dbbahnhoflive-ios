// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "HeadCell.h"
#import "MBUIHelper.h"

@interface HeadCell()

@property (nonatomic, strong) UILabel *destinationLabel;
@property (nonatomic, assign) BOOL lastPosition;

@end

@implementation HeadCell

@synthesize head = _head;
@synthesize waggon = _waggon;
@synthesize train = _train;

- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]){
        self.trainIconView = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"TrainHead"]];
        
        self.backgroundColor = [UIColor db_f5f5f5];
     
        self.destinationLabel = [[UILabel alloc] init];
        self.destinationLabel.font = [UIFont db_RegularTwelve];
        self.destinationLabel.textColor = [UIColor db_787d87];
        self.destinationLabel.adjustsFontSizeToFitWidth = YES;
        self.destinationLabel.numberOfLines = 1;
        
        [self.contentView addSubview:self.trainIconView];
        [self.contentView addSubview:self.destinationLabel];
    }
    return self;
}

- (void) setTrain:(Train *)train
{
    _train = train;
    NSString *destinationString = @"";
    
    if (!_train) {
        // catch invalid, missing Train
        self.destinationLabel.text = destinationString;
        return;
    }
    
    if (train.destinationStation && train.destinationStation.length > 0) {
        destinationString = [NSString stringWithFormat:@"%@ %@ nach %@", train.type, train.number, train.destinationStation];
    } else {
        destinationString = [NSString stringWithFormat:@"%@ %@", train.type, train.number];   
    }
    
    if (train.destinationStation) {
        NSRange rangeOfBoldPart = [destinationString rangeOfString:train.destinationStation];
        
        NSMutableAttributedString *formattedDestination = [[NSMutableAttributedString alloc] initWithString:destinationString];
        [formattedDestination addAttribute:NSFontAttributeName value:[UIFont db_RegularTwelve] range:NSMakeRange(0,destinationString.length)];
        [formattedDestination addAttribute:NSFontAttributeName value:[UIFont db_BoldTwelve] range:rangeOfBoldPart];
        
        self.destinationLabel.attributedText = formattedDestination;
    } else {
        self.destinationLabel.text = destinationString;
    }
}

- (void) setWaggon:(Waggon *)waggon lastPosition:(BOOL)lastPosition
{
    _waggon = waggon;
    
    self.lastPosition = lastPosition;
    [self setHead:_waggon.isTrainHead];
}

- (void) setHead:(BOOL)head
{
    _head = head;
    if (self.waggon.isTrainBothWays) {
        self.trainIconView.image = [UIImage db_imageNamed:@"RegioTrain"];
    } else {
        
        if (head) {
            self.trainIconView.image = [UIImage db_imageNamed:@"TrainHead"];
        } else {
            self.trainIconView.image = [UIImage db_imageNamed:@"TrainBack"];
        }
        
    }
    
    self.destinationLabel.hidden = NO;//!_head;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    self.trainIconView.width = 85;
    self.trainIconView.height = self.trainIconView.image.size.height;
    self.trainIconView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [self.trainIconView setGravityLeft:(ISIPAD ? 120 : 20)];
    
    
    [self.destinationLabel sizeToFit];
    self.destinationLabel.size = CGSizeMake(self.sizeWidth-(self.trainIconView.originX+self.trainIconView.sizeWidth+25),
                                            self.destinationLabel.sizeHeight);
    
    if ([self.waggon.type isEqualToString:@"s"]) {
        if (self.lastPosition) {
            [self.trainIconView setGravityTop:0];
            [self.destinationLabel setGravityTop:10];
        } else {
            [self.trainIconView setGravityBottom:0];
            [self.destinationLabel setGravityBottom:10];
        }
    } else {
        if (self.head) {
            [self.trainIconView setGravityBottom:0];
            [self.destinationLabel setGravityBottom:10];
        } else {
            [self.trainIconView setGravityTop:0];
            [self.destinationLabel setGravityTop:10];
        }
    }
    
    [self.destinationLabel setRight:self.trainIconView withPadding:20];
}

@end
