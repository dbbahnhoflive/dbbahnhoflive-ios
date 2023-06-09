// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBNetworkFactory.h"
#import "Constants.h"

@implementation MBNetworkFactory

+(AFHTTPSessionManager*)createRISSessionManager{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFHTTPSessionManager* networkManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
    [self configureRISHeader:networkManager];
    return networkManager;
}

+(void)configureRISHeader:(AFHTTPSessionManager*)networkManager{
    [networkManager.requestSerializer setValue:@"application/json, application/vnd.de.db.ris+json, */*" forHTTPHeaderField:@"Accept"];

    [networkManager.requestSerializer setValue:[Constants dbAPIKey] forHTTPHeaderField:@"db-api-key"];
    [networkManager.requestSerializer setValue:[Constants dbAPIClient] forHTTPHeaderField:@"db-client-id"];
    networkManager.responseSerializer.acceptableContentTypes = [networkManager.responseSerializer.acceptableContentTypes setByAddingObject:@"application/vnd.de.db.ris+json"];
}

@end
