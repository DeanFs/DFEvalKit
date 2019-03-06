//
//  DFEvaluatorParser.h
//  DFEvalKit
//
//  Created by Dean_F on 15/1/7.
//  Copyright (c) 2015年 Dean_F. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DFEvaluatorNode.h"

@interface DFEvaluatorParser : NSObject


#pragma mark - properties
/**
 * 当前分析的表达式
 */
@property (nonatomic, copy, readonly) NSString *expression;

/**
 * 当前读取的位置
 */
@property (nonatomic, assign, readonly) NSInteger position;


#pragma mark - methods
- (DFEvaluatorParser *)initWithExpression:(NSString *)expression;

- (DFEvaluatorNode *)readNode;

@end
