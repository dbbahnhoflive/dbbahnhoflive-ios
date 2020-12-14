// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>

@interface Message : NSObject

@property (nonatomic, strong) NSString *messageId;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *validFrom;
@property (nonatomic, strong) NSString *validTo;
@property (nonatomic, assign) NSUInteger code;
@property (nonatomic, strong) NSString *internalText;
@property (nonatomic, strong) NSString *externalText;
@property (nonatomic, strong) NSString *category;
@property (nonatomic, assign) NSUInteger externalCategory;
@property (nonatomic, assign) double timestamp;
@property (nonatomic, strong) NSString *priority;
@property (nonatomic, strong) NSString *owner;
@property (nonatomic, assign) NSUInteger deleted;

@property (nonatomic, strong) NSString *displayMessage;
@property (nonatomic, assign) BOOL revoked;

@end
