//
//  DFEvaluatorParser.m
//  DFEvalKit
//
//  Created by Dean_F on 15/1/7.
//  Copyright (c) 2015年 Dean_F. All rights reserved.
//

#import "DFEvaluatorParser.h"z

@implementation DFEvaluatorParser

- (DFEvaluatorParser *)initWithExpression:(NSString *)expression
{
    if(self = [super init])
    {
        _expression = expression;
        _position = 0;
    }
    return self;
}

/**
 *  读取下一个表达式节点,如果读取失败则返回null
 */
- (DFEvaluatorNode *)readNode
{
    // 空格的位置
    NSInteger whileSpacePos = -1;
    bool isString = false;
    
    NSMutableString *buffer = [NSMutableString string];
    while (_position < _expression.length)
    {
        NSString *c = [_expression substringWithRange:(NSRange){_position, 1}];
        
        if ([c isEqualToString:@"\""]) // 如果是字符串操作数，标识
        {
            isString = !isString;
            if (!isString) // 如果是字符串结束处的引号，结束本次读取，返回读取结果
            {
                _position++;
                [buffer appendString:c];
                break;
            }
            else
            {
                if (buffer.length != 0)  // 如果是字符串开始处的引号，而前面还有字符，应该结束上次读取
                {
                    break;
                }
            }
        }
        
        if (isString) // 如果是字符串操作数，一直读取到下一个引号前字符为止
        {
            _position++;
            [buffer appendString:c];
            continue;
        }
        
        // 空白字符不处理
        if ([c isMatchedByRegex:@"\\s"])
        {
            // 判断两次的空白字符是否连续
            if (whileSpacePos >= 0 && (_position - whileSpacePos) > 1)
            {
                NSString *message = [NSString stringWithFormat:@"Error：\n表达式“%@”的第%ld个字符“%@”不合法", _expression, _position,  c];
                NSAssert(false, message);
            }
            else
            {
                if (buffer.length == 0)
                {
                    // 前空白不判断处理
                    whileSpacePos = -1;
                }
                else
                {
                    whileSpacePos = _position;
                }
                _position++;
            }
            continue;
        }
        
        if (buffer.length == 0 || [DFEvaluatorNode isCongener:[buffer characterAtIndex:buffer.length - 1] with:[c characterAtIndex:0]])
        {
            // 同一类字符则继续读取字符
            _position++;
            [buffer appendString:c];
        }
        else
        {
            break;
        }
        
        // 判断是否需要更多的操作符
        if (![DFEvaluatorNode needMoreOperator:[c characterAtIndex:0]])
        {
            break;
        }
    }
    
    if (buffer.length == 0)
    {
        return nil;
    }
    
    DFEvaluatorNode *expNode = [[DFEvaluatorNode alloc] initWithValue:buffer];
    if (expNode.type == Unknown)
    {
        NSString *message = [NSString stringWithFormat:@"Error：\n表达式“%@”的第%ld个字符“%@”不合法",
                             _expression, _position - expNode.value.length, expNode.value];
        NSAssert(false, message);
    }
    return expNode;
}


@end
