//
//  ViewController.m
//  CXKDownLoader
//
//  Created by admin on 15/12/2.
//  Copyright © 2015年 CXK. All rights reserved.
//

#import "ViewController.h"
#import "CXKHTTPDownloader.h"

NSString * const URL_STR = @"https://github.com/nsdictionary/CoreLock";

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;

@property (nonatomic,strong)CXKHTTPDownloader * downloader;
@property (nonatomic,strong)NSOperationQueue * operationQueue;


- (IBAction)buttonAction:(UIButton *)sender;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor orangeColor];
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = 1;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonAction:(UIButton *)sender {
    
    if ([sender.titleLabel.text isEqualToString:@"Download"]) {
        [self.button setTitle:@"Cancel" forState:UIControlStateNormal];
        self.progress.progress = 0.f;
        NSURL * URL = [NSURL URLWithString:URL_STR];
        self.downloader = [[CXKHTTPDownloader alloc] initWithRequestURL:URL progress:^(float persent) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.progress.progress = persent;
            });
        } completion:^(id response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.button setTitle:@"Download" forState:UIControlStateNormal];
                if (error) {
                    self.progress.progress = 0.f;
                }
            });
        }];
        [self.operationQueue addOperation:self.downloader];
        [self.operationQueue addOperationWithBlock:^{
            NSLog(@"---------->next Operation !");
        }];
    }else {
        [self.button setTitle:@"Download" forState:UIControlStateNormal];
        self.progress.progress = 0.f;
        [self.downloader cancel];
        
    }
}









































@end
