//
//  UIResponder+InsertTextAdditions.m
//  DFEvaluatorDemo
//
//  Created by JZ_Stone on 2017/6/6.
//  Copyright © 2017年 JZ_Stone. All rights reserved.
//

#import "UIResponder+InsertTextAdditions.h"

@implementation UIResponder (InsertTextAdditions)

- (void)insertTextAtCursor:(NSString *)text
{
    // 获取系统剪贴板
    UIPasteboard *generalPasteboard = [UIPasteboard generalPasteboard];
    
    // 保存系统剪贴板内容，以便最后能恢复它们
    NSArray *items = [generalPasteboard.items copy];
    
    // 修改系统剪贴板的内容为要插入的文本
    generalPasteboard.string = text;
    
    [self becomeFirstResponder];
    // 告诉responder从系统剪贴板粘贴文本到当前光标位置
    [self paste:self];
    
    // 恢复系统剪贴板原有的内容
    generalPasteboard.items = items;
}

@end
