//
//  DFEvaluatorFunctionNode.h
//  DFEvalKit
//
//  Created by Dean_F on 2017/6/10.
//  Copyright © 2017年 Dean_F. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DFEvaluatorFunctionNode : NSObject

/**
 *  使用在表达式中的函数名 【 xxx() 形式的 】
 */
@property (nonatomic, copy) NSString *name;

/**
 *  使用在表达式中的函数参数，【 xxx(paramExpression) 形式的括号中的 paramExpression 部分】
 */
@property (nonatomic, copy) NSString *paramExpression;

/**
 *  完整函数调用表达式，整个 xxx(paramExpression) 表达式
 */
@property (nonatomic, copy) NSString *functionInvoke;

/**
 *  函数对应的 OC 实现的 selector
 */
@property (nonatomic, assign) SEL selector;


@end
