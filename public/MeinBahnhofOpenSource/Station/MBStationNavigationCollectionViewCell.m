// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBStationNavigationCollectionViewCell.h"

@interface MBStationNavigationCollectionViewCell()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *warnIconimageView;
@property (nonatomic, strong) UIView* errorView;
@property (nonatomic, strong) UILabel* errorLabel;
@property (nonatomic, strong) UIImageView* errorImageView;


@end

@implementation MBStationNavigationCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    self.backgroundColor = [UIColor whiteColor];
    self.imageAsBackground = NO;
    // image on top
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    
    self.imageView.contentMode = UIViewContentModeCenter;
    self.imageView.clipsToBounds = YES;
    
    [self.contentView addSubview:self.imageView];
    
    self.warnIconimageView = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_warndreieck"]];
    self.warnIconimageView.hidden = YES;
    [self.contentView addSubview:self.warnIconimageView];
    
    
    self.errorView = [[UIView alloc] initWithFrame:CGRectZero];
    self.errorView.backgroundColor = [UIColor whiteColor];
    [self.contentView addSubview:self.errorView];
    self.errorImageView = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_error"]];
    self.errorImageView.contentMode = UIViewContentModeCenter;
    [self.errorView addSubview:self.errorImageView];
    self.errorLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.errorLabel.text = @"Daten nicht verfügbar";
    self.errorLabel.font = [UIFont db_RegularFourteen];
    self.errorLabel.numberOfLines = 0;
    self.errorLabel.textColor = [UIColor redColor];
    self.errorLabel.textAlignment = NSTextAlignmentCenter;
    [self.errorView addSubview:self.errorLabel];
    self.errorView.hidden = YES;
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.font = [UIFont db_BoldFourteen];
    if ([UIScreen mainScreen].bounds.size.width <= 320){
        self.titleLabel.font = [UIFont db_BoldTwelve];
    }
    self.titleLabel.textColor = [UIColor db_333333];
    self.titleLabel.numberOfLines = 2;
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
    self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    [self.contentView addSubview:self.titleLabel];
    
    self.layer.shadowColor = [[UIColor db_dadada] CGColor];
    self.layer.shadowOffset = CGSizeMake(3.0, 3.0);
    self.layer.shadowRadius = 3.0;
    self.layer.shadowOpacity = 1.0;
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    
    self.titleLabel.frame = CGRectMake(10, 10, self.bounds.size.width, 80.0);
    self.titleLabel.size = [self.titleLabel sizeThatFits:self.titleLabel.size];
    
    if (self.imageAsBackground) {
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.frame = CGRectMake(1, 1, self.bounds.size.width-2, self.bounds.size.height-2);
        self.imageView.alpha = 0.5;
    } else {
        self.imageView.contentMode = UIViewContentModeCenter;
        CGRect imageRect = CGRectMake(0, self.titleLabel.sizeHeight, self.bounds.size.width, self.bounds.size.height-self.titleLabel.sizeHeight);
        self.imageView.frame = imageRect;
        self.imageView.alpha = 1.;
    }
    
    //center warn icon in imageview but put it a bit right+up
    [self.warnIconimageView setGravityLeft:CGRectGetMidX(self.imageView.frame)+4];
    [self.warnIconimageView setGravityTop:CGRectGetMidY(self.imageView.frame)-self.warnIconimageView.sizeHeight-4];
    
    self.errorView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height-44);
    self.errorLabel.frame = CGRectMake(10, 0, self.bounds.size.width-2*10, 200);
    self.errorLabel.size = CGSizeMake(self.errorLabel.size.width, [self.errorLabel sizeThatFits:self.errorLabel.size].height);
    self.errorImageView.frame = CGRectMake(0, 0, self.bounds.size.width, self.imageView.image.size.height);
    NSInteger errorContentHeight = self.errorLabel.size.height +20 + self.errorImageView.size.height;
    [self.errorImageView setY:(int)(((self.errorView.frame.size.height)-errorContentHeight)/2.)];
    [self.errorLabel setBelow:self.errorImageView withPadding:20];
    [self.errorView centerViewVerticalInSuperView];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.imageAsBackground = NO;
    self.imageView.image = nil;
    self.warnIconimageView.hidden = YES;
    self.imageView.hidden = YES;
    self.errorView.hidden = YES;
    self.kachel = nil;
}


- (void)setKachel:(MBStationKachel *)kachel {
    _kachel = kachel;
    if (nil != _kachel) {
        
        self.warnIconimageView.hidden = !kachel.showWarnIcon;
        
        NSString* imageName = _kachel.imageName;
        if(_kachel.requestFailed){
            imageName = nil;
            self.errorView.hidden = NO;
        } else {
            self.errorView.hidden = YES;
        }
        
        if (nil != imageName) {
            UIImage *image = nil;
            if([imageName isEqualToString:@"ÖPNV-Kombi-Icon"]){
                //this is a temporary solution until we can get an appropriate asset
                UIView* iconContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, (40-4)*4, 40)];
                iconContainer.backgroundColor = [UIColor whiteColor];
                UIImageView* iconTram = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_tram"]];
                UIImageView* iconS = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_sbahn"]];
                UIImageView* iconU = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_ubahn"]];
                UIImageView* iconBus = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_bus"]];
                [iconContainer addSubview:iconTram];
                [iconContainer addSubview:iconS];
                [iconContainer addSubview:iconU];
                [iconContainer addSubview:iconBus];
                [iconS setGravityLeft:(40-4)];
                [iconU setGravityLeft:(40-4)*2];
                [iconBus setGravityLeft:(40-4)*3];
                image = [MBStationNavigationCollectionViewCell imageWithView:iconContainer];
            } else {
                image = [UIImage db_imageNamed:imageName];
            }
            _imageView.image = image;
            _imageView.hidden = NO;
        } else {
            if (nil != _icon) {
                _imageView.image = _icon;
                _imageView.hidden = NO;
            }
        }
        if (nil != _kachel.title) {
            _titleLabel.text = _kachel.title;
        }
        
        self.isAccessibilityElement = true;
        self.accessibilityLabel = self.titleLabel.text;
        if(_kachel.titleForVoiceOver){
            self.accessibilityLabel = _kachel.titleForVoiceOver;
        }
        self.accessibilityTraits = UIAccessibilityTraitStaticText|UIAccessibilityTraitButton;
        self.titleLabel.isAccessibilityElement = NO;
        
        [self setNeedsLayout];
    }
}


+ (UIImage *)imageWithView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}
@end
