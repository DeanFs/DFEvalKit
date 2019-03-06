//
//  DFEvaluator.m
//  DFEvalKit
//
//  Created by Dean_F on 15/1/7.
//  Copyright (c) 2015年 Dean_F. All rights reserved.
//

#import "DFEvaluator.h"
#import "DFEvaluatorFunctionNode.h"
#import "DFEvaluatorNode.h"
#import "DFEvaluatorParser.h"
#import "DFEvaluatorStack.h"

@implementation DFEvaluator
{
    /**
     *  开发者自定义的函数集，每个函数用 DFEvaluatorFunction 对象来描述，以表达式中使用的函数名为 key
     *  自定义函数的OC实现必须有返回值，且返回值为 DFEvaluatorFunctionResult 对象
     */
    NSDictionary *_customFunctions;
    
    // 日期格式
    NSDateFormatter *_dateFormatter;
    
    // 不使用函数调用，仅用于计算纯数学表达式
    BOOL _withoutFunctionInvoke;
}


- (instancetype)init
{
    if (self = [super init])
    {
        _customFunctions = nil;
        _withoutFunctionInvoke = false;
        _dateFormatter = [[NSDateFormatter alloc] init];
        
        [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    return self;
}


#pragma mark - API
- (void)setCustomFunctions:(NSDictionary *)customFunctions
{
    _customFunctions = customFunctions;
}

- (void)setDateFormat:(NSString *)dateFormat
{
    [_dateFormatter setDateFormat:dateFormat];
}

/**
 *  不使用函数调用，仅用于计算纯数学表达式
 */
- (void)withoutFunctionInvoke:(BOOL)withoutFunction
{
    _withoutFunctionInvoke = withoutFunction;
}

/**
 *  表达式计算
 *
 *  @param expression 需要计算的表达式
 *
 *  @return 计算结果
 */
- (NSString *)eval:(NSString *)expression
{
    if(expression == nil)
    {
        return nil;
    }
    
    if(!_withoutFunctionInvoke)
    {
        expression = [self preprocessor:expression];
    }
    
    id result = [self calcExpression:[self parseExpression:[self preprocessor:expression]]];
    
    return result;
}


#pragma mark - 预处理
/**
 *  表达式预处理
 *
 *  @param expression 需要计算的表达式，纯数学表达式，或者包含如DateDiff等库中已实现的函数或者开发者自己定义的扩展函数
 *
 *  @return 得到纯数学表达式，用函数执行结果替换函数
 */
- (NSString *)preprocessor:(NSString *)expression
{
    // 找出函数调用
    NSArray *functionNodes = [self findFunctionNodeFromExpression:expression];
    if(functionNodes)
    {
        NSString *result = nil;
        for(DFEvaluatorFunctionNode *node in functionNodes)
        {
            if([self respondsToSelector:node.selector])
            {
                result = [self performSelector:node.selector withObject:node.paramExpression];
            }
            else // 在开发者自定义方法中寻找
            {
                DFEvaluatorFunction *customFunction = [_customFunctions objectForKey:node.name];
                if(!customFunction ||
                   !customFunction.target ||
                   [customFunction.target isKindOfClass:[NSNull class]] ||
                   ![customFunction.target respondsToSelector:customFunction.selector])
                {
                    NSString *message = @"Error：\n在表达式“%@”中函数“%@”未实现对应的OC方法，表达式无法完成计算";
                    NSAssert(false, message);
                }
                
                id param = [self decodeCustomFunctionParams:[self preprocessor:node.paramExpression]]; // 去除参数中的函数调用，并解析函数参数
                
                DFEvaluatorFunctionResult *resultModel = [customFunction.target performSelector:customFunction.selector
                                                                                            withObject:param];
                if(resultModel.dataType == DFEvaluatorFunctionResultDataTypeString)
                {
                    result = [NSString stringWithFormat:@"\"%@\"", resultModel.result];
                }
                if(resultModel.dataType == DFEvaluatorFunctionResultDataTypeDatetime)
                {
                    if([resultModel.result isKindOfClass:[NSDate class]])
                    {
                        result = [NSString stringWithFormat:@"\"%@\"", [_dateFormatter stringFromDate:resultModel.result]];
                    }
                    else
                    {
                        result = [NSString stringWithFormat:@"\"%@\"", resultModel.result];
                    }
                }
            }
            expression = [expression stringByReplacingOccurrencesOfString:node.functionInvoke withString:result];
        }
    }
    return expression;
}

/**
 *  找出表达式中的函数调用，当前表达式中的第外层调用
 *
 *  @param expression 需要计算的表达式，纯数学表达式，或者包含如DateDiff等库中已实现的函数或者开发者自己定义的扩展函数
 *
 *  @return 所有匹配结果
 */
- (NSArray *)findFunctionNodeFromExpression:(NSString *)expression
{
    NSRange range = [expression rangeOfRegex:@"[\\W]?[\\w]+\\("];
    if(range.length > 0)
    {
        NSMutableArray *functionNodes = [NSMutableArray array];
        DFEvaluatorFunctionNode *node = nil; // 一个函数调用的节点描述
        
        NSString *functionName = nil; // 函数名称
        NSMutableString *paramExpression = nil; // 函数括号内的参数
        
        NSInteger location = range.location + range.length;
        NSInteger count = 1;
        
        while(location < expression.length)
        {
            if(location == range.location + range.length)
            {
                count = 1;
                paramExpression = [NSMutableString string];
                
                NSRange subRange = NSMakeRange(range.location, range.length - 1);
                functionName = [[expression substringWithRange:subRange] stringByReplacingOccurrencesOfRegex:@"^\\W" withString:@""];
                
                node = [[DFEvaluatorFunctionNode alloc] init];
                node.name = functionName;
                node.selector = NSSelectorFromString([NSString stringWithFormat:@"%@:", functionName]);
                
                [functionNodes addObject:node];
            }
            
            NSString *c = [expression substringWithRange:(NSRange){location, 1}];
            if([c isEqualToString:@"("])
            {
                count ++;
            }
            else if([c isEqualToString:@")"])
            {
                count --;
                if(count == 0)
                {
                    node.paramExpression = paramExpression;
                    node.functionInvoke = [NSString stringWithFormat:@"%@(%@)", functionName, paramExpression];
                    
                    range = [expression rangeOfRegex:@"[\\W]?[\\w]+\\(" inRange:NSMakeRange(location+1, expression.length - location-1)];
                    if(range.length > 0)
                    {
                        location = range.location + range.length;
                        continue;
                    }
                    else
                    {
                        break;
                    }
                }
            }
            
            [paramExpression appendString:c];
            location ++;
        }
        return functionNodes;
    }
    return nil;
}

/**
 *  解析自定函数传入的参数
 *
 *  @param params 自定义函数传入的参数集
 *
 *  @return 所有匹配结果
 */
- (id)decodeCustomFunctionParams:(NSString *)params
{
    if([DFEvaluatorNode isString:params])
    {
        return [params stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    }
    
    if([DFEvaluatorNode isNumerics:params])
    {
        return [NSString stringWithFormat:@"%@", @([params doubleValue])];
    }
    
    NSMutableArray *arguments = [NSMutableArray array]; // 一维元素
    NSString *tempStr = nil;
    if([params rangeOfRegex:@"\\[(.*?)\\]"].length > 0) // 二维参数集
    {
        NSMutableArray *subArguments; // 二维元素
        NSArray *arr = [params componentsSeparatedByRegex:@"\\s*,\\s*"];
        
        BOOL forSub = false; // 是二维元素
        for(NSString *str in arr)
        {
            tempStr = str;
            
            if([tempStr rangeOfRegex:@"^\\["].length > 0)
            {
                subArguments = [NSMutableArray array];
                [arguments addObject:subArguments];
                
                if([tempStr rangeOfRegex:@"\\]$"].length)
                {
                    tempStr = [tempStr stringByReplacingOccurrencesOfRegex:@"^\\[|\\]$" withString:@""];
                    if(![DFEvaluatorNode isString:tempStr] && ![DFEvaluatorNode isNumerics:tempStr])
                    {
                        tempStr = [self calcExpression:[self parseExpression:tempStr]];
                    }
                    tempStr = [tempStr stringByReplacingOccurrencesOfRegex:@"^\"|\"$" withString:@""];
                    [subArguments addObject:tempStr];
                    continue;
                }
                tempStr = [tempStr stringByReplacingOccurrencesOfRegex:@"^\\[" withString:@""];
                forSub = true;
            }
            if([tempStr rangeOfRegex:@"\\]$"].length > 0)
            {
                tempStr = [tempStr stringByReplacingOccurrencesOfRegex:@"\\]$" withString:@""];
                if(![DFEvaluatorNode isString:tempStr] && ![DFEvaluatorNode isNumerics:tempStr])
                {
                    tempStr = [self calcExpression:[self parseExpression:tempStr]];
                }
                tempStr = [tempStr stringByReplacingOccurrencesOfRegex:@"^\"|\"$" withString:@""];
                [subArguments addObject:tempStr];
                continue;
                
                forSub = false;
            }
            
            if(![DFEvaluatorNode isString:tempStr] && ![DFEvaluatorNode isNumerics:tempStr])
            {
                tempStr = [self calcExpression:[self parseExpression:tempStr]];
            }
            tempStr = [tempStr stringByReplacingOccurrencesOfRegex:@"^\"|\"$" withString:@""];
            if(forSub)
            {
                [subArguments addObject:tempStr];
            }
            else
            {
                [arguments addObject:tempStr];
            }
        }
    }
    else // 一维多参数
    {
        NSArray *arr = [params componentsSeparatedByRegex:@"\\s*,\\s*"];
        
        for(NSString *str in arr)
        {
            tempStr = str;
            if(![DFEvaluatorNode isString:tempStr] && ![DFEvaluatorNode isNumerics:tempStr])
            {
                tempStr = [self calcExpression:[self parseExpression:tempStr]];
            }
            [arguments addObject:[tempStr stringByReplacingOccurrencesOfRegex:@"^\"|\"$" withString:@""]]; // 字符串参数脱引号
        }
    }
    return arguments;
}

- (double)getNumerics:(NSString *)expression forFunction:(NSString *)functionName
{
    NSString *tempExpression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    if(![DFEvaluatorNode isNumerics:tempExpression])
    {
        tempExpression = [self calcExpression:[self parseExpression:tempExpression]];
    }
    if(![DFEvaluatorNode isNumerics:tempExpression])
    {
        NSString *message = [NSString stringWithFormat:@"Error：\n在表达式中函数”%@(%@)“传入的参数”%@“不是数值", functionName, expression, expression];
        NSAssert(false, message);
    }
    
    return [tempExpression doubleValue];
}


#pragma mark - 数学计算
/**
 *  将算术表达式转换为逆波兰表达式
 *  @param expression 要计算的表达式,如"1+2+3+4"
 */
- (NSMutableArray *)parseExpression:(NSString *)expression
{
    if ([expression isKindOfClass:[NSNull class]] || expression.length == 0)
    {
        return [NSMutableArray array];
    }
    
    NSMutableArray *listOperator = [NSMutableArray array]; // 后缀表达式，操作符和操作数根据优先级以中间堆成的形式排列
    DFEvaluatorStack *stackOperator = [DFEvaluatorStack new]; // 栈的形式临时存储操作符
    
    DFEvaluatorParser *expParser = [[DFEvaluatorParser alloc] initWithExpression:expression];
    DFEvaluatorNode *beforeExpNode = nil;       //前一个节点
    DFEvaluatorNode *unitaryNode = nil;         //一元操作符
    DFEvaluatorNode *expNode; // 当前遍历节点
    bool requireOperand = false; // 是否需要操作数
    
    while ((expNode = [expParser readNode]) != nil)
    {
        if(expNode.type == Numeric || expNode.type == String || expNode.type == Datetime) // 是操作数
        {
            if(unitaryNode != nil)
            {
                // 设置一元操作符节点
                expNode.unitaryNode = unitaryNode;
                unitaryNode = nil;
            }
            // 操作数，直接加入后缀表达式中
            [listOperator addObject:expNode];
            requireOperand = false;
        }
        else if (expNode.type == LParentheses) // 是左括号 (
        {
            // 左括号， 直接加入操作符栈
            [stackOperator push:expNode];
        }
        else if (expNode.type == RParentheses) // 是右括号 )
        {
            // 右括号则在操作符栈中反向搜索，直到遇到匹配的左括号为止，将中间的操作符依次加到后缀表达式中。
            DFEvaluatorNode *lpNode = nil;
            while(stackOperator.stackLength > 0)
            {
                lpNode = [stackOperator popObject];
                if(lpNode.type == LParentheses)
                {
                    break;
                }
                [listOperator addObject:lpNode];
            }
            if (lpNode == nil || lpNode.type != LParentheses)
            {
                NSString *message = [NSString stringWithFormat:@"Error：\n在表达式“%@”中括号不匹配，丢失左括号", expParser.expression]; // 中没有与第%ld个字符\")\"匹配的\"(\"字符!, expParser.position
                NSAssert(false, message);
            }
        }
        else // 是运算符
        {
            if(stackOperator.stackLength == 0) // 没有临时操作符
            {
                if (listOperator.count == 0) // 没有操作数，即表达式的第一个节点
                {
                    // 后缀表达式没有任何数据则判断是否是一元操作数
                    if ([DFEvaluatorNode isUnitaryNode:expNode.type]) // 是正号+或者符号- 
                    {
                        unitaryNode = expNode;
                    }
                    else if (expNode.type == Not) // 是取反符号
                    {
                        [stackOperator push:expNode];
                    }
                    else
                    {
                        NSString *message = [NSString stringWithFormat:@"Error：\n表达式“%@”在第%ld个字符位置缺少操作数", expParser.expression, expParser.position-1];
                        NSAssert(false, message);
                    }
                }
                else // 已经有操作数，或者第一个是左括号(或取反!
                {
                    [stackOperator push:expNode];
                }
                requireOperand = true; // 下一个节点需要操作数
            }
            else
            {
                if(requireOperand) // 碰到连续运算符
                {
                    if ([DFEvaluatorNode isUnitaryNode:expNode.type] && unitaryNode == nil) // 如果"+","-"号(算作有符号数)
                    {
                        unitaryNode = expNode; // 预备给操作数加符号
                    }
                    else if(expNode.type == Not) // 如果是取反号，把取反号入栈
                    {
                        [stackOperator push:expNode];
                    }
                    else
                    {
                        NSString *message = [NSString stringWithFormat:@"Error：\n表达式“%@”在第%ld个字符位置缺少操作数", expParser.expression, expParser.position-1];
                        NSAssert(false, message);
                    }
                }
                else
                {
                    do // 对前面的所有操作符进行优先级比较
                    {
                        beforeExpNode = [stackOperator topObject]; // 取得上一次的操作符
                        
                        // 如果前一个操作符优先级较高，则将前一个操作符加入后缀表达式中
                        if (beforeExpNode.type != LParentheses && (beforeExpNode.pri - expNode.pri) >= 0)
                        {
                            [listOperator addObject:[stackOperator popObject]];
                        }
                        else
                        {
                            break;
                        }
                    } while (stackOperator.stackLength > 0);
                    
                    // 将操作符压入操作符栈
                    [stackOperator push:expNode];
                    requireOperand = true;
                }
            }
        }
    }
    if (requireOperand)
    {
        // 丢失操作数
        NSString *message = [NSString stringWithFormat:@"Error：\n表达式“%@”在第%ld个字符位置缺少操作数", expParser.expression, expParser.position-1];
        NSAssert(false, message);
    }
    // 清空堆栈
    while (stackOperator.stackLength > 0)
    {
        // 取得操作符
        beforeExpNode = [stackOperator popObject];
        if (beforeExpNode.type == LParentheses)
        {
            NSString *message = [NSString stringWithFormat:@"Error：\n表达式“%@”中括号不匹配，丢失右括号", expParser.expression];
            NSAssert(false, message);
        }
        [listOperator addObject:beforeExpNode];
    }
    return listOperator;
}

/**
 *  对逆波兰表达式进行计算 (values 压栈，出栈)
 */
- (id)calcExpression:(NSMutableArray *)nodes
{
    if ([nodes isKindOfClass:[NSNull class]] || nodes.count == 0)
    {
        return nil;
    }
    if(nodes.count > 1)
    {
        int index = 0;
        // 储存数据
        DFEvaluatorStack *values = [DFEvaluatorStack new];
        while(index < nodes.count)
        {
            DFEvaluatorNode *node = nodes[index];
            
            switch (node.type)
            {
                case Numeric:
                case String:
                case Datetime:
                    [values push:node.numeric]; // 是操作数则压入 values 栈中
                    index++;
                    break;
                default: // 操作符
                {
                    NSInteger paramCount = 2; // 操作符需要操作数个数，一般二元表达式需要二个参数
                    if (node.type == Not)
                    {
                        paramCount = 1; // 如果是Not的话，则只要一个参数
                    }
                    
                    if (values.stackLength < paramCount)
                    {
                        NSAssert(false, @"Error：\n缺少操作数");
                    }
                    
                    // 在 values 栈中取操作数存入data，作为参数用于真正的计算
                    NSMutableArray *data = [NSMutableArray array];
                    for (int i = 0; i < paramCount; i++)
                    {
                        [data insertObject:[values popObject] atIndex:0]; // 反序插入，栈顶存的是被操作数
                    }
                    
                    // 将计算结果再存入当前节点
                    node.numeric = [self calculate:node.type objects:data];
                    node.type = Numeric; // 设置运算结果的类型，三种操作数类型的任意一种均可，目的在于在下一次遍历时能压入 values 栈中
                    
                    // 将原始的操作数节点删除
                    for (int i = 0; i < paramCount; i++)
                    {
                        [nodes removeObjectAtIndex:(index - i - 1)];
                    }
                    index -= paramCount;
                }
                    break;
            }
        }
    }
    
    if (nodes.count == 1)
    {
        DFEvaluatorNode *node = nodes[0];
        switch(node.type)
        {
            case Numeric:
            {
                return node.numeric;
            }
                
            case String:
            case Datetime:
            {
                return [[node.numeric stringByReplacingOccurrencesOfRegex:@"^\"" withString:@""]
                        stringByReplacingOccurrencesOfRegex:@"\"$" withString:@""];
            }
                
            default:
            {
                NSAssert(false, @"Error：\n缺少操作数");
            }
        }
    }
    else
    {
        NSAssert(false, @"Error：\n缺少操作符或操作数");
    }
    return nil;
}

/**
 *  计算节点的值
 *  @param nodeType 节点的类型
 *  @param data 要计算的值,有可能是两位或一位数
 */
- (NSString *)calculate:(DFEvaluatorNodeType)nodeType objects:(NSArray *)data
{
    NSString *ops1 = [NSString stringWithFormat:@"%@", [data firstObject]];
    NSString *ops2 = [NSString stringWithFormat:@"%@", [data lastObject]];
    
    NSString *dateString1;
    NSString *dateString2;
    NSDate *dt1;
    NSDate *dt2;
    double result;
    BOOL b1;
    BOOL b2;
    BOOL isString = [DFEvaluatorNode isString:ops1] || [DFEvaluatorNode isString:ops2];
    BOOL isDatetime = [DFEvaluatorNode isDatetime:ops1] || [DFEvaluatorNode isDatetime:ops2];
    
    // 对日期处理
    if(isDatetime)
    {
        dateString1 = [ops1 stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        dateString2 = [ops2 stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        
        dt1 = [_dateFormatter dateFromString:dateString1];
        dt2 = [_dateFormatter dateFromString:dateString2];
    }
    
    switch (nodeType)
    {
        case Plus: // 加
        {
            if(isString || isDatetime)
            {
                NSString *str1 = [[[NSString stringWithFormat:@"%@", ops1] stringByReplacingOccurrencesOfRegex:@"^\"" withString:@""] stringByReplacingOccurrencesOfRegex:@"\"$" withString:@""];
                NSString *str2 = [[[NSString stringWithFormat:@"%@", ops2] stringByReplacingOccurrencesOfRegex:@"^\"" withString:@""] stringByReplacingOccurrencesOfRegex:@"\"$" withString:@""];
                return [NSString stringWithFormat:@"\"%@%@\"", str1, str2];
            }
            result = [self convertToDecimal:ops1] + [self convertToDecimal:ops2];
            break;
        }
            
        case Subtract: // 减
        {
            if(isString || isDatetime)
            {
                NSString *str1 = [[NSString stringWithFormat:@"%@", ops1] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                NSString *str2 = [[NSString stringWithFormat:@"%@", ops2] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                NSString *resultString = [str1 stringByReplacingOccurrencesOfString:str2 withString:@""];
                return [NSString stringWithFormat:@"\"%@\"", resultString];
            }
            result = [self convertToDecimal:ops1] - [self convertToDecimal:ops2];
            break;
        }
            
        case MultiPly: // 乘
        {
            result = [self convertToDecimal:ops1] * [self convertToDecimal:ops2];
            if(fabs(result) == 0)
            {
                result = fabs(result);
            }
            break;
        }
            
        case Divide: // 除
        {
            if([self convertToDecimal:ops2] == 0)
            {
                NSAssert(false, @"Error：\n被除数为0");
            }
            result = [self convertToDecimal:ops1] / [self convertToDecimal:ops2];
            if(fabs(result) == 0)
            {
                result = fabs(result);
            }
            break;
        }
            
        case Power: // 次幂
        {
            result = pow([self convertToDecimal:ops1], [self convertToDecimal:ops2]);
            break;
        }
            
        case Mod: // 求模，取余
        {
            if([self convertToDecimal:ops2] == 0)
            {
                NSAssert(false, @"Error：\n被除数为0");
            }
            return [NSString stringWithFormat:@"%ld", (NSInteger)[self convertToDecimal:ops1] % (NSInteger)[self convertToDecimal:ops2]];
        }
            
        case BitwiseAnd: // 按位与
        {
            result = (NSInteger)[self convertToDecimal:ops1] & (NSInteger)[self convertToDecimal:ops2];
            return [NSString stringWithFormat:@"%ld", (NSInteger)result];
        }
            
        case BitwiseOr: // 按位或
        {
            result = (NSInteger)[self convertToDecimal:ops1] | (NSInteger)[self convertToDecimal:ops2];
            return [NSString stringWithFormat:@"%ld", (NSInteger)result];
        }
            
        case And: // 逻辑与
        {
            b1 = [self convertToBool:ops1];
            b2 = [self convertToBool:ops2];
            return [NSString stringWithFormat:@"%d", b1 && b2];
        }
            
        case Or: // 逻辑或
        {
            if(isDatetime)
            {
                if(dt1 != nil) // 所有非数值对象传入，为空时都传0
                {
                    return dateString1;
                }
                else if(dt2 != nil)
                {
                    return dateString2;
                }
                else
                {
                    return @"0";
                }
            }
            else if(isString)
            {
                if(([ops1 rangeOfString:@"\""].length > 0 && ops1.length > 2) || [ops1 boolValue])
                {
                    return [ops1 stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                }
                else if(([ops2 rangeOfString:@"\""].length > 0 && ops2.length > 2) || [ops2 boolValue])
                {
                    return [ops2 stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                }
                return @"0";
            }
            else
            {
                if([self convertToBool:ops1])
                {
                    result = [self convertToDecimal:ops1];
                }
                else if([self convertToBool:ops2])
                {
                    result = [self convertToDecimal:ops2];
                }
                else
                {
                    return @"0";
                }
                break;
            }
        }
            
        case Not: // 逻辑非
        {
            return [NSString stringWithFormat:@"%d", ![self convertToBool:ops1]];
        }
            
        case Equal: // 相等
        {
            if (isDatetime)
            {
                return [NSString stringWithFormat:@"%d", [dt1 isEqualToDate:dt2]];
            }
            else if (isString)
            {
                return [NSString stringWithFormat:@"%d", [ops1 isEqualToString:ops2]];
            }
            else
            {
                return [NSString stringWithFormat:@"%d", [self convertToDecimal:ops1] == [self convertToDecimal:ops2]];
            }
        }
            
        case Unequal: // 不等于
        {
            if (isDatetime)
            {
                return [NSString stringWithFormat:@"%d", ![dt1 isEqualToDate:dt2]];
            }
            else if (isString)
            {
                return [NSString stringWithFormat:@"%d", ![ops1 isEqualToString:ops2]];
            }
            else
            {
                return [NSString stringWithFormat:@"%d", [self convertToDecimal:ops1] != [self convertToDecimal:ops2]];
            }
        }
            
        case GT: // 大于
        {
            if (isDatetime)
            {
                NSComparisonResult result = [dt1 compare:dt2];
                if(result == NSOrderedDescending)
                {
                    return @"1";
                }
                return @"0";
            }
            else if(isString)
            {
                return [NSString stringWithFormat:@"%d", [self convertToDecimal:[ops1 stringByReplacingOccurrencesOfString:@"\"" withString:@""]] > [self convertToDecimal:[ops2 stringByReplacingOccurrencesOfString:@"\"" withString:@""]]];
            }
            else
            {
                return [NSString stringWithFormat:@"%d", [self convertToDecimal:ops1] > [self convertToDecimal:ops2]];
            }
        }
            
        case LT: // 小于
        {
            if (isDatetime)
            {
                NSComparisonResult result = [dt1 compare:dt2];
                if(result == NSOrderedAscending)
                {
                    return @"1";
                }
                return @"0";
            }
            else if(isString)
            {
                return [NSString stringWithFormat:@"%d", [self convertToDecimal:[ops1 stringByReplacingOccurrencesOfString:@"\"" withString:@""]] < [self convertToDecimal:[ops2 stringByReplacingOccurrencesOfString:@"\"" withString:@""]]];
            }
            else
            {
                return [NSString stringWithFormat:@"%d", [self convertToDecimal:ops1] < [self convertToDecimal:ops2]];
            }
        }
            
        case GTOrEqual: // 大于等于
        {
            if (isDatetime)
            {
                NSComparisonResult result = [dt1 compare:dt2];
                if(result == NSOrderedDescending || result == NSOrderedSame)
                {
                    return @"1";
                }
                return @"0";
            }
            else if(isString)
            {
                return [NSString stringWithFormat:@"%d", [self convertToDecimal:[ops1 stringByReplacingOccurrencesOfString:@"\"" withString:@""]] >= [self convertToDecimal:[ops2 stringByReplacingOccurrencesOfString:@"\"" withString:@""]]];
            }
            else
            {
                return [NSString stringWithFormat:@"%d", [self convertToDecimal:ops1] >= [self convertToDecimal:ops2]];
            }
        }
            
        case LTOrEqual: // 小于等于
        {
            if (isDatetime)
            {
                NSComparisonResult result = [dt1 compare:dt2];
                if(result == NSOrderedAscending || result == NSOrderedSame)
                {
                    return @"1";
                }
                return @"0";
            }
            else if(isString)
            {
                return [NSString stringWithFormat:@"%d", [self convertToDecimal:[ops1 stringByReplacingOccurrencesOfString:@"\"" withString:@""]] <= [self convertToDecimal:[ops2 stringByReplacingOccurrencesOfString:@"\"" withString:@""]]];
            }
            else
            {
                return [NSString stringWithFormat:@"%d", [self convertToDecimal:ops1] <= [self convertToDecimal:ops2]];
            }
        }
            
        case LShift: // 左移位
        {
            return [NSString stringWithFormat:@"%lu", (long)[self convertToDecimal:ops1] <<
                    (int)[self convertToDecimal:ops2]];
        }
            
        case RShift: // 右移位
        {
            return [NSString stringWithFormat:@"%lu", (long)[self convertToDecimal:ops1] >>
                    (int)[self convertToDecimal:ops2]];
        }
            
        default:
        {
            return 0;
        }
    }
    return [NSString stringWithFormat:@"%@", @(result)];
}

/**
 *  将某个值转换为bool值
 */
- (BOOL)convertToBool:(NSString *)value
{
    if(![DFEvaluatorNode isBool:value])
    {
        NSAssert(false, @"Error：\n操作数不是布尔值");
    }
    return [value boolValue];
}

/**
 *  将某个值转换为decimal值
 */
- (double)convertToDecimal:(NSString *)value
{
    value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    if(![DFEvaluatorNode isNumerics:value])
    {
        NSString *message = [NSString stringWithFormat:@"Error：\n操作数“%@”不是数值", value];
        NSAssert(false, message);
    }
    return [value doubleValue];
}


#pragma mark - 三目运算的实现
- (NSString *)ternaryOperation:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    NSArray *arr = [expression componentsSeparatedByRegex:@"\\s*,\\s*"];
    if(arr.count != 3)
    {
        NSString *message = [NSString stringWithFormat:@"Error：\n在表达式中函数”ternaryOperation(%@)“传入的参数”%@“不合法", expression, expression];
        NSAssert(false, message);
    }
    
    NSString *formulation = [arr firstObject];
    BOOL ok = [[self calcExpression:[self parseExpression:formulation]] boolValue]; // 计算条件是否成立
    formulation = arr[1]; // 如果条件成立
    if(!ok) // 如果条件不成立
    {
        formulation = [arr lastObject]; // 截取条件成立时的对应操作
    }
    
    if(([formulation rangeOfRegex:@"^\""].length  &&
        [formulation rangeOfRegex:@"\"$"].length)||
       [DFEvaluatorNode isNumerics:formulation]) // 如果formulation是字符串或者数值，可以结束计算直接返回字符串
    {
        return formulation;
    }
    
    return [self calcExpression:[self parseExpression:formulation]];
}


#pragma mark - 时间相关的OC实现
/**
 *  计算时间差
 *
 *  @param expression 参数字符串，结构必须为“差值类型, 较早日期, 较晚日期”
 *  差值类型有：
 *          "dd" 天数
 *          "ww" 周数
 *          "mm" 月数
 *          "qq" 季度数
 *          "yy" 年数
 *          "hh" 小时数
 *          "mi" 分钟数
 *          "ss" 秒钟数
 *
 *  @return 差值结果
 */
- (NSString *)dateDiff:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    NSArray *arr = [[expression stringByReplacingOccurrencesOfString:@"\"" withString:@""]
                    componentsSeparatedByRegex:@"\\s*,\\s*"];
    NSString *message = [NSString stringWithFormat:@"Error：\n在表达式中函数“DateDiff(差值类型, 较早日期, 较晚日期)”参数组（%@）中\n", expression];
    if(arr.count != 3)
    {
        message = [message stringByAppendingString:@"参数个数不匹配"];
        NSAssert(false, message);
    }
    
    NSString *type = arr[0];
    NSString *dateString1 = arr[1];
    NSString *dateString2 = arr[2];
    
    // 获取日期
    NSDate *date1 = [_dateFormatter dateFromString:dateString1];
    NSDate *date2 = [_dateFormatter dateFromString:dateString2];
    
    if(date1 == nil || date2 == nil)
    {
        message = [message stringByAppendingFormat:@"【较早日期】“%@”或者【较晚日期】“%@”无法得到正确的日期数据", arr[1], arr[2]];
        NSAssert(false, message);
    }
    
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    
    if([type isEqualToString:@"dd"]) // 日
    {
        NSInteger day1 = [calendar ordinalityOfUnit:NSDayCalendarUnit
                                             inUnit:NSEraCalendarUnit
                                            forDate:date1];
        NSInteger day2 = [calendar ordinalityOfUnit:NSDayCalendarUnit
                                             inUnit:NSEraCalendarUnit
                                            forDate:date2];
        return [NSString stringWithFormat:@"%ld", day2 - day1];
    }
    else if([type isEqualToString:@"ww"]) // 周
    {
        NSInteger ww1 = [calendar ordinalityOfUnit:NSWeekCalendarUnit
                                            inUnit:NSEraCalendarUnit
                                           forDate:date1];
        NSInteger ww2 = [calendar ordinalityOfUnit:NSWeekCalendarUnit
                                            inUnit:NSEraCalendarUnit
                                           forDate:date2];
        return [NSString stringWithFormat:@"%ld", ww2 - ww1];
    }
    else if([type isEqualToString:@"mm"]) // 月
    {
        NSInteger mm1 = [calendar ordinalityOfUnit:NSMonthCalendarUnit
                                            inUnit:NSEraCalendarUnit
                                           forDate:date1];
        NSInteger mm2 = [calendar ordinalityOfUnit:NSMonthCalendarUnit
                                            inUnit:NSEraCalendarUnit
                                           forDate:date2];
        return [NSString stringWithFormat:@"%ld", mm2 - mm1];
    }
    else if([type isEqualToString:@"qq"]) // 季度
    {
        NSInteger qq1 = [calendar ordinalityOfUnit:NSQuarterCalendarUnit
                                            inUnit:NSEraCalendarUnit
                                           forDate:date1];
        NSInteger qq2 = [calendar ordinalityOfUnit:NSQuarterCalendarUnit
                                            inUnit:NSEraCalendarUnit
                                           forDate:date2];
        return [NSString stringWithFormat:@"%ld", qq2 - qq1];
    }
    else if([type isEqualToString:@"yy"]) // 年
    {
        NSInteger yy1 = [calendar ordinalityOfUnit:NSYearCalendarUnit
                                            inUnit:NSEraCalendarUnit
                                           forDate:date1];
        NSInteger yy2 = [calendar ordinalityOfUnit:NSYearCalendarUnit
                                            inUnit:NSEraCalendarUnit
                                           forDate:date2];
        return [NSString stringWithFormat:@"%ld", yy2 - yy1];
    }
    else if([type isEqualToString:@"hh"]) // 小时
    {
        NSInteger hh1 = [calendar ordinalityOfUnit:NSHourCalendarUnit
                                            inUnit:NSEraCalendarUnit
                                           forDate:date1];
        NSInteger hh2 = [calendar ordinalityOfUnit:NSHourCalendarUnit
                                            inUnit:NSEraCalendarUnit
                                           forDate:date2];
        return [NSString stringWithFormat:@"%ld", hh2 - hh1];
    }
    else if([type isEqualToString:@"mi"]) // 分
    {
        NSInteger mi1 = [calendar ordinalityOfUnit:NSMinuteCalendarUnit
                                            inUnit:NSEraCalendarUnit
                                           forDate:date1];
        NSInteger mi2 = [calendar ordinalityOfUnit:NSMinuteCalendarUnit
                                            inUnit:NSEraCalendarUnit
                                           forDate:date2];
        return [NSString stringWithFormat:@"%ld", mi2 - mi1];
    }
    else if([type isEqualToString:@"ss"]) // 秒
    {
        NSInteger ss1 = [calendar ordinalityOfUnit:NSSecondCalendarUnit
                                            inUnit:NSEraCalendarUnit
                                           forDate:date1];
        NSInteger ss2 = [calendar ordinalityOfUnit:NSSecondCalendarUnit
                                            inUnit:NSEraCalendarUnit
                                           forDate:date2];
        return [NSString stringWithFormat:@"%ld", ss2 - ss1];
    }
    else
    {
        message = [message stringByAppendingFormat:@"【差值类型】“%@”不合法，请参考：\n“dd” 天数差\n“ww” 周数差\n“mm” 月数差\n“qq” 季度数差\n“yy” 年数差\n“hh” 小时数差\n“mi” 分钟数差\n“ss” 秒钟数差", arr[0]];
        NSAssert(false, message);
    }
    return nil;
}

/**
 *  获取年份
 *  @param expression 传入时间表达式
 *  @return 年份
 */
- (NSString *)getYear:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    expression = [expression stringByReplacingOccurrencesOfRegex:@"\"" withString:@""];
    
    NSDate *date = [_dateFormatter dateFromString:expression];
    if(date == nil)
    {
        NSString *message = [NSString stringWithFormat:@"Error：\n在表达式中函数“getYear(日期)”输入的【日期】参数“%@“是一个无法识别的日期数据", expression];
        NSAssert(false, message);
    }
    
    return [NSString stringWithFormat:@"%ld", [[NSCalendar autoupdatingCurrentCalendar] ordinalityOfUnit:NSYearCalendarUnit
                                                                                                  inUnit:NSEraCalendarUnit
                                                                                                 forDate:date]];
}

/**
 *  获取第几季度
 *  @param expression 传入时间表达式
 *  @return 第几季度
 */
- (NSString *)getQuarter:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    expression = [expression stringByReplacingOccurrencesOfRegex:@"\"" withString:@""];
    
    NSDate *date = [_dateFormatter dateFromString:expression];
    if(date == nil)
    {
        NSString *message = [NSString stringWithFormat:@"Error：\n在表达式中函数”getQuarter(日期)“输入的【日期】参数“%@“是一个无法识别的日期数据", expression];
        NSAssert(false, message);
    }

    return [NSString stringWithFormat:@"%ld", [[NSCalendar autoupdatingCurrentCalendar] ordinalityOfUnit:NSQuarterCalendarUnit
                                                                                                  inUnit:NSYearCalendarUnit
                                                                                                 forDate:date]];
}

/**
 *  获取中文第几季度
 *  @param expression 传入时间表达式
 *  @return 中文第几季度
 */
- (NSString *)getLocalQuarter:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    expression = [expression stringByReplacingOccurrencesOfRegex:@"\"" withString:@""];
    
    NSDate *date = [_dateFormatter dateFromString:expression];
    if(date == nil)
    {
        NSString *message = [NSString stringWithFormat:@"Error：\n在表达式中函数”getLocalQuarter(日期)“输入的【日期】参数“%@“是一个无法识别的日期数据", expression];
        NSAssert(false, message);
    }
    
    NSDateFormatter *quarterOnly = [[NSDateFormatter alloc] init];
    [quarterOnly setDateFormat:@"Q"];
    NSArray *arr = @[@"一",
                     @"二",
                     @"三",
                     @"四"];
    return [NSString stringWithFormat:@"\"第%@季度\"", arr[[[NSCalendar autoupdatingCurrentCalendar] ordinalityOfUnit:NSQuarterCalendarUnit
                                                                                                          inUnit:NSYearCalendarUnit
                                                                                                         forDate:date]-1]];
}

/**
 *  获取月份
 *  @param expression 传入时间表达式
 *  @return 月份
 */
- (NSString *)getMonth:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    expression = [expression stringByReplacingOccurrencesOfRegex:@"\"" withString:@""];
    
    NSDate *date = [_dateFormatter dateFromString:expression];
    if(date == nil)
    {
        NSString *message = [NSString stringWithFormat:@"Error：\n在表达式中函数”getMonth(日期)“输入的【日期】参数“%@“是一个无法识别的日期数据", expression];
        NSAssert(false, message);
    }
    
    return [NSString stringWithFormat:@"%ld", [[NSCalendar autoupdatingCurrentCalendar] ordinalityOfUnit:NSMonthCalendarUnit
                                                                                                  inUnit:NSYearCalendarUnit
                                                                                                 forDate:date]];
}

/**
 *  获取中文月份
 *  @param expression 传入时间表达式
 *  @return 中文月份
 */
- (NSString *)getLocalMonth:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    expression = [expression stringByReplacingOccurrencesOfRegex:@"\"" withString:@""];
    
    NSDate *date = [_dateFormatter dateFromString:expression];
    if(date == nil)
    {
        NSString *message = [NSString stringWithFormat:@"Error：\n在表达式中函数”getLocalMonth(日期)“输入的【日期】参数“%@“是一个无法识别的日期数据", expression];
        NSAssert(false, message);
    }
    
    NSArray *arr = @[@"一",
                     @"二",
                     @"三",
                     @"四",
                     @"五",
                     @"六",
                     @"七",
                     @"八",
                     @"九",
                     @"十",
                     @"十一",
                     @"十二"];
    return [NSString stringWithFormat:@"\"%@月份\"", arr[[[NSCalendar autoupdatingCurrentCalendar] ordinalityOfUnit:NSMonthCalendarUnit
                                                                                                        inUnit:NSYearCalendarUnit
                                                                                                       forDate:date]-1]];
}

/**
 *  获取日
 *  @param expression 传入时间表达式
 *  @return 日
 */
- (NSString *)getDay:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    expression = [expression stringByReplacingOccurrencesOfRegex:@"\"" withString:@""];
    
    NSDate *date = [_dateFormatter dateFromString:expression];
    if(date == nil)
    {
        NSString *message = [NSString stringWithFormat:@"Error：\n在表达式中函数“getMonth(日期)“输入的【日期】参数“%@“是一个无法识别的日期数据", expression];
        NSAssert(false, message);
    }
    
    return [NSString stringWithFormat:@"%ld", [[NSCalendar autoupdatingCurrentCalendar] ordinalityOfUnit:NSDayCalendarUnit
                                                                                                  inUnit:NSMonthCalendarUnit
                                                                                                 forDate:date]];
}

/**
 *  获取日
 *  @param expression 表达式
 *  @return 日
 */
- (NSString *)getLocalDay:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    expression = [expression stringByReplacingOccurrencesOfRegex:@"\"" withString:@""];
    
    NSDate *date = [_dateFormatter dateFromString:expression];
    if(date == nil)
    {
        NSString *message = [NSString stringWithFormat:@"Error：\n在表达式中函数”getMonth(日期)“输入的【日期】参数“%@“是一个无法识别的日期数据", expression];
        NSAssert(false, message);
    }
    NSArray *localDay = @[@"一",
                         @"二",
                         @"三",
                         @"四",
                         @"五",
                         @"六",
                         @"七",
                         @"八",
                         @"九",
                         @"十",
                         @"十一",
                         @"十二",
                         @"十三",
                         @"十四",
                         @"十五",
                         @"十六",
                         @"十七",
                         @"十八",
                         @"十九",
                         @"廿",
                         @"廿一",
                         @"廿二",
                         @"廿三",
                         @"廿四",
                         @"廿五",
                         @"廿六",
                         @"廿七",
                         @"廿吧",
                         @"廿九",
                         @"卅",
                         @"卅一"];
    return [NSString stringWithFormat:@"\"%@日\"", localDay[[[NSCalendar autoupdatingCurrentCalendar] ordinalityOfUnit:NSDayCalendarUnit
                                                                                                            inUnit:NSMonthCalendarUnit
                                                                                                           forDate:date]-1]];
}

