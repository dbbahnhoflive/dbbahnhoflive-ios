// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBStationTopView.h"


@interface MBStationTopView()

@property (nonatomic, strong) UILabel *titleView;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIView* darkImageLayer;
@end

@implementation MBStationTopView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    self.backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.backgroundImageView.clipsToBounds = YES;
    [self addSubview:self.backgroundImageView];
    
    self.darkImageLayer = [[UIView alloc] initWithFrame:CGRectZero];
    self.darkImageLayer.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    self.darkImageLayer.clipsToBounds = YES;
    CAGradientLayer* gradient = [CAGradientLayer layer];
    gradient.startPoint = CGPointMake(0.5, 1);
    gradient.endPoint = CGPointMake(0.5, 0);
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor blackColor] CGColor], (id)[[UIColor clearColor] CGColor], nil];
    self.darkImageLayer.layer.mask = gradient;
    self.darkImageLayer.alpha = 1;
    [self addSubview:self.darkImageLayer];

    self.titleView = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleView.font = [UIFont db_BoldTwentyTwo];
    self.titleView.textColor = [UIColor whiteColor];
    self.titleView.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.titleView];
        
    return self;
}


- (void)setTitle:(NSString *)title {
    _title = title;
    self.titleView.text = title;
    [self.titleView setNeedsDisplay];
}


- (void)hideSubviews:(BOOL)hide {
    self.titleView.hidden = hide;
    self.backgroundImageView.hidden = hide;
    if(!hide && self.backgroundImageView.image == nil){
        //lazy loading
        // NSLog(@"lazy loading station image");
        [MBStationTopView loadBackgroundImage:self.backgroundImageView forStation:self.stationId smallSize:NO];
    }
    self.darkImageLayer.hidden = hide;
}

+(void)loadBackgroundImage:(UIImageView*)iv forStation:(NSNumber*)idNum smallSize:(BOOL)smallSize{
    [self loadBackgroundImage:iv forStation:idNum smallSize:smallSize isOEPNV:NO];
}
+(void)loadBackgroundImage:(UIImageView*)iv forStation:(NSNumber*)idNum smallSize:(BOOL)smallSize isOEPNV:(BOOL)isOEPNV{
    if(idNum){
        NSString* idString = idNum.stringValue;
        NSString* prefix = smallSize ? @"station_kachel_" : @"station_header_";
        NSString* path = [[NSBundle mainBundle] pathForResource:[prefix stringByAppendingString:idString] ofType:@"jpg"];
        if(path){
            UIImage* img = [UIImage imageWithContentsOfFile:path];
            if(img){
                iv.image = img;
            }
        }
    }
    if(iv.image == nil){
        //fallback
        if(smallSize){
            if(isOEPNV){
                iv.image = [UIImage db_imageNamed:@"station_kachel_opnv.jpg"];//cache this one
            } else {
                iv.image = [UIImage db_imageNamed:@"station_kachel_default.jpg"];//cache this one
            }
        } else {
            NSString* path = [[NSBundle mainBundle] pathForResource:@"station_header_default" ofType:@"jpg"];
            iv.image = [UIImage imageWithContentsOfFile:path];
        }
    }
}


- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat titleHeight = 30.0;
    CGFloat titleWidth = 300.0;
    CGFloat titleYCorrection = 45-2;
    CGRect titleRect = CGRectMake((self.frame.size.width - titleWidth) / 2.0, self.frame.size.height - titleHeight - titleYCorrection, titleWidth, titleHeight);
    self.titleView.frame = titleRect;
    
    self.backgroundImageView.frame = self.frame;
    self.darkImageLayer.frame = self.frame;
    self.darkImageLayer.layer.mask.frame = CGRectMake(0, 0, self.darkImageLayer.sizeWidth, self.darkImageLayer.sizeHeight);
    [self.darkImageLayer.layer.mask removeAllAnimations];
    
    // title label should always have 8 points distance to bottom
    // until frame is too small
    if (nil != self.titleView) {
        if (self.frame.size.height > (self.titleView.frame.size.height + 16.0)) {
            CGRect newTitleFrame = self.titleView.frame;
            CGFloat newOrigin = self.frame.size.height - newTitleFrame.size.height - titleYCorrection;
            newTitleFrame.origin.y = newOrigin;
            self.titleView.frame = newTitleFrame;
            self.titleView.font = [UIFont db_BoldTwentyTwo];
            self.titleView.hidden = NO;
        } else {
            self.titleView.hidden = YES;
        }
    }
}

@end
