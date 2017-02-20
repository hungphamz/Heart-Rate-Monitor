//
//  HistoryVC.m
//  HeartRateDetector
//
//  Created by Phạm Hùng on 1/3/17.
//  Copyright © 2017 Phạm Hùng. All rights reserved.
//

#import "HistoryVC.h"
#import "HistoryCell.h"
#import "FMDB/FMDB.h"
//#import "FMDB/FMDatabase.h"
#import "DBManager.h"
#import "HistoryData.h"

@interface HistoryVC () <UITableViewDataSource, UITableViewDelegate>
{
    NSMutableArray *arrHisData;
}

@property (weak, nonatomic) IBOutlet UITableView *tbvHistory;


@property NSInteger numOfRows;

@end

@implementation HistoryVC

- (void)viewDidDisappear:(BOOL)animated {
    [arrHisData removeAllObjects];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    arrHisData = [[NSMutableArray alloc] init];
    
    NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [docPaths objectAtIndex:0];
    NSString *dbPath = [documentsDir stringByAppendingPathComponent:@"dbheartrate.sqlite"];
    
    FMDatabase *database = [FMDatabase databaseWithPath:dbPath];
    [database open];
    
    FMResultSet *results = [database executeQuery:@"SELECT * FROM dbheartrate"];
    
    while([results next]) {
        HistoryData *hData = [[HistoryData alloc] init];
        hData.hDate = [results stringForColumn:@"mdate"];
        hData.hBPM = [results intForColumn:@"mhr"];
        
        [arrHisData addObject:hData];
    }
    
    [database close];
    
    _numOfRows = [arrHisData count];
    
    [_tbvHistory reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Incomplete implementation, return the number of sections
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete implementation, return the number of rows
    return _numOfRows;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50.0f;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    HistoryCell *hCell = [tableView dequeueReusableCellWithIdentifier:@"HistoryCell" forIndexPath:indexPath];
    // Configure the cell...
    
    HistoryData *hData = [[HistoryData alloc] init];
    hData = [arrHisData objectAtIndex:indexPath.row];
    
    hCell.lblDate.text = hData.hDate;
    hCell.lblBPM.text = [NSString stringWithFormat:@"%d BPM", hData.hBPM];
    
    return hCell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete){
        
        HistoryData *hdata = [arrHisData objectAtIndex:indexPath.row];
        [arrHisData removeObjectAtIndex:indexPath.row];
        
        NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDir = [docPaths objectAtIndex:0];
        NSString *dbPath = [documentsDir stringByAppendingPathComponent:@"dbheartrate.sqlite"];
        
        FMDatabase *database = [FMDatabase databaseWithPath:dbPath];
        [database open];
        
//        [database beginTransaction];
        
        [database executeUpdate:@"DELETE FROM dbheartrate WHERE mdate = ?", [NSString stringWithFormat:@"%@", hdata.hDate]];
        
//        [database commit];
        
        [database close];
        
        _numOfRows = [arrHisData count];
        [tableView reloadData];
    }
}

@end
