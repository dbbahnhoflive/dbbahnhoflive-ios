// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <UIKit/UIKit.h>
#import "MBLocker.h"
#import "NSDictionary+MBDictionary.h"
#import "MBISO8601DurationParser.h"

@implementation MBLocker

-(MBLocker *)initWithDict:(NSDictionary *)dict{
    self = [super init];
    if(self){
        _amount = [dict db_numberForKey:@"amount"].integerValue;
        _size = [self parseSize:[dict db_stringForKey:@"size"]];
        _paymentTypes = [self parsePaymentTypes:[dict db_arrayForKey:@"paymentTypes"]];
        _maxLeaseDuration = [self parseMaxLeaseDuration:[dict db_stringForKey:@"maxLeaseDuration"]];

        //check if this is a "short lease" locker, with a time <24h
        NSString* hourSuffix = UIAccessibilityIsVoiceOverRunning() ? @"Stunden" : @"h";
        if(_maxLeaseDuration && [_maxLeaseDuration hasSuffix:hourSuffix]){
            //remove suffix, check if only a number is left
            NSString* time = [_maxLeaseDuration substringToIndex:_maxLeaseDuration.length-hourSuffix.length];
            time = [time stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
            NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
            if ([time rangeOfCharacterFromSet:notDigits].location == NSNotFound)
            {
                // time is only digits
                NSInteger timeInt = time.integerValue;
                if(timeInt > 0 && timeInt < 24){
                    _isShortLeaseLocker = true;
                }
            }
        }
                
        NSDictionary* fee = [dict db_dictForKey:@"fee"];
        if([fee isKindOfClass:NSDictionary.class]){
            _fee = [fee db_numberForKey:@"fee"].integerValue;
            [self fillFeePeriod:[fee db_stringForKey:@"feePeriod"]];
        }
        NSDictionary* dimension = [dict db_dictForKey:@"dimension"];
        if([dimension isKindOfClass:NSDictionary.class]){
            _depth = [dimension db_numberForKey:@"depth"].integerValue;
            _width = [dimension db_numberForKey:@"width"].integerValue;
            _height = [dimension db_numberForKey:@"height"].integerValue;
        }
    }
    return self;
}
    
-(void)fillFeePeriod:(NSString*)feePeriod{
    if([feePeriod isEqualToString:@"PER_MAX_LEASE_DURATION"]){
        _feePeriod = _maxLeaseDuration;
    } else if([feePeriod isEqualToString:@"PER_HOUR"]){
        _feePeriod = @"1h";
    } else if([feePeriod isEqualToString:@"PER_DAY"]){
        _feePeriod = @"Tag";
    }
}
    

-(MBLockerSize)parseSize:(NSString*)size{
    if(![size isKindOfClass:NSString.class]){
        return MBLockerSizeUnknown;
    }
    if([size isEqualToString:@"SMALL"]){
        return MBLockerSizeSmall;
    } else if([size isEqualToString:@"MEDIUM"]){
        return MBLockerSizeMedium;
    } else if([size isEqualToString:@"LARGE"]){
        return MBLockerSizeLarge;
    } else if([size isEqualToString:@"JUMBO"]){
        return MBLockerSizeJumbo;
    } else {
        return MBLockerSizeUnknown;
    }
}
-(NSString*)parsePaymentTypes:(NSArray<NSString*>*)paymentTypes{
    if(![paymentTypes isKindOfClass:NSArray.class]){
        return @"unbekannt";
    }
    NSMutableString* res = [NSMutableString new];
    for(NSString* type in paymentTypes){
        if(![type isKindOfClass:NSString.class]){
            continue;
        }
        if([type isEqualToString:@"CASH"]){
            if(res.length > 0){
                [res appendString:@", "];
            }
            [res appendString:@"bar"];
        } else if([type isEqualToString:@"CASHLESS"]){
            if(res.length > 0){
                [res appendString:@", "];
            }
            [res appendString:@"bargeldlos"];
        } else if(![res containsString:@"unbekannt"]) {
            if(res.length > 0){
                [res appendString:@", "];
            }
            [res appendString:@"unbekannt"];
        }
    }
    if(res.length == 0){
        [res appendString:@"unbekannt"];
    }
    return res;
}
-(NSString*)parseMaxLeaseDuration:(NSString*)ISO8601{
    if([ISO8601 isKindOfClass:NSString.class]){
        return [MBISO8601DurationParser.shared parseString:ISO8601 forVoiceOver:UIAccessibilityIsVoiceOverRunning()];
    }
    return nil;
}

-(NSString *)headerText{
    NSString* res = nil;
    switch(self.size){
        case MBLockerSizeSmall:
            res = @"Kleines Schließfach";
            break;
        case MBLockerSizeMedium:
            res = @"Mittleres Schließfach";
            break;
        case MBLockerSizeLarge:
            res = @"Großes Schließfach";
            break;
        case MBLockerSizeJumbo:
            res = @"Jumbo-Schließfach";
            break;
        case MBLockerSizeUnknown:
        default:
            res = @"Unbekannte Größe";
            break;
    }
    if(_isShortLeaseLocker){
        res = [res stringByAppendingString:@" (Kurzzeit)"];
    }
    return res;
}
-(NSString *)lockerDescriptionTextForVoiceOver:(BOOL)voiceOver{
    NSString* notAvailableString = @"Information liegt nicht vor";
    
    NSMutableString* res = [NSMutableString new];
    [res appendFormat:@"Insgesamt %ld Schließfächer\n",(long)_amount];
    //l,b,h
    if(_width > 0 && _depth > 0 && _height > 0){
        if(voiceOver){
            [res appendFormat:@"Größe: %ld Zentimeter Länge, %ld Zentimeter Breite, %ld Zentimeter Höhe\n",(long)_depth/10,(long)_width/10,(long)_height/10];
        } else {
            [res appendFormat:@"Größe: %ld x %ld x %ld\n",(long)_depth/10,(long)_width/10,(long)_height/10];
        }
    } else {
        [res appendFormat:@"Größe: %@\n",notAvailableString];
    }
    NSString* leaseTime = _maxLeaseDuration.length > 0 ? _maxLeaseDuration : notAvailableString;
    if(voiceOver){
        [res appendFormat:@"Maximale Mietdauer: %@\n",leaseTime];
    } else {
        [res appendFormat:@"Max. Mietdauer: %@\n",leaseTime];
    }
    if(_fee > 0 && _feePeriod != nil){
        NSString* feeString = [NSString stringWithFormat:@"%0.2f",_fee/100.];
        feeString = [feeString stringByReplacingOccurrencesOfString:@"." withString:@","];
        feeString = [feeString stringByReplacingOccurrencesOfString:@",00" withString:@""];
        if(voiceOver){
            [res appendFormat:@"Preis: %@ € pro %@\n",feeString,_feePeriod];
        } else {
            [res appendFormat:@"Preis: %@ € / %@\n",feeString,_feePeriod];
        }
    } else {
        [res appendFormat:@"Preis: %@\n",notAvailableString];
    }
    NSString* payment = _paymentTypes.length > 0 ? _paymentTypes : notAvailableString;
    [res appendFormat:@"Zahlungsmittel: %@\n",payment];
    return [res stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}


@end
