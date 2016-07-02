//
//  JSWebViewController.m
//  WebViewJavascriptBridgeDemo
//
//  Created by CY on 16/7/1.
//  Copyright © 2016年 CY. All rights reserved.
//

#import "JSWebViewController.h"

@interface JSWebViewController ()<UIWebViewDelegate>

@property(nonatomic ,strong) UIWebView *webView;

@end

@implementation JSWebViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"reload" style:UIBarButtonItemStylePlain target:self action:@selector(reload)];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.webView = [[UIWebView alloc] init];
    self.webView.delegate = self;
    self.webView.frame = CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height-64);
    [self.view addSubview:self.webView];

//    http://192.168.1.111:3000/index.html
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://192.168.1.111:3000/index.html"]];
    [self.webView loadRequest:request];
    
    NSLog(@"%@",self.webView);
    
}

-(void)reload
{
    [self.webView reload];
}


-(void)webViewDidFinishLoad:(UIWebView *)webView{
    //OC调用JS，只要利用UIWebView的stringByEvaluatingJavaScriptFromString方法，告诉系统
    [self.webView stringByEvaluatingJavaScriptFromString:@"show();"];
}

@end
