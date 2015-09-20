//
// CompositeOperations
//
// CompositeOperations/COOperation.m
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <CompositeOperations/COOperation.h>
#import <CompositeOperations/COTypedefs.h>

typedef NS_ENUM(NSInteger, COOperationState) {
    COOperationStateReady = 0,
    COOperationStateExecuting = 1,
    COOperationStateFinished = 2
};

NSString *const COOperationErrorKey = @"COOperationErrorKey";

static inline NSString *COKeyPathFromOperationState(COOperationState state) {
    switch (state) {
        case COOperationStateReady: {
            return @"isReady";
        }

        case COOperationStateExecuting: {
            return @"isExecuting";
        }

        case COOperationStateFinished: {
            return @"isFinished";
        }

        default: {
            return @"state";
        }
    }
}

static inline int COStateTransitionIsValid(COOperationState fromState, COOperationState toState) {
    switch (fromState) {
        case COOperationStateReady: {
            return YES;
        }

        case COOperationStateExecuting: {
            if (toState == COOperationStateFinished) {
                return YES;
            } else {
                return NO;
            }
        }

        case COOperationStateFinished: {
            return NO;
        }

        default: {
            return NO;
        }
    }
}

@interface COOperation ()

@property (assign, nonatomic) COOperationState state;

@property (strong, nonatomic) id result;
@property (strong, nonatomic) NSError *error;

- (NSError *)resultErrorForError:(NSError *)error code:(NSUInteger)code userInfo:(NSDictionary *)userInfo;

@end

@implementation COOperation

@synthesize state = _state;
@synthesize result = _result;
@synthesize error = _error;
@synthesize completion = _completion;

- (id)init {
    self = [super init];

    if (self == nil) return nil;

    _state = COOperationStateReady;

    return self;
}

- (COOperationState)state {
    COOperationState state;
    @synchronized(self) {
        state = _state;
    }
    return state;
}

- (void)setState:(COOperationState)state {
    if (COStateTransitionIsValid(self.state, state) == NO) {
        NSString *errMessage = [NSString stringWithFormat:@"%@: transition from %@ to %@ is invalid", self, COKeyPathFromOperationState(self.state), COKeyPathFromOperationState(state)];

        @throw [NSException exceptionWithName:COGenericException reason:errMessage userInfo:nil];
    }

    @synchronized(self) {
        if (COStateTransitionIsValid(self.state, state) == NO) {
            NSString *errMessage = [NSString stringWithFormat:@"%@: transition from %@ to %@ is invalid", self, COKeyPathFromOperationState(self.state), COKeyPathFromOperationState(state)];

            @throw [NSException exceptionWithName:COGenericException reason:errMessage userInfo:nil];
        };

        NSString *oldStateKey = COKeyPathFromOperationState(self.state);
        NSString *newStateKey = COKeyPathFromOperationState(state);

        [self willChangeValueForKey:newStateKey];
        [self willChangeValueForKey:oldStateKey];
        _state = state;
        [self didChangeValueForKey:oldStateKey];
        [self didChangeValueForKey:newStateKey];
    }
}

#pragma mark - NSOperation

- (BOOL)isReady {
    return self.state == COOperationStateReady && super.isReady;
}

- (BOOL)isExecuting {
    return self.state == COOperationStateExecuting;
}

- (BOOL)isFinished {
    return self.state == COOperationStateFinished;
}

- (void)main {
    [self finish];
}

- (void)start {
    if (self.isReady) {
        self.state = COOperationStateExecuting;

        if (self.isCancelled) {
            [self reject];
        } else {
            [self main];
        }
    }
}

#pragma mark - <COOperation>

- (void)finish {
    [self finishWithResult:[NSNull null]];
}

- (void)finishWithResult:(id)result {
    NSParameterAssert(result);

    if (self.isCancelled == NO) {
        self.result = result;
    } else {
        self.error = [self resultErrorForError:nil code:COOperationErrorCancelled userInfo:nil];
    }

    self.state = COOperationStateFinished;

    if (self.completion) {
        self.completion(self.result, self.error);
    }
}

- (void)reject {
    if (self.isCancelled == NO) {
        self.error = [self resultErrorForError:nil code:COOperationErrorRejected userInfo:nil];
    } else {
        self.error = [self resultErrorForError:nil code:COOperationErrorCancelled userInfo:nil];
    }

    self.state = COOperationStateFinished;

    if (self.completion) {
        self.completion(nil, self.error);
    }
}

- (void)rejectWithError:(NSError *)error {
    NSParameterAssert(error);

    if (self.isCancelled == NO) {
        self.error = [self resultErrorForError:error code:COOperationErrorRejected userInfo:nil];
    } else {
        self.error = [self resultErrorForError:error code:COOperationErrorCancelled userInfo:nil];
    }

    self.state = COOperationStateFinished;

    if (self.completion) {
        self.completion(nil, self.error);
    }
}

- (NSError *)resultErrorForError:(NSError *)error code:(NSUInteger)code userInfo:(NSDictionary *)userInfo {
    NSDictionary *resultErrorUserInfo = error ? @{COOperationErrorKey: error} : nil;

    NSError *resultError = [NSError errorWithDomain:COErrorDomain code:code userInfo:resultErrorUserInfo];

    return resultError;
}

#pragma mark
#pragma mark <NSObject>

- (NSString *)description {
    NSMutableArray *descriptionComponents = [NSMutableArray array];

    [descriptionComponents addObject:[NSString stringWithFormat:@"state = %@; isCancelled = %@; result = %@; error = \"%@\"", COKeyPathFromOperationState(self.state), self.isCancelled ? @"YES" : @"NO", self.result, self.error.localizedDescription]];

    NSString *description = [NSString stringWithFormat:@"<%@: %p (%@)>", NSStringFromClass([self class]), self, [descriptionComponents componentsJoinedByString:@"; "]];

    return description;
}

- (NSString *)debugDescription {
    NSMutableArray *descriptionComponents = [NSMutableArray array];

    [descriptionComponents addObject:[NSString stringWithFormat:@"state = %@; isCancelled = %@; result = %@; error = \"%@\"", COKeyPathFromOperationState(self.state), self.isCancelled ? @"YES" : @"NO", self.result, self.error]];

    NSString *description = [NSString stringWithFormat:@"<%@: %p (%@)>", NSStringFromClass([self class]), self, [descriptionComponents componentsJoinedByString:@"; "]];

    return description;
}

@end
