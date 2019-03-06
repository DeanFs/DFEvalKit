//
//  DFViewController.m
//  DFEvalKit
//
//  Created by Dean_F on 03/05/2019.
//  Copyright (c) 2019 Dean_F. All rights reserved.
//

#import "DFViewController.h"
#import "UIView+Frame.h"
#import "UIResponder+InsertTextAdditions.h"

#import <DFEvalKit/DFEvaluator.h>
#import <FSTextView/FSTextView.h>
#import <ZWLimitCounter/UITextView+ZWLimitCounter.h>
#import <Aspects/Aspects.h>
#import <Masonry/Masonry.h>

@interface DFViewController () <UIPickerViewDataSource, UIPickerViewDelegate>

/**
 *  表示输入框
 */
@property (nonatomic, strong) FSTextView *expressionTextView;

/**
 *  选择函数表达式
 */
@property (nonatomic, strong) UIButton *chooseFunctionButton;

/**
 *  选择自定义函数的按钮
 */
@property (nonatomic, strong) UIButton *chooseCustomFunctionButton;

/**
 *  等于
 */
@property (nonatomic, strong) UIButton *countButton;

/**
 *  计算结果
 */
@property (nonatomic, strong) UILabel *resultLabel;

/**
 *  错误输出
 */
@property (nonatomic, strong) UILabel *errorMessageLabel;

/**
 *  使用说明
 */
@property (nonatomic, strong) UIWebView *explainWeb;

/**
 *  picke选择窗口
 */
@property (nonatomic, strong) UIWindow *window;

/**
 *  函数选择器窗口
 */
@property (nonatomic, strong) UIView *chooseWindow;

/**
 *  picker选择器的标题
 */
@property (nonatomic, strong) UILabel *pickerTitleLabel;

/**
 *  函数选择器
 */
@property (nonatomic, strong) UIPickerView *formulationPicker;

/**
 *  函数名称数组
 */
@property (nonatomic, copy) NSArray *functionNamesArray;

/**
 *  函数例子数组
 */
@property (nonatomic, copy) NSArray *functionsArray;

/**
 *  自定义函数名称数组
 */
@property (nonatomic, copy) NSArray *customFunctionNamesArray;

/**
 *  自定义函数例子数组
 */
@property (nonatomic, copy) NSArray *customFunctionsArray;

/**
 *  自定义函数集，用于出入eval中调用
 */
@property (nonatomic, copy) NSMutableDictionary *customFunctions;

/**
 *  evaluator
 */
@property (nonatomic, strong) DFEvaluator *evaluator;

@end

