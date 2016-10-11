//
//  SLWebTitleView.m
//  WebViewJavascriptBridgeDemo
//
//  Created by CY on 16/10/11.
//  Copyright © 2016年 CY. All rights reserved.
//

#import "SLWebTitleView.h"

@interface SLWebTitleView ()
@property(nonatomic ,strong) UILabel *titleLabel;
@property(nonatomic ,strong) UIActivityIndicatorView *indicatorView;

@end

@implementation SLWebTitleView


-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self addSubview:self.titleLabel];
        [self addSubview:self.indicatorView];
        self.backgroundColor = [UIColor clearColor];
//        [self.indicatorView startAnimating];
        self.indicatorView.hidesWhenStopped = YES;
    }
    
    return self;
}


-(void)layoutSubviews
{
    [super layoutSubviews];
    self.indicatorView.frame = CGRectMake(-28, 0, 20, 20);
    self.titleLabel.frame = CGRectMake(0, 0, 35, 20);
}

-(void)setShowLoading:(BOOL)showLoading
{
    _showLoading = showLoading;
    
//    NSLog(@"setShowLoading :%d", showLoading);
    
    if (showLoading)
    {
        [self.indicatorView startAnimating];
    }
    else
    {
        [self.indicatorView stopAnimating];
    }
}


-(UILabel *)titleLabel
{
    if (!_titleLabel)
    {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"客服";
        _titleLabel.textColor = [UIColor whiteColor];
    }
    
    return _titleLabel;
}

-(UIActivityIndicatorView *)indicatorView
{
    if (!_indicatorView)
    {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    }
    
    return _indicatorView;
}



@end
