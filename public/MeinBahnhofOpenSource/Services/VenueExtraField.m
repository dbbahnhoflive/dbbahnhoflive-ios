// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "VenueExtraField.h"

@implementation VenueExtraField



// It would be better if the phone number would be without additional text
- (NSString*)sanitizedPhoneNumber
{
    if (!self.phone || self.phone.length == 0) {
        return @"";
    }
    
    NSString *regexExpression = @"([\\d]|\\s)+";
    
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:regexExpression
                                  options:NSRegularExpressionCaseInsensitive
                                  error:&error];
    
    NSArray *results = [regex matchesInString:self.phone options:0 range:NSMakeRange(0,self.phone.length)];
    
    NSTextCheckingResult *firstMatch = [results firstObject];
    if (firstMatch) {
        return [self.phone substringWithRange:firstMatch.range];
    }
    
    return self.phone;
}


@end