@implementation DFViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *cleanButton = [[UIButton alloc] init];
    [cleanButton setTitle:@"清空" forState:UIControlStateNormal];
    [cleanButton setBackgroundColor:[UIColor redColor]];
    [cleanButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cleanButton addTarget:self action:@selector(cleanTextView:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.expressionTextView];
    [self.view addSubview:cleanButton];
    [self.view addSubview:self.chooseFunctionButton];
    [self.view addSubview:self.chooseCustomFunctionButton];
    [self.view addSubview:self.countButton];
    [self.view addSubview:self.resultLabel];
    [self.view addSubview:self.errorMessageLabel];
    [self.view addSubview:self.explainWeb];
    
    __weak typeof (self) weakSelf = self;
    
    [self.expressionTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_offset(10);
        make.top.mas_offset(30);
        make.right.mas_offset(-10);
        make.height.mas_equalTo(55);
    }];
    
    [cleanButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(weakSelf.expressionTextView.mas_bottom).mas_offset(15);
        make.left.mas_offset(10);
        make.width.mas_equalTo(50);
        make.height.mas_equalTo(35);
    }];
    
    [self.chooseFunctionButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(weakSelf.expressionTextView.mas_bottom).mas_offset(15);
        make.left.mas_equalTo(cleanButton.mas_right).mas_offset(10);
        make.width.mas_equalTo(80);
        make.height.mas_equalTo(35);
    }];
    
    [self.chooseCustomFunctionButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(weakSelf.chooseFunctionButton.mas_right).mas_offset(10);
        make.top.mas_equalTo(weakSelf.expressionTextView.mas_bottom).mas_offset(15);
        make.right.mas_equalTo(weakSelf.countButton.mas_left).mas_offset(-10);
        make.height.mas_equalTo(35);
    }];
    
    [self.countButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(weakSelf.expressionTextView.mas_bottom).mas_offset(15);
        make.right.mas_offset(-10);
        make.height.mas_equalTo(35);
        make.width.mas_equalTo(50);
    }];
    
    [self.resultLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_offset(10);
        make.top.mas_equalTo(weakSelf.chooseFunctionButton.mas_bottom).mas_offset(15);
        make.right.mas_offset(-10);
        make.height.mas_equalTo(35);
    }];
    
    [self.errorMessageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_offset(10);
        make.top.mas_equalTo(weakSelf.resultLabel.mas_bottom).mas_offset(10);
        make.right.mas_offset(-10);
        make.height.mas_equalTo(0);
    }];
    
    [self.explainWeb mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_offset(10);
        make.top.mas_equalTo(weakSelf.errorMessageLabel.mas_bottom).mas_offset(10);
        make.right.mas_offset(-10);
        make.bottom.mas_offset(0);
    }];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ReadMe" ofType:@"rtf"];
    NSURL *url = [NSURL fileURLWithPath:path];
    [self.explainWeb loadRequest:[NSURLRequest requestWithURL:url]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - event response
- (void)cleanTextView:(UIButton *)btn
{
    self.expressionTextView.text = nil;
    [self.view endEditing:true];
    self.resultLabel.text = @"  结果：";
    self.errorMessageLabel.text = nil;
}

/*
 *  “计算”按钮的响应函数，开始执行计算
 */
- (void)startEval:(UIButton *)btn
{
    [self.view endEditing:true];
    
    if(self.expressionTextView.text.length == 0)
    {
        return;
    }
    
    [btn setUserInteractionEnabled:false];
    
    @try {
        
        NSString *result = [self.evaluator eval:self.expressionTextView.formatText];
        self.resultLabel.text = result;
        
        if(self.errorMessageLabel.text.length)
        {
            self.errorMessageLabel.text = nil;
        }
        
    } @catch (NSException *exception) {
        self.errorMessageLabel.text = exception.description;
    }
    
    [btn setUserInteractionEnabled:true];
}

- (void)chooseFunction:(UIButton *)btn
{
    [btn setUserInteractionEnabled:false];
    
    self.formulationPicker.tag = 100;
    self.pickerTitleLabel.text = btn.currentTitle;
    
    [self showPickerWindow];
    
    [btn setUserInteractionEnabled:true];
}

- (void)chooseCustomFunction:(UIButton *)btn
{
    [btn setUserInteractionEnabled:false];
    
    self.formulationPicker.tag = 200;
    self.pickerTitleLabel.text = btn.currentTitle;
    
    [self showPickerWindow];
    
    [btn setUserInteractionEnabled:true];
}

- (void)showPickerWindow
{
    [self.view endEditing:YES];
    [self.formulationPicker reloadComponent:0];
    
    self.window = [[UIWindow alloc] initWithFrame:self.view.frame];
    self.window.windowLevel = UIWindowLevelStatusBar;
    self.window.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.7];
    self.window.hidden = false;
    
    //添加手势
    UIGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] init];
    [gesture addTarget:self action:@selector(hidePickerWindow)];
    [self.window addGestureRecognizer:gesture];
    
    [self.window addSubview:self.chooseWindow];
    self.chooseWindow.y = self.view.height;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.chooseWindow.y = self.view.height-self.chooseWindow.height-230;
    }];
}

- (void)hidePickerWindow
{
    [UIView animateWithDuration:0.3 animations:^{
        self.chooseWindow.y = self.view.height;
    } completion:^(BOOL finished) {
        [self.chooseWindow removeFromSuperview];
        self.window.hidden = true;
        self.window = nil;
    }];
}

