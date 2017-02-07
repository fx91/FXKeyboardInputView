//
//  ViewController.m
//  FXKeyboardInputView
//
//  Created by fx on 2017/2/7.
//  Copyright © 2017年 com.fx. All rights reserved.
//

#import "ViewController.h"
#import "FXKeyboardInputView.h"

@interface ViewController ()

@property (nonatomic, strong) FXKeyboardInputView *keyboardInputView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.keyboardInputView = [FXKeyboardInputView viewFromBundle];
    
    [self.keyboardInputView setPlaceHolderString:@"aa"];
    
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    //点击屏幕弹出
    [self.keyboardInputView showInWindow:self.view.window];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
