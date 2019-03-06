//
//  DFEvaluatorStack.m
//  DFEvalKit
//
//  Created by Dean_F on 2017/6/12.
//  Copyright © 2017年 Dean_F. All rights reserved.
//

#import "DFEvaluatorStack.h"

@interface DFEvaluatorStack ()

// 存储栈数据
@property (nonatomic, strong) NSMutableArray *stackArray;

@end


@implementation DFEvaluatorStack

- (void)push:(id)obj
{
    [self.stackArray addObject:obj];
}

- (id)popObject
{
    if ([self isEmpty])
    {
        return nil;
    }
    else
    {
        id obj = [self.stackArray lastObject];
        [self.stackArray removeLastObject];
        return obj;
    }
}

- (BOOL)isEmpty
{
    return ![self.stackArray count];
}

- (NSInteger)stackLength
{
    return [self.stackArray count];
}

- (void)enumerateObjectsFromBottom:(DFEvaluatorStackBlock)block
{
    [self.stackArray enumerateObjectsWithOptions:NSEnumerationConcurrent
                                      usingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                          block ? block(obj) : nil;
                                      }];
}

- (void)enumerateObjectsFromtop:(DFEvaluatorStackBlock)block
{
    [self.stackArray enumerateObjectsWithOptions:NSEnumerationReverse
                                      usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                          block ? block(obj) : nil;
                                      }];
}

- (void)enumerateObjectsPopStack:(DFEvaluatorStackBlock)block
{
    __weak typeof(self) weakSelf = self;
    NSUInteger count = self.stackArray.count;
    
    for (NSUInteger i = count; i > 0; i --)
    {
        if (block)
        {
            block([weakSelf.stackArray lastObject]);
            [self.stackArray removeLastObject];
        }
    }
}

- (void)removeAllObjects
{
    [self.stackArray removeAllObjects];
}

- (id)topObject
{
    if ([self isEmpty])
    {
        return nil;
    }
    else
    {
        return [self.stackArray lastObject];
    }
}

-(id)objectAtIndex:(NSInteger)index
{
    if (index < [self.stackArray count])
    {
        return [self.stackArray lastObject];
    }
    return nil;
}

- (NSMutableArray *)stackArray
{
    if (!_stackArray)
    {
        _stackArray = [NSMutableArray array];
    }
    return _stackArray;
}

@end