- (void)chooseFormulationDone:(UIButton *)btn
{
    NSInteger row = [self.formulationPicker selectedRowInComponent:0];
    NSString *text = nil;
    if(self.formulationPicker.tag == 200)
    {
        text = self.customFunctionsArray[row];
    }
    else
    {
        text = self.functionsArray[row];
    }
    NSMutableString *str = [NSMutableString stringWithString:self.expressionTextView.text];
    NSInteger loc = self.expressionTextView.selectedRange.location;
    [str insertString:text atIndex:loc];
    self.expressionTextView.text = str;
    
    // 以下方法不太稳定，有时不生效，有知道原因的大神还请不吝赐教
    [self.expressionTextView insertTextAtCursor:text];
    
    [self hidePickerWindow];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:true];
}


#pragma mark - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if(pickerView.tag == 200)
    {
        return self.customFunctionNamesArray.count;
    }
    return self.functionNamesArray.count;
}


#pragma mark - UIPickerViewDelegate
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if(pickerView.tag == 200)
    {
        return self.customFunctionNamesArray[row];
    }
    return self.functionNamesArray[row];
}


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


#pragma mark - getters
- (FSTextView *)expressionTextView
{
    if(!_expressionTextView)
    {
        _expressionTextView = [FSTextView textView];
        _expressionTextView.autocapitalizationType = UITextAutocapitalizationTypeNone; // 不自动首字母大写
        _expressionTextView.autocorrectionType = UITextAutocorrectionTypeNo; // 自动校正关闭
        _expressionTextView.spellCheckingType = UITextSpellCheckingTypeNo; // 自动拼写检测关闭
        _expressionTextView.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        _expressionTextView.returnKeyType = UIReturnKeyDone;
        _expressionTextView.enablesReturnKeyAutomatically = YES; // nonullable
        _expressionTextView.font = [UIFont systemFontOfSize:15];
        
        // 子类扩展属性
        _expressionTextView.placeholder = @"输入需要计算的表达式";
        _expressionTextView.zw_limitCount = 1024;
        _expressionTextView.cornerRadius = 5;
        _expressionTextView.borderColor = [UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1.0];
        _expressionTextView.borderWidth = 0.5;
        
        __weak typeof(self) weakSelf = self;
        [_expressionTextView addTextDidChangeHandler:^(FSTextView *textView) {
            NSString *text = textView.text;
            
            NSDictionary * tdic = [NSDictionary dictionaryWithObjectsAndKeys:textView.font, NSFontAttributeName,nil];
            CGSize size =[text boundingRectWithSize:CGSizeMake(weakSelf.view.width-20, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:tdic context:nil].size;
            
            CGFloat height = (NSInteger)ceil(size.height)+30;
            if(height < 55)
            {
                height = 55;
            }
            if(height > 100)
            {
                height = 120;
            }
            
            [textView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(height);
            }];
            
            weakSelf.resultLabel.text = @"  结果：";
            weakSelf.errorMessageLabel.text = nil;
        }];
    }
    return _expressionTextView;
}

