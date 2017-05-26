//
//  ViewController.m
//  MAC_YUV
//
//  Created by Ruiwen Feng on 2017/5/25.
//  Copyright © 2017年 Ruiwen Feng. All rights reserved.
//

#import "ViewController.h"
#import "YUVView.h"


@interface ViewController ()
@property (strong,nonatomic)     YUVView * playView;
@end

@implementation ViewController
{
    FILE * file;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString * path = [[NSBundle mainBundle] pathForResource:@"file" ofType:@"yuv"];
    
    file = fopen(path.UTF8String, "r");
    
    self.view.frame = CGRectMake(0, 0, 176*4, 144*4);
    _playView = [[YUVView alloc]initWithFrame:self.view.bounds];
    [self.view addSubview:_playView];
    
    NSButton * btn = [NSButton buttonWithTitle:@"play" target:self action:@selector(draw)];
    btn.frame = CGRectMake(0, 0, 176*4, 50);
    [self.view addSubview:btn];
    // Do any additional setup after loading the view.
}

- (void)draw {
    
    int isEnd = feof(file);
    if (isEnd >0) {
        NSLog(@"结束了。");
        return;
    }
    
    size_t yuv_length = 176*144*3/2;
    Byte buf[yuv_length];
    fread(buf, 1, yuv_length, file);
    NSLog(@"%@",[NSData dataWithBytes:buf length:yuv_length]);
    
    [_playView displayYUV_I420:(char*)buf width:176 height:144];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self draw];
    });
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}


@end
