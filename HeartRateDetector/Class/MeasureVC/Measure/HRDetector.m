//
//  HRDetector.m
//  HeartRateDetector
//
//  Created by Phạm Hùng on 1/2/17.
//  Copyright © 2017 Phạm Hùng. All rights reserved.
//

#import "HRDetector.h"
#import <QuartzCore/QuartzCore.h>

#define MAX_PERIOD 1.5
#define MIN_PERIOD 0.1
#define INVALID_ENTRY -100

@interface HRDetector ()

@end

@implementation HRDetector

@synthesize periodStart;

- (id) init
{
    self = [super init];
    if (self != nil) {

        [self reset];
    }
    return self;
}

-(void) reset {
    for(int i=0; i<MAX_PERIODS_TO_STORE; i++) {
        periods[i]=INVALID_ENTRY;
    }
    for(int i=0; i<AVERAGE_SIZE; i++) {
        upVals[i]=INVALID_ENTRY;
        downVals[i]=INVALID_ENTRY;
    }
    freq=0.5;
    periodIndex=0;
    downValIndex=0;
    upValIndex=0;
}

-(float) addNewValue:(float) newVal atTime:(double) time {

    if(newVal>0) {
        upVals[upValIndex]=newVal;
        upValIndex++;
        if(upValIndex>=AVERAGE_SIZE) {
            upValIndex=0;
        }
    }
    if(newVal<0) {
        downVals[downValIndex]=-newVal;
        downValIndex++;
        if(downValIndex>=AVERAGE_SIZE) {
            downValIndex=0;
        }
    }

    float count=0;
    float total=0;
    for(int i=0; i<AVERAGE_SIZE; i++) {
        if(upVals[i]!=INVALID_ENTRY) {
            count++;
            total+=upVals[i];
        }
    }
    float averageUp=total/count;
    
    count=0;
    total=0;
    for(int i=0; i<AVERAGE_SIZE; i++) {
        if(downVals[i]!=INVALID_ENTRY) {
            count++;
            total+=downVals[i];
        }
    }
    float averageDown=total/count;
    
    if(newVal<-0.5*averageDown) {
        wasDown=true;
    }

    if(newVal>=0.5*averageUp && wasDown) {
        wasDown=false;
        
        if(time-periodStart<MAX_PERIOD && time-periodStart>MIN_PERIOD) {
            periods[periodIndex]=time-periodStart;
            periodTimes[periodIndex]=time;
            periodIndex++;
            if(periodIndex>=MAX_PERIODS_TO_STORE) {
                periodIndex=0;
            }
        }
        periodStart=time;
    }
    if(newVal<-0.5*averageDown) {
        return -1;
    } else if(newVal>0.5*averageUp) {
        return 1;
    }
    return 0;
}

-(float) getAverage {
    double time=CACurrentMediaTime();
    double total=0;
    double count=0;
    for(int i=0; i<MAX_PERIODS_TO_STORE; i++) {
        // only use upto 10 seconds worth of data
        if(periods[i]!=INVALID_ENTRY  && time-periodTimes[i]<10) {
            count++;
            total+=periods[i];
        }
    }
    // do we have enough values?
    if(count>2) {
        return total/count;
    }
    return INVALID_PULSE_PERIOD;
}

@end
