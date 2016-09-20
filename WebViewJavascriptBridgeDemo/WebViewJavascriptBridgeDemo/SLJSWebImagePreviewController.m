//
//  SLJSWebImagePreviewController.m
//  WebViewJavascriptBridgeDemo
//
//  Created by CY on 16/9/20.
//  Copyright © 2016年 CY. All rights reserved.
//

#import "SLJSWebImagePreviewController.h"

@interface SLJSWebImagePreviewController ()

@property(nonatomic ,strong) UIImageView *imageView;

@end

@implementation SLJSWebImagePreviewController

#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}


#pragma mark - event responses

#pragma mark - privace methods

#pragma mark - Delegate

#pragma mark - getter and setter

@end
