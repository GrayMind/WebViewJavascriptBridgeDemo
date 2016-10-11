//
//  SiLinJSBridge.m
//  WebViewJavascriptBridgeDemo
//
//  Created by CY on 16/8/22.
//  Copyright © 2016年 CY. All rights reserved.
//

#import "SiLinJSBridge.h"

#import <AFNetworking.h>
#import <MWPhotoBrowser.h>

#import "iflyMSC/iflyMSC.h"
#import "Definition.h"
#import "ISRDataHelper.h"
#import "IATConfig.h"

#import "SLWebTitleView.h"

@interface SiLinJSBridge ()<MWPhotoBrowserDelegate, IFlySpeechRecognizerDelegate>

@property(nonatomic ,strong) JSValue *imageCallback;

@property(nonatomic ,assign) CGFloat keyboardH;

@property(nonatomic ,strong) NSMutableArray *photoArray;




//
@property (nonatomic, strong) NSString *pcmFilePath;//音频文件路径
@property (nonatomic, strong) IFlySpeechRecognizer *iFlySpeechRecognizer;//不带界面的识别对象
@property (nonatomic, strong) IFlyDataUploader *uploader;//数据上传对象

@property (nonatomic, assign) BOOL isCanceled; //手动取消
@property(nonatomic ,assign) BOOL isStop;//手动停止
@property (nonatomic, strong) NSString * result;

@property(nonatomic ,strong) JSValue *manualStopCallback; // 手动结束回调
@property(nonatomic ,strong) JSValue *autoStopCallback; // 自动结束回调
@end


@implementation SiLinJSBridge


#pragma mark - life cycle
-(instancetype)init
{
    self = [super init];
    if (self)
    {
        _keyboardH = 0;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    }
    
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - SiLinJSObjectProtocol
-(CGFloat)keyboardHeight
{
    if (_keyboardH != 0) {
        return _keyboardH;
    }
    return 305;
}

/**
 *  选择图片
 *
 *  @param type     0：拍照； 1：相册
 *  @param callback 选择/上传图片回调
 */
-(void)chooseImageWithType:(JSValue *)type callback:(JSValue *)callback
{
    NSInteger t = [type toInt32];
    
    if(!self.imageCallback)
    {
        self.imageCallback = callback;
    }
    
    if (t == 0)
    {
        // 拍照
        UIImagePickerController *controller = [[UIImagePickerController alloc] init];
        controller.sourceType = UIImagePickerControllerSourceTypeCamera;
        controller.delegate = self;
        [self.viewController presentViewController:controller animated:YES completion:nil];
    }
    else if(t == 1)
    {
        UIImagePickerController *controller = [[UIImagePickerController alloc] init];
        controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        controller.delegate = self;
        [self.viewController presentViewController:controller animated:YES completion:nil];
    }
}

-(void)previewImage:(JSValue *)imageUrl
{
    NSString *image = [imageUrl toString];
    NSURL *url = [NSURL URLWithString:image];
    if ([image hasPrefix:@"slimage://"])
    {
        image = [image stringByReplacingOccurrencesOfString:@"slimage://" withString:@""];
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        // 拼接图片路径
        NSString *imageFilePath = [path stringByAppendingPathComponent:image];
        
        url = [NSURL fileURLWithPath:imageFilePath];
    }
    
    self.photoArray = [NSMutableArray array];
    // Add photos
    [self.photoArray addObject:[MWPhoto photoWithURL:url]];
    NSLog(@"previewImage %@", [imageUrl toString]);
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    
    // Set options
    browser.displayActionButton = YES; // Show action button to allow sharing, copying, etc (defaults to YES)
    browser.displayNavArrows = NO; // Whether to display left and right nav arrows on toolbar (defaults to NO)
    browser.displaySelectionButtons = NO; // Whether selection buttons are shown on each image (defaults to NO)
    browser.zoomPhotosToFill = YES; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
    browser.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
    browser.enableGrid = YES; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
    browser.startOnGrid = NO; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
    browser.autoPlayOnAppear = NO; // Auto-play first video
    
    // Customise selection images to change colours if required
    browser.customImageSelectedIconName = @"ImageSelected.png";
    browser.customImageSelectedSmallIconName = @"ImageSelectedSmall.png";
    
    // Optionally set the current visible photo before displaying
    [browser setCurrentPhotoIndex:1];
    
    // Present
    [self.navigationController pushViewController:browser animated:YES];

}

#pragma mark - privace method

// 获取图片 MD5
-(NSString *)imageMD5:(UIImage *)image
{
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(image)];
    CC_MD5([imageData bytes], (CC_LONG)[imageData length], result);
    NSString *imageHash = [NSString stringWithFormat:
                           @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                           result[0], result[1], result[2], result[3],
                           result[4], result[5], result[6], result[7],
                           result[8], result[9], result[10], result[11],
                           result[12], result[13], result[14], result[15]
                           ];
    
    return imageHash;
}