- (UIButton *)chooseFunctionButton
{
    if(!_chooseFunctionButton)
    {
        _chooseFunctionButton = [[UIButton alloc] init];
        [_chooseFunctionButton setTitle:@"选择函数" forState:UIControlStateNormal];
        [_chooseFunctionButton setBackgroundColor:[UIColor grayColor]];
        [_chooseFunctionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_chooseFunctionButton addTarget:self action:@selector(chooseFunction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _chooseFunctionButton;
}

- (UIButton *)chooseCustomFunctionButton
{
    if(!_chooseCustomFunctionButton)
    {
        _chooseCustomFunctionButton = [[UIButton alloc] init];
        [_chooseCustomFunctionButton setTitle:@"快速测试" forState:UIControlStateNormal];
        [_chooseCustomFunctionButton setBackgroundColor:[UIColor purpleColor]];
        [_chooseCustomFunctionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_chooseCustomFunctionButton addTarget:self action:@selector(chooseCustomFunction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _chooseCustomFunctionButton;
}

- (UIButton *)countButton
{
    if(!_countButton)
    {
        _countButton = [[UIButton alloc] init];
        [_countButton setTitle:@"计算" forState:UIControlStateNormal];
        [_countButton setBackgroundColor:[UIColor blueColor]];
        [_countButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_countButton addTarget:self action:@selector(startEval:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _countButton;
}

- (UILabel *)resultLabel
{
    if(!_resultLabel)
    {
        _resultLabel = [[UILabel alloc] init];
        [_resultLabel setTextColor:[UIColor blackColor]];
        [_resultLabel setFont:[UIFont systemFontOfSize:15]];
        [_resultLabel setText:@"  结果："];
        [_resultLabel setBackgroundColor:[UIColor colorWithRed:0.89 green:0.89 blue:0.89 alpha:0.7]];
        [_resultLabel setNumberOfLines:0];
        
        __weak typeof(self) weakSelf = self;
        [_resultLabel aspect_hookSelector:@selector(setText:) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> aspectInfo){
            
            UILabel *label = [aspectInfo instance];
            NSString *text = [[aspectInfo arguments] firstObject];
            
            if(![text isKindOfClass:[NSNull class]] && text.length > 0)
            {
                NSDictionary * tdic = [NSDictionary dictionaryWithObjectsAndKeys:label.font, NSFontAttributeName,nil];
                CGSize size =[text boundingRectWithSize:CGSizeMake(weakSelf.view.width-20, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:tdic context:nil].size;
                
                CGFloat height = (NSInteger)ceil(size.height) + 10;
                if(height < 35)
                {
                    height = 35;
                }
                
                [label mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.height.mas_equalTo(height);
                }];
            }
            else
            {
                [label mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.height.mas_equalTo(35);
                }];
            }
            
        }error:nil];
    }
    return _resultLabel;
}

- (UILabel *)errorMessageLabel
{
    if(!_errorMessageLabel)
    {
        _errorMessageLabel = [[UILabel alloc] init];
        [_errorMessageLabel setTextColor:[UIColor redColor]];
        [_errorMessageLabel setBackgroundColor:[UIColor colorWithRed:0.92 green:0.92 blue:0.92 alpha:0.9]];
        [_errorMessageLabel setFont:[UIFont systemFontOfSize:15]];
        [_errorMessageLabel setNumberOfLines:0];
        
        __weak typeof(self) weakSelf = self;
        [_errorMessageLabel aspect_hookSelector:@selector(setText:) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> aspectInfo){
            
            UILabel *label = [aspectInfo instance];
            NSString *text = [[aspectInfo arguments] firstObject];
            
            if(![text isKindOfClass:[NSNull class]] && text.length > 0)
            {
                NSDictionary * tdic = [NSDictionary dictionaryWithObjectsAndKeys:label.font, NSFontAttributeName,nil];
                CGSize size =[text boundingRectWithSize:CGSizeMake(weakSelf.view.width-20, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:tdic context:nil].size;
                
                CGFloat height = (NSInteger)ceil(size.height) + 10;
                if(height < 35)
                {
                    height = 35;
                }
                
                [label mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.height.mas_equalTo(height);
                }];
            }
            else
            {
                [label mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.height.mas_equalTo(0);
                }];
            }
            
        }error:nil];
    }
    return _errorMessageLabel;
}

- (UIWebView *)explainWeb
{
    if(!_explainWeb)
    {
        _explainWeb = [[UIWebView alloc] init];
        _explainWeb.backgroundColor = [UIColor clearColor];
        _explainWeb.scalesPageToFit = YES;
    }
    return _explainWeb;
}

- (UIView *)chooseWindow
{
    if(!_chooseWindow)
    {
        _chooseWindow = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.height, self.view.width, 246)];
        [_chooseWindow setBackgroundColor:[UIColor whiteColor]];
        
        [_chooseWindow addSubview:self.pickerTitleLabel];
        
        UIButton *confirmButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.width - 60, 0, 60, 30)];
        [confirmButton setTitle:@"确认"
                       forState:UIControlStateNormal];
        [confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [confirmButton setBackgroundColor:[UIColor colorWithRed:0.6 green:0.3 blue:0.8 alpha:1.0f]];
        [confirmButton addTarget:self action:@selector(chooseFormulationDone:) forControlEvents:UIControlEventTouchUpInside];
        [_chooseWindow addSubview:confirmButton];
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 29.5, self.view.width, 0.5)];
        [line setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:9.8]];
        [_chooseWindow addSubview:line];
        
        [_chooseWindow addSubview:self.formulationPicker];
    }
    return _chooseWindow;
}

