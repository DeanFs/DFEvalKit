//
//  DFEvaluatorNode.m
//  DFEvalKit
//
//  Created by Dean_F on 15/1/7.
//  Copyright (c) 2015年 Dean_F. All rights reserved.
//

#include <ctype.h>
#import "DFEvaluatorNode.h"

@implementation DFEvaluatorNode

- (DFEvaluatorNode *)initWithValue:(NSString *)value
{
    if(self = [super init])
    {
        _value = value;
        self.type = [DFEvaluatorNode parseNodeType:self.value];
        _pri = [DFEvaluatorNode getNodeTypePRI:self.type];
        self.numeric = nil;
    }
    return self;
}

/**
 *  返回此节点的数值
 */
- (NSString *)numeric
{
    if (_numeric == nil)
    {
        _numeric = self.value;
        
        if (self.type == Numeric)
        {
            if (self.unitaryNode != nil)
            {
                if(self.unitaryNode.type == Subtract)
                {
                    _numeric = [NSString stringWithFormat:@"%@", @(-[self.value doubleValue])];
                }
            }
        }
    }
    return _numeric;
}

- (NSString *)description
{
    NSArray *typeList = @[
                          @"Unknown",
                          @"Plus",
                          @"Subtract",
                          @"MultiPly",
                          @"Divide",
                          @"LParentheses",
                          @"RParentheses",
                          @"Mod",
                          @"Power",
                          @"LShift",
                          @"RShift",
                          @"BitwiseAnd",
                          @"BitwiseOr",
                          @"And",
                          @"Or",
                          @"Not",
                          @"Equal",
                          @"Unequal",
                          @"GT",
                          @"LT",
                          @"GTOrEqual",
                          @"LTOrEqual",
                          @"Numeric",
                          @"String",
                          @"Datetime"
                          ];
    return [NSString stringWithFormat:@"\n\t{\n\t\ttype: %@\n\t\tvalue: %@\n\t\tnumeric: %@\n\t\tpri: %ld\n\t\tunitaryNode: %@\n\t}", typeList[self.type], self.value, self.numeric, self.pri, [self.unitaryNode description]];
}

/**
 *  解析节点类型
 */
+ (DFEvaluatorNodeType)parseNodeType:(NSString *)value
{
    if ([value isKindOfClass:[NSNull class]] || value.length == 0)
    {
        return Unknown;
    }
    if([value isEqualToString:@"+"])
    {
        return Plus;
    }
    else if([value isEqualToString:@"-"])
    {
        return Subtract;
    }
    else if([value isEqualToString:@"*"])
    {
        return MultiPly;
    }
    else if([value isEqualToString:@"/"])
    {
        return Divide;
    }
    else if([value isEqualToString:@"%"])
    {
        return Mod;
    }
    else if([value isEqualToString:@"^"])
    {
        return Power;
    }
    else if([value isEqualToString:@"("])
    {
        return LParentheses;
    }
    else if([value isEqualToString:@")"])
    {
        return RParentheses;
    }
    else if([value isEqualToString:@"&"])
    {
        return BitwiseAnd;
    }
    else if([value isEqualToString:@"|"])
    {
        return BitwiseOr;
    }
    else if([value isEqualToString:@"&&"])
    {
        return And;
    }
    else if([value isEqualToString:@"||"])
    {
        return Or;
    }
    else if([value isEqualToString:@"!"])
    {
        return Not;
    }
    else if([value isEqualToString:@"=="])
    {
        return Equal;
    }
    else if([value isEqualToString:@"!="] || [value isEqualToString:@"<>"])
    {
        return Unequal;
    }
    else if([value isEqualToString:@">"])
    {
        return GT;
    }
    else if([value isEqualToString:@"<"])
    {
        return LT;
    }
    else if([value isEqualToString:@">="])
    {
        return GTOrEqual;
    }
    else if([value isEqualToString:@"<="])
    {
        return LTOrEqual;
    }
    else if([value isEqualToString:@"<<"])
    {
        return LShift;
    }
    else if([value isEqualToString:@">>"])
    {
        return RShift;
    }
    else
    {
        // 判断是否操作数
        if ([DFEvaluatorNode isNumerics:value])
        {
            return Numeric;
        }
        else if ([DFEvaluatorNode isDatetime:value])
        {
            return Datetime;
        }
        else if ([DFEvaluatorNode isString:value])
        {
            return String;
        }
        else
        {
            return Unknown;
        }
    }
}