/**
 *  第几周
 *  @param expression 表达式
 *  @return 第几周
 */
- (NSString *)getWeek:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    expression = [expression stringByReplacingOccurrencesOfRegex:@"\"" withString:@""];
    
    NSDate *date = [_dateFormatter dateFromString:expression];
    if(date == nil)
    {
        NSString *message = [NSString stringWithFormat:@"Error：\n在表达式中函数“getWeek(日期)“输入的【日期】参数“%@“是一个无法识别的日期数据", expression];
        NSAssert(false, message);
    }
    
    return [NSString stringWithFormat:@"%ld", [[NSCalendar autoupdatingCurrentCalendar] ordinalityOfUnit:NSWeekCalendarUnit
                                                                                                  inUnit:NSYearCalendarUnit
                                                                                                 forDate:date]];
}

/**
 *  获得中文的第几周
 *  @param expression 表达式
 *  @return 返回当前中文第几周
 */
- (NSString *)getLocalWeek:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    expression = [expression stringByReplacingOccurrencesOfRegex:@"\"" withString:@""];
    
    NSDate *date = [_dateFormatter dateFromString:expression];
    if(date == nil)
    {
        NSString *message = [NSString stringWithFormat:@"Error：\n在表达式中函数”getLocalWeek(日期)“输入的【日期】参数“%@“是一个无法识别的日期数据", expression];
        NSAssert(false, message);
    }
    NSArray *cnDigitArr = @[@"一",
                            @"二",
                            @"三",
                            @"四",
                            @"五",
                            @"六",
                            @"七",
                            @"八",
                            @"九"];
    NSInteger week = [[NSCalendar autoupdatingCurrentCalendar] ordinalityOfUnit:NSWeekCalendarUnit
                                                                         inUnit:NSYearCalendarUnit
                                                                        forDate:date];
    if(week <= 10)
    {
        return [NSString stringWithFormat:@"\"第%@周\"", cnDigitArr[week-1]];
    }
    else
    {
        return [NSString stringWithFormat:@"\"第%@十%@周\"", cnDigitArr[week/10-1], cnDigitArr[week%10-1]];
    }
}

