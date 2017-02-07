//
//  FXKeyboardInputView.m
//
//
//  Created by fx on 17/2/7.
//  Copyright © 2017年 All rights reserved.
//

#import "FXKeyboardInputView.h"

@interface FXKeyboardInputView () <UITextViewDelegate>
@property (nonatomic) NSUInteger lastTextLength;
@property (nonatomic) CGFloat lastHeight;

@property (weak, nonatomic) IBOutlet UILabel *placeholderLabel;

@end

@implementation FXKeyboardInputView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChangeNotification:) name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChangeNotification:) name:UITextFieldTextDidEndEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChangeNotification:) name:UITextFieldTextDidBeginEditingNotification object:nil];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] init];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [tapGesture addTarget:self action:@selector(hideManually)];
    [self addGestureRecognizer:tapGesture];
    
    self.textView.layer.cornerRadius = 1;
    self.textView.layer.borderColor = [UIColor grayColor].CGColor;
    self.textView.layer.borderWidth = 1;
    
    self.textView.delegate = self;
    
    self.lastTextLength = 0;
    self.lastHeight = 34.f;
    
    [self.textView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
    
    [self.backView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentOffset"]) {
        
        CGPoint contentOffset = self.textView.contentOffset;
        
        if (self.textView.contentSize.height <= 88 && contentOffset.y > 0) {
            [self.textView setContentOffset:CGPointZero];
        }
        else if(self.textView.contentSize.height > 88 && contentOffset.y > self.textView.contentSize.height - 88){
            [self.textView setContentOffset:CGPointMake(0, self.textView.contentSize.height - 88)];
        }
    }
    
    if ([keyPath isEqualToString:@"frame"]) {
        if ([self.delegate respondsToSelector:@selector(keyboardInputView:didChangeTopY:)]) {
            [self.delegate keyboardInputView:self didChangeTopY:self.backView.frame.origin.y];
        }
        if (self.changeTopY) {
            CGRect rect = [self convertRect:self.backView.frame toView:self.window];
            NSLog(@"topY:%f",rect.origin.y);
            self.changeTopY(self, CGRectGetMinY(rect));
        }
    }
}


- (void)textChangeNotification:(NSNotification *)notification
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        [self resizeFrames];
    }
    else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self resizeFrames];
        });
    }
}

- (void)resizeFrames
{
    [self.placeholderLabel setHidden:([self.textView.text length] > 0)];
    
    if ([self textLengthToShow] >= 130) {
        self.textCountLabel.text = [NSString stringWithFormat:@"%zd", ((NSInteger)self.textLengthLimit - [self textLengthToShow])];
    }
    else{
        self.textCountLabel.text = @"";
    }
    
    CGFloat height = self.textView.contentSize.height >= 34.f ? self.textView.contentSize.height : 34.f;
    
    //检验字数和height的匹配
    if(self.textView.text.length != 0 && self.lastTextLength <= [self.textView.text length] && height < self.lastHeight)
    {
        height = self.lastHeight;
    }
    
    if (height > 88) {
        height = 88;
    }
    
    if (height != self.lastHeight) {
        CGRect frame = self.textView.frame;
        [self.textView setFrame:CGRectMake(frame.origin.x, frame.origin.y - height + self.lastHeight, frame.size.width, height)];
        frame = self.textCountLabel.frame;
        frame.origin.y = self.textView.frame.origin.y - 20;
        [self.textCountLabel setFrame:frame];
        
        frame = self.backView.frame;
        frame.origin.y = self.textView.frame.origin.y - 20;
        frame.size.height = self.textView.frame.size.height + 40;
        self.backView.frame = frame;
    }
    
    if (self.textView.contentSize.height <= 88) {
        [self.textView setContentOffset:CGPointZero];
    }
    else{
        [self.textView setContentOffset:CGPointMake(0, self.textView.contentSize.height - 88)];
    }
    
    self.lastHeight = height;
    self.lastTextLength = self.textView.text.length;
}


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString * trimStr = [text stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    if ([text isEqualToString:@"\n"]) {
        if ([self textLengthToShow] > [self textLengthLimit]) {
            NSLog(@"请不要超过XXX字哦!");
            return NO;
        }
        
        if ([self.delegate respondsToSelector:@selector(keyboardInputView:wantSendText:)]) {
            [self.delegate keyboardInputView:self wantSendText:self.textView.text];
        }
        if (self.sendText) {
            self.sendText(self, self.textView.text);
        }
        
        return NO;
    }
    
    if (text.length > 0 && trimStr.length == 0) {
        return NO;
    }
    
    if (text.length > 0 && [self textLengthWithString:text] + [self textLengthToShow] > [self textLengthLimit]) {
        //超过字数限制，不让输入
        return NO;
    }
    
    return YES;
}


