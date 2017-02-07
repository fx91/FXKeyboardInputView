//
//  FXKeyboardInputView.h
//  
//
//  Created by fx on 17/2/7.
//  Copyright © 2017年 All rights reserved.
//

#import <UIKit/UIKit.h>

@class FXKeyboardInputView;
@protocol FXKeyboardInputViewDelegate <NSObject>

@optional

//点击发送
- (void)keyboardInputView:(FXKeyboardInputView *)keyboardInputView wantSendText:(NSString *)toSnedText;

//输入框 origin Y变化回调
- (void)keyboardInputView:(FXKeyboardInputView *)keyboardInputView didChangeTopY:(CGFloat)topY;

@end

@interface FXKeyboardInputView : UIView

@property (nonatomic, weak) id<FXKeyboardInputViewDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIView *backView;
@property (weak, nonatomic) IBOutlet UILabel *textCountLabel;

@property (weak, nonatomic) IBOutlet UITextView *textView;

//字数限制
@property (nonatomic) NSUInteger textLengthLimit;

//占位文字
@property (nonatomic, copy) NSString *placeHolderString;

@property (nonatomic, copy) void(^sendText)(FXKeyboardInputView *keyboardInputView, NSString *text);
@property (nonatomic, copy) void(^changeTopY)(FXKeyboardInputView *keyboardInputView, CGFloat topY);

@property (nonatomic, copy) void(^didHidden)(FXKeyboardInputView *keyboardInputView, BOOL manual);

//获取实例
+ (instancetype)viewFromBundle;

//在一个window上显示
- (void)showInWindow:(UIWindow *)window;

//隐藏
- (void)hide;

//清除输入文字
- (void)cleanText;

@end
