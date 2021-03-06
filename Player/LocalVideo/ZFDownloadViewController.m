//
//  ZFDownloadViewController.m
//
// Copyright (c) 2016年 任子丰 ( http://github.com/renzifeng )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ZFDownloadViewController.h"
#import "MoviePlayerViewController.h"
#import "ZFPlayer.h"
#import "ZFDownloadingCell.h"
#import "ZFDownloadedCell.h"

@interface ZFDownloadViewController ()<UITableViewDataSource,UITableViewDelegate,ZFDownloadDelegate>

@property (weak, nonatomic  ) IBOutlet UITableView    *tableView;
@property (nonatomic, strong) NSMutableArray *downloadObjectArr;
@property (nonatomic, strong) FilesDownManage *downloadManage;

@end

@implementation ZFDownloadViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    // 更新数据源
    [self initData];
}

- (void)reloadTableView
{
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView = [UIView new];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, -49, 0);
    self.downloadManage.downloadDelegate = self;
    //NSLog(@"%@", NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES));
}

- (void)initData
{
    [self.downloadManage startLoad];
    [self.tableView reloadData];
}

- (NSMutableArray *)downloadObjectArr
{
    NSMutableArray *downladed = self.downloadManage.finishedlist;
    NSMutableArray *downloading = self.downloadManage.downinglist;

    _downloadObjectArr = @[].mutableCopy;
    [_downloadObjectArr addObject:downladed];
    [_downloadObjectArr addObject:downloading];
    return _downloadObjectArr;
}
- (FilesDownManage *)downloadManage
{
    if (!_downloadManage) {
        _downloadManage = [FilesDownManage sharedFilesDownManageWithBasepath:@"ZFDownLoad" TargetPathArr:[NSArray arrayWithObject:@"ZFDownLoad/CacheList"]];
    }
    return _downloadManage;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}
   
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionArray = self.downloadObjectArr[section];
    return sectionArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        ZFDownloadedCell *cell = [tableView dequeueReusableCellWithIdentifier:@"downloadedCell"];
        FileModel *fileInfo = self.downloadObjectArr[indexPath.section][indexPath.row];
        cell.fileInfo = fileInfo;
        return cell;
    } else if (indexPath.section == 1) {
        ZFDownloadingCell *cell = [tableView dequeueReusableCellWithIdentifier:@"downloadingCell"];
        ZFHttpRequest *request = self.downloadObjectArr[indexPath.section][indexPath.row];
        FileModel *fileInfo = [request.userInfo objectForKey:@"File"];
        if (request == nil) { return nil; }
        cell.controller = self;
        cell.fileInfo = fileInfo;
        cell.request = request;
        return cell;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath{
    return @"删除";
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        FileModel *fileInfo = self.downloadObjectArr[indexPath.section][indexPath.row];
        [self.downloadManage deleteFinishFile:fileInfo];
    }else if (indexPath.section == 1) {
        ZFHttpRequest *request = self.downloadObjectArr[indexPath.section][indexPath.row];
        [self.downloadManage deleteRequest:request];
    }
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @[@"下载完成",@"下载中"][section];
}

#pragma mark - ZFDownloadDelegate

// 开始下载
- (void)startDownload:(ZFHttpRequest *)request;
{
    NSLog(@"开始下载!");
}

// 下载中
- (void)updateCellProgress:(ZFHttpRequest *)request;
{
    FileModel *fileInfo = [request.userInfo objectForKey:@"File"];
    [self performSelectorOnMainThread:@selector(updateCellOnMainThread:) withObject:fileInfo waitUntilDone:YES];
}

// 下载完成
- (void)finishedDownload:(ZFHttpRequest *)request;
{
    [self.tableView reloadData];
}

// 更新下载进度
- (void)updateCellOnMainThread:(FileModel *)fileInfo
{
    NSArray *cellArr = [self.tableView visibleCells];
    for(id obj in cellArr)
    {
        if([obj isKindOfClass:[ZFDownloadingCell class]])
        {
            ZFDownloadingCell *cell = (ZFDownloadingCell *)obj;
            if([cell.fileInfo.fileURL isEqualToString:fileInfo.fileURL])
            {
                cell.fileInfo = fileInfo;
            }
        }
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    UITableViewCell *cell            = (UITableViewCell *)sender;
    NSIndexPath *indexPath           = [self.tableView indexPathForCell:cell];
    FileModel *model                 = self.downloadObjectArr[indexPath.section][indexPath.row];
    NSURL *videoURL                  = [NSURL fileURLWithPath:model.targetPath];

    MoviePlayerViewController *movie = (MoviePlayerViewController *)segue.destinationViewController;
    movie.videoURL                   = videoURL;
}


@end