/**
 *  星期几
 *  @param expression 表达式
 *  @return 返回星期几
 */
- (NSString *)getDayOfWeek:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    expression = [expression stringByReplacingOccurrencesOfRegex:@"\"" withString:@""];
    
    NSDate *date = [_dateFormatter dateFromString:expression];
    if(date == nil)
    {
        NSString *message = [NSString stringWithFormat:@"Error：\n在表达式中函数“DayOfWeek(日期)“输入的【日期】参数“%@“是一个无法识别的日期数据", expression];
        NSAssert(false, message);
    }
    
    NSInteger weekday = ([[NSCalendar autoupdatingCurrentCalendar] ordinalityOfUnit:NSWeekdayCalendarUnit
                                                                             inUnit:NSWeekCalendarUnit
                                                                            forDate:date]+6)%7;
    if(weekday == 0)
    {
        weekday = 7;
    }
    return [NSString stringWithFormat:@"%ld", weekday];
}

/**
 *  中文星期几
 *  @param expression 表达式
 *  @return 返回中文星期几
 */
- (NSString *)getLocalDayOfWeek:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    expression = [expression stringByReplacingOccurrencesOfRegex:@"\"" withString:@""];
    
    NSDate *date = [_dateFormatter dateFromString:expression];
    if(date == nil)
    {
        NSString *message = [NSString stringWithFormat:@"Error：\n在表达式中函数”LocalDayOfWeek(日期)“输入的【日期】参数“%@“是一个无法识别的日期数据", expression];
        NSAssert(false, message);
    }
    
    NSArray *arr = @[@"天",
                     @"一",
                     @"二",
                     @"三",
                     @"四",
                     @"五",
                     @"六"];
    return [NSString stringWithFormat:@"\"星期%@\"", arr[[[NSCalendar autoupdatingCurrentCalendar] ordinalityOfUnit:NSWeekdayCalendarUnit
                                                                                                           inUnit:NSWeekCalendarUnit
                                                                                                          forDate:date]-1]];
}

