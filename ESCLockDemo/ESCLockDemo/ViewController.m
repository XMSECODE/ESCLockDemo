//
//  ViewController.m
//  ESCLockDemo
//
//  Created by xiatian on 2024/1/10.
//

#import "ViewController.h"
//os_unfair_lock
#import <os/lock.h>
//pthread_mutex_t
#import <pthread/pthread.h>

@interface ViewController ()

@property(nonatomic,assign)int count;

@property(nonatomic,assign)os_unfair_lock unfair_lock;

@property(nonatomic,assign)pthread_mutex_t mutexLock;

@property(nonatomic,assign)pthread_mutexattr_t muteAttr;

@property(nonatomic,assign)pthread_cond_t cond;

@property(nonatomic,strong)NSLock* lock;

@property(nonatomic,strong)NSCondition* condition;

@property(nonatomic,strong)NSConditionLock* conditionLock;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //无线程锁
//    [self unlockTest];
    
//    [self unfairlockTest1];
    
//    [self unfairlockTest2];
    
//    [self mutexLockTest1];
    
//    [self mutexLockTest2];
    
//    [self NSLockTest1];
    
//    [self NSConditionTest1];
    
//    [self NSConditionLockTest1];
    
    [self synchronizedTest];
}

- (void)synchronizedTest {
    
    for (int i = 0; i < 10000; i++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{

            //强制加锁
            @synchronized (self) {
                self.count = self.count + 1;
            }
//            NSLog(@"%@ = %d",[NSThread currentThread],self.count);
        });
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"%@ = %d",[NSThread currentThread],self.count);
    });
    
}

- (void)NSConditionLockTest1 {
    //创建条件2的锁
    NSConditionLock *lock = [[NSConditionLock alloc] initWithCondition:2];
    self.conditionLock = lock;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //等待条件1
        [self.conditionLock lockWhenCondition:1];
        NSLog(@"1");
        //打开条件3
        [self.conditionLock unlockWithCondition:3];
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //等待条件4
        [self.conditionLock lockWhenCondition:4];
        NSLog(@"2");
        //打开条件1
        [self.conditionLock unlockWithCondition:1];
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //等待条件2
        [self.conditionLock lockWhenCondition:2];
        NSLog(@"3");
        //打开条件4
        [self.conditionLock unlockWithCondition:4];
    });
    
    //打印3，2，1
}

- (void)NSConditionTest1 {
    self.condition = [[NSCondition alloc] init];

    NSLog(@"开始运行");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
        //激活所有等待该条件的线程
        //[self.condition broadcast];
        //激活一个等待该条件的线程
        [self.condition signal];
    });
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.condition wait];
        NSLog(@"开始计算");
        for (int i = 0; i < 10000; i++) {
            
            
            self.count = self.count + 1;
            
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"%@ = %d",[NSThread currentThread],self.count);
            //销毁锁
            self.condition = nil;
        });
    });
    
}

- (void)NSRecursiveLockTest1 {
    NSRecursiveLock* lock = [[NSRecursiveLock alloc] init];
    [lock lock];
    
    [lock unlock];
}

- (void)NSLockTest1 {
    self.lock = [[NSLock alloc] init];
    
    for (int i = 0; i < 10000; i++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            //尝试加锁，返回1代表加锁成功
//            BOOL result = [self.lock tryLock];
            //强制加锁
            [self.lock lock];
            self.count = self.count + 1;
            [self.lock unlock];
//            NSLog(@"%@ = %d",[NSThread currentThread],self.count);
        });
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"%@ = %d",[NSThread currentThread],self.count);
        self.lock = nil;
    });
}

