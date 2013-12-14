
#import <Foundation/Foundation.h>
#import <SenTestingKit/SenTestingKit.h>
#import <Kiwi.h>

#define raiseShouldNotReachHere() @throw [NSException exceptionWithName:NSGenericException reason:[NSString stringWithFormat:@"Should not reach here: %s:%d, %s", __FILE__, __LINE__, __PRETTY_FUNCTION__] userInfo:nil]

dispatch_queue_t currentQueue();

dispatch_queue_t serialQueue();
dispatch_queue_t concurrentQueue();
dispatch_queue_t createQueue();

typedef void (^asyncronousBlock)(void);

void asynchronousJob(asyncronousBlock block);

@interface SenTestCase (Helpers)
- (void) setUp;
@end

static inline void dispatch_once_and_next_time(dispatch_once_t *oncePredicate, dispatch_block_t onceBlock, dispatch_block_t nextTimeBlock) {
    if (*oncePredicate) {
        [nextTimeBlock invoke];
    }

    dispatch_once(oncePredicate, ^{
        [onceBlock invoke];
    });
}