/**
 *  获取现在时间
 *  @param expression 表达式
 *  @return 返回现在时间
 */
- (NSString *)now:(NSString *)expression
{
    NSDate *now = [NSDate date];
    return [NSString stringWithFormat:@"\"%@\"", [_dateFormatter stringFromDate:now]];
}


#pragma mark - 数值类处理的OC实现
/**
 *  将数值转换成大写金额
 *  @param expression 表达式
 *  @return 大写金额
 */
- (NSString *)getLocalMoney:(NSString *)expression
{
    double digit = [self getNumerics:expression forFunction:@"getLocalMoney"];
    
    NSArray *fractionArr = @[@"角", @"分"];
    NSArray *cnDigitArr = @[@"零", @"壹", @"贰", @"叁", @"肆", @"伍", @"陆", @"柒", @"捌", @"玖"];
    NSMutableArray *cnUnitArr = [NSMutableArray array];
    [cnUnitArr addObject:@[@"元", @"万", @"亿"]];
    [cnUnitArr addObject:@[@"", @"拾", @"佰", @"仟", @"万", @"拾", @"佰", @"仟", @"亿"]];
    NSInteger times[] = {4, 4, 9};
    NSString *head = digit < 0 ? @"欠" : @"";
    digit = fabs(digit);

    NSString *result;

    for(NSInteger i = 0; i < fractionArr.count; i++)
    {
        if(result == nil)
        {
            result = [[NSString stringWithFormat:@"%@%@", cnDigitArr[(NSInteger)floor(digit * 10 * pow(10, i)) % 10], fractionArr[i]]
                      stringByReplacingOccurrencesOfRegex:@"零." withString:@""];
        }
        else
        {
            result = [[NSString stringWithFormat:@"%@%@%@",result, cnDigitArr[(NSInteger)floor(digit * 10 * pow(10, i)) % 10], fractionArr[i]]
                      stringByReplacingOccurrencesOfRegex:@"零." withString:@""];
        }
    }
    if(result.length == 0)
    {
        result = @"整";
    }
    digit = floor(digit);
    for(NSInteger i = 0; i < [(NSArray *)cnUnitArr[0] count] && digit > 0; i++)
    {
        NSString *temp;
        for(NSInteger j = 0; j < [(NSArray *)cnUnitArr[1] count] && digit > 0; j++)
        {
            if(j >= times[i])
            {
                break;
            }
            if(temp == nil)
            {
                temp = [NSString stringWithFormat:@"%@%@", cnDigitArr[(NSInteger)digit % 10], cnUnitArr[1][j]];
            }
            else
            {
                temp = [NSString stringWithFormat:@"%@%@%@", cnDigitArr[(NSInteger)digit % 10], cnUnitArr[1][j], temp];
            }
            digit = floor(digit / 10);
        }
        temp = [[temp stringByReplacingOccurrencesOfRegex:@"(零.)*零$" withString:@""]
                stringByReplacingOccurrencesOfRegex:@"^$" withString:@"零"];
        result = [NSString stringWithFormat:@"%@%@%@", temp, cnUnitArr[0][i], result];
    }
    result = [[[result stringByReplacingOccurrencesOfRegex:@"(零.)*零元" withString:@"元"]
               stringByReplacingOccurrencesOfRegex:@"(零.)+" withString:@"零"]
              stringByReplacingOccurrencesOfRegex:@"^整$" withString:@"零元整"];
    return [NSString stringWithFormat:@"\"%@%@\"", head, result];
}

