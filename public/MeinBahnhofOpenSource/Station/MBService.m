// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBService.h"
#import "MBStation.h"
#import "MBPlatformAccessibility.h"

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
                                   @"mobilitaetsservice": @"app_mobilitaetservice",
                                   @"stufenfreier_zugang": @"IconBarrierFree",
                                   @"barrierefreiheit": @"IconBarrierFree",
                                   @"3-s-zentrale": @"app_3s",
                                   @"bahnhofsmission": @"rimap_bahnhofsmission_grau",
                                   @"fundservice": @"app_fundservice",
                                   @"db_information": @"app_information",
                                   @"wlan": @"rimap_wlan_grau",
                                   @"local_travelcenter": @"rimap_reisezentrum_grau",
                                   @"local_db_lounge": @"app_db_lounge",
                                   @"local_lostfound": @"app_fundservice",
                                   @"chatbot": @"chatbot_icon",
                                   @"pickpack": @"pickpack",
                                   @"mobiler_service": @"app_mobiler_service",
                                   @"parkplaetze": @"rimap_parkplatz_grau",
                                   @"verschmutzung_mitwhatsapp": @"verschmutzungmelden",
                                   @"verschmutzung_ohnewhatsapp": @"verschmutzungmelden",
                                   @"bewertung": @"app_bewerten",
                                   @"problemmelden": @"probleme_app_melden",
                                   };
    
    NSString *name = [mappingTypes objectForKey:self.type];
    name = nil == name ? @"" : name;
    return name;
}

- (NSArray*) parseDreiSComponents:(NSString*)string
{
    NSError *error;
    // Special case for 3S content detail:
    // Parse the text enclosed by <p></p> everything after that will be interpreted as phone number
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:kHTMLPTagParser options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSTextCheckingResult *match = [regex firstMatchInString:string options:0 range:NSMakeRange(0, [string length])];
    NSString *descriptionText = [string substringWithRange:[match rangeAtIndex:0]];
    NSString *phoneNumber = [string stringByReplacingOccurrencesOfString:descriptionText withString:@""];
    
    return @[descriptionText, @{kPhoneKey: phoneNumber}];
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
    if ([self.type isEqualToString:@"3-s-zentrale"]) {
        return [self parseDreiSComponents:string];
    } else if ([self.type isEqualToString:@"chatbot"]) {
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
    } else if ([self.type isEqualToString:@"pickpack"]) {
        return [self parsePickpackComponents:string];
    } else if ([self.type isEqualToString:@"mobilitaetsservice"] || [self.type hasPrefix:@"verschmutzung"] || [self.type isEqualToString:@"bewertung"] || [self.type isEqualToString:@"problemmelden"]
               || [self.type isEqualToString:@"stufenfreier_zugang"] || [self.type isEqualToString:@"barrierefreiheit"]){
        NSArray* res = [self parseConfigurableService:string];
        if([self.type isEqualToString:@"barrierefreiheit"]){
            NSString* firstString = res.firstObject;
            //replace [STATUS] in first string with the calculated status
            NSString* status = @"";
            MBPlatformAccessibilityType type = [MBPlatformAccessibility statusStepFreeAccessForAllPlatforms:self.station.platformAccessibility];
            switch (type) {
                case MBPlatformAccessibilityType_UNKNOWN:
                    status = @"";
                    break;
                case MBPlatformAccessibilityType_AVAILABLE:
                    status = @"Dieser Bahnhof bietet Ihnen stufenfreien Zugang.";
                    break;
                case MBPlatformAccessibilityType_NOT_AVAILABLE:
                    status = @"Dieser Bahnhof bietet Ihnen leider <b>keinen</b> stufenfreien Zugang.";
                    break;
                case MBPlatformAccessibilityType_PARTIAL:
                    status = @"Dieser Bahnhof bietet Ihnen <b>teilweise</b> stufenfreien Zugang.";
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

- (NSArray*)parsePickpackComponents:(NSString*)string{
    //we expect a text and add one or two buttons
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:3];
    [res addObject:string];
    [res addObject:@{kActionButtonKey:@"Webseite", kActionButtonAction:kActionPickpackWebsite}];
    [res addObject:@{kActionButtonKey:@"pickpack App", kActionButtonAction:kActionPickpackApp}];
    return res;
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
            NSString* hrefString = @"";
            NSRange hrefStart = [inputString rangeOfString:@"href=\""];
            if(hrefStart.location != NSNotFound){
                NSRange hrefEnd = [inputString rangeOfString:@"\"" options:0 range:NSMakeRange(hrefStart.location+hrefStart.length, inputString.length-(hrefStart.location+hrefStart.length))];
                if(hrefEnd.location != NSNotFound){
                    hrefString = [inputString substringWithRange:NSMakeRange(hrefStart.location+hrefStart.length, hrefEnd.location-(hrefStart.location+hrefStart.length))];
                }
            }
            [res addObject:@{ kActionButtonKey:btntext, kActionButtonAction:hrefString }];
            [inputString deleteCharactersInRange:NSMakeRange(0, btnEnd.location+btnEnd.length)];
        } else {
            //no more buttons, rest is text
            if(inputString.length > 0){
                [res addObject:inputString];
            }
            break;
        }
    }
    return res;
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

-(void)fillTableWithOpenTimes:(NSString *)openTimes{
    
    openTimes = [openTimes stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
    
    self.table = @{ @"headlines":@[@"Öffnungszeiten"],
                       @"rows":@[ @{@"rowItems": @[ @{
                                                        @"key": @"Öffnungszeiten",
                                                        @"headline": @"Öffnungszeiten",
                                                        @"content": openTimes
                                                        }] }  ],
                       };
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"title": @"title",
             @"descriptionText": @"descriptionText",
             @"additionalText": @"additionalText",
             @"type": @"type",
             @"position": @"position",
             @"table": @"table" 
             };
}

@end
