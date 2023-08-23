// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBParkingExpandableTableViewCell.h"
#import "MBParkingInfoView.h"
#import "MBUIHelper.h"
#import "MBStatusImageView.h"

@interface MBParkingExpandableTableViewCell()
@property (nonatomic, strong) UIView *topView;

@property (nonatomic, strong) UILabel *cellTitle;
@property (nonatomic, strong) UIImageView *cellIcon;
@property (nonatomic, strong) UILabel *opencloseLabel;
@property (nonatomic, strong) MBStatusImageView *opencloseImage;

@property (nonatomic, strong) UIView *bottomView;//includes the text labels and the infoView
@property (nonatomic, strong) NSMutableArray* labels;
@property (nonatomic, strong) MBParkingInfoView *infoView;//the buttons


@end

@implementation MBParkingExpandableTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    [self configureCell];
    return self;
}

- (void)configureCell {
    self.labels = [NSMutableArray arrayWithCapacity:6];
    
    self.backgroundColor = [UIColor clearColor];
    
    self.topView = [UIView new];
    self.topView.backgroundColor = [UIColor whiteColor];
    [self.topView configureDefaultShadow];

    [self.contentView addSubview:self.topView];
    
    self.cellIcon = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_parkhaus"]];
    [self.cellIcon setSize:CGSizeMake(40, 40)];
    [self.topView addSubview:self.cellIcon];
    
    self.cellTitle = [UILabel new];
    self.cellTitle.font = [UIFont db_BoldSixteen];
    self.cellTitle.textColor = [UIColor db_333333];
    [self.topView addSubview:self.cellTitle];
    
    self.opencloseLabel = [UILabel new];
    self.opencloseLabel.font = [UIFont db_RegularFourteen];
    [self.topView addSubview:self.opencloseLabel];
    
    self.opencloseImage = [[MBStatusImageView alloc] init];
    [self.opencloseImage setStatusActive];
    [self.topView addSubview:self.opencloseImage];
    
    
    self.bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, 92, 0, 0)];
    self.bottomView.backgroundColor = [UIColor db_f3f5f7];
    [self.bottomView configureDefaultShadow];

    [self.contentView addSubview:self.bottomView];
    
    self.isAccessibilityElement = NO;
    self.accessibilityTraits = self.accessibilityTraits|UIAccessibilityTraitButton;
    self.bottomView.isAccessibilityElement = NO;
}

-(NSInteger)bottomViewHeight{
    return self.bottomView.frame.size.height;
}

- (void)setItem:(MBParkingInfo *)item {
    _item = item;
    self.cellIcon.image = [UIImage db_imageNamed:item.isParkHaus ? @"rimap_parkhaus_grau" : @"rimap_parkplatz_grau"];
    self.cellTitle.text = item.name;

    self.opencloseLabel.hidden = YES;
    self.opencloseImage.hidden = YES;

    NSString *openInfoString = item.textForAllocation;
    self.opencloseLabel.textColor = [UIColor db_green];
    if (item.isOutOfOrder) {
        openInfoString = @"Geschlossen";
        self.opencloseLabel.textColor = [UIColor db_mainColor];
        [self.opencloseImage setStatusInactive];
    } else {
        [self.opencloseImage setStatusActive];
    }
    [self.opencloseImage setSize:CGSizeMake(24, 24)];
    self.opencloseLabel.text = openInfoString;
    if(openInfoString.length > 0){
        self.opencloseLabel.hidden = NO;
        self.opencloseImage.hidden = NO;
    }

    
    // additional info in bottom view
    [self.labels removeAllObjects];
    [self.bottomView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self addLabelWithTitle:@"Name: " andText:item.name];
    [self addLabelWithTitle:@"Zufahrt: " andText:item.accessDescription];
    [self addLabelWithTitle:@"Öffnungszeiten: " andText:item.openingTimes];
    [self addLabelWithTitle:@"Frei Parken: " andText:item.tarifFreeParkTime];
    [self addLabelWithTitle:@"Maximale Parkdauer: " andText:item.maximumParkingTime];
    [self addLabelWithTitle:@"Nächster Bahnhofseingang: " andText:item.distanceToStation];
    
    self.infoView = [[MBParkingInfoView alloc] initWithParkingItem:item];
    self.infoView.delegate = self;
    [self.bottomView addSubview:self.infoView];

}

