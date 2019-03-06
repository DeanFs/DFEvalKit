//
//  DFEvaluatorFunction.m
//  DFEvalKit
//
//  Created by Dean_F on 2017/6/7.
//  Copyright © 2017年 Dean_F. All rights reserved.
//

#import "DFEvaluatorFunction.h"

@implementation DFEvaluatorFunction

- (instancetype)initWithFunctionName:(NSString *)functionName
                            selector:(SEL)selector
                              target:(id)target
{
    if(self = [super init])
    {
        self.functionName = functionName;
        self.selector = selector;
        self.target = target;
    }
    return self;
}

@end
