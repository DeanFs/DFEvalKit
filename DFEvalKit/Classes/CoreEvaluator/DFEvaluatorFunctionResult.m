//
//  DFEvaluatorFunctionResult.m
//  DFEvalKit
//
//  Created by Dean_F on 2017/6/9.
//  Copyright © 2017年 Dean_F. All rights reserved.
//

#import "DFEvaluatorFunctionResult.h"

@implementation DFEvaluatorFunctionResult

- (instancetype)initWithResult:(id)result dataType:(DFEvaluatorFunctionResultDataType)dataType
{
    if(self = [super init])
    {
        _result = result;
        _dataType = dataType;
    }
    return self;
}

@end