- (void)dealloc
{
    [self.textView removeObserver:self forKeyPath:@"contentOffset"];
    
    [self.backView removeObserver:self forKeyPath:@"frame"];
    [self removeObserver:self forKeyPath:@"frame"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)viewFromBundle
{
    return (FXKeyboardInputView *)[[[NSBundle mainBundle] loadNibNamed:@"FXKeyboardInputView" owner:nil options:nil] objectAtIndex:0];;
}

- (void)showInWindow:(UIWindow *)window
{
    self.frame = window.bounds;
    [window addSubview:self];
    
    [self.textView becomeFirstResponder];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self resizeFrames];
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self resizeFrames];
    });
}

- (void)hide:(BOOL)manual
{
    if (self.didHidden) {
        self.didHidden(self, manual);
    }
    [self removeFromSuperview];
}

- (void)hideManually
{
    [self hide:YES];
}

- (void)hide
{
    [self hide:NO];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSValue *vFrame = [notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [vFrame CGRectValue];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    CGRect frame = self.frame;
    frame.origin.y = self.superview.frame.size.height - keyboardRect.size.height - frame.size.height;
    [self setFrame: frame];
    
    [UIView commitAnimations];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    if ([self.delegate respondsToSelector:@selector(keyboardInputView:didChangeTopY:)]) {
        [self.delegate keyboardInputView:self didChangeTopY:self.backView.frame.origin.y];
    }
    if (self.changeTopY) {
        CGRect rect = [self convertRect:self.backView.frame toView:self.window];
        self.changeTopY(self, CGRectGetMinY(rect));
    }
}

- (void)keyboardWillHide:(NSNotification *) notification
{
    NSValue *vDuration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval duration;
    [vDuration getValue:&duration];
    if (self.superview) {
        [UIView animateWithDuration:duration animations:^{
            CGRect frame = self.frame;
            frame.origin.y  = self.superview.frame.size.height - frame.size.height;
            [self setFrame: frame];
            
        }];
        
    }
}

- (void)setPlaceHolderString:(NSString *)placeHolderString
{
    _placeHolderString = placeHolderString;
    
    [self.placeholderLabel setText:placeHolderString];
}

- (NSUInteger)textLengthLimit
{
    if (_textLengthLimit == 0) {
        //默认140字
        return 140;
    }
    
    return _textLengthLimit;
}

- (NSUInteger)textLengthToShow
{
    return [self textLengthWithString:self.textView.text];
}

- (NSInteger)textLengthWithString:(NSString *)string
{
    int i, n = (int)[string length], l=0, a=0, b=0;
    unichar c;
    for(i = 0;i < n;i ++){
        c=[string characterAtIndex:i];
        if(isblank(c)){
            b++;
        }else if(isascii(c)){
            a++;
        }else{
            l++;
        }
    }
    if(a == 0 && l == 0){
        return 0;
    }
    return l + (int)ceilf((float)(a + b) / 2.0);
}

- (void)cleanText
{
    [self.textView setText:@""];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self resizeFrames];
    });
}


@end