- (void)mutexLockTest2 {
    pthread_mutex_t mutexLock;
    pthread_mutex_init(&mutexLock, NULL);
    self.mutexLock = mutexLock;
    //初始化条件
    pthread_cond_t cond;
    pthread_cond_init(&cond, NULL);
    self.cond = cond;
    NSLog(@"开始运行");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
        //激活所有等待该条件的线程
//        pthread_cond_broadcast(&self->_cond);
        //激活一个等待该条件的线程
        pthread_cond_signal(&self->_cond);
    });
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        pthread_cond_wait(&self->_cond, &self->_mutexLock);
        NSLog(@"开始计算");
        for (int i = 0; i < 10000; i++) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                //尝试加锁，返回1代表加锁成功
    //            int r = pthread_mutex_trylock(&self->_mutexLock);
                //强制加锁
                pthread_mutex_lock(&self->_mutexLock);
                self.count = self.count + 1;
                pthread_mutex_unlock(&self->_mutexLock);
    //            NSLog(@"%@ = %d",[NSThread currentThread],self.count);
            });
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"%@ = %d",[NSThread currentThread],self.count);
            //销毁锁
            pthread_mutexattr_destroy(&self->_muteAttr);
            pthread_mutex_destroy(&(self->_mutexLock));
            pthread_cond_destroy(&self->_cond);
        });
    });
    
}

- (void)mutexLockTest1 {
    
    //创建锁属性
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    /*
     * Mutex type attributes
     */
//    #define PTHREAD_MUTEX_NORMAL        0
//    #define PTHREAD_MUTEX_ERRORCHECK    1
//    #define PTHREAD_MUTEX_RECURSIVE        2
//    #define PTHREAD_MUTEX_DEFAULT        PTHREAD_MUTEX_NORMAL
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_NORMAL);
    self.muteAttr = attr;
    //初始化锁
    pthread_mutex_t mutexLock;
    //可设置属性
//    pthread_mutex_init(&mutexLock, &attr);
    pthread_mutex_init(&mutexLock, NULL);
    self.mutexLock = mutexLock;
    
    for (int i = 0; i < 10000; i++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            //尝试加锁，返回1代表加锁成功
//            int r = pthread_mutex_trylock(&self->_mutexLock);
            //强制加锁
            pthread_mutex_lock(&self->_mutexLock);
            self.count = self.count + 1;
            pthread_mutex_unlock(&self->_mutexLock);
//            NSLog(@"%@ = %d",[NSThread currentThread],self.count);
        });
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"%@ = %d",[NSThread currentThread],self.count);
        //销毁锁
        pthread_mutexattr_destroy(&self->_muteAttr);
        pthread_mutex_destroy(&(self->_mutexLock));
    });
}

- (void)unfairlockTest2 {
    //创建锁
    os_unfair_lock lock = OS_UNFAIR_LOCK_INIT;

    self.unfair_lock = lock;
    
    for (int i = 0; i < 10000; i++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            //强制加锁
            os_unfair_lock_lock(&self->_unfair_lock);
            self.count = self.count + 1;
            os_unfair_lock_unlock(&self->_unfair_lock);
//            NSLog(@"%@ = %d",[NSThread currentThread],self.count);
        });
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"%@ = %d",[NSThread currentThread],self.count);
    });
}

- (void)unfairlockTest1 {
    
    os_unfair_lock lock = OS_UNFAIR_LOCK_INIT;
    self.unfair_lock = lock;
    
    for (int i = 0; i < 10000; i++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            //尝试加锁，加上返回true，未加上返回false
            bool r = os_unfair_lock_trylock(&self->_unfair_lock);
            if (r == true) {
                self.count = self.count + 1;
                os_unfair_lock_unlock(&self->_unfair_lock);
            }
//            NSLog(@"%@ = %d",[NSThread currentThread],self.count);
        });
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"%@ = %d",[NSThread currentThread],self.count);
    });
}

- (void)unlockTest {
    
    for (int i = 0; i < 10000; i++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            self.count = self.count + 1;
//            NSLog(@"%@ = %d",[NSThread currentThread],self.count);
        });
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //正常逻辑为10000,多线程不安全操作少于10000
        NSLog(@"%@ = %d",[NSThread currentThread],self.count);
    });
    
}





@end
