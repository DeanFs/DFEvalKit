# DFEvalKit

[![CI Status](https://img.shields.io/travis/Dean_F/DFEvalKit.svg?style=flat)](https://travis-ci.org/Dean_F/DFEvalKit)
[![Version](https://img.shields.io/cocoapods/v/DFEvalKit.svg?style=flat)](https://cocoapods.org/pods/DFEvalKit)
[![License](https://img.shields.io/cocoapods/l/DFEvalKit.svg?style=flat)](https://cocoapods.org/pods/DFEvalKit)
[![Platform](https://img.shields.io/cocoapods/p/DFEvalKit.svg?style=flat)](https://cocoapods.org/pods/DFEvalKit)

## Introduce
1. 一个数学表达式计算器，能实现和 **UIWebView** 的 stringByEvaluatingJavaScriptFromString: 一样的计算效果，但效率要高很多，可以在子线程中执行；

2.  基本全面覆盖 **NSExpression** 的 expressionForFunction:arguments 中的所有function，使用要比 **NSExpression** 简单很多，只需将注意力放大expression表达式的编辑上，将任意复杂度的表达式，通过eval:方法传入便可轻松得到计算结果；

3. 支持复杂加减乘除四则运算，与或非逻辑运算，和大于小于等比较运算；

4. 支持三目运算；

5. 表达式中能自动识别处理的函数，基本全部覆盖**NSExpression**，有的未实现的，因为可以自己有数学表达式表达，比如 a+b，这个表达式计算最基本功能，无需通过函数调用来实现；

6. 以上所述的计算类型在符合数学表达式逻辑的前提下，可以组合在一个表达式中，函数支持嵌套调用；

7.  支持字符串相加（字符串拼接）；

8.  开发者可以扩展自己的函数，通过构建 **DFEvaluatorFunction** 对象来声明自定义的函数，详细使用方式可以参考 demo。

## Usage

1. 引入头文件

	```Objective-C
	#import <DFEvalKit/DFEvaluator.h>
	```
	
	**DFEvaluator.h** 文件中只声明了4个方法：<br>
	- -(id)eval:(NSString *)expression // 用于传入表达式进行计算并返回计算结果<br>
	- -(void)setCustomFunctions:(NSDictionary *)customFunctions // 用于给开发者注册自定义方法<br>
	- -(void)setDateFormatter:(NSDateFormatter *)dateFormatter // 设置支持的日期格式，默认只支持 yyyy-MM-dd HH:mm:ss 格式<br>
	- -(void)withoutFunctionTransfer:(BOOL)withoutFunction; // 不支持函数调用，仅用于计算纯数学表达式，默认为支持函数调用<br><br>
	
	开发者仅需通过这4个 **API** 来使用表达式计算全部功能<br>
		
	```Objective-C
	// DFEvaluator.h

    @interface DFEvaluator : NSObject

	#pragma mark - API
	/**
	 *  表达式计算
	 *
	 *  @param expression 需要计算的表达式
	 *
	 *  @return 计算结果
	 */
	- (id)eval:(NSString *)expression;

	/**
	 *	设置开发者自定义的函数集
	 *
	 *  @param customFunctions 每个函数用 DFEvaluatorFunction 对象来描述，以函数名为 key
	 *                         
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
	- (void)withoutFunctionTransfer:(BOOL)withoutFunction;

	@end
	```
	
2. 具体使用方式
	
	1. 支持的数学运算操作符和操作数类型
	
		```Objective-C
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
		```
	2. 使用示例

		```Objective-C
		// 简单四则运算
		[DFEvaluator eval:@"22 + 33 * 66 + 3^5"]; // 3^5 3的5次方
		
		// 简单比较运算
		[DFEvaluator eval:@"5 < 6"];
		
		// 逻辑运算
		[DFEvaluator eval:@"5 < 3 || 6 > 5)"];
		
		// 位运算
		[DFEvaluator eval:@"4 << 5"];
		
		// 字符串相加
		[DFEvaluator eval:@"\"Hello\" + \" \" + \"World\" << 5"];
		```
	3. 包含函数的运算
		
		1. 支持的函数清单
		
			```Objective-C
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
			``` 
		2. 调用方式
			
			```Objective-C
			// 三目运算函数
			[DFEvaluator eval:@"ternaryOperation(5<7, \"真\", \"假\")"];
			
			// 获取大写金额
			[DFEvaluator eval:@"getLocalMoney(10086)"];
			
			// 复杂混合运算表达式
			[DFEvaluator eval:@"dateDiff(\"dd\", \"2016-12-17\", now()) * 10 - getYear(now()) + max(11, 22,33,1000) * sqrt(floor(1000.445))"];
			```
		3. 自定义函数的使用，以 demo 为例：
			<br><br>**第一步：自定义方法的OC实现**
			<br><br>demo 中在 ViewController.m 实现了如下四个方法，可以看到返回时，均构建了 DFEvaluatorFunctionResult 类实例来返回，这是必须的；
			<br> 方法中传入的 param 会根据表达式中调用函数时括号内传入的参数情况解析成字符串，一维数组，或者二维数组，具体规则看如下代码段的注释。
			
			```Objective-C
			#pragma mark - 自定义函数测试
			/*
			 *  不带参函数
			 *  在表达式中写入 test1()
			 *
			 *  @return 创建 DFEvaluatorFunctionResult 实例，返回函数运行结果
			 */
			- (DFEvaluatorFunctionResult *)test1
			{
			    return [[DFEvaluatorFunctionResult alloc] initWithResult:@"测试不带参函数"
			                                                     dataType:DFEvaluatorFunctionResultDataTypeString] ;
			}
			
			/*
			 *  带一个加单参数的函数
			 *
			 *  @param param 如在表达式中写：test2(123) 则此处 param 为: @"123"
			 *
			 *  @return 创建 DFEvaluatorFunctionResult 实例，返回函数运行结果
			 */
			- (DFEvaluatorFunctionResult *)test2:(id)param
			{
			    return [[DFEvaluatorFunctionResult alloc] initWithResult:[NSString stringWithFormat:@"测试带参函数，传入参数为：%@", param]
			                                                     dataType:DFEvaluatorFunctionResultDataTypeString];
			}
			
			/*
			 *  一维多参函数，将所有参数拼接成一个字符串
			 *  如表达式中写：test3(123, 456, 789...) 数量根据自己的需要来定
			 *
			 *  @param param 此处得到 param 为一维数组 @[@"123", @"456", @"789"...]
			 *
			 *  @return 创建 DFEvaluatorFunctionResult 实例，返回函数运行结果
			 */
			- (DFEvaluatorFunctionResult *)test3:(id)param
			{
			    // 将所有参数拼接成一个字符串
			    
			    NSMutableString *result = [NSMutableString string];
			    for(NSString *str in param)
			    {
			        [result appendString:str];
			    }
			    
			    return [[DFEvaluatorFunctionResult alloc] initWithResult:result
			                                                     dataType:DFEvaluatorFunctionResultDataTypeString];
			}
			
			/*
			 *  二维多参函数，函数功能为将所有参数拼接为字符串
			 *  如表达式中写：test3(123, [456, 789], @"333", [234]...) 数量根据自己的需要来定
			 *
			 *  @param param 此处得到 param 为二维数组 @[@"123", @[@"456", @"789"], @"333", @[@"234"]...]
			 *
			 *  @return 创建 DFEvaluatorFunctionResult 实例，返回函数运行结果
			 */
			- (DFEvaluatorFunctionResult *)test4:(id)param
			{
			    NSMutableString *result = [NSMutableString string];
			    
			    for(id obj in param)
			    {
			        if([obj isKindOfClass:[NSArray class]])
			        {
			            for(NSString *str in (NSArray *)obj)
			            {
			                [result appendString:str];
			            }
			        }
			        else
			        {
			            [result appendString:obj];
			        }
			    }
			    
			    return [[DFEvaluatorFunctionResult alloc] initWithResult:result
			                                                     dataType:DFEvaluatorFunctionResultDataTypeString];
			}
			```
			**第二步：构建 DFEvaluatorFunction 实例**
			<br><br>如下代码将上述四个 test 方法分别构建一个 DFEvaluatorFunction 实例来进行描述，并以用于表达式调用的函数名为 key 存入字典，准备注入表达式解析计算器中。
			
			```Objective-C
			- (NSDictionary *)customFunctions
			{
			    if(!_customFunctions)
			    {
			        _customFunctions = [NSMutableDictionary dictionary];
			        
			        DFEvaluatorFunction *function = [[DFEvaluatorFunction alloc] initWithFunctionName:@"test1"
			                                                                                                         selector:@selector(test1)
			                                                                                                           target:self];
			        [_customFunctions setObject:function forKey:function.functionName];
			        
			        function = [[DFEvaluatorFunction alloc] initWithFunctionName:@"test2"
			                                                                        selector:@selector(test2:)
			                                                                          target:self];
			        [_customFunctions setObject:function forKey:function.functionName];
			        
			        function = [[DFEvaluatorFunction alloc] initWithFunctionName:@"test3"
			                                                                        selector:@selector(test3:)
			                                                                          target:self];
			        [_customFunctions setObject:function forKey:function.functionName];
			        
			        function = [[DFEvaluatorFunction alloc] initWithFunctionName:@"test4"
			                                                                        selector:@selector(test4:)
			                                                                          target:self];
			        [_customFunctions setObject:function forKey:function.functionName];
			    }
			    return _customFunctions;
			}
			```
			**第三步：将构建好的 DFEvaluatorFunction 实例注入表达式解析计算器**
			<br><br>代码如下，即在 demo 中点击 “计算” 按钮时执行的代码
			
			```Objective-C
			/*
			 *  创建表达式计算器对象
			 */
			- (DFEvaluator *)evaluator
			{
			    if(!_evaluator)
			    {
			        _evaluator = [[DFEvaluator alloc] init];
			        [_evaluator setCustomFunctions:self.customFunctions]; // 注入自定义函数集
			        
			        // 默认就是这个格式
			        // [_evaluator setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
			        
			        // 默认就是 false，即表达式支持函数调用，当表达式不需要函数调用是，调用该方法置为 true，可以调高运算效率
			        // [_evaluator withoutFunctionTransfer:false];
			    }
			    return _evaluator;
			}
			```
				
<br>	
由于时间问题，详细的说明以后再补，感兴趣请下载demo研究，运行后，点击快速测试，快速一睹 DFEvaluatorValuator 的风采吧！

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.


## Installation

DFEvalKit is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'DFEvalKit'
```

## Author

Dean_F, stone.feng1990@gmail.com <br>

**QQ: 247159603** <br>
**简书：** <a href = "https://www.jianshu.com/p/79bbaea5dd4d"> **DREvalKit使用简介**

## License

DFEvalKit is available under the MIT license. See the LICENSE file for more info.