/**
 *  四舍五入取值
 *  @param expression 表达式
 *  @return 四舍五入的结果
 */
- (NSString *)round:(NSString *)expression
{
    double digit = [self getNumerics:expression forFunction:@"round"];
    
    return [NSString stringWithFormat:@"%ld", (NSInteger)round(digit)];
}

/**
 *  零舍一入，即取整
 *  @param expression 表达式
 *  @return 零舍一入结果
 */
- (NSString *)ceil:(NSString *)expression
{
    double digit = [self getNumerics:expression forFunction:@"ceil"];
    
    return [NSString stringWithFormat:@"%ld", (NSInteger)ceil(digit)];
}

/**
 *  向下取整
 *  @param expression 表达式
 *  @return 函数运行结果
 */
- (NSString *)trunc:(NSString *)expression
{
    double digit = [self getNumerics:expression forFunction:@"trunc"];
    
    return [NSString stringWithFormat:@"%ld", (NSInteger)trunc(digit)];
}

/**
 *  向下取整
 *  @param expression 表达式
 *  @return 函数运行结果
 */
- (NSString *)floor:(NSString *)expression
{
    double digit = [self getNumerics:expression forFunction:@"floor"];
    
    return [NSString stringWithFormat:@"%ld", (NSInteger)floor(digit)];
}

