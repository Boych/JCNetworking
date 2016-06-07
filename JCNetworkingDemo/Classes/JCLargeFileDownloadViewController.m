//
//  JCLargeFileDownloadViewController.m
//  JCNetworking
//
//  Created by ChenJianjun on 16/6/4.
//  Copyright © 2016年 JC. All rights reserved.
//

#import "JCLargeFileDownloadViewController.h"
#import "JCDownloadOperation.h"
#import "JCDownloadQueue.h"
#import "JCDownloadUtilities.h"

@interface JCLargeFileDownloadViewController ()

@property (nonatomic, strong) JCDownloadOperation *downloadOperation;
@property (nonatomic, strong) UIButton *downloadButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UILabel *progressLabel;

@end

@implementation JCLargeFileDownloadViewController

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"downloadOperation.item.status"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *downloadButton = [[UIButton alloc] init];
    downloadButton.clipsToBounds = YES;
    downloadButton.layer.cornerRadius = 2.f;
    downloadButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    downloadButton.layer.borderWidth = 1.f;
    [downloadButton setTitle:@"开始下载" forState:UIControlStateNormal];
    [downloadButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [downloadButton setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    [downloadButton addTarget:self action:@selector(downloadAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:downloadButton];
    _downloadButton = downloadButton;
    
    UIButton *deleteButton = [[UIButton alloc] init];
    deleteButton.clipsToBounds = YES;
    deleteButton.layer.cornerRadius = 2.f;
    deleteButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    deleteButton.layer.borderWidth = 1.f;
    [deleteButton setTitle:@"删除下载" forState:UIControlStateNormal];
    [deleteButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [deleteButton setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    [deleteButton addTarget:self action:@selector(deleteAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:deleteButton];
    _deleteButton = deleteButton;
    
    _progressView = [[UIProgressView alloc] init];
    _progressView.layer.cornerRadius = 2.f;
    _progressView.clipsToBounds = YES;
    [self.view addSubview:_progressView];
    
    _progressLabel = [[UILabel alloc] init];
    _progressLabel.textAlignment = NSTextAlignmentRight;
    _progressLabel.textColor = [UIColor blackColor];
    _progressLabel.font = [UIFont systemFontOfSize:14.f];
    [self.view addSubview:_progressLabel];
    
    [_downloadButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(60);
        make.center.mas_equalTo(0);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
    }];
    [_deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(_downloadButton.mas_height);
        make.top.mas_equalTo(_downloadButton.mas_bottom).mas_offset(10);
        make.left.mas_equalTo(_downloadButton.mas_left);
        make.right.mas_equalTo(_downloadButton.mas_right);
    }];
    [_progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(_downloadButton.mas_top).mas_offset(-10);
        make.height.mas_equalTo(4);
        make.left.mas_equalTo(_downloadButton.mas_left);
        make.right.mas_equalTo(_downloadButton.mas_right);
    }];
    [_progressLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(_progressView.mas_top);
        make.height.mas_equalTo(20);
        make.left.mas_equalTo(_progressView.mas_left);
        make.right.mas_equalTo(_progressView.mas_right).mas_offset(-2);
    }];
    
    [self initDownloadData];
    [self addObserver:self forKeyPath:@"downloadOperation.item.status" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initDownloadData
{
    JCDownloadItem *downloadItem = [[JCDownloadItem alloc] init];
    downloadItem.groupId = @"largeFileDownloadGroupId";
    downloadItem.downloadUrl = @"http://dldir1.qq.com/qqfile/QQforMac/QQ_V4.0.6.dmg";
    downloadItem.downloadFilePath = [JCDownloadUtilities filePathWithFileName:[downloadItem.downloadUrl lastPathComponent] folderName:@"downloadFiles"];
    JCDownloadOperation *operation = [[JCDownloadQueue sharedQueue] downloadOperation:downloadItem.downloadId groupId:downloadItem.groupId];
    if (operation) {
        self.downloadOperation = operation;
        @weakify(self);
        [self.downloadOperation resetProgressBlock:^(NSProgress *progress) {
            @strongify(self);
            [self resetProgressWithCompletedUnitCount:progress.completedUnitCount
                                       totalUnitCount:progress.totalUnitCount];
        } completionBlock:^(NSURL *filePath, NSError *error) {
            @strongify(self);
            [self resetProgressWithCompletedUnitCount:self.downloadOperation.item.completedUnitCount
                                       totalUnitCount:self.downloadOperation.item.totalUnitCount];
        }];
    } else {
        self.downloadOperation = [[JCDownloadOperation alloc] init];
        self.downloadOperation.item = downloadItem;
    }
    [self downloadStatusChanged:self.downloadOperation.item.status];
    [self resetProgressWithCompletedUnitCount:self.downloadOperation.item.completedUnitCount
                               totalUnitCount:self.downloadOperation.item.totalUnitCount];
}

- (void)downloadAction:(id)sender
{
    switch (self.downloadOperation.item.status) {
        case JCDownloadStatusWait:
        case JCDownloadStatusPause:
        case JCDownloadStatusUnknownError: {
            @weakify(self);
            [self.downloadOperation startWithProgressBlock:^(NSProgress *progress) {
                @strongify(self);
                [self resetProgressWithCompletedUnitCount:progress.completedUnitCount
                                           totalUnitCount:progress.totalUnitCount];
            } completionBlock:^(NSURL *filePath, NSError *error) {
                @strongify(self);
                [self resetProgressWithCompletedUnitCount:self.downloadOperation.item.completedUnitCount
                                           totalUnitCount:self.downloadOperation.item.totalUnitCount];
            }];
        }
            break;
        case JCDownloadStatusDownloading:
            [self.downloadOperation pauseDownload];
            break;
        case JCDownloadStatusFinished:
            break;
    }
}

- (void)deleteAction:(id)sender
{
    [self.downloadOperation removeDownload];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)resetProgressWithCompletedUnitCount:(int64_t)completedUnitCount
                             totalUnitCount:(int64_t)totalUnitCount
{
    if (totalUnitCount > 0) {
        [self resetProgress:(CGFloat)completedUnitCount/totalUnitCount];
    } else {
        [self resetProgress:0];
    }
    self.progressLabel.text = [NSString stringWithFormat:@"%@ / %@", [JCDownloadUtilities sizeStringWithFileSize:completedUnitCount], [JCDownloadUtilities sizeStringWithFileSize:totalUnitCount]];
}

- (void)resetProgress:(CGFloat)progress
{
    [self.progressView setProgress:progress];
}

- (void)downloadStatusChanged:(JCDownloadStatus)status
{
    switch (status) {
        case JCDownloadStatusWait:
        case JCDownloadStatusPause:
        case JCDownloadStatusUnknownError:
            [self.downloadButton setTitle:@"开始下载" forState:UIControlStateNormal];
            self.downloadButton.enabled = YES;
            break;
        case JCDownloadStatusDownloading:
            [self.downloadButton setTitle:@"暂停下载" forState:UIControlStateNormal];
            self.downloadButton.enabled = YES;
            break;
        case JCDownloadStatusFinished:
            [self.downloadButton setTitle:@"已下载" forState:UIControlStateNormal];
            self.downloadButton.enabled = NO;
            break;
    }
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"downloadOperation.item.status"]) {
        JCDownloadStatus status = [change[@"new"] integerValue];
        [self downloadStatusChanged:status];
    }
}


@end
