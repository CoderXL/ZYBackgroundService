//
//  MainViewController.h
//  ZYBackgroundService
//
//  Created by ZYVincent on 13-12-13.
//  Copyright (c) 2013年 ZYProSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface MainViewController : UIViewController<NSURLSessionDelegate,NSURLSessionTaskDelegate,NSURLSessionDownloadDelegate,UIDocumentInteractionControllerDelegate>
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@property (nonatomic)NSURLSession *session;
@property (nonatomic)NSURLSessionDownloadTask *downloadTask;
@property (strong,nonatomic)UIDocumentInteractionController *documentInteractionController;
@property (nonatomic,strong)AVPlayer *player;

- (IBAction)startDownload:(id)sender;
@end
