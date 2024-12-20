// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBService.h"
#import "MBStation.h"
#import "MBPlatformAccessibility.h"
#import "UIImage+MBImage.h"
#import "SEVWebViewController.h"
#import "MBNews.h"

// Pattern to detect phone numbers in a text which also may be surrounded by anchor-tags or white spaces
#define kPhoneRegexPattern @"(>|\\s)[\\d]{3,}\\/?([^\\D]|\\s)+[\\d]"
#define kHTMLPTagParser @"<p>.*</p>"

#define kTagCloseBraceChar @">"
#define kTagSlashChar @"/"

@implementation MBService

- (UIImage*) iconForType
{
    
    UIImage *icon = [UIImage db_imageNamed:[self iconImageNameForType]];
    if (!icon) {
        icon = [UIImage db_imageNamed:@""];
    }
    return icon;
}

- (NSString *)iconImageNameForType {
    NSDictionary *mappingTypes = @{
        kServiceType_MobilityService: @"app_mobilitaetservice",
        kServiceType_Barrierefreiheit: @"IconBarrierFree",
        kServiceType_3SZentrale: @"app_3s",
        kServiceType_Bahnhofsmission: @"rimap_bahnhofsmission_grau",
        kServiceType_DBInfo: @"app_information",
        kServiceType_WLAN: @"rimap_wlan_grau",
        kServiceType_SEV: @"sev_bus",
        kServiceType_SEV_AccompanimentService: @"SEV_Icon",
        kServiceType_Locker: @"rimap_schliessfach_grau",
        kServiceType_LocalTravelCenter: @"rimap_reisezentrum_grau",
        kServiceType_LocalDBLounge: @"app_db_lounge",
        kServiceType_LocalLostFound: @"app_fundservice",
        kServiceType_Chatbot: @"chatbot_icon",
        kServiceType_MobilerService: @"app_mobiler_service",
        kServiceType_Parking: @"rimap_parkplatz_grau",
        kServiveType_Dirt_Whatsapp: @"verschmutzungmelden",
        kServiceType_Dirt_NoWhatsapp: @"verschmutzungmelden",
        kServiceType_Rating: @"app_bewerten",
        kServiceType_Problems: @"probleme_app_melden",
        kServiceType_NEXTAPP: NEW_APP_ICON,
    };

    NSString *name = [mappingTypes objectForKey:self.type];
    name = nil == name ? @"" : name;
    return name;
}


