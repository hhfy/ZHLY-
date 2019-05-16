//
//  ItemCell.h
//  ZTXWYGL
//
//  Created by LTWL on 2017/6/19.
//  Copyright © 2017年 LTWL. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ItemCell;
@protocol ItemCellDelegate <NSObject>
@optional;
- (void)itemCell:(ItemCell *)itemCell closeBtnDidClick:(UIButton *)button;
@end

@interface ItemCell : UICollectionViewCell
@property (nonatomic, weak) id<ItemCellDelegate> delegate;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, weak) UIButton *closeBtn;
@end
