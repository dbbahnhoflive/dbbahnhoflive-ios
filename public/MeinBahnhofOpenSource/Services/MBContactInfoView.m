// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBContactInfoView.h"
#import "MBUIHelper.h"

@interface MBContactInfoView()
@property (nonatomic, strong) VenueExtraField *extraField;
@property (nonatomic, strong) UIButton *webButton;
@property (nonatomic, strong) UIButton *emailButton;
@property (nonatomic, strong) UIButton *phoneButton;
@property (nonatomic, strong) NSArray *buttons;
@end

@implementation MBContactInfoView


- (instancetype)initWithExtraField:(VenueExtraField *)extraField {
    self = [super initWithFrame:CGRectZero];
    self.extraField = extraField;
    [self setup];
    return self;
}



- (void)setup {
    NSMutableArray *buttons = [NSMutableArray new];
    if (nil != self.extraField.web && self.extraField.web.length > 0) {
        self.webButton = [UIButton new];
        [self.webButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self setupLayerForButton:self.webButton];
        self.webButton.accessibilityLabel = @"Webseite";
        [self.webButton setImage:[UIImage db_imageNamed:@"app_website"] forState:UIControlStateNormal];
        [self addSubview:self.webButton];
        [buttons addObject:self.webButton];
    }
    if (nil != self.extraField.phone && self.extraField.phone.length > 0) {
        self.phoneButton = [UIButton new];
        self.phoneButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.phoneButton setImage:[UIImage db_imageNamed:@"app_service_rufnummern"] forState:UIControlStateNormal];
        self.phoneButton.accessibilityLabel = @"Anrufen";
        [self setupLayerForButton:self.phoneButton];
        [self.phoneButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.phoneButton];
        [buttons addObject:self.phoneButton];
    }
    if (nil != self.extraField.email && self.extraField.email.length > 0) {
        self.emailButton = [UIButton new];
        self.emailButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self setupLayerForButton:self.emailButton];
        self.emailButton.accessibilityLabel = @"Email";
        [self.emailButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.emailButton setImage:[UIImage db_imageNamed:@"app_mail"] forState:UIControlStateNormal];
        [self addSubview:self.emailButton];
        [buttons addObject:self.emailButton];
    }
    self.buttons = buttons;
}

- (void)setupLayerForButton:(UIButton *)button {
    button.backgroundColor = [UIColor whiteColor];
    button.layer.shadowOffset = CGSizeMake(1.0, 2.0);
    button.layer.shadowColor = [[UIColor db_dadada] CGColor];
    button.layer.shadowRadius = 1.5;
    button.layer.shadowOpacity = 1.0;
}

- (void)buttonTapped:(UIButton *)sender {
    if ([sender isEqual:self.webButton]) {
        NSString* urlString = self.extraField.web;
        if(![urlString hasPrefix:@"http"]){
            urlString = [@"http://" stringByAppendingString:urlString];
        }
        NSURL *url = [NSURL URLWithString:urlString];
        [self.delegate didOpenUrl:url];
    } else if ([sender isEqual:self.emailButton]) {
        [self.delegate didTapOnEmailLink:self.extraField.email];
    } else if ([sender isEqual:self.phoneButton]) {
        [self.delegate didTapOnPhoneLink:self.extraField.phone];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat distance = 16.0;
    CGFloat completeWidth = 72.0 * self.buttons.count + distance * (self.buttons.count - 1);
    CGFloat leftSlack = (self.frame.size.width - completeWidth) / 2.0;
    
    for(UIView* v in self.buttons){
        v.frame = CGRectMake(leftSlack, 16, 72, 72);
        leftSlack += v.frame.size.width+distance;
    }
    
    self.phoneButton.layer.cornerRadius = self.phoneButton.frame.size.height / 2.0;
    self.webButton.layer.cornerRadius = self.webButton.frame.size.height / 2.0;
    self.emailButton.layer.cornerRadius = self.emailButton.frame.size.height / 2.0;

}

- (void)updateButtonConstraints {
}

@end