- (UILabel *)pickerTitleLabel
{
    if(!_pickerTitleLabel)
    {
        _pickerTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.view.width - 90, 30)];
        [_pickerTitleLabel setBackgroundColor:[UIColor clearColor]];
        [_pickerTitleLabel setTextColor:[UIColor darkGrayColor]];
        [_pickerTitleLabel setFont:[UIFont systemFontOfSize:15]];
    }
    return _pickerTitleLabel;
}

- (UIPickerView *)formulationPicker
{
    if(!_formulationPicker)
    {
        _formulationPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 30, self.view.width, 216)];
        _formulationPicker.dataSource = self;
        _formulationPicker.delegate = self;
    }
    return _formulationPicker;
}

- (NSArray *)functionNamesArray
{
    if(!_functionNamesArray)
    {
        _functionNamesArray = @[@"三目运算ternaryOperation",
                                @"时间差dateDiff",
                                @"获取年份getYear",
                                @"获取季度getQuarter",
                                @"获取中文季度getLocalQuarter",
                                @"获取月份getMonth",
                                @"获取中文月份getLocalMonth",
                                @"获取周数getWeek",
                                @"获取中文周数getLocalWeek",
                                @"获取星期getDayOfWeek",
                                @"获取中文星期getLocalDayOfWeek",
                                @"获取当月第几天getDay",
                                @"获取中文当月第几天getLocalDay",
                                @"获取现在时间now",
                                @"数值转大写金额getLocalMoney",
                                @"数值4舍5入round",
                                @"数值0舍1入ceil",
                                @"向下取整trunc",
                                @"向下取整floor",
                                @"求绝对值abs",
                                @"开平方sqrt",
                                @"底数为e对数log",
                                @"底数为e对数ln",
                                @"底数为10对数log10",
                                @"底数为2对数log2",
                                @"计算x的n次方raiseToPower",
                                @"求e的x次方exp",
                                @"异或bitwiseXor",
                                @"得到补码onesComplement",
                                @"求平均average",
                                @"求和sum",
                                @"计数count",
                                @"找最小值min",
                                @"找最大值max",
                                @"找中值median",
                                @"频率最高的数值mode",
                                @"样本标准偏差stddev",
                                @"获取随机小数random",
                                @"获取随机整数randomn",
                                @"判断包含字符串contains",
                                @"判断不包含字符串unContains",
                                @"转小写lowercase",
                                @"转大写uppercase"
                                ];
    }
    return _functionNamesArray;
}