- (NSArray*) descriptionTextComponents
{
    NSString *string = self.descriptionText;
    
    // strip additional new lines to improve linebreaks and word wrapping
    string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    if (string.length == 0) {
        return @[];
    }
    
    // check if we need special content handling
    if ([self.type isEqualToString:kServiceType_3SZentrale]
        ||
        [self.type isEqualToString:kServiceType_LocalLostFound]
        ||
        [self.type isEqualToString:kServiceType_SEV]
        ||
        [self.type isEqualToString:kServiceType_SEV_AccompanimentService]
        ||
        [self.type isEqualToString:kServiceType_NEXTAPP]
        ) {
        NSArray* res = [self parseConfigurableService:string];
        return res;
    } else if ([self.type isEqualToString:kServiceType_Chatbot]) {
        NSMutableArray* res = [[self parseConfigurableService:string] mutableCopy];
        [res insertObject:@{kImageKey:@"chatbot_d1"} atIndex:0];
        /*
        if(![self isChatBotTime]){
            for(NSInteger i=0; i<res.count; i++){
                if([res[i] isKindOfClass:NSDictionary.class]){
                    NSDictionary* d = res[i];
                    NSString* link = d[kActionButtonAction];
                    if([link isEqualToString:kActionChatbot]){
                        [res removeObjectAtIndex:i];
                        break;
                    }
                }
            }
        }*/
        return res;
    } else if ([self.type isEqualToString:kServiceType_MobilityService] || [self.type hasPrefix:kServiceType_Dirt_Prefix] || [self.type isEqualToString:kServiceType_Rating] || [self.type isEqualToString:kServiceType_Problems]
               || [self.type isEqualToString:kServiceType_Barrierefreiheit]){
        NSArray* res = [self parseConfigurableService:string];
        if([self.type isEqualToString:kServiceType_Barrierefreiheit]){
            NSString* firstString = res.firstObject;
            //replace [STATUS] in first string with the calculated status
            NSString* status = @"";
            MBPlatformAccessibilityType type = [MBPlatformAccessibility statusStepFreeAccessForAllPlatforms:self.station.platformAccessibility];
            switch (type) {
                case MBPlatformAccessibilityType_UNKNOWN:
                    status = @"";
                    break;
                case MBPlatformAccessibilityType_AVAILABLE:
                    status = @"Dieser Bahnhof bietet Ihnen einen stufenfreien Zugang zu den Bahnsteigen.";
                    break;
                case MBPlatformAccessibilityType_NOT_AVAILABLE:
                    status = @"Dieser Bahnhof verfügt über <b>keinen</b> stufenfreien Zugang zu den Bahnsteigen.";
                    break;
                case MBPlatformAccessibilityType_PARTIAL:
                    status = @"Dieser Bahnhof bietet nur <b>teilweise</b> stufenfreien Zugang zu den Bahnsteigen. Für detaillierte Informationen wählen Sie bitte weiter unten auf dieser Seite ein Gleis aus.";
                    break;
                default:
                    break;
            }
            
            firstString = [firstString stringByReplacingOccurrencesOfString:@"[STATUS]" withString:status];
            NSMutableArray* resAcc = [res mutableCopy];
            [resAcc removeObjectAtIndex:0];
            [resAcc insertObject:firstString atIndex:0];
            //add UI elements
            [resAcc addObject:@{kSpecialAction:kSpecialActionPlatformAccessibiltyUI}];
            return resAcc;
        }
        return res;
    } else {
        return [self parseRegularComponents:string];
    }
}


-(NSArray*)parseConfigurableService:(NSString*)string{
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:6];
    //expecting text with configured dbactionbutton(s)
    
    NSMutableString* inputString = [string mutableCopy];
    while(true){
        NSRange btnStart = [inputString rangeOfString:@"<dbactionbutton"];
        if(btnStart.location != NSNotFound){
            NSString* firstText = [inputString substringToIndex:btnStart.location];
            if(firstText.length > 0){
                [res addObject:firstText];
            }
            NSRange btnStartEnd = [inputString rangeOfString:@">" options:0 range:NSMakeRange(btnStart.location, inputString.length-btnStart.location)];
            if(btnStartEnd.location == NSNotFound){
                NSLog(@"html error in input: %@",inputString);
                return res;
            }
            NSInteger btnStartLength = (btnStartEnd.location+1-btnStart.location);
            NSRange btnEnd = [inputString rangeOfString:@"</dbactionbutton>"];
            NSString* btntext = [inputString substringWithRange:NSMakeRange(btnStart.location+btnStartLength, btnEnd.location-(btnStart.location+btnStartLength))];
            
            //parse single href-param in button
            NSString* hrefString = [self parseParameter:@"href" inString:inputString rangeStart:btnStart rangeEnd:btnEnd];
            NSString* typeString = [self parseParameter:@"type" inString:inputString rangeStart:btnStart rangeEnd:btnEnd];
            if(typeString.length == 0){
                typeString = @"action";
            } else if(![typeString isEqualToString:@"action"] && ![typeString isEqualToString:@"extern"] && ![typeString isEqualToString:@"intern"]){
                NSAssert(false, @"invalid type, expected action, extern or intern");
            }
            
            [res addObject:@{ kActionButtonKey:btntext, kActionButtonAction:hrefString, kActionButtonType:typeString }];
            [inputString deleteCharactersInRange:NSMakeRange(0, btnEnd.location+btnEnd.length)];
        } else {
            //no more buttons, rest is text
            if(inputString.length > 0){
                [res addObject:inputString];
            }
            break;
        }
    }
    //replace other placeholders
    [self replaceString:kPlaceholderARService with:@{kSpecialAction:kSpecialActionAR_Teaser} inList:res];
    return res;
}