// 上传图片
-(void)uploadImage:(UIImage *)image MD5Url:(NSString *)imgUrl
{
    NSString *url = @"http://121.42.201.123:20091/chime/api/v1/upload";
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager.requestSerializer setValue:@"iOS.1234567890" forHTTPHeaderField:@"X-Client-Id"];
    [manager.requestSerializer setValue:@"dongya" forHTTPHeaderField:@"X-App-Id"];
    [manager.requestSerializer setValue:@"f5e424137912485a15d1447a50669ce6" forHTTPHeaderField:@"X-Token"];

    NSData *imgData = UIImageJPEGRepresentation(image, 0.05);
    
    [manager POST:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFileData:imgData name:@"pic" fileName:@"image.jpg" mimeType:@"image/png"];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
//        CGFloat fractionCompleted = uploadProgress.fractionCompleted;
        NSLog(@"%f", 1.0 * uploadProgress.completedUnitCount / uploadProgress.totalUnitCount);
//        NSLog(@"%f", uploadProgress.fractionCompleted);
        NSNumber *prog = [NSNumber numberWithDouble:1.0 * uploadProgress.completedUnitCount / uploadProgress.totalUnitCount];
        [self.imageCallback invokeMethod:@"uploadImageProgress" withArguments:@[imgUrl, prog]];
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"success :%@", imgUrl);
        [self.imageCallback invokeMethod:@"uploadImageSuccess" withArguments:@[imgUrl]];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"failure :%@", imgUrl);
       
        NSString *errorStr = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        NSString *errorMessage = @"";
        
        if (![errorStr isEqual: [NSNull null]] && errorStr.length > 0)
        {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] options:NSJSONReadingMutableLeaves error:nil];
            errorMessage = dic[@"message"];
        }
        NSLog(@"%@", error);
        NSLog(@"%@", errorMessage);
    }];

}

-(void)keyboardWillShow:(NSNotification *)noti
{
    NSDictionary *userInfo = noti.userInfo;
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect userInfoKey = [aValue CGRectValue];
    _keyboardH = userInfoKey.size.height;
}