/**
 *  求绝对值
 *  @param expression 表达式
 *  @return 函数运行结果
 */
- (NSString *)abs:(NSString *)expression
{
    double digit = [self getNumerics:expression forFunction:@"abs"];
    
    return [NSString stringWithFormat:@"%@", @(fabs(digit))];
}

/**
 *  开平方
 *  @param expression 表达式
 *  @return 函数运行结果
 */
- (NSString *)sqrt:(NSString *)expression
{
    double digit = [self getNumerics:expression forFunction:@"sqrt"];
    
    return [NSString stringWithFormat:@"%@", @(sqrt(digit))];
}

/**
 *  底数为e对数
 *  @param expression 表达式
 *  @return 函数运行结果
 */
- (NSString *)log:(NSString *)expression
{
    double digit = [self getNumerics:expression forFunction:@"log"];
    
    return [NSString stringWithFormat:@"%@", @(log(digit))];
}

/**
 *  底数为e对数
 *  @param expression 表达式
 *  @return 函数运行结果
 */
- (NSString *)ln:(NSString *)expression
{
    double digit = [self getNumerics:expression forFunction:@"ln"];
    
    return [NSString stringWithFormat:@"%@", @(log(digit))];
}

/**
 *  底数为10对数
 *  @param expression 表达式
 *  @return 函数运行结果
 */
