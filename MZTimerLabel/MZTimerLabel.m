//
//  MZTimerLabel.h
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

#import "MZTimerLabel.h"
#import "MZTimer.h"

#define kDefaultTimeFormat  @"HH:mm:ss"
#define kHourFormatReplace  @"!!!*"
#define kDefaultFireIntervalNormal  0.1
#define kDefaultFireIntervalHighUse  0.01
#define kDefaultTimerType MZTimerLabelTypeStopWatch

@interface MZTimerLabel(){
    
    //NSTimeInterval timeUserValue;
    //NSDate *self.timer.startCountDate;
    NSDate *pausedTime;
    NSDate *date1970;
    //NSDate *timeToCountOff;
}

@property (nonatomic,strong) NSDateFormatter *dateFormatter;

- (void)setup;
- (void)updateLabel;

@end

#pragma mark - Initialize method

@implementation MZTimerLabel

@synthesize timeFormat = _timeFormat;

- (id)init {
    return [self initWithFrame:CGRectZero label:nil andTimer:[MZTimer sharedTimer]];
}

- (id)initWithLabel:(UILabel*)theLabel {
    return [self initWithFrame:CGRectZero label:theLabel andTimer:[MZTimer sharedTimer]];
}

- (id)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame label:nil andTimer:[MZTimer sharedTimer]];
}

-(id)initWithFrame:(CGRect)frame label:(UILabel*)theLabel andTimer:(MZTimer*)timer {
    self = [super initWithFrame:frame];
    if (self) {
        self.timeLabel = theLabel;
        self.timer = timer;
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
        self.timer = [MZTimer sharedTimer];
        self.timeLabel = self;
        [self setup];
	}
	return self;
}

#pragma mark - Lifecycle -

- (void) setup
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLabel) name:kMZTimer_UpdatedNotification object:nil];
}

- (void) tearDown
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Cleanup

- (void) removeFromSuperview {
    
    [self tearDown];
    [super removeFromSuperview];
    
}

- (void) dealloc
{
    [self tearDown];
}

#pragma mark - Getter and Setter Method

- (void)setTimeFormat:(NSString *)timeFormat{
    
    if ([timeFormat length] != 0) {
        _timeFormat = timeFormat;
        self.dateFormatter.dateFormat = timeFormat;
    }
    [self updateLabel];
}

- (NSString*)timeFormat
{
    if ([_timeFormat length] == 0 || _timeFormat == nil) {
        _timeFormat = kDefaultTimeFormat;
    }
    
    return _timeFormat;
}

- (NSDateFormatter*)dateFormatter{
    
    if (_dateFormatter == nil) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"];
        [_dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
        _dateFormatter.dateFormat = self.timeFormat;
    }
    return _dateFormatter;
}

- (UILabel*)timeLabel
{
    if (_timeLabel == nil) {
        _timeLabel = self;
    }
    return _timeLabel;
}



- (NSTimeInterval)getTimeCounted
{
    if(!self.timer.startCountDate) return 0;
    NSTimeInterval countedTime = [[NSDate date] timeIntervalSinceDate:self.timer.startCountDate];
    
    if(pausedTime != nil){
        NSTimeInterval pauseCountedTime = [[NSDate date] timeIntervalSinceDate:pausedTime];
        countedTime -= pauseCountedTime;
    }
    return countedTime;
}

- (NSTimeInterval)getTimeRemaining {
    
    if (self.timer.timerType == MZTimerLabelTypeTimer) {
        return self.timer.timeUserValue - [self getTimeCounted];
    }
    
    return 0;
}

- (NSTimeInterval)getCountDownTime {
    
    if (self.timer.timerType == MZTimerLabelTypeTimer) {
        return self.timer.timeUserValue;
    }
    
    return 0;
}

- (void)setShouldCountBeyondHHLimit:(BOOL)shouldCountBeyondHHLimit {
    _shouldCountBeyondHHLimit = shouldCountBeyondHHLimit;
    [self updateLabel];
}