-(NSString*)parseParameter:(NSString*)parameter inString:(NSString*)inputString rangeStart:(NSRange)btnStart rangeEnd:(NSRange)btnEnd{
    NSString* paramString = [parameter stringByAppendingString:@"=\""];
    NSString* hrefString = @"";
    NSRange hrefStart = [inputString rangeOfString:paramString options:0 range:NSMakeRange(btnStart.location, btnEnd.location-btnStart.location)];
    if(hrefStart.location != NSNotFound){
        NSRange hrefEnd = [inputString rangeOfString:@"\"" options:0 range:NSMakeRange(hrefStart.location+hrefStart.length, inputString.length-(hrefStart.location+hrefStart.length))];
        if(hrefEnd.location != NSNotFound){
            hrefString = [inputString substringWithRange:NSMakeRange(hrefStart.location+hrefStart.length, hrefEnd.location-(hrefStart.location+hrefStart.length))];
        }
    }
    return hrefString;
}

-(void)replaceString:(NSString*)placeholder with:(NSDictionary*)action inList:(NSMutableArray*)list{
    NSInteger index = 0;
    BOOL found = false;
    for(id item in list){
        if([item isKindOfClass:NSString.class]){
            NSString* text = item;
            if([text containsString:placeholder]){
                found = true;
                break;
            }
        }
        index++;
    }
    if(found){
        NSString* text = list[index];
        NSRange range = [text rangeOfString:placeholder];
        NSString* textBefore = [text substringToIndex:range.location];
        NSString* textAfter = [text substringFromIndex:range.location+range.length];
        [list removeObjectAtIndex:index];
        [list insertObject:textBefore atIndex:index];
        [list insertObject:action atIndex:index+1];
        [list insertObject:textAfter atIndex:index+2];
    }
}

-(ShopOpenState)openState{
    if([self.type isEqualToString:kServiceType_SEV_AccompanimentService]){
        if(self.station.hasAccompanimentServiceActive && [SEVWebViewController wegbegleitungIsActiveTime]){
            return POI_OPEN;
        } else {
            return POI_CLOSED;
        }
    }
    return POI_UNKNOWN;
}

-(BOOL)isChatBotTime{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    [gregorian setLocale:[NSLocale localeWithLocaleIdentifier:@"de_DE"]];
    [gregorian setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Berlin"]];
    
    NSDateComponents *comps = [gregorian components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:[NSDate date]];
    NSInteger currentHour = [comps hour];
    return currentHour >= 7 && currentHour <= 21;//7:00-21:59
}

- (NSArray*)parseRegularComponents:(NSString*)string
{
    // parse the phone number and create an array which keeps the components
    NSString *phoneNumber = [self parsePhoneNumber];
    NSArray *components = @[string];
    
    // the resulting array, in case a phone number was found
    if (phoneNumber && phoneNumber.length > 0) {
        NSMutableArray *arrComponents = [[string componentsSeparatedByString:phoneNumber] mutableCopy];
        [arrComponents insertObject:@{kPhoneKey: phoneNumber} atIndex:1];
        components = arrComponents;
    }
    
    return components;
}

- (NSString*) parsePhoneNumber
{
    NSString *string = self.descriptionText;
    
    NSError *error = nil;
    // search the descriptionText for a phone number
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:kPhoneRegexPattern options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSTextCheckingResult *match = [regex firstMatchInString:string options:0 range:NSMakeRange(0, [string length])];
    NSString *phoneNumber = [string substringWithRange:[match rangeAtIndex:0]];
    phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:kTagCloseBraceChar withString:@""];
    
    return phoneNumber;
}


+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"title": @"title",
             @"descriptionText": @"descriptionText",
             @"additionalText": @"additionalText",
             @"type": @"type",
             @"position": @"position"
             };
}

@end