/**
 *  获取各节点类型的优先级
 */
+ (NSInteger)getNodeTypePRI:(DFEvaluatorNodeType)nodeType
{
    switch (nodeType)
    {
        case LParentheses:
        case RParentheses:
            return 9;
        case Not: // 逻辑非是一元操作符，所以其优先级较高
            return 8;
        case Mod:
            return 7;
        case MultiPly:
        case Divide:
        case Power:
            return 6;
        case Plus:
        case Subtract:
            return 5;
        case LShift:
        case RShift:
            return 4;
        case BitwiseAnd:
        case BitwiseOr:
            return 3;
        case Equal:
        case Unequal:
        case GT:
        case LT:
        case GTOrEqual:
        case LTOrEqual:
            return 2;
        case And:
        case Or:
            return 1;
        default:
            return 0;
    }
}

/**
 *  判断某个操作数是否是数值
 */
+ (BOOL)isNumerics:(NSString *)op
{
    if([op rangeOfRegex:@"^[+-]?0*(\\d+\\.?\\d*|\\.\\d+)$"].length > 0)
    {
        return true;
    }
    return false;
}

/**
 *  判断某个操作数是否是布尔值
 */
+ (BOOL)isBool:(NSString *)op
{
    if([DFEvaluatorNode isNumerics:op])
    {
        return true;
    }
    else
    {
        NSString *bo = [op lowercaseString];
        if([bo isEqualToString:@"true"] ||
           [bo isEqualToString:@"false"] ||
           [bo isEqualToString:@"yes"] ||
           [bo isEqualToString:@"no"])
        {
            return true;
        }
    }
    return false;
}

/**
 *  判断某个操作数是否是字符串
 */
+ (BOOL)isString:(NSString *)op
{
    if([op isMatchedByRegex:@"^\"[^\"]*\"$"])
    {
        return true;
    }
    return false;
}

/**
 *  判断某个操作数是否是日期时间
 */
+ (BOOL)isDatetime:(NSString *)op
{
    if([op componentsMatchedByRegex:@"\\d{4}\\-\\d{2}\\-\\d{2}(\\s\\d{2}\\:\\d{2}\\:\\d{2})?"].count > 0)
    {
        return true;
    }
    return false;
}

/**
 *  判断某个字符后是否需要更多的操作符
 */
+ (BOOL)needMoreOperator:(char)c
{
    switch (c)
    {
        case '&':
        case '|':
        case '=':
        case '!':
        case '>':
        case '<':
        case '.':   // 小数点
            return true;
    }
    // 数字则需要更多
    return isdigit(c);
}

/**
 *  判断两个字符是否是同一类
 */
+ (BOOL)isCongener:(char)c1 with:(char)c2
{
    if(c1 == '(' || c2 == '(')
    {
        return false;
    }
    if(c1 == ')' || c2 == ')')
    {
        return false;
    }
    if(c1 == '!')
    {
        return c2 == '=';
    }
    if(c1 == '|')
    {
        return c2 == '|';
    }
    if(c1 == '&')
    {
        return c2 == '&';
    }
    if(c1 == '=')
    {
        return c2 == '=';
    }
    if(c1 == '<')
    {
        return c2 == '<' || c2 == '>' || c2 == '=';
    }
    if(c1 == '>')
    {
        return c2 == '>' || c2 == '=';
    }
    if(isdigit(c1))
    {
        // c1为数字,则c2也为数字
        return (isdigit(c2) || c2 == '.');
    }
    else if(c1 == '.')
    {
        return isdigit(c2);
    }
    else
    {
        // c1为非数字,则c2也为非数字
        return !(isdigit(c2));
    }
}

/**
 *  判断是否是一元操作符节点
 */
+ (BOOL)isUnitaryNode:(DFEvaluatorNodeType)nodeType
{
    return (nodeType == Plus || nodeType == Subtract);
}

@end
