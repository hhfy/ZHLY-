//
//  HZPhotoBrowser.m
//  photoBrowser
//
//  Created by huangzhenyu on 15/6/23.
//  Copyright (c) 2015年 eamon. All rights reserved.
//

#import "HZPhotoBrowser.h"
#import "HZPhotoBrowserConfig.h"

@interface HZPhotoBrowser() <UIScrollViewDelegate>
@property (nonatomic,strong) UIScrollView *scrollView;
@property (nonatomic,assign) BOOL hasShowedPhotoBrowser;
@property (nonatomic,strong) UILabel *indexLabel;
@property (nonatomic,strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic,strong) UIButton *saveButton;
@property (nonatomic, weak) UIPageControl *pageControl;
@property (nonatomic, assign) BOOL isHiddenStatusBar;
@end

@implementation HZPhotoBrowser

- (void)viewDidLoad
{
    [super viewDidLoad];
    _hasShowedPhotoBrowser = NO;
    self.isHiddenStatusBar = NO;
    self.view.backgroundColor = [UIColor clearColor];
    [self addScrollView];
    [self addToolbars];
    [self setUpFrames];
    [self.view addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesture:)]];
}

- (void)longPressGesture:(UILongPressGestureRecognizer *)longPress
{
    if (longPress.state == UIGestureRecognizerStateBegan) {
        [LaiMethod alertSPAlerSheetControllerWithTitle:nil message:nil defaultActionTitles:@[@"保存图片"] destructiveTitle:nil cancelTitle:@"取消" handler:^(NSInteger actionIndex) {
            if (actionIndex == 0) [self saveImage];
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!_hasShowedPhotoBrowser) {
        [self showPhotoBrowser];
    }
}

#pragma mark 重置各控件frame（处理屏幕旋转）
- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self setUpFrames];
}

#pragma mark 设置各控件frame
- (void)setUpFrames
{
    CGRect rect = self.view.bounds;
    rect.size.width += kPhotoBrowserImageViewMargin * 2;
    _scrollView.bounds = rect;
    _scrollView.center = CGPointMake(kAPPWidth *0.5, kAppHeight *0.5);
    
    CGFloat y = 0;
    __block CGFloat w = kAPPWidth;
    CGFloat h = kAppHeight;
    
    //设置所有HZPhotoBrowserView的frame
    [_scrollView.subviews enumerateObjectsUsingBlock:^(HZPhotoBrowserView *obj, NSUInteger idx, BOOL *stop) {
        CGFloat x = kPhotoBrowserImageViewMargin + idx * (kPhotoBrowserImageViewMargin * 2 + w);
        obj.frame = CGRectMake(x, y, w, h);
    }];
    
    _scrollView.contentSize = CGSizeMake(_scrollView.subviews.count * _scrollView.frame.size.width, kAppHeight);
    _scrollView.contentOffset = CGPointMake(self.currentImageIndex * _scrollView.frame.size.width, 0);
}

