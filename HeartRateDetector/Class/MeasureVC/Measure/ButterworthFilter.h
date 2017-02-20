//
//  ButterworthFilter.h
//  HeartRateDetector
//
//  Created by Phạm Hùng on 1/2/17.
//  Copyright © 2017 Phạm Hùng. All rights reserved.
//
#define NZEROS 10
#define NPOLES 10

#import <Foundation/Foundation.h>

@interface ButterworthFilter : NSObject {
    float xv[NZEROS+1], yv[NPOLES+1];
}
-(float) processValue:(float) value;


@end