-(void)addLabelWithTitle:(NSString*)title andText:(NSString*)text{
    if(text.length > 0){
        UILabel *titleLabel = [UILabel new];
        titleLabel.text = title;
        [self.bottomView addSubview:titleLabel];
        [self.labels addObject:titleLabel];

        UILabel *addressLabel2 = [UILabel new];
        addressLabel2.text = text;
        addressLabel2.numberOfLines = 0;
        [self.bottomView addSubview:addressLabel2];
        [self.labels addObject:addressLabel2];

        titleLabel.font = [UIFont db_BoldFourteen];
        addressLabel2.font = [UIFont db_RegularFourteen];
        titleLabel.textColor = addressLabel2.textColor = UIColor.db_333333;
    }
}

-(void)layoutContentAndResize{
    self.topView.frame = CGRectMake(8, 8, self.sizeWidth-2*8, 80);
    [self.cellIcon setGravityLeft:36];
    [self.cellIcon setGravityTop:16];//Need additional 8px spacing to the end of this view

    NSInteger x = CGRectGetMaxX(self.cellIcon.frame)+30;
    NSInteger w = self.topView.sizeWidth-x-8;
    self.cellTitle.frame = CGRectMake(x, 8, w, 30);
    
    [self.opencloseImage setGravityLeft:x];
    [self.opencloseImage setBelow:self.cellTitle withPadding:8-4];
    [self.opencloseLabel setBelow:self.cellTitle withPadding:8];
    [self.opencloseLabel setRight:self.opencloseImage withPadding:8];
    [self.opencloseLabel setWidth:self.sizeWidth-x-8];
    [self.opencloseLabel setHeight:16];
    
    //bottom
    self.bottomView.frame = CGRectMake(8, 8+80+4, self.sizeWidth-2*8, 0);

    //labels
    NSInteger y = 8;
    x = 16;
    for(UILabel* label in self.labels){
        CGSize maxSize = CGSizeMake(self.frame.size.width - 32.0-x, CGFLOAT_MAX);
        CGSize wrappedSize = [label sizeThatFits:maxSize];
        label.frame = CGRectMake(x, y, wrappedSize.width, wrappedSize.height);
        y += label.frame.size.height+8;
    }

    //info view
    [self.infoView setWidth:self.topView.sizeWidth];
    [self.infoView setBelow:self.labels.lastObject withPadding:16];
    
    [self.bottomView setHeight:CGRectGetMaxY(self.infoView.frame)];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutContentAndResize];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.expanded = NO;
    for (UIView *sub in self.bottomView.subviews) {
        [sub removeFromSuperview];
    }
    [self.labels removeAllObjects];
}

- (void)setExpanded:(BOOL)expanded {
    _expanded = expanded;
    if(expanded){
        self.accessibilityHint = @"";
    } else {
        self.accessibilityHint = @"Zur Anzeige von Details doppeltippen.";
    }
    self.bottomView.hidden = !_expanded;
    
    [self layoutContentAndResize];
    [self setNeedsLayout];
}

#pragma mark MBParkingInfoDelegate
- (void)didOpenOverviewForParking:(MBParkingInfo *)parking {
    [self.delegate didOpenOverviewForParking:parking];
}

- (void)didOpenTarifForParking:(MBParkingInfo *)parking {
    [self.delegate didOpenTarifForParking:parking];
}

- (void)didStartNavigationForParking:(MBParkingInfo *)parking {
    [self.delegate didStartNavigationForParking:parking];
}

@end
