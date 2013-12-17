//
//  MainViewController.m
//  ZYBackgroundService
//
//  Created by ZYVincent on 13-12-13.
//  Copyright (c) 2013年 ZYProSoft. All rights reserved.
//

#import "MainViewController.h"
#import "ZYBackgroundServiceAppDelegate.h"

static NSString *DownloadURLString = @"http://www.zyprosoft.com/samplesource/love.mp3";

@interface MainViewController ()

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.session = [self backgroundSession];
    self.progressView.progress = 0;
    self.progressView.hidden = YES;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startDownload:(id)sender {
    
    if (self.downloadTask) {
        return;
    }
    NSURL *downloadURL = [NSURL URLWithString:DownloadURLString];
    NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
    self.downloadTask = [self.session downloadTaskWithRequest:request];
    [self.downloadTask resume];
    self.progressView.hidden = NO;
    
}

- (NSURLSession *)backgroundSession {
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        //这个sessionConfiguration 很重要， com.zyprosoft.xxx  这里，这个com.company.这个一定要和 bundle identifier 里面的一致，否则ApplicationDelegate 不会调用handleEventsForBackgroundURLSession代理方法
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:@"com.zyprosoft.backgroundsession"];
        session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    });
    return session;
}

#pragma mark - NSURLSessionDownloadDelegate

//这个方法用来跟踪下载数据并且根据进度刷新ProgressView
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    if (downloadTask == self.downloadTask) {
        double progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
        NSLog(@"下载任务: %@ 进度: %lf", downloadTask, progress);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progress = progress;
        });
    }
}

//下载任务完成,这个方法在下载完成时触发，它包含了已经完成下载任务得 Session Task,Download Task和一个指向临时下载文件得文件路径
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *URLs = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsDirectory = [URLs objectAtIndex:0];
    NSURL *originalURL = [[downloadTask originalRequest] URL];
    NSURL *destinationURL = [documentsDirectory URLByAppendingPathComponent:[originalURL lastPathComponent]];
    NSError *errorCopy;
    // For the purposes of testing, remove any esisting file at the destination.
    [fileManager removeItemAtURL:destinationURL error:NULL];
    BOOL success = [fileManager copyItemAtURL:location toURL:destinationURL error:&errorCopy];
    if (success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //download finished - open the pdf
            
            //原文下载的苹果的pdf，感觉有点慢，自己又没找到比较大一点的pdf，干脆就放了个mp3歌曲在自己服务器上，所以下载完就播放mp3吧
//            self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:destinationURL];
//            // Configure Document Interaction Controller
//            [self.documentInteractionController setDelegate:self];
//            // Preview PDF
//            [self.documentInteractionController presentPreviewAnimated:YES];
//            self.progressView.hidden = YES;
            
            //播放音乐
            self.player = [AVPlayer playerWithURL:destinationURL];
            [self.player play];

            
        });
    } else {
        NSLog(@"复制文件发生错误: %@", [errorCopy localizedDescription]);
    }
}

//这个方法我们暂时用不上
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    
}

#pragma mark - NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error == nil) {
        NSLog(@"任务: %@ 成功完成", task);
    } else {
        NSLog(@"任务: %@ 发生错误: %@", task, [error localizedDescription]);
    }
    double progress = (double)task.countOfBytesReceived / (double)task.countOfBytesExpectedToReceive;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressView.progress = progress;
    });
    self.downloadTask = nil;
}

#pragma mark - NSURLSessionDelegate
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    ZYBackgroundServiceAppDelegate *appDelegate = (ZYBackgroundServiceAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.backgroundSessionCompletionHandler) {
        void (^completionHandler)() = appDelegate.backgroundSessionCompletionHandler;
        appDelegate.backgroundSessionCompletionHandler = nil;
        completionHandler();
    }
    NSLog(@"所有任务已完成!");
}


@end
