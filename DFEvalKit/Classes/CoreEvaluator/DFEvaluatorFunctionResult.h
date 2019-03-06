//
//  DFEvaluatorFunctionResult.h
//  DFEvalKit
//
//  Created by Dean_F on 2017/6/9.
//  Copyright © 2017年 Dean_F. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, DFEvaluatorFunctionResultDataType)
{
    /**
     * 数值
     */
    DFEvaluatorFunctionResultDataTypeNumeric,
    
    /**
     * 字符串
     */
    DFEvaluatorFunctionResultDataTypeString,
    
    /**
     * 日期时间，可以是日期格式的字符串，也可以是NSDate类实例
     */
    DFEvaluatorFunctionResultDataTypeDatetime
};


@interface DFEvaluatorFunctionResult : NSObject

/**
 *  计算结果数据类型
 */
@property (nonatomic, assign, readonly) DFEvaluatorFunctionResultDataType dataType;

/**
 *  计算结果
 */
@property (nonatomic, copy, readonly) id result;


- (instancetype)initWithResult:(id)result dataType:(DFEvaluatorFunctionResultDataType)dataType;

@end
