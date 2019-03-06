#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "DFEvaluator.h"
#import "DFEvaluatorFunction.h"
#import "DFEvaluatorFunctionNode.h"
#import "DFEvaluatorFunctionResult.h"
#import "DFEvaluatorNode.h"
#import "DFEvaluatorParser.h"
#import "DFEvaluatorStack.h"
#import "DFRegexKitLite.h"

FOUNDATION_EXPORT double DFEvalKitVersionNumber;
FOUNDATION_EXPORT const unsigned char DFEvalKitVersionString[];

