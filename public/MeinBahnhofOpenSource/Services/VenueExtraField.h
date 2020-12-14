// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


@interface VenueExtraField : NSObject

@property (nonatomic, copy) NSString *web;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *phone;

- (NSString*)sanitizedPhoneNumber;

@end
