//
//  DFEvaluatorFunction.h
//  DFEvalKit
//
//  Created by Dean_F on 2017/6/7.
//  Copyright © 2017年 Dean_F. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DFEvaluatorFunction : NSObject

/**
 *  写入表达式中的函数名称
 */
@property (nonatomic, copy) NSString *functionName;

/**
 *  开发者命名的函数对应的实际执行方法
 */
@property (nonatomic, assign) SEL selector;

/**
 *  函数方法的执行者
 */
@property (nonatomic, weak) id target;


- (instancetype)initWithFunctionName:(NSString *)fucntionName
                            selector:(SEL)selector
                              target:(id)target;

@end
