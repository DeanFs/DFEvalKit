//
//  DFEvaluatorStack.h
//  DFEvalKit
//
//  Created by Dean_F on 2017/6/12.
//  Copyright © 2017年 Dean_F. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  定义block
 *  @param obj 回调值
 */
typedef void(^DFEvaluatorStackBlock)(id obj);


@interface DFEvaluatorStack : NSObject

/**
 *  入栈
 *  @param object 指定入栈对象
 */
- (void)push:(id)object;

/**
 *  出栈
 */
- (id)popObject;

/**
 *  是否为空
 */
- (BOOL)isEmpty;

/**
 *  栈的长度
 */
- (NSInteger)stackLength;

/**
 *  从栈底开始遍历
 *  @param block 回调遍历的结果
 */
-(void)enumerateObjectsFromBottom:(DFEvaluatorStackBlock)block;

/**
 *  从顶部开始遍历
 */
-(void)enumerateObjectsFromtop:(DFEvaluatorStackBlock)block;

/**
 *  所有元素出栈，一边出栈一边返回元素
 */
-(void)enumerateObjectsPopStack:(DFEvaluatorStackBlock)block;

/**
 *  清空
 */
-(void)removeAllObjects;

/**
 *  返回栈顶元素
 */
-(id)topObject;

/**
 *  返回栈中 index 处元素，index 超出范围则返回 nil
 */
-(id)objectAtIndex:(NSInteger)index;

@end