#pragma mark 显示图片浏览器
- (void)showPhotoBrowser
{
    UIView *sourceView = self.sourceImagesContainerView.subviews[self.currentImageIndex];
    UIView *parentView = [self getParsentView:sourceView];
    CGRect rect = [sourceView.superview convertRect:sourceView.frame toView:parentView];
    
    //如果是tableview，要减去偏移量
    if ([parentView isKindOfClass:[UITableView class]]) {
        UITableView *tableview = (UITableView *)parentView;
        rect.origin.y =  rect.origin.y - tableview.contentOffset.y;
    }
    
    UIImageView *tempImageView = [[UIImageView alloc] init];
    tempImageView.frame = rect;
    tempImageView.image = [self placeholderImageForIndex:self.currentImageIndex];
    [self.view addSubview:tempImageView];
    tempImageView.contentMode = UIViewContentModeScaleAspectFit;
    CGFloat placeImageSizeW = tempImageView.image.size.width;;
    CGFloat placeImageSizeH;
    if(tempImageView.image){ //解决报错：CALayerInvalidGeometry CALayer position contains NaN:
        placeImageSizeH = tempImageView.image.size.height;
    }
    else {
        placeImageSizeH = MainScreenSize.height;
    }
    CGRect targetTemp;
    
    if (!kIsFullWidthForLandScape) {
        if (kAPPWidth < kAppHeight) {
            CGFloat placeHolderH = (placeImageSizeH * kAPPWidth)/placeImageSizeW;
            if (placeHolderH <= kAppHeight) {
                targetTemp = CGRectMake(0, (kAppHeight - placeHolderH) * 0.5 , kAPPWidth, placeHolderH);
            } else {
                targetTemp = CGRectMake(0, 0, kAPPWidth, placeHolderH);
            }
        } else {
            CGFloat placeHolderW = (placeImageSizeW * kAppHeight)/placeImageSizeH;
            if (placeHolderW < kAPPWidth) {
                targetTemp = CGRectMake((kAPPWidth - placeHolderW)*0.5, 0, placeHolderW, kAppHeight);
            } else {
                targetTemp = CGRectMake(0, 0, placeHolderW, kAppHeight);
            }
        }

    } else {
        CGFloat placeHolderH = (placeImageSizeH * kAPPWidth)/placeImageSizeW;
        if (placeHolderH <= kAppHeight) {
            targetTemp = CGRectMake(0, (kAppHeight - placeHolderH) * 0.5 , kAPPWidth, placeHolderH);
        } else {
            targetTemp = CGRectMake(0, 0, kAPPWidth, placeHolderH);
        }
    }
    
    _scrollView.hidden = YES;
    _indexLabel.hidden = YES;
    _saveButton.hidden = YES;
    sourceView.hidden = YES;

    [UIView animateWithDuration:kPhotoBrowserShowDuration animations:^{
        tempImageView.frame = targetTemp;
        self.view.backgroundColor = [UIColor blackColor];
    } completion:^(BOOL finished) {
        _hasShowedPhotoBrowser = YES;
        [tempImageView removeFromSuperview];
        _scrollView.hidden = NO;
        _indexLabel.hidden = NO;
        _saveButton.hidden = NO;
        _isHiddenStatusBar = YES;
        [self setNeedsStatusBarAppearanceUpdate];
    }];
}

#pragma mark 添加scrollview
- (void)addScrollView
{
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.frame = self.view.bounds;
    _scrollView.delegate = self;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.pagingEnabled = YES;
    _scrollView.hidden = YES;
    [self.view addSubview:_scrollView];
    
    for (int i = 0; i < self.imageCount; i++) {
        HZPhotoBrowserView *view = [[HZPhotoBrowserView alloc] init];
        view.imageview.tag = i;
        
        //处理单击
        __weak __typeof(self)weakSelf = self;
        view.singleTapBlock = ^(UITapGestureRecognizer *recognizer){
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf hidePhotoBrowser:recognizer];
        };
        
        [_scrollView addSubview:view];
    }
    [self setupImageOfImageViewForIndex:self.currentImageIndex];
}

#pragma mark 添加操作按钮
- (void)addToolbars
{
    // 保存按钮
    UIButton *saveButton = [[UIButton alloc] init];
    [saveButton setImage:SetImage(@"photoBroser.bundle/download") forState:UIControlStateNormal];
    [saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    saveButton.size = CGSizeMake(30, 30);
    saveButton.y = MainScreenSize.height - saveButton.height * 2;
    saveButton.x = MainScreenSize.width - saveButton.width * 2;
    saveButton.layer.borderWidth = 0.1;
    saveButton.layer.borderColor = [UIColor whiteColor].CGColor;
    saveButton.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.3f];
    saveButton.layer.cornerRadius = 2;
    saveButton.clipsToBounds = YES;
    [saveButton addTarget:self action:@selector(saveImage) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:saveButton];
    _saveButton = saveButton;
    
    //序标
    UILabel *indexLabel = [[UILabel alloc] init];
    indexLabel.textAlignment = NSTextAlignmentCenter;
    indexLabel.textColor = [UIColor whiteColor];
    indexLabel.font = [UIFont boldSystemFontOfSize:17];
    indexLabel.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.3f];
    indexLabel.bounds = CGRectMake(0, 0, 80, 30);
    indexLabel.center = CGPointMake(kAPPWidth * 0.5, 30);
    indexLabel.layer.cornerRadius = 15;
    indexLabel.clipsToBounds = YES;
    if (self.imageCount > 1) {
        indexLabel.text = [NSString stringWithFormat:@"1/%ld", (long)self.imageCount];
        _indexLabel = indexLabel;
        [self.view addSubview:indexLabel];
    }
    
    // pageControl
    UIPageControl *pageControl = [[UIPageControl alloc] init];
    pageControl.width = 100;
    pageControl.height = 35;
    pageControl.centerX = self.view.width * 0.5;
    pageControl.y = kAppHeight - 70;
    pageControl.pageIndicatorTintColor = [UIColor grayColor];
    pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
    pageControl.numberOfPages = self.imageCount;
    pageControl.hidden = (self.imageCount == 1);
    if (self.imageCount > 1) [self.view addSubview:pageControl];
    _pageControl = pageControl;
    
    switch (self.indexType) {
        case PhotoIndexTypeIndexLabel:
        {
            indexLabel.hidden = NO;
            [pageControl removeFromSuperview];
        }
            break;
        case PhotoIndexTypePageControl:
        {
            [indexLabel removeFromSuperview];
            pageControl.hidden = NO;
        }
            break;
        case PhotoIndexTypePageCustom:
        {
            pageControl.hidden = YES;
            indexLabel.y = MainScreenSize.height - 50 - indexLabel.height;
            indexLabel.x = MainScreenSize.width - indexLabel.width - 15;
            saveButton.y = Height44 - 10;
            saveButton.x = MainScreenSize.width - saveButton.width - 15;
        }
            break;
        default:
            break;
    }
}

