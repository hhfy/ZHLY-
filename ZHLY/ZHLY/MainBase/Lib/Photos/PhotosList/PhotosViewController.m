//
//  PhotosViewController.m
//  ImagePickerController
//
//  Created by LTWL on 2017/5/23.
//  Copyright © 2017年 LTWL. All rights reserved.
//

#import "PhotosViewController.h"
#import "PhotosTableViewCell.h"
#import "PhotoPickerController.h"
#import "PhotosDataHandle.h"

@interface PhotosViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *albumArray;

@end

@implementation PhotosViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"照片";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    [self configTableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_albumArray) {
        return;
    }
    [self configTableView];
}

- (void)configTableView {
    PhotosNavigationController *navigation = (PhotosNavigationController *)self.navigationController;
    [[PhotosDataHandle manager] getAllAlbums:navigation.allowPickingVideo completion:^(NSArray<PhotosDataModel *> *models) {
        _albumArray = [NSMutableArray arrayWithArray:models];
        
        CGFloat top = 44;
        if (iOS7Later) {
            top += (iPhoneX) ? 44 : 20;
        }
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, top, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - top) style:UITableViewStylePlain];
        _tableView.rowHeight = 70;
        _tableView.tableFooterView = [[UIView alloc] init];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        [_tableView registerClass:[PhotosTableViewCell class] forCellReuseIdentifier:@"ListCell"];
        [self.view addSubview:_tableView];
    }];
}

#pragma mark - Click Event
- (void)cancel {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    PhotosNavigationController *navigation = (PhotosNavigationController *)self.navigationController;
    if ([navigation.pickerDelegate respondsToSelector:@selector(PhotosNavigationControllerDidCancel:)]) {
        [navigation.pickerDelegate PhotosNavigationControllerDidCancel:navigation];
    }
    if (navigation.PhotosNavigationControllerDidCancelHandle) {
        navigation.PhotosNavigationControllerDidCancelHandle();
    }
}

#pragma mark - UITableView代理
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _albumArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return AlbumListCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PhotosTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ListCell"];
    cell.model = _albumArray[indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PhotoPickerController *photoPickerVc = [[PhotoPickerController alloc] init];
    photoPickerVc.model = _albumArray[indexPath.row];
    [self.navigationController pushViewController:photoPickerVc animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end