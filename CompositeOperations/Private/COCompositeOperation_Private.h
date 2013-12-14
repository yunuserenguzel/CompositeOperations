//
//  COCompositeOperation_Private.h
//  TestsApp
//
//  Created by Stanislaw Pankevich on 14/12/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import "COCompositeOperation.h"

@interface COCompositeOperation ()

@property (nonatomic) COCompositeOperationConcurrencyType concurrencyType;

@property (nonatomic, getter = isRegistrationStarted) BOOL registrationStarted;
@property (nonatomic, getter = isRegistrationCompleted) BOOL registrationCompleted;

@property (nonatomic, readonly, getter = isInternalReady) BOOL internalReady;
@property (nonatomic) NSMutableArray *internalDependencies;

@property (nonatomic, getter = isInternalCancelled) BOOL internalCancelled;

@property (nonatomic, strong) NSMutableArray *result;

@end