#pragma mark 保存图像
- (void)saveImage
{
    int index = _scrollView.contentOffset.x / _scrollView.bounds.size.width;
    
    HZPhotoBrowserView *currentView = _scrollView.subviews[index];
    
    UIImageWriteToSavedPhotosAlbum(currentView.imageview.image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] init];
    indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    indicator.center = self.view.center;
    _indicatorView = indicator;
    [[UIApplication sharedApplication].keyWindow addSubview:indicator];
    [indicator startAnimating];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;
{
    [_indicatorView removeFromSuperview];
//    UILabel *label = [[UILabel alloc] init];
//    label.textColor = [UIColor whiteColor];
//    label.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.50f];
//    label.layer.cornerRadius = 5;
//    label.clipsToBounds = YES;
//    label.bounds = CGRectMake(0, 0, 150, 60);
//    label.center = self.view.center;
//    label.textAlignment = NSTextAlignmentCenter;
//    label.font = [UIFont boldSystemFontOfSize:21];
//    [[UIApplication sharedApplication].keyWindow addSubview:label];
//    [[UIApplication sharedApplication].keyWindow bringSubviewToFront:label];
//    [label performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1.0];
    if (error) {
        // label.text = @"保存失败";
        [SVProgressHUD showError:@"保存失败"];
    }   else {
        // label.text = @"保存成功";
        [SVProgressHUD showSuccess:@"保存成功"];
    }
}

- (void)show
{
    self.isHiddenStatusBar = YES;
    self.modalPresentationCapturesStatusBarAppearance = YES;
    self.modalPresentationStyle = UIModalPresentationCustom;
    [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:self animated:NO completion:nil];
}

#pragma mark 单击隐藏图片浏览器
- (void)hidePhotoBrowser:(UITapGestureRecognizer *)recognizer
{
    HZPhotoBrowserView *view = (HZPhotoBrowserView *)recognizer.view;
    UIImageView *currentImageView = view.imageview;
    UIView *sourceView = self.sourceImagesContainerView.subviews[self.currentImageIndex];
    UIView *parentView = [self getParsentView:sourceView];
    CGRect targetTemp = [sourceView.superview convertRect:sourceView.frame toView:parentView];
    
    
    // 减去偏移量
    if ([parentView isKindOfClass:[UITableView class]]) {
        UITableView *tableview = (UITableView *)parentView;
        targetTemp.origin.y -= tableview.contentOffset.y;
    }
    
    // tableview初始设置有20个电池状态栏
    targetTemp.origin.y += self.offsetY;
    
    CGFloat appWidth;
    CGFloat appHeight;
    if (kAPPWidth < kAppHeight) {
        appWidth = kAPPWidth;
        appHeight = kAppHeight;
    } else {
        appWidth = kAppHeight;
        appHeight = kAPPWidth;
    }
    
    UIImageView *tempImageView = [[UIImageView alloc] init];
    tempImageView.image = currentImageView.image;
    if (tempImageView.image) {
        CGFloat tempImageSizeH = tempImageView.image.size.height;
        CGFloat tempImageSizeW = tempImageView.image.size.width;
        CGFloat tempImageViewH = (tempImageSizeH * appWidth)/tempImageSizeW;
        if (tempImageViewH < appHeight) {
            tempImageView.frame = CGRectMake(0, (appHeight - tempImageViewH)*0.5, appWidth, tempImageViewH);
        } else {
            tempImageView.frame = CGRectMake(0, 0, appWidth, tempImageViewH);
        }
    } else {
        tempImageView.backgroundColor = [UIColor whiteColor];
        tempImageView.frame = CGRectMake(0, (appHeight - appWidth)*0.5, appWidth, appWidth);
    }
    
    [self.view.window addSubview:tempImageView];
    self.isHiddenStatusBar = NO;
    [self setNeedsStatusBarAppearanceUpdate];
    
    WeakSelf(weakSelf)
    [UIView animateWithDuration:kPhotoBrowserHideDuration animations:^{
        tempImageView.frame = targetTemp;
        tempImageView.contentMode = UIViewContentModeScaleAspectFill;
        tempImageView.clipsToBounds = YES;
        weakSelf.view.alpha = 0;
    } completion:^(BOOL finished) {
        [weakSelf dismissViewControllerAnimated:NO completion:^{
            [tempImageView removeFromSuperview];
            sourceView.hidden = NO;
        }];
    }];
}

