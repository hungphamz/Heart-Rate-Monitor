//
//  MainVC.m
//  HeartRateDetector
//
//  Created by Phạm Hùng on 12/31/16.
//  Copyright © 2016 Phạm Hùng. All rights reserved.
//


#import "MainVC.h"
#import "DBManager.h"
#import "FMDB/FMDB.h"

@interface MainVC ()

@end

@implementation MainVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [DBManager runQuery:@"CREATE TABLE dbheartrate (mdate text primary key default null, mhr int default null)"];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
