//
//  DBManager.h
//  HeartRateDetector
//
//  Created by Phạm Hùng on 1/4/17.
//  Copyright © 2017 Phạm Hùng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DBManager : NSObject

+(void)runQuery:(NSString *)query;

@end