#pragma mark 网络加载图片
- (void)setupImageOfImageViewForIndex:(NSInteger)index
{
    HZPhotoBrowserView *view = _scrollView.subviews[index];
    if (view.beginLoadingImage) return;
    if ([self highQualityImageURLForIndex:index]) {
        [view setImageWithURL:[self highQualityImageURLForIndex:index] placeholderImage:[self placeholderImageForIndex:index]];
    } else {
        view.imageview.image = [self placeholderImageForIndex:index];
    }
    view.beginLoadingImage = YES;
}

#pragma mark 获取控制器的view
- (UIView *)getParsentView:(UIView *)view{
    if ([[view nextResponder] isKindOfClass:[UIViewController class]] || view == nil) {
        return view;
    }
    return [self getParsentView:view.superview];
}

#pragma mark 获取低分辨率（占位）图片
- (UIImage *)placeholderImageForIndex:(NSInteger)index
{
    if ([self.delegate respondsToSelector:@selector(photoBrowser:placeholderImageForIndex:)]) {
        return [self.delegate photoBrowser:self placeholderImageForIndex:index];
    } else {
        return (self.smallImage) ? self.smallImage : nil;
    }
}

#pragma mark 获取高分辨率图片url
- (NSURL *)highQualityImageURLForIndex:(NSInteger)index
{
    if ([self.delegate respondsToSelector:@selector(photoBrowser:highQualityImageURLForIndex:)]) {
        return [self.delegate photoBrowser:self highQualityImageURLForIndex:index];
    }
    return nil;
}


#pragma mark - scrollview代理方法
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger page = scrollView.contentOffset.x / self.view.width;
    _pageControl.currentPage = page;
    if (self.currentImageIndex != page) {//解决数组越界bug
//        if(self.sourceImagesContainerView.subviews.count < self.currentImageIndex){
            UIView *sourceView = self.sourceImagesContainerView.subviews[self.currentImageIndex];
            sourceView.hidden = NO;
//        }
    }
    
    int index = (scrollView.contentOffset.x + _scrollView.bounds.size.width * 0.5) / _scrollView.bounds.size.width;
    
    _indexLabel.text = [NSString stringWithFormat:@"%d/%ld", index + 1, (long)self.imageCount];
    long left = index - 2;
    long right = index + 2;
    left = left>0?left : 0;
    right = right>self.imageCount?self.imageCount:right;
    
    //预加载三张图片
    for (long i = left; i < right; i++) {
        [self setupImageOfImageViewForIndex:i];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    int autualIndex = scrollView.contentOffset.x  / _scrollView.bounds.size.width;
    //设置当前下标
    self.currentImageIndex = autualIndex;
    
    //将不是当前imageview的缩放全部还原 (这个方法有些冗余，后期可以改进)
    for (HZPhotoBrowserView *view in _scrollView.subviews) {
        if (view.imageview.tag != autualIndex) {
            view.scrollview.zoomScale = 1.0;
        }
    }
}

#pragma mark 横竖屏设置
- (BOOL)shouldAutorotate
{
    return shouldSupportLandscape;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if (shouldSupportLandscape) {
        return UIInterfaceOrientationMaskAll;
    } else{
        return UIInterfaceOrientationMaskPortrait;
    }
    
}

- (BOOL)prefersStatusBarHidden {
    return self.isHiddenStatusBar;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.presentingViewController.preferredStatusBarStyle;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}
@end
