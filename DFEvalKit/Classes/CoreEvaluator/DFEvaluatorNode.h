//
//  DFEvaluatorNode.h
//  DFEvalKit
//
//  Created by Dean_F on 15/1/7.
//  Copyright (c) 2015年 Dean_F. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DFRegexKitLite.h"

#if DEBUG
    #define DFLog(fmt, ...)  NSLog((@"\n%s [Line %d]\n" fmt), __PRETTY_FUNCTION__, __LINE__, ## __VA_ARGS__);
#else
    #define DFLog(fmt, ...)
#endif

typedef NS_ENUM(NSInteger, DFEvaluatorNodeType)
{
    /**
     * 未知  0
     */
    Unknown,
    
    /**
     * + 加
     */
    Plus,
    
    /**
     * - 减
     */
    Subtract,
    
    /**
     * * 乘
     */
    MultiPly,
    
    /**
     * / 除
     */
    Divide,
    
    /**
     * ( 左括号
     */
    LParentheses,
    
    /**
     * ) 右括号
     */
    RParentheses,
    
    /**
     * % 求模,取余
     */
    Mod,
    
    /**
     * ^ 幂运算
     */
    Power,
    
    /**
     * << 左移位
     */
    LShift,
    
    /**
     * >> 右移位
     */
    RShift,
    
    /**
     * & 按位与
     */
    BitwiseAnd,
    
    /**
     * | 按位或
     */
    BitwiseOr,
    
    /**
     * && 逻辑与
     */
    And,
    
    /**
     * || 逻辑或
     */
    Or,
    
    /**
     * ! 逻辑非
     */
    Not,
    
    /**
     * == 比较等
     */
    Equal,
    
    /**
     * != 或 <> 比较不等
     */
    Unequal,
    
    /**
     * > 比较大于
     */
    GT,
    
    /**
     * < 比较小于
     */
    LT,
    
    /**
     * >= 比较大于等于
     */
    GTOrEqual,
    
    /**
     * <= 比较小于等于
     */
    LTOrEqual,
    
    /**
     * 数值
     */
    Numeric,
    
    /**
     * 字符串
     */
    String,
    
    /**
     * 日期时间
     */
    Datetime
};


@class DFEvaluatorNode;

@interface DFEvaluatorNode : NSObject


#pragma mark - properties
/**
 * 当前节点的操作数
 */
@property (nonatomic, copy, readonly) NSString *value;

/**
 * 当前节点的类型
 */
@property (nonatomic, assign) DFEvaluatorNodeType type;

/**
 * 设置或返回与当前节点相关联的一元操作符节点，实际用于存储正负号
 */
@property (nonatomic, strong) DFEvaluatorNode *unitaryNode;

/**
 * 当前节点的优先级
 */
@property (nonatomic, assign, readonly) NSInteger pri;

/**
 * 返回此节点的数值
 */
@property (nonatomic, copy) NSString *numeric;


#pragma mark - methods
/**
 * 初始化构造函数
 */
- (DFEvaluatorNode *)initWithValue:(NSString *)value;

/**
 * 判断是否是一元操作符节点
 */
+ (BOOL)isUnitaryNode:(DFEvaluatorNodeType)nodeType;

/**
 * 判断某个字符后是否需要更多的操作符
 */
+ (BOOL)needMoreOperator:(char)c;

/**
 * 判断两个字符是否是同一类
 */
+ (BOOL)isCongener:(char)c1 with:(char)c2;

/**
 * 判断某个操作数是否是数值
 */
+ (BOOL)isNumerics:(NSString *)op;

/**
 * 判断某个操作数是否是布尔值
 */
+ (BOOL)isBool:(NSString *)op;

/**
 * 判断某个操作数是否是字符串
 */
+ (BOOL)isString:(NSString *)op;

/**
 * 判断某个操作数是否是日期时间
 */
+ (BOOL)isDatetime:(NSString *)op;


@end
