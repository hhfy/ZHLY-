
//
//  ServiceMyMsgVC.m
//  ZHLY
//
//  Created by LTWL on 2017/11/29.
//  Copyright © 2017年 LTWL. All rights reserved.
//

#import "ServiceMyMsgVC.h"
#import "ServiceMyMsgHeaderView.h"
#import "ServiceMyMsgFooterView.h"
#import "ServiceMyMsgCell.h"
#import "Service.h"

@interface ServiceMyMsgVC () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, strong) NSMutableArray *myLeaveMsgs;
@end

@implementation ServiceMyMsgVC

- (NSMutableArray *)myLeaveMsgs
{
    if (_myLeaveMsgs == nil)
    {
        _myLeaveMsgs = [NSMutableArray array];
    }
    return _myLeaveMsgs;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupValue];
    [self setupTableView];
    [self getNewMyLeaveMsgData];
    [LaiMethod setupDownRefreshWithTableView:self.tableView target:self action:@selector(getNewMyLeaveMsgData)];
    [LaiMethod setupUpRefreshWithTableView:self.tableView target:self action:@selector(getMoreMyLeaveMsgData)];
}

- (void)setupValue {
    self.title = @"我的留言";
}

- (void)setupTableView {
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    tableView.backgroundColor = [UIColor clearColor];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.estimatedRowHeight = 45.0f;
    tableView.estimatedSectionHeaderHeight = 20;
    tableView.estimatedSectionFooterHeight = 20;
    tableView.rowHeight = UITableViewAutomaticDimension;
    tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.contentInset = UIEdgeInsetsMake(0, 0, NavHeight + Height44 + SpaceHeight * 2, 0);
    tableView.placeholderText = @"暂无留言";
    [self.view addSubview:tableView];
    _tableView = tableView;
}

#pragma mark - 接口
// 获取我的留言数据
- (void)getNewMyLeaveMsgData {
    self.currentPage = 1;
    WeakSelf(weakSelf)
    [self getMyLeaveMsgDataWithSuccessHandle:^{
        [UITableViewAnmtionTool alphaAnimationWithTableView:weakSelf.tableView];
    }];
}

- (void)getMoreMyLeaveMsgData {
    self.currentPage++;
    [self getMyLeaveMsgDataWithSuccessHandle:nil];
}

- (void)getMyLeaveMsgDataWithSuccessHandle:(void (^)(void))successHandle {
    NSString *url = [MainURL stringByAppendingPathComponent:@"customer/mine"];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[Token] = self.token;
    params[Page] = @(self.currentPage);
    
    WeakSelf(weakSelf)
    [HttpTool getWithURL:url params:params isHiddeHUD:YES progress:nil success:^(id json) {
        if (weakSelf.currentPage == 1) [weakSelf.myLeaveMsgs removeAllObjects];
        NSInteger oldCount = weakSelf.myLeaveMsgs.count;
        NSArray *myLeaveMsgArr = [ServiceMyLeaveMsg mj_objectArrayWithKeyValuesArray:json[Data][List]];
        [weakSelf.myLeaveMsgs addObjectsFromArray:myLeaveMsgArr];
        if (weakSelf.myLeaveMsgs.count == [json[Data][Total] integerValue]) {
            [weakSelf.tableView.mj_footer endRefreshingWithNoMoreData];
        } else {
            [weakSelf.tableView.mj_footer endRefreshing];
        }
        [weakSelf.tableView.mj_header endRefreshing];
        [weakSelf.tableView reloadData];
        if (oldCount > 0 && weakSelf.currentPage > 1) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(oldCount - 1) inSection:0];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        }
        if (successHandle) successHandle();
    } otherCase:^(NSInteger code) {
        [weakSelf.tableView.mj_header endRefreshing];
        [weakSelf.tableView reloadData];
    } failure:^(NSError *error) {
        if (weakSelf.currentPage > 1) weakSelf.currentPage--;
        [weakSelf.myLeaveMsgs removeAllObjects];
        [weakSelf.tableView.mj_header endRefreshing];
        [weakSelf.tableView reloadData];
    }];
}

#pragma mark - tableView数据源和代理
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.myLeaveMsgs.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ServiceMyMsgCell *cell = [ServiceMyMsgCell cellFromXibWithTableView:tableView];
    ServiceMyLeaveMsg *myLeaveMsg = self.myLeaveMsgs[indexPath.section];
    cell.myLeaveMsg = myLeaveMsg;
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    ServiceMyMsgHeaderView *headerView = [ServiceMyMsgHeaderView headerFooterViewFromXibWithTableView:tableView];
    ServiceMyLeaveMsg *myLeaveMsg = self.myLeaveMsgs[section];
    headerView.text = myLeaveMsg.content;
    return headerView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    ServiceMyMsgFooterView *footerView = [ServiceMyMsgFooterView headerFooterViewFromXibWithTableView:tableView];
    ServiceMyLeaveMsg *myLeaveMsg = self.myLeaveMsgs[section];
    footerView.myLeaveMsg = myLeaveMsg;
    return footerView;
}

@end