- (NSString *)log10:(NSString *)expression
{
    double digit = [self getNumerics:expression forFunction:@"log10"];
    
    return [NSString stringWithFormat:@"%@", @(log10(digit))];
}

/**
 *  底数为2对数
 *  @param expression 表达式
 *  @return 函数运行结果
 */
- (NSString *)log2:(NSString *)expression
{
    double digit = [self getNumerics:expression forFunction:@"log2"];
    
    return [NSString stringWithFormat:@"%@", @(log2(digit))];
}

/**
 *  计算 x 的 n 次方
 *  @param expression 表达式
 *  @return 函数运行结果
 */
- (NSString *)raiseToPower:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    NSArray *arr = [expression componentsSeparatedByRegex:@"\\s*,\\s*"];
    if(arr.count != 2)
    {
        NSString *message = [NSString stringWithFormat:@"Error：\n表达式中函数“raiseToPower(%@)”，传入的参数“%@”不合法", expression, expression];
        NSAssert(false, message);
    }
    
    NSNumber *x = @([self getNumerics:[arr firstObject] forFunction:@"raiseToPower"]);
    NSNumber *n = @([self getNumerics:[arr lastObject] forFunction:@"raiseToPower"]);
    
    NSArray *arguments = @[[NSExpression expressionForConstantValue:x],
                           [NSExpression expressionForConstantValue:n]];
    NSExpression *valuator = [NSExpression expressionForFunction:@"raise:toPower:" arguments:arguments];
    id result = [valuator expressionValueWithObject:nil context:nil];
    
    return [NSString stringWithFormat:@"%@", result];
}

/**
 *  求e的x次方
 *  @param expression 表达式
 *  @return 函数运行结果
 */
- (NSString *)exp:(NSString *)expression
{
    double digit = [self getNumerics:expression forFunction:@"exp"];
    
    return [NSString stringWithFormat:@"%@", @(exp(digit))];
}

/**
 *  计算 a 异或 b
 *  @param expression 表达式
 *  @return 函数运行结果
 */
- (NSString *)bitwiseXor:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    NSArray *arr = [expression componentsSeparatedByRegex:@"\\s*,\\s*"];
    if(arr.count != 2)
    {
        NSString *message = [NSString stringWithFormat:@"Error：\n表达式中函数“bitwiseXor(%@)”，传入的参数“%@”不合法", expression, expression];
        NSAssert(false, message);
    }
    
    NSNumber *x = @([self getNumerics:[arr firstObject] forFunction:@"bitwiseXor"]);
    NSNumber *n = @([self getNumerics:[arr lastObject] forFunction:@"bitwiseXor"]);
    
    NSArray *arguments = @[[NSExpression expressionForConstantValue:x],
                           [NSExpression expressionForConstantValue:n]];
    NSExpression *valuator = [NSExpression expressionForFunction:@"bitwiseXor:with:" arguments:arguments];
    id result = [valuator expressionValueWithObject:nil context:nil];
    
    return [NSString stringWithFormat:@"%@", result];
}

/**
 *  求 a 的补码
 *  @param expression 表达式
 *  @return 函数运行结果
 */
- (NSString *)onesComplement:(NSString *)expression
{
    double digit = [self getNumerics:expression forFunction:@"onesComplement"];
    
    NSArray *arguments = @[[NSExpression expressionForConstantValue:@(digit)]];
    NSExpression *valuator = [NSExpression expressionForFunction:@"onesComplement:" arguments:arguments];
    id result = [valuator expressionValueWithObject:nil context:nil];
    
    return [NSString stringWithFormat:@"%@", result];
}

/**
 *  求平均
 *  @param expression 表达式
 *  @return 函数运行结果
 */
- (NSString *)average:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    NSArray *arr = [expression componentsSeparatedByRegex:@"\\s*,\\s*"];
    NSMutableArray *numbers = [NSMutableArray array];
    
    for(NSString *str in arr)
    {
        double digit = [self getNumerics:str forFunction:@"average"];
        
        NSNumber *num = @(digit);
        [numbers addObject:num];
    }
    
    NSArray *arguments = @[[NSExpression expressionForConstantValue:numbers]];
    NSExpression *valuator = [NSExpression expressionForFunction:@"average:" arguments:arguments];
    id result = [valuator expressionValueWithObject:nil context:nil];
    
    return [NSString stringWithFormat:@"%@", result];
}

/**
 *  求和
 *  @param expression 表达式
 *  @return 函数运行结果
 */
