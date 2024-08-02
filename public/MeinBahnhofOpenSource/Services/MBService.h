// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Mantle/Mantle.h>
#import "MBTravelcenter.h"
#import "MBOSMOpeningWeek.h"
#import "RIMapPoi.h"

#define kPhoneKey @"phone"
#define kImageKey @"image"

#define kPlaceholderARService @"[ARTEASER]"

#define kSpecialAction @"specialAction"
#define kSpecialActionPlatformAccessibiltyUI @"kSpecialActionPlatformAccessibiltyUI"
#define kSpecialActionAR_Teaser @"kSpecialActionAR_Teaser"

#define kActionButtonKey @"actionButton"
#define kActionButtonType @"actionButtonType"
#define kActionButtonAction @"actionButtonAction"
#define kActionChatbot @"chatbot"
#define kActionWegbegleitung @"actionWegbegleitungVideo"
#define kActionWegbegleitung_info @"actionWegbegleitungInfo"
#define kActionMobilitaetsService @"mobilitaetsservice"
#define kActionFeedbackMail @"feedbackmail"
#define kActionWhatsAppFeedback @"whatsappfeedback"
#define kActionFeedbackVerschmutzungMail @"feedbackverschmutzung"
#define kActionFeedbackChatbotMail @"feedbackchatbot"

#define kServiceType_SEV @"schienenersatzverkehr"
#define kServiceType_SEV_AccompanimentService @"accompanimentservice"
#define kServiceType_Locker @"locker"
#define kServiceType_LocalTravelCenter @"local_travelcenter"
#define kServiceType_LocalDBLounge @"local_db_lounge"
#define kServiceType_DBInfo @"db_information"
#define kServiceType_Bahnhofsmission @"bahnhofsmission"
#define kServiceType_MobilerService @"mobiler_service"
#define kServiceType_MobilityService @"mobilitaetsservice"
#define kServiceType_Chatbot @"chatbot"
#define kServiceType_LocalLostFound @"local_lostfound"
#define kServiceType_3SZentrale @"3-s-zentrale"
#define kServiceType_Problems @"problemmelden"
#define kServiceType_Dirt_Prefix @"verschmutzung"
#define kServiveType_Dirt_Whatsapp @"verschmutzung_mitwhatsapp"
#define kServiceType_Dirt_NoWhatsapp @"verschmutzung_ohnewhatsapp"

#define kServiceType_Rating @"bewertung"
#define kServiceType_WLAN @"wlan"
#define kServiceType_Barrierefreiheit @"barrierefreiheit"
#define kServiceType_Parking @"parkplaetze"


@class MBStation;

@import CoreLocation;

/*!
 *  @brief  This Model represents a Service as it is aggregated by our API from bahnhof.de
 */
@interface MBService : MTLModel <MTLJSONSerializing>

@property(nonatomic,strong) MBStation* station;

@property (nonatomic, copy, readonly) NSString *type;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *descriptionText;
@property (nonatomic, copy) NSString *additionalText;
@property (nonatomic, copy, readonly) NSNumber *position;

@property (nonatomic, strong) MBOSMOpeningWeek *openingTimesOSM;


//these properties are used in the DB-Travelcenter view to display address and opening times before the descriptiontext
@property (nonatomic,copy) NSString* firstHeader;
@property (nonatomic,copy) NSString* addressHeader;
@property (nonatomic,copy) NSString* addressStreet;
@property (nonatomic,copy) NSString* addressPLZ;
@property (nonatomic,copy) NSString* addressCity;
@property (nonatomic) CLLocationCoordinate2D addressLocation;
@property (nonatomic,copy) NSString* secondHeader;
@property (nonatomic,copy) NSString* secondText;
@property (nonatomic,strong) MBTravelcenter* travelCenter;


@property (nonatomic, copy) NSString* trackingKey;

@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSDictionary* serviceConfiguration;

- (NSString *)iconImageNameForType;
- (UIImage*) iconForType;
- (NSString*) parsePhoneNumber;

- (NSArray*) descriptionTextComponents;

-(ShopOpenState)openState;

@end
