// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Mantle/Mantle.h>
#import "MBPTSTravelcenter.h"

#define kPhoneKey @"phone"
#define kImageKey @"image"
#define kActionButtonKey @"actionButton"
#define kActionButtonAction @"actionButtonAction"
#define kActionChatbot @"chatbot"
#define kActionPickpackWebsite @"pickpackWebsite"
#define kActionPickpackApp @"pickpackApp"
#define kActionFeedbackMail @"feedbackmail"
#define kActionWhatsAppFeedback @"whatsappfeedback"
#define kActionFeedbackVerschmutzungMail @"feedbackverschmutzung"
#define kActionFeedbackChatbotMail @"feedbackchatbot"

@import CoreLocation;

/*!
 *  @brief  This Model represents a Service as it is aggregated by our API from bahnhof.de
 */
@interface MBService : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSString *type;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *descriptionText;
@property (nonatomic, copy) NSString *additionalText;
@property (nonatomic, copy, readonly) NSNumber *position;
@property (nonatomic, copy) NSDictionary *table;

//these properties are used in the DB-Travelcenter view to display address and opening times before the descriptiontext
@property (nonatomic,copy) NSString* firstHeader;
@property (nonatomic,copy) NSString* addressHeader;
@property (nonatomic,copy) NSString* addressStreet;
@property (nonatomic,copy) NSString* addressPLZ;
@property (nonatomic,copy) NSString* addressCity;
@property (nonatomic) CLLocationCoordinate2D addressLocation;
@property (nonatomic,copy) NSString* secondHeader;
@property (nonatomic,copy) NSString* secondText;
@property (nonatomic,strong) MBPTSTravelcenter* travelCenter;


@property (nonatomic, copy) NSString* trackingKey;

@property (nonatomic, strong) NSString *phoneNumber;

- (NSString *)iconImageNameForType;
- (UIImage*) iconForType;
- (NSString*) parsePhoneNumber;

- (NSArray*) descriptionTextComponents;

-(void)fillTableWithOpenTimes:(NSString*)openTimes;

@end
