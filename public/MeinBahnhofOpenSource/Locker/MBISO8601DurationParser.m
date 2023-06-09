// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBISO8601DurationParser.h"

@implementation MBISO8601DurationParser

+ (MBISO8601DurationParser *)shared{
    static MBISO8601DurationParser *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[self alloc] init];
    });
    return sharedClient;
}

-(NSString* _Nullable)parseString:(NSString*)string forVoiceOver:(BOOL)voiceOver{
    string = [string uppercaseString];
    //https://en.wikipedia.org/wiki/ISO_8601#Durations
    //parse P[YY][MM][WW][DD][T[hH][mM][s[.f]S]]
    if([string hasPrefix:@"P"]){
        NSMutableString* processedString = [[NSMutableString alloc] initWithString:string];
        //delete first "P"
        [processedString deleteCharactersInRange:NSMakeRange(0, 1)];
        if([processedString containsString:@"T"]){
            NSArray<NSString*>* components = [processedString componentsSeparatedByString:@"T"];
            if(components.count == 2){
                NSString* dateTime = [self parseDateString:components.firstObject];
                NSString* timeTime = [self parseTimeString:components.lastObject forVoiceOver:voiceOver];
                if(dateTime != nil && timeTime != nil){
                    NSString* res = [NSString stringWithFormat:@"%@%@",dateTime,timeTime];
                    return [self removeCommaSuffix:res];
                }
            }
        } else {
            //no "T", must be just [YY][MM][WW][DD]
            NSString* res = [self parseDateString:processedString];
            return [self removeCommaSuffix:res];
        }
    }
    return nil;
}

-(NSString*)removeCommaSuffix:(NSString*)input{
    if([input hasSuffix:@", "]){
        return [input substringToIndex:input.length-2];
    }
    return input;
}

-(NSString*)parseDateString:(NSString*)string{
    //parse [YY][MM][WW][DD]
    if([string containsString:@"H"]){
        return nil;
    }
    if([string containsString:@"S"]){
        return nil;
    }
    string = [string stringByReplacingOccurrencesOfString:@"Y" withString:@" Jahre, "];
    string = [string stringByReplacingOccurrencesOfString:@"M" withString:@" Monate, "];
    string = [string stringByReplacingOccurrencesOfString:@"W" withString:@" Wochen, "];
    string = [string stringByReplacingOccurrencesOfString:@"D" withString:@" Tage, "];
    return string;
}
-(NSString*)parseTimeString:(NSString*)string forVoiceOver:(BOOL)voiceOver{
    //parse [hH][mM][s[.f]S]
    if(voiceOver){
        string = [string stringByReplacingOccurrencesOfString:@"S" withString:@" Sekunden, "];
        string = [string stringByReplacingOccurrencesOfString:@"H" withString:@" Stunden, "];
        string = [string stringByReplacingOccurrencesOfString:@"M" withString:@" Minuten, "];
    } else {
        string = [string stringByReplacingOccurrencesOfString:@"H" withString:@"h, "];
        string = [string stringByReplacingOccurrencesOfString:@"M" withString:@"m, "];
        string = [string stringByReplacingOccurrencesOfString:@"S" withString:@"s, "];
    }
    return string;
}


@end