- (NSString *)sum:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    NSArray *arr = [expression componentsSeparatedByRegex:@"\\s*,\\s*"];
    NSMutableArray *numbers = [NSMutableArray array];
    
    for(NSString *str in arr)
    {
        double digit = [self getNumerics:str forFunction:@"sum"];
        
        NSNumber *num = @(digit);
        [numbers addObject:num];
    }
    
    NSArray *arguments = @[[NSExpression expressionForConstantValue:numbers]];
    NSExpression *valuator = [NSExpression expressionForFunction:@"sum:" arguments:arguments];
    id result = [valuator expressionValueWithObject:nil context:nil];
    
    return [NSString stringWithFormat:@"%@", result];
}

/**
 *  计数
 *  @param expression 表达式
 *  @return 函数运行结果
 */
- (NSString *)count:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    NSArray *arr = [expression componentsSeparatedByRegex:@"\\s*,\\s*"];
    
    return [NSString stringWithFormat:@"%ld", [arr count]];
}

/**
 *  找最小值
 *  @param expression 表达式
 *  @return 函数运行结果
 */
- (NSString *)min:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    NSArray *arr = [expression componentsSeparatedByRegex:@"\\s*,\\s*"];
    NSMutableArray *numbers = [NSMutableArray array];
    
    for(NSString *str in arr)
    {
        double digit = [self getNumerics:str forFunction:@"min"];
        
        NSNumber *num = @(digit);
        [numbers addObject:num];
    }
    
    NSArray *arguments = @[[NSExpression expressionForConstantValue:numbers]];
    NSExpression *valuator = [NSExpression expressionForFunction:@"min:" arguments:arguments];
    id result = [valuator expressionValueWithObject:nil context:nil];
    
    return [NSString stringWithFormat:@"%@", result];
}

/**
 *  找最大值
 *  @param expression 表达式
 *  @return 函数运行结果
 */
- (NSString *)max:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    NSArray *arr = [expression componentsSeparatedByRegex:@"\\s*,\\s*"];
    NSMutableArray *numbers = [NSMutableArray array];
    
    for(NSString *str in arr)
    {
        double digit = [self getNumerics:str forFunction:@"max"];
        
        NSNumber *num = @(digit);
        [numbers addObject:num];
    }
    
    NSArray *arguments = @[[NSExpression expressionForConstantValue:numbers]];
    NSExpression *valuator = [NSExpression expressionForFunction:@"max:" arguments:arguments];
    id result = [valuator expressionValueWithObject:nil context:nil];
    
    return [NSString stringWithFormat:@"%@", result];
}

/**
 *  找中值
 *  @param expression 表达式
 *  @return 函数运行结果
 */
- (NSString *)median:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    NSArray *arr = [expression componentsSeparatedByRegex:@"\\s*,\\s*"];
    NSMutableArray *numbers = [NSMutableArray array];
    
    for(NSString *str in arr)
    {
        double digit = [self getNumerics:str forFunction:@"median"];
        
        NSNumber *num = @(digit);
        [numbers addObject:num];
    }
    
    NSArray *arguments = @[[NSExpression expressionForConstantValue:numbers]];
    NSExpression *valuator = [NSExpression expressionForFunction:@"median:" arguments:arguments];
    id result = [valuator expressionValueWithObject:nil context:nil];
    
    return [NSString stringWithFormat:@"%@", result];
}

/**
 *  一数组或数据区域中出现频率最多的数值
 *  @param expression 表达式
 *  @return 函数运行结果
 */
- (NSString *)mode:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    NSArray *arr = [expression componentsSeparatedByRegex:@"\\s*,\\s*"];
    NSMutableArray *numbers = [NSMutableArray array];
    
    for(NSString *str in arr)
    {
        double digit = [self getNumerics:str forFunction:@"mode"];
        
        NSNumber *num = @(digit);
        [numbers addObject:num];
    }
    
    NSArray *arguments = @[[NSExpression expressionForConstantValue:numbers]];
    NSExpression *valuator = [NSExpression expressionForFunction:@"mode:" arguments:arguments];
    NSArray *result = (NSArray *)[valuator expressionValueWithObject:nil context:nil];
    
    NSMutableString *str = [NSMutableString stringWithFormat:@"\"(\n"];
    for(id obj in result)
    {
        [str appendFormat:@"\t%@\n", obj];
    }
    [str appendString:@")\""];
    
    return str;
}

/**
 *  样本标准偏差
 *  @param expression 表达式
 *  @return 函数运行结果
 */
- (NSString *)stddev:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    NSArray *arr = [expression componentsSeparatedByRegex:@"\\s*,\\s*"];
    NSMutableArray *numbers = [NSMutableArray array];
    
    for(NSString *str in arr)
    {
        double digit = [self getNumerics:str forFunction:@"stddev"];
        
        NSNumber *num = @(digit);
        [numbers addObject:num];
    }
    
    NSArray *arguments = @[[NSExpression expressionForConstantValue:numbers]];
    NSExpression *valuator = [NSExpression expressionForFunction:@"stddev:" arguments:arguments];
    id result = [valuator expressionValueWithObject:nil context:nil];
    
    return [NSString stringWithFormat:@"%@", result];
}

/**
 *  获取随机数
 *  @return 函数运行结果
 */
- (NSString *)random:(NSString *)expression
{
    NSExpression *valuator = [NSExpression expressionForFunction:@"random" arguments:@[]];
    id result = [valuator expressionValueWithObject:nil context:nil];
    
    return [NSString stringWithFormat:@"%@", result];
}

/**
 *  获取随机数
 *  @param expression 表达式
 *  @return 函数运行结果
 */
- (NSString *)randomn:(NSString *)expression
{
    double digit = [self getNumerics:expression forFunction:@"randomn"];
    
    NSArray *arguments = @[[NSExpression expressionForConstantValue:@(digit)]];
    NSExpression *valuator = [NSExpression expressionForFunction:@"randomn:" arguments:arguments];
    id result = [valuator expressionValueWithObject:nil context:nil];
    
    return [NSString stringWithFormat:@"%@", result];
}


#pragma mark - 字符串类处理
/**
 *  检查包含
 */
- (NSString *)contains:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    NSArray *arr = [expression componentsSeparatedByRegex:@"\\s*,\\s*"];
    
    if(arr.count != 2)
    {
        NSString *message = [NSString stringWithFormat:@"Error：\n表达式中函数“contains(%@)”，传入的参数“%@”不合法", expression, expression];
        NSAssert(false, message);
    }
    
    NSString *str1 = [[arr firstObject] stringByReplacingOccurrencesOfRegex:@"^\"|\"$" withString:@""];
    NSString *str2 = [[arr lastObject] stringByReplacingOccurrencesOfRegex:@"^\"|\"$" withString:@""];
    
    return [str1 rangeOfString:str2].length>0?@"1":@"0";
}

/**
 *  检查不包含
 */
- (NSString *)unContains:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    
    NSArray *arr = [expression componentsSeparatedByRegex:@"\\s*,\\s*"];
    
    if(arr.count != 2)
    {
        NSString *message = [NSString stringWithFormat:@"Error：\n表达式中函数“contains(%@)”，传入的参数“%@”不合法", expression, expression];
        NSAssert(false, message);
    }
    
    NSString *str1 = [[arr firstObject] stringByReplacingOccurrencesOfRegex:@"^\"|\"$" withString:@""];
    NSString *str2 = [[arr lastObject] stringByReplacingOccurrencesOfRegex:@"^\"|\"$" withString:@""];
    
    return [str1 rangeOfString:str2].length == 0 ? @"1" : @"0";
}

/**
 *  转小写
 *  @param expression 表达式
 *  @return 函数运行结果
 */
- (NSString *)lowercase:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    expression = [expression stringByReplacingOccurrencesOfRegex:@"^\"|\"$" withString:@""];
    expression = [expression lowercaseString];
    
    return [NSString stringWithFormat:@"\"%@\"", expression];
}

/**
 *  转大写
 *  @param expression 表达式
 *  @return 函数运行结果
 */
- (NSString *)uppercase:(NSString *)expression
{
    expression = [self preprocessor:expression]; // 去除参数中的函数调用
    expression = [expression stringByReplacingOccurrencesOfRegex:@"^\"|\"$" withString:@""];
    expression = [expression uppercaseString];
    
    return [NSString stringWithFormat:@"\"%@\"", expression];
}

@end