- (NSArray *)functionsArray
{
    if(!_functionsArray)
    {
        _functionsArray = @[@"ternaryOperation(5<7, \"真\", \"假\")",
                            @"dateDiff(\"dd\", \"2016-12-17 06:33:56\", now())",
                            @"getYear(now())",
                            @"getQuarter(now())",
                            @"getLocalQuarter(now())",
                            @"getMonth(now())",
                            @"getLocalMonth(now())",
                            @"getWeek(now())",
                            @"getLocalWeek(now())",
                            @"getDayOfWeek(now())",
                            @"getLocalDayOfWeek(now())",
                            @"getDay(now())",
                            @"getLocalDay(now())",
                            @"now()",
                            @"getLocalMoney(10086)",
                            @"round(123.633)",
                            @"ceil(123.336)",
                            @"trunc(10.99)", // 向下取整
                            @"floor(10.99)", // 向下取整
                            @"abs(-3241.334)", // 求绝对值
                            @"sqrt(100)", // 开平方
                            @"log(100)", // 底数为e对数
                            @"ln(100)", // 底数为e对数
                            @"log10(100)", // 底数为10对数
                            @"log2(100)", // 底数为2对数
                            @"raiseToPower(5, 3)", // 计算 x 的 n 次方
                            @"exp(10)", // 求e的x次方
                            @"bitwiseXor(1, 0)", // a 异或 b
                            @"onesComplement(-7)", // a 的补码
                            @"average(100, 99, 88, 66, 33, 44, 78, 122, 77)", // 求平均
                            @"sum(100, 99, 88, 66, 33, 44, 78, 122, 77)", // 求和
                            @"count(100, 99, 88, 66, 33, 44, 78, 122, 77)", // 计数
                            @"min(100, 99, 88, 66, 33, 44, 78, 122, 77)", // 找最小值
                            @"max(100, 99, 88, 66, 33, 44, 78, 122, 77)", // 找最大值
                            @"median(100, 99, 88, 66, 33, 44, 78, 122, 77)", // 找中值
                            @"mode(100, 99, 88, 88, 99, 44, 88, 122, 99)", // 一数组或数据区域中出现频率最多的数值
                            @"stddev(100, 22, 33, 12, 1000, 99, 44)", // 样本标准偏差
                            @"random()", // 获取随机数
                            @"randomn(33)", // 获取随机数
                            @"contains(\"hgklknbaklkfeo\", \"kfeo\")",
                            @"unContains(\"hgklknbaklkfeo\",\"kfeo\")",
                            @"lowercase(\"AdLsdDdKFfdaGFRDDFkjJJLjfkal\")", // 转小写
                            @"uppercase(\"fjlakjelkHJdlfkaUUalfkfjl\")" // 转大写
                            ];
    }
    return _functionsArray;
}

- (NSArray *)customFunctionNamesArray
{
    if(!_customFunctionNamesArray)
    {
        _customFunctionNamesArray = @[@"自定义无参数传递函数test1",
                                      @"自定义单个参数传递test2",
                                      @"自定义多个一维参数test3",
                                      @"自定义多个二维参数传递test4",
                                      @"简单数学表达式计算",
                                      @"简单的比较运算",
                                      @"简单的位运算",
                                      @"与或非逻辑运算",
                                      @"复杂纯数学表达式",
                                      @"复杂函数调用表达式"
                                      ];
    }
    return _customFunctionNamesArray;
}

- (NSArray *)customFunctionsArray
{
    if(!_customFunctionsArray)
    {
        _customFunctionsArray = @[@"test1()",
                                  @"test2(\"Hello World!\")",
                                  @"test3(\"Hello\", \" \", \"World \", 23 + 77, \" !\")",
                                  @"test4(\"He\", [\"ll\", \"o \"], \"W\", [\"orld \", 1 || 0], 23 + 77)",
                                  @"(12 * 4 + 55 % 6 + 88 / 9 - 30 + 23.33 * (100 + 23)) / 33",
                                  @"12 > 11",
                                  @"3 << 2 + 3 & 7 + 2 | 2",
                                  @"12 > 11 && 5 < 3 * 4",
                                  @"(12 < 22) * 100 + (4 & 4) * 20 - (5 | 7) * 33 + 66 * ((3 == 3) || (6 > 3))",
                                  @"dateDiff(\"dd\", \"2016-12-17 06:23:33\", now()) * 10 - getYear(now()) + max(11, 22,33,1000) * sqrt(floor(1000.445))"
                                  ];
    }
    return _customFunctionsArray;
}

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
        //        [_evaluator setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
        // 默认就是 false，即表达式支持函数调用，当表达式不需要函数调用是，调用该方法置为 true，可以调高运算效率
        //        [_evaluator withoutFunctionInvoke:false];
    }
    return _evaluator;
}

@end
