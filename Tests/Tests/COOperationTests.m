
#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "COOperation.h"
#import "CompositeOperations.h"
#import "COOperation_Private.h"
#import "COQueues.h"

@interface COOperationTests : SenTestCase
@end

@implementation COOperationTests

// Suprisingly ensures that new COOperation instance when called with -finish, triggers its completionBlock, even when its main body is undefined.
- (void)test_NSOperationCallsCompletionBlockWhenFinished_evenWithoutActualyStartMainCalls {
    __block BOOL isFinished = NO;

    COOperation *operation = [COOperation new];

    operation.completionBlock = ^{
        isFinished = YES;
    };

    [operation finish];

    while (isFinished == NO);

    STAssertTrue(isFinished, nil);
}

- (void)test_resolveWithOperation {
    __block BOOL isFinished = NO;

    COOperation *operation = [COOperation new];
    COOperation *anotherOperation = [COOperation new];
    anotherOperation.operationBlock = ^(COOperation *operation){
        [operation finish];
    };

    operation.operationBlock = ^(COOperation *operation){
        [operation resolveWithOperation:anotherOperation];
    };

    operation.completionBlock = ^{
        isFinished = YES;
    };

    CORunOperation(operation);

    while(isFinished == NO) {}

    STAssertTrue(isFinished, nil);
    STAssertTrue(operation.isFinished, nil);
    STAssertTrue(anotherOperation.isFinished, nil);
}

- (void)test_run_completionHandler_cancellationHandler {
    waitSemaphore = dispatch_semaphore_create(0);
    
    COOperation *operation = [COOperation new];

    [operation run:^(COOperation *operation) {
        [operation reject];
    } completionHandler:^(id result){
        AssertShouldNotReachHere();
    } cancellationHandler:^(COOperation *operation, NSError *error) {
        STAssertTrue(operation.isCancelled, nil);

        dispatch_semaphore_signal(waitSemaphore);
    }];

    while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
    }

    STAssertTrue(operation.isCancelled, nil);
}

@end
