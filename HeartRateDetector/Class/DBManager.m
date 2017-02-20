//
//  DBManager.m
//  HeartRateDetector
//
//  Created by Phạm Hùng on 1/4/17.
//  Copyright © 2017 Phạm Hùng. All rights reserved.
//

#import "DBManager.h"
#import "FMDB/FMDB.h"


@implementation DBManager

+(void)runQuery:(NSString *)query {
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];
    NSString *dbPath = [documentsDir   stringByAppendingPathComponent:@"dbheartrate.sqlite"];
    
    FMDatabase *database = [FMDatabase databaseWithPath:dbPath];
    [database open];
    [database executeUpdate:query, nil];
    [database close];
}

@end
