//
//  HistoryCell.h
//  HeartRateDetector
//
//  Created by Phạm Hùng on 1/3/17.
//  Copyright © 2017 Phạm Hùng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HistoryCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *lblBPM;
@property (weak, nonatomic) IBOutlet UILabel *lblDate;

@end