-(void) updateLabel {

    NSTimeInterval timeDiff = [[NSDate date] timeIntervalSinceDate:self.timer.startCountDate];
    NSDate *timeToShow = [NSDate date];
    BOOL timerEnded = false;
    
    /***MZTimerLabelTypeStopWatch Logic***/
    
    if(self.timer.timerType == MZTimerLabelTypeStopWatch){
        
        if (self.timer.counting) {
            timeToShow = [date1970 dateByAddingTimeInterval:timeDiff];
        }else{
            timeToShow = [date1970 dateByAddingTimeInterval:(!self.timer.startCountDate)?0:timeDiff];
        }
        
        if([_delegate respondsToSelector:@selector(timerLabel:countingTo:timertype:)]){
            [_delegate timerLabel:self countingTo:timeDiff timertype:self.timer.timerType];
        }
    
    }else{
        
    /***MZTimerLabelTypeTimer Logic***/
        
        if (self.timer.counting) {
            
            if([_delegate respondsToSelector:@selector(timerLabel:countingTo:timertype:)]){
                NSTimeInterval timeLeft = self.timer.timeUserValue - timeDiff;
                [_delegate timerLabel:self countingTo:timeLeft timertype:self.timer.timerType];
            }
                        
            if(timeDiff >= self.timer.timeUserValue){
                
                timeToShow = [date1970 dateByAddingTimeInterval:0];
                self.timer.startCountDate = nil;
                timerEnded = true;
            }else{
                timeToShow = [self.timer.timeToCountOff dateByAddingTimeInterval:(timeDiff*-1)]; //added 0.999 to make it actually counting the whole first second
            }
            
        }else{
            timeToShow = self.timer.timeToCountOff;
        }
    }

    //setting text value
    if ([_delegate respondsToSelector:@selector(timerLabel:customTextToDisplayAtTime:)]) {
        NSTimeInterval atTime = (self.timer.timerType == MZTimerLabelTypeStopWatch) ? timeDiff : ((self.timer.timeUserValue - timeDiff) < 0 ? 0 : (self.timer.timeUserValue - timeDiff));
        NSString *customtext = [_delegate timerLabel:self customTextToDisplayAtTime:atTime];
        if ([customtext length]) {
            self.timeLabel.text = customtext;
        }else{
            self.timeLabel.text = [self.dateFormatter stringFromDate:timeToShow];
        }
    }else{
        
        if(_shouldCountBeyondHHLimit) {
            //0.4.7 added---start//
            NSString *originalTimeFormat = _timeFormat;
            NSString *beyondFormat = [_timeFormat stringByReplacingOccurrencesOfString:@"HH" withString:kHourFormatReplace];
            beyondFormat = [beyondFormat stringByReplacingOccurrencesOfString:@"H" withString:kHourFormatReplace];
            self.dateFormatter.dateFormat = beyondFormat;
            
            int hours = (self.timer.timerType == MZTimerLabelTypeStopWatch)? ([self getTimeCounted] / 3600) : ([self getTimeRemaining] / 3600);
            NSString *formmattedDate = [self.dateFormatter stringFromDate:timeToShow];
            NSString *beyondedDate = [formmattedDate stringByReplacingOccurrencesOfString:kHourFormatReplace withString:[NSString stringWithFormat:@"%02d",hours]];
            
            self.timeLabel.text = beyondedDate;
            self.dateFormatter.dateFormat = originalTimeFormat;
            //0.4.7 added---endb//
        }else{
            if(self.textRange.length > 0){
                if(self.attributedDictionaryForTextInRange){
                    
                    NSAttributedString *attrTextInRange = [[NSAttributedString alloc] initWithString:[self.dateFormatter stringFromDate:timeToShow] attributes:self.attributedDictionaryForTextInRange];
                    
                    NSMutableAttributedString *attributedString;
                    attributedString = [[NSMutableAttributedString alloc]initWithString:self.text];
                    [attributedString replaceCharactersInRange:self.textRange withAttributedString:attrTextInRange];
                    self.timeLabel.attributedText = attributedString;
        
                } else {
                    NSString *labelText = [self.text stringByReplacingCharactersInRange:self.textRange withString:[self.dateFormatter stringFromDate:timeToShow]];
                    self.timeLabel.text = labelText;
                }
            } else {
                self.timeLabel.text = [self.dateFormatter stringFromDate:timeToShow];
            }
        }
    }
    
    //0.5.1 moved below to the bottom
    if(timerEnded) {
        if([_delegate respondsToSelector:@selector(timerLabel:finshedCountDownTimerWithTime:)]){
            [_delegate timerLabel:self finshedCountDownTimerWithTime:self.timer.timeUserValue];
        }
        
#if NS_BLOCKS_AVAILABLE
        if(_endedBlock != nil){
            _endedBlock(self.timer.timeUserValue);
        }
#endif
        if(_resetTimerAfterFinish){
           
        }
        
    }
    
}

@end
