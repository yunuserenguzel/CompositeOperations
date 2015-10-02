//
//  GithubUserRepositoriesFetchOperation.h
//  DevelopmentApp
//
//  Created by Stanislaw Pankevich on 02/10/15.
//  Copyright © 2015 Stanislaw Pankevich. All rights reserved.
//

#import <CompositeOperations/COSimpleOperation.h>

@interface GithubUserRepositoriesFetchOperation : COSimpleOperation

- (id)initWithUser:(NSString *)user NS_DESIGNATED_INITIALIZER;
- (id)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end