#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    UIImage *portraitImg = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    UIImageOrientation imageOrientation = portraitImg.imageOrientation;
    
    if(imageOrientation != UIImageOrientationUp)
    {
        // 原始图片可以根据照相时的角度来显示，但UIImage无法判定，于是出现获取的图片会向左转９０度的现象。
        // 以下为调整图片角度的部分
        UIGraphicsBeginImageContext(portraitImg.size);
        [portraitImg drawInRect:CGRectMake(0, 0, portraitImg.size.width, portraitImg.size.height)];
        portraitImg = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        // 调整图片角度完毕
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    NSString *imageMD5 = [self imageMD5:portraitImg];
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    // 拼接图片路径
    NSString *imageFilePath = [path stringByAppendingPathComponent:imageMD5];
    //其中参数0.5表示压缩比例，1表示不压缩，数值越小压缩比例越大
    [UIImageJPEGRepresentation(portraitImg, 0.5) writeToFile:imageFilePath  atomically:YES];
    
    // slimage://imagemd5
    NSString *data = [NSString stringWithFormat:@"slimage://%@",imageMD5];
    //
    [self.imageCallback invokeMethod:@"chooseImageSuccess" withArguments:@[data]];
    [self uploadImage:portraitImg MD5Url:data];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - MWPhotoBrowserDelegate
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser
{
    return self.photoArray.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index
{
    if (index < self.photoArray.count)
    {
        return [self.photoArray objectAtIndex:index];
    }
    return nil;
}

#pragma mark - 语音相关
/**
 设置识别参数
 ****/
-(void)initRecognizer
{
    NSLog(@"%s",__func__);
    
    if ([IATConfig sharedInstance].haveView == NO) //无界面
    {
        
        //单例模式，无UI的实例
        if (_iFlySpeechRecognizer == nil)
        {
            _iFlySpeechRecognizer = [IFlySpeechRecognizer sharedInstance];
            
            [_iFlySpeechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
            
            //设置听写模式
            [_iFlySpeechRecognizer setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
        }
        _iFlySpeechRecognizer.delegate = self;
        
        if (_iFlySpeechRecognizer != nil)
        {
            IATConfig *instance = [IATConfig sharedInstance];
            
            //设置最长录音时间
            [_iFlySpeechRecognizer setParameter:instance.speechTimeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
            //设置后端点
            [_iFlySpeechRecognizer setParameter:instance.vadEos forKey:[IFlySpeechConstant VAD_EOS]];
            //设置前端点
            [_iFlySpeechRecognizer setParameter:instance.vadBos forKey:[IFlySpeechConstant VAD_BOS]];
            //网络等待时间
            [_iFlySpeechRecognizer setParameter:@"20000" forKey:[IFlySpeechConstant NET_TIMEOUT]];
            
            //设置采样率，推荐使用16K
            [_iFlySpeechRecognizer setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
            
            if ([instance.language isEqualToString:[IATConfig chinese]])
            {
                //设置语言
                [_iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
                //设置方言
                [_iFlySpeechRecognizer setParameter:instance.accent forKey:[IFlySpeechConstant ACCENT]];
            }
            else if ([instance.language isEqualToString:[IATConfig english]])
            {
                [_iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
            }
            //设置是否返回标点符号
            [_iFlySpeechRecognizer setParameter:instance.dot forKey:[IFlySpeechConstant ASR_PTT]];
        }
    }
}

// 开始录音
-(void)startRecording:(JSValue *)callback
{
    NSLog(@"%s[IN]",__func__);
    
    
    if ([IATConfig sharedInstance].haveView == NO) //无界面
    {
        _result = @"";
        self.isCanceled = NO;
        self.isStop = NO;
        
        if(_iFlySpeechRecognizer == nil)
        {
            [self initRecognizer];
        }
        
        [_iFlySpeechRecognizer cancel];
        
        //设置音频来源为麦克风
        [_iFlySpeechRecognizer setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];
        
        //设置听写结果格式为json
        [_iFlySpeechRecognizer setParameter:@"json" forKey:[IFlySpeechConstant RESULT_TYPE]];
        
        //保存录音文件，保存在sdk工作路径中，如未设置工作路径，则默认保存在library/cache下
        [_iFlySpeechRecognizer setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
        
        [_iFlySpeechRecognizer setDelegate:self];
        
        BOOL ret = [_iFlySpeechRecognizer startListening];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!ret)
            {
                NSLog(@"启动识别服务失败，请稍后重试");
                [callback callWithArguments:@[@0]];
            }
            else
            {
                [callback callWithArguments:nil];
            }
        });
//        if (!ret)
//        {
//            NSLog(@"启动识别服务失败，请稍后重试");
//            [callback callWithArguments:@[@0]];
//        }
//        else
//        {
//            [callback callWithArguments:nil];
//        }
    }
    
}

// 取消录音
-(void)cancelRecording:(JSValue *)callback
{
    self.isCanceled = YES;
    [_iFlySpeechRecognizer cancel];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [callback callWithArguments:@[]];
    });
}

// 手动结束录音
-(void)endRecording:(JSValue *)callback
{
    self.isStop = YES;
    [_iFlySpeechRecognizer stopListening];
    
    self.manualStopCallback = callback;
    
//    [callback callWithArguments:@[]];
}

// 自动结束录音
-(void)onVoiceRecordEnd:(JSValue *)callback
{
    self.autoStopCallback = callback;
}

#pragma mark - IFlySpeechRecognizerDelegate

/**
 音量回调函数
 volume 0－30
 ****/
- (void)onVolumeChanged:(int)volume
{
//    NSString * vol = [NSString stringWithFormat:@"音量：%d",volume];
//    NSLog(@"音量: %@", vol);
}


/**
 开始识别回调
 ****/
- (void)onBeginOfSpeech
{
    NSLog(@"onBeginOfSpeech");
}

/**
 停止录音回调
 ****/
- (void)onEndOfSpeech
{
    NSLog(@"onEndOfSpeech");
}

/**
 听写取消回调
 ****/
- (void)onCancel
{
    NSLog(@"识别取消");
}


/**
 听写结束回调（注：无论听写是否正确都会回调）
 error.errorCode =
 0     听写正确
 other 听写出错
 ****/
- (void)onError:(IFlySpeechError *)error
{
    NSLog(@"%s",__func__);
    
    if ([IATConfig sharedInstance].haveView == NO )
    {
        NSString *text ;
        
        if (self.isCanceled)
        {
            text = @"识别取消";
        }
        else if (error.errorCode == 0 )
        {
            if (_result.length == 0)
            {
                text = @"无识别结果";
            }
            else
            {
                text = @"识别成功";
            }
        }
        else
        {
            text = [NSString stringWithFormat:@"发生错误：%d %@", error.errorCode, error.errorDesc];
        }
        NSLog(@"%@",text);
        
    }
}

/**
 无界面，听写结果回调
 results：听写结果
 isLast：表示最后一次
 ****/
- (void)onResults:(NSArray *)results isLast:(BOOL)isLast
{
    
    NSMutableString *resultString = [[NSMutableString alloc] init];
    NSDictionary *dic = results[0];
    for (NSString *key in dic) {
        [resultString appendFormat:@"%@",key];
    }
//    _result =[NSString stringWithFormat:@"%@%@", _result,resultString];
    NSString * resultFromJson =  [ISRDataHelper stringFromJson:resultString];
    _result = [NSString stringWithFormat:@"%@%@", _result,resultFromJson];
    
    if (isLast)
    {
        NSLog(@"听写结果(json)：%@",  _result);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.isStop)
            {
                if(self.manualStopCallback)
                {
                    [self.manualStopCallback callWithArguments:@[_result]];
                }
            }
            else
            {
                if(self.autoStopCallback)
                {
                    [self.autoStopCallback callWithArguments:@[_result]];
                }
                
            }

        });
    }
    NSLog(@"_result=%@",_result);
    NSLog(@"isLast=%d",isLast);
}



#pragma mark - 
-(void)showLoading:(JSValue *)show
{
//    NSLog(@"showLoading: %d", [show toBool]);
    self.titleView.showLoading = [show toBool];
}




@end
