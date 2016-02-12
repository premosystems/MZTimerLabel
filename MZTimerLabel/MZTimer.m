//
//  MZTimer.h
//  Version 0.5.1
//  Created by MineS Chan on 2013-10-16
//  Updated 2014-12-15

// This code is distributed under the terms and conditions of the MIT license.

// Copyright (c) 2014 MineS Chan
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MZTimer.h"


#define kDefaultTimeFormat  @"HH:mm:ss"
#define kHourFormatReplace  @"!!!*"
#define kDefaultFireIntervalNormal  0.1
#define kDefaultFireIntervalHighUse  0.01
#define kDefaultTimerType MZTimerTypeStopWatch

NSString *const kMZTimer_UpdatedNotification = @"kMZTimer_UpdatedNotification";

@interface MZTimer(){
    
    //NSTimeInterval timeUserValue;
    //NSDate *self.startCountDate;
    NSDate *pausedTime;
    NSDate *date1970;
    //NSDate *timeToCountOff;
}

@property (strong) NSTimer *timer;
@property (nonatomic,strong) NSDateFormatter *dateFormatter;

- (void)setup;
- (void)postUpdateNotification;

@end

#pragma mark - Initialize method

@implementation MZTimer



+ (MZTimer*) sharedTimer
{
    static MZTimer *sharedTimer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTimer = [[MZTimer alloc] initWithTimerType:MZTimerTypeTimer];
    });
    return sharedTimer;
}

- (void)dealloc {
    if (_timer) {
        [_timer invalidate];
    }
}

- (id)initWithTimerType:(MZTimerType)theType {
    if (self) {
        
        self.timerType = theType;
        [self setup];
    }
    
    return self;
}

#pragma mark - Getter and Setter Method

- (void)setStopWatchTime:(NSTimeInterval)time{
    
    self.timeUserValue = (time < 0) ? 0 : time;
    if(self.timeUserValue > 0){
        self.startCountDate = [[NSDate date] dateByAddingTimeInterval:-self.timeUserValue];
        pausedTime = [NSDate date];
        [self postUpdateNotification];
    }
}

- (void)setCountDownTime:(NSTimeInterval)time{
    
    self.timeUserValue = (time < 0)? 0 : time;
    self.timeToCountOff = [date1970 dateByAddingTimeInterval:self.timeUserValue];
    [self postUpdateNotification];
}

-(void)setCountDownToDate:(NSDate*)date{
    NSTimeInterval timeLeft = (int)[date timeIntervalSinceDate:[NSDate date]];
    
    if (timeLeft > 0) {
        self.timeUserValue = timeLeft;
        self.timeToCountOff = [date1970 dateByAddingTimeInterval:timeLeft];
    }else{
        self.timeUserValue = 0;
        self.timeToCountOff = [date1970 dateByAddingTimeInterval:0];
    }
    [self postUpdateNotification];
    
}




-(void)addTimeCountedByTime:(NSTimeInterval)timeToAdd
{
    if (_timerType == MZTimerTypeTimer) {
        [self setCountDownTime:timeToAdd + self.timeUserValue];
    }else if (_timerType == MZTimerTypeStopWatch) {
        NSDate *newStartDate = [self.startCountDate dateByAddingTimeInterval:-timeToAdd];
        if([[NSDate date] timeIntervalSinceDate:newStartDate] <= 0) {
            //prevent less than 0
            self.startCountDate = [NSDate date];
        }else{
            self.startCountDate = newStartDate;
        }
    }
    [self postUpdateNotification];
}


- (NSTimeInterval)getTimeCounted
{
    if(!self.startCountDate) return 0;
    NSTimeInterval countedTime = [[NSDate date] timeIntervalSinceDate:self.startCountDate];
    
    if(pausedTime != nil){
        NSTimeInterval pauseCountedTime = [[NSDate date] timeIntervalSinceDate:pausedTime];
        countedTime -= pauseCountedTime;
    }
    return countedTime;
}

- (NSTimeInterval)getTimeRemaining {
    
    if (_timerType == MZTimerTypeTimer) {
        return self.timeUserValue - [self getTimeCounted];
    }
    
    return 0;
}

- (NSTimeInterval)getCountDownTime {
    
    if (_timerType == MZTimerTypeTimer) {
        return self.timeUserValue;
    }
    
    return 0;
}

- (void)setShouldCountBeyondHHLimit:(BOOL)shouldCountBeyondHHLimit {
    _shouldCountBeyondHHLimit = shouldCountBeyondHHLimit;
    [self postUpdateNotification];
}

#pragma mark - Timer Control Method


-(void)start{
    
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    if (self.timerType == MZTimerTypeStopWatch) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:kDefaultFireIntervalHighUse target:self selector:@selector(postUpdateNotification) userInfo:nil repeats:YES];
    }else{
        self.timer = [NSTimer scheduledTimerWithTimeInterval:kDefaultFireIntervalNormal target:self selector:@selector(postUpdateNotification) userInfo:nil repeats:YES];
    }
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    
    if(self.startCountDate == nil){
        self.startCountDate = [NSDate date];
        
        if (self.timerType == MZTimerTypeStopWatch && self.timeUserValue > 0) {
            self.startCountDate = [self.startCountDate dateByAddingTimeInterval:-self.timeUserValue];
        }
    }
    if(pausedTime != nil){
        NSTimeInterval countedTime = [pausedTime timeIntervalSinceDate:self.startCountDate];
        self.startCountDate = [[NSDate date] dateByAddingTimeInterval:-countedTime];
        pausedTime = nil;
    }
    
    _counting = YES;
    [self.timer fire];
}

#if NS_BLOCKS_AVAILABLE
-(void)startWithEndingBlock:(void(^)(NSTimeInterval))end{
    self.endedBlock = end;
    [self start];
}
#endif

-(void)pause{
    if(_counting){
        [_timer invalidate];
        _timer = nil;
        _counting = NO;
        pausedTime = [NSDate date];
    }
}

-(void)reset{
    pausedTime = nil;
    self.timeUserValue = (self.timerType == MZTimerTypeStopWatch)? 0 : self.timeUserValue;
    self.startCountDate = (self.counting)? [NSDate date] : nil;
    [self postUpdateNotification];
}


#pragma mark - Private method

-(void)setup{
    date1970 = [NSDate dateWithTimeIntervalSince1970:0];
    [self postUpdateNotification];
}


-(void) postUpdateNotification {
    
    NSTimeInterval timeDiff = [[NSDate date] timeIntervalSinceDate:self.startCountDate];
   
    BOOL timerEnded = NO;
    if(timeDiff >= self.timeUserValue){
        
        self.startCountDate = nil;
        timerEnded = YES;
        [self.timer invalidate];
    } else {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kMZTimer_UpdatedNotification object:self];
    }
    
    if(timerEnded) {
        if([_delegate respondsToSelector:@selector(timerLabel:finshedCountDownTimerWithTime:)]){
            [_delegate timerLabel:self finshedCountDownTimerWithTime:self.timeUserValue];
        }
        
#if NS_BLOCKS_AVAILABLE
        if(_endedBlock != nil){
            _endedBlock(self.timeUserValue);
        }
#endif
        
    }

    
}

@end
