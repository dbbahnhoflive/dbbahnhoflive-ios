// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBShopDetailCellView.h"

#import "MBLabel.h"
#import "MBTextView.h"
#import "MBUIHelper.h"


@interface MBShopDetailCellView()

@property (nonatomic, strong) MBLabel *addressLabel;
@property (nonatomic, strong) MBLabel *openingHeaderLabel;
@property (nonatomic, strong) MBLabel *openingHoursLabel;
@property (nonatomic, strong) MBLabel *paymentHeaderLabel;
@property (nonatomic, strong) MBLabel *paymentTextLabel;

@end

@implementation MBShopDetailCellView

- (instancetype)initWithPXR:(RIMapPoi *)poi {
    self = [super initWithFrame:CGRectZero];
    self.poi = poi;
    [self setupViews];
    [self fillWithData];
    return self;
}

- (void)setupViews {
    self.addressLabel = [MBLabel new];
    self.addressLabel.font = [UIFont db_RegularFourteen];
    self.addressLabel.textColor = [UIColor db_333333];
    self.addressLabel.numberOfLines = 0;
    [self addSubview:self.addressLabel];

    self.openingHeaderLabel = [MBLabel new];
    self.openingHeaderLabel.font = [UIFont db_BoldFourteen];
    self.openingHeaderLabel.textColor = [UIColor db_333333];
    [self addSubview:self.openingHeaderLabel];

    self.openingHoursLabel = [MBLabel new];
    self.openingHoursLabel.font = [UIFont db_RegularFourteen];
    self.openingHoursLabel.textColor = [UIColor db_333333];
    self.openingHoursLabel.numberOfLines = 0;
    [self addSubview:self.openingHoursLabel];
        
    self.paymentHeaderLabel = [MBLabel new];
    self.paymentHeaderLabel.font = [UIFont db_BoldFourteen];
    self.paymentHeaderLabel.textColor = [UIColor db_333333];
    [self addSubview:self.paymentHeaderLabel];

    self.paymentTextLabel = [MBLabel new];
    self.paymentTextLabel.font = [UIFont db_RegularFourteen];
    self.paymentTextLabel.textColor = [UIColor db_333333];
    self.paymentTextLabel.numberOfLines = 0;
    [self addSubview:self.paymentTextLabel];

    self.isAccessibilityElement = YES;
    self.addressLabel.isAccessibilityElement = NO;
    self.openingHoursLabel.isAccessibilityElement = NO;
    self.openingHeaderLabel.isAccessibilityElement = NO;

}

-(NSString *)accessibilityLabel{
    NSString* res = [NSString stringWithFormat:@"%@. %@ %@",self.addressLabel.accessibilityLabel, self.openingHeaderLabel.accessibilityLabel, self.openingHoursLabel.accessibilityLabel];
    if(!self.paymentHeaderLabel.hidden && self.paymentHeaderLabel.accessibilityLabel.length > 0){
        res = [NSString stringWithFormat:@"%@. %@ %@",res,self.paymentHeaderLabel.accessibilityLabel,self.paymentTextLabel.accessibilityLabel];
    }
    return res;
}

-(BOOL)hasContactLinks{
    if(self.poi){
        return
        self.poi.phone.length > 0
        || self.poi.email.length > 0
        || self.poi.website.length > 0;
    }
    return NO;
}
-(VenueExtraField*)contactLinks{
    if(self.poi) {
        VenueExtraField* ve = [VenueExtraField new];
        ve.phone = self.poi.phone;
        ve.web = self.poi.website;
        ve.email = self.poi.email;
        return ve;
    }
    return nil;
}

+(NSString*)displayStringForOpeningTimes:(NSArray<NSDictionary*>*)openingTimes voiceOver:(BOOL)voiceOver{
    NSMutableArray *openingTimeComponents = [NSMutableArray array];
    NSString *timeText = @"";
    for (NSDictionary *timeDict in openingTimes) {
        NSString *days = [timeDict objectForKey:@"day-range"];
        NSString *timeFrom = [timeDict objectForKey:@"time-from"];
        NSString *timeTo = [timeDict objectForKey:@"time-to"];
        if(voiceOver){
            [openingTimeComponents addObject:[NSString stringWithFormat:@"%@.: %@ bis %@ Uhr.", [days stringByReplacingOccurrencesOfString:@"-" withString:@". bis "], timeFrom, timeTo]];
        } else {
            [openingTimeComponents addObject:[NSString stringWithFormat:@"%@: %@-%@", days, timeFrom, timeTo]];
        }
    }
    timeText = [openingTimeComponents componentsJoinedByString:@"\n"];
    return timeText;
}

- (void)fillWithData {
    // Location
    if(self.poi){
        self.addressLabel.text = [RIMapPoi levelCodeToDisplayString:self.poi.levelcode ];
        // Opening hours
        self.openingHeaderLabel.text = @"Öffnungszeiten";
        
        
        NSString* timeText = self.poi.allOpenTimes;
        if (nil == timeText || timeText.length == 0) {
            self.openingHoursLabel.text = @"keine Angaben";
        } else {
            self.openingHoursLabel.text = timeText;
        }
        if(timeText.length > 0){
            NSMutableString* timeVoiceOver = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"%@ Uhr.",timeText]];
            [timeVoiceOver replaceOccurrencesOfString:@"-" withString:@" bis " options:0 range:NSMakeRange(0, timeVoiceOver.length)];
            [timeVoiceOver replaceOccurrencesOfString:@"\n" withString:@" Uhr\n" options:0 range:NSMakeRange(0, timeVoiceOver.length)];
            
            self.openingHoursLabel.accessibilityLabel = timeVoiceOver;
            //NSLog(@"converted %@ into %@",timeText,timeVoiceOver);
        }
        
    }
    [self setNeedsLayout];
}

-(NSInteger)layoutForSize:(NSInteger)frameWidth{
    NSInteger x = 110;
    NSInteger y = 16;
    NSInteger maxWidth = frameWidth-8-x;
    self.addressLabel.frame = CGRectMake(x, y, maxWidth, 0);
    CGSize size = [self.addressLabel sizeThatFits:CGSizeMake(maxWidth, 1000)];
    [self.addressLabel setSize:size];
    y += self.addressLabel.size.height+16;
    
    y = [self layoutLabelHeader:self.openingHeaderLabel withText:self.openingHoursLabel atX:x y:y width:maxWidth];
    
    if(!self.paymentHeaderLabel.hidden){
        y = [self layoutLabelHeader:self.paymentHeaderLabel withText:self.paymentTextLabel atX:x y:y width:maxWidth];
    }
    
    //NSLog(@"layoutsubviews in shopdetails, %@",self.addressLabel);
    self.frame = CGRectMake(0,0,frameWidth, y);
    return self.frame.size.height;
}

-(NSInteger)layoutLabelHeader:(UILabel*)header withText:(UILabel*)text atX:(NSInteger)x y:(NSInteger)y width:(NSInteger)maxWidth{
    header.frame = CGRectMake(x, y, maxWidth, 0);
    CGSize size = [header sizeThatFits:CGSizeMake(maxWidth, 1000)];
    [header setSize:size];
    y += header.size.height+8;
    
    text.frame = CGRectMake(x, y, maxWidth, 0);
    size = [text sizeThatFits:CGSizeMake(maxWidth, 1000)];
    [text setSize:size];
    y += text.size.height+16;
    return y;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutForSize:self.sizeWidth];
}


@end
