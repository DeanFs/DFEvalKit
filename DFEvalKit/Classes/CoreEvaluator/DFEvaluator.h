//
//  DFEvaluator.h
//  DFEvalKit
//
//  Created by Dean_F on 15/1/7.
//  Copyright (c) 2015年 Dean_F. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DFEvaluatorFunction.h"
#import "DFEvaluatorFunctionResult.h"

@interface DFEvaluator : NSObject


#pragma mark - API
/**
 *  设置开发者自定义的函数集
 *
 *  @param customFunctions 每个函数用 DFEvaluatorFunction 对象来描述，以表达式中使用的函数名为 key
 *                         自定义函数的OC实现必须有返回值，且返回值为 DFEvaluatorFunctionResult 对象
 */
- (void)setCustomFunctions:(NSDictionary *)customFunctions;

/**
 *  设置支持的日期格式，默认只支持 yyyy-MM-dd HH:mm:ss 格式
 *
 *  @param dateFormat 日期格式
 */
- (void)setDateFormat:(NSString *)dateFormat;

/**
 *  不支持函数调用，仅用于计算纯数学表达式，默认为支持函数调用
 */
- (void)withoutFunctionInvoke:(BOOL)withoutFunction;

/**
 *  表达式计算
 *
 *  @param expression 需要计算的表达式
 *
 *  // 库中内置实现了一下函数，可以直接在表达式中调用
 *
    // 逻辑运算类
    ternaryOperation(5<7, \"真\", \"假\") // 三目表达式

    日期类处理方法, 日期字符串格式要求为：yyyy-MM-dd或者yyyy-MM-dd HH:mm:ss
    dateDiff(差值类型, 较早日期, 较晚日期) // 时间差值
    getYear(date) // 获取日期中的年份
    getQuarter(date) // 获取日期中的第几季度
    getLocalQuarter(date) // 获取日期中的中文第几季度
    getMonth(date) // 获取日期中的月份
    getLocalMonth(date) // 获取日期中的中文月份
    getWeek(date) // 获取日期中的第几周
    getLocalWeek(date) // 获取日期中的中文第几周
    getDayOfWeek(date) // 获取日期中的星期几
    getLocalDayOfWeek(date) // 获取日期中的中文星期几
    getDay(date) // 获取日子
    getLocalDay // 获取中文日子
    now() // 获取现在时间

    // 数值类
    getLocalMoney(digit) // 将数值转换为大写金额
    round(digit) // 数值四舍五入
    ceil(digit) // 数值0舍1入
    trunc(digit) // 向下取整
    floor(digit) // 向下取整
    abs(digit) // 求绝对值
    sqrt(digit) // 开平方
    log(digit) // 底数为e对数
    ln(digit) // 底数为e对数
    log10(digit) // 底数为10对数
    log2(digit) // 底数为2对数
    raiseToPower(x, n) // 计算 x 的 n 次方
    exp(digit) // 求e的x次方
    bitwiseXor(a, b) // a 异或 b
    onesComplement(a) // a 的补码
    average(digit, digit, ...) // 求平均
    sum(digit, digit, ...) // 求和
    count(digit, digit, ...) // 计数
    min(digit, digit, ...) // 找最小值
    max(digit, digit, ...) // 找最大值
    median(digit, digit, ...) // 找中值
    mode(digit, digit, ...) // 一数组或数据区域中出现频率最多的数值
    stddev(digit, digit, ...) // 样本标准偏差
    random(void) // 获取随机数小数
    randomn(digit) // 获取随机数整数

    // 字符串类
    contains("待检字符串", "被包含字符串") // 检查包含子字符串
    unContains("待检字符串", "不被包含字符串") // 检查不包含子字符串
    lowercase("字符串") // 转小写
    uppercase("字符串") // 转大写
    *
 *  @return 计算结果
 */
- (id)eval:(NSString *)expression;

@end



















