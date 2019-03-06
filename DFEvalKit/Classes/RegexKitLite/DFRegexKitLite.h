//
//  DFRegexKitLite.h
//  DFEvalKit
//
//  Created by Dean_F on 2017/6/7.
//  Copyright © 2017年 Dean_F. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, RKLRegexOptions) {
    RKLNoOptions                = 0,
    RKLCaseless                 = NSRegularExpressionCaseInsensitive,
    RKLComments                 = NSRegularExpressionAllowCommentsAndWhitespace,
    RKLIgnoreMetacharacters     = NSRegularExpressionIgnoreMetacharacters,
    RKLDotAll                   = NSRegularExpressionDotMatchesLineSeparators,
    RKLMultiline                = NSRegularExpressionAnchorsMatchLines,
    RKLUseUnixLineSeparators    = NSRegularExpressionUseUnixLineSeparators,
    RKLUnicodeWordBoundaries    = NSRegularExpressionUseUnicodeWordBoundaries
};

@interface NSString (EntireRange)
- (NSRange)stringRange;
@end

@interface NSString (DFRegexKitLite)

#pragma mark - componentsSeparatedByRegex:

- (NSArray *)componentsSeparatedByRegex:(NSString *)pattern;
- (NSArray *)componentsSeparatedByRegex:(NSString *)pattern range:(NSRange)range;
- (NSArray *)componentsSeparatedByRegex:(NSString *)pattern options:(RKLRegexOptions)options range:(NSRange)range error:(NSError **)error;
- (NSArray *)componentsSeparatedByRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions range:(NSRange)range error:(NSError **)error;

#pragma mark - isMatchedByRegex:

- (BOOL)isMatchedByRegex:(NSString *)pattern;
- (BOOL)isMatchedByRegex:(NSString *)pattern inRange:(NSRange)range;
- (BOOL)isMatchedByRegex:(NSString *)pattern options:(RKLRegexOptions)options inRange:(NSRange)range error:(NSError **)error;
- (BOOL)isMatchedByRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions inRange:(NSRange)range error:(NSError **)error;

#pragma mark - rangeOfRegex:

- (NSRange)rangeOfRegex:(NSString *)pattern;
- (NSRange)rangeOfRegex:(NSString *)pattern capture:(NSInteger)capture;
- (NSRange)rangeOfRegex:(NSString *)pattern inRange:(NSRange)range;
- (NSRange)rangeOfRegex:(NSString *)pattern options:(RKLRegexOptions)options inRange:(NSRange)range capture:(NSInteger)capture error:(NSError **)error;
- (NSRange)rangeOfRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions inRange:(NSRange)range capture:(NSInteger)capture error:(NSError **)error;

#pragma mark - rangesOfRegex:

- (NSArray *)rangesOfRegex:(NSString *)pattern;
- (NSArray *)rangesOfRegex:(NSString *)pattern inRange:(NSRange)targetRange;
- (NSArray *)rangesOfRegex:(NSString *)pattern options:(RKLRegexOptions)options inRange:(NSRange)targetRange error:(NSError **)error;
- (NSArray *)rangesOfRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions inRange:(NSRange)targetRange error:(NSError **)error;

#pragma mark - stringByMatching:

- (NSString *)stringByMatching:(NSString *)pattern;
- (NSString *)stringByMatching:(NSString *)pattern capture:(NSInteger)capture;
- (NSString *)stringByMatching:(NSString *)pattern inRange:(NSRange)range;
- (NSString *)stringByMatching:(NSString *)pattern options:(RKLRegexOptions)options inRange:(NSRange)range capture:(NSInteger)capture error:(NSError **)error;
- (NSString *)stringByMatching:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions inRange:(NSRange)range capture:(NSInteger)capture error:(NSError **)error;

#pragma mark - stringByReplacincOccurrencesOfRegex:withString:

- (NSString *)stringByReplacingOccurrencesOfRegex:(NSString *)pattern withString:(NSString *)replacement;
- (NSString *)stringByReplacingOccurrencesOfRegex:(NSString *)pattern withString:(NSString *)replacement range:(NSRange)searchRange;
- (NSString *)stringByReplacingOccurrencesOfRegex:(NSString *)pattern withString:(NSString *)replacement options:(RKLRegexOptions)options range:(NSRange)searchRange error:(NSError **)error;
- (NSString *)stringByReplacingOccurrencesOfRegex:(NSString *)pattern withString:(NSString *)replacement options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions range:(NSRange)searchRange error:(NSError **)error;

#pragma mark - captureCount:

- (NSInteger)captureCount;
- (NSInteger)captureCountWithOptions:(RKLRegexOptions)options error:(NSError **)error;

#pragma mark - isRegexValid

- (BOOL)isRegexValid;
- (BOOL)isRegexValidWithOptions:(RKLRegexOptions)options error:(NSError **)error;

#pragma mark - componentsMatchedByRegex:

- (NSArray *)componentsMatchedByRegex:(NSString *)pattern;
- (NSArray *)componentsMatchedByRegex:(NSString *)pattern capture:(NSInteger)capture;
- (NSArray *)componentsMatchedByRegex:(NSString *)pattern range:(NSRange)range;
- (NSArray *)componentsMatchedByRegex:(NSString *)pattern options:(RKLRegexOptions)options range:(NSRange)range capture:(NSInteger)capture error:(NSError **)error;
- (NSArray *)componentsMatchedByRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions range:(NSRange)range capture:(NSInteger)capture error:(NSError **)error;

#pragma mark - captureComponentsMatchedByRegex:

- (NSArray *)captureComponentsMatchedByRegex:(NSString *)pattern;
- (NSArray *)captureComponentsMatchedByRegex:(NSString *)pattern range:(NSRange)range;
- (NSArray *)captureComponentsMatchedByRegex:(NSString *)pattern options:(RKLRegexOptions)options range:(NSRange)range error:(NSError **)error;
- (NSArray *)captureComponentsMatchedByRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions range:(NSRange)range error:(NSError **)error;

#pragma mark - arrayOfCaptureComponentsMatchedByRegex:

- (NSArray *)arrayOfCaptureComponentsMatchedByRegex:(NSString *)pattern;
- (NSArray *)arrayOfCaptureComponentsMatchedByRegex:(NSString *)pattern range:(NSRange)range;
- (NSArray *)arrayOfCaptureComponentsMatchedByRegex:(NSString *)pattern options:(RKLRegexOptions)options range:(NSRange)range error:(NSError **)error;
- (NSArray *)arrayOfCaptureComponentsMatchedByRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions range:(NSRange)range error:(NSError **)error;

#pragma mark - arrayOfDictionariesByMatchingRegex:

- (NSArray *)arrayOfDictionariesByMatchingRegex:(NSString *)pattern withKeysAndCaptures:(id)firstKey, ... NS_REQUIRES_NIL_TERMINATION;
- (NSArray *)arrayOfDictionariesByMatchingRegex:(NSString *)pattern range:(NSRange)range withKeysAndCaptures:(id)firstKey, ... NS_REQUIRES_NIL_TERMINATION;
- (NSArray *)arrayOfDictionariesByMatchingRegex:(NSString *)pattern options:(RKLRegexOptions)options range:(NSRange)range error:(NSError **)error withKeysAndCaptures:(id)firstKey, ... NS_REQUIRES_NIL_TERMINATION;
- (NSArray *)arrayOfDictionariesByMatchingRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions range:(NSRange)range error:(NSError **)error withKeysAndCaptures:(id)firstKey, ... NS_REQUIRES_NIL_TERMINATION;

- (NSArray *)arrayOfDictionariesByMatchingRegex:(NSString *)pattern options:(RKLRegexOptions)options range:(NSRange)range error:(NSError **)error withKeys:(NSArray *)keys forCaptures:(NSArray *)captures;
- (NSArray *)arrayOfDictionariesByMatchingRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions range:(NSRange)range error:(NSError **)error withKeys:(NSArray *)keys forCaptures:(NSArray *)captures;

#pragma mark - dictionaryByMatchingRegex:

- (NSDictionary *)dictionaryByMatchingRegex:(NSString *)pattern withKeysAndCaptures:(id)firstKey, ... NS_REQUIRES_NIL_TERMINATION;
- (NSDictionary *)dictionaryByMatchingRegex:(NSString *)pattern range:(NSRange)range withKeysAndCaptures:(id)firstKey, ... NS_REQUIRES_NIL_TERMINATION;
- (NSDictionary *)dictionaryByMatchingRegex:(NSString *)pattern options:(RKLRegexOptions)options range:(NSRange)range error:(NSError **)error withKeysAndCaptures:(id)firstKey, ... NS_REQUIRES_NIL_TERMINATION;

- (NSDictionary *)dictionaryByMatchingRegex:(NSString *)pattern options:(RKLRegexOptions)options range:(NSRange)range error:(NSError **)error withKeys:(NSArray *)keys forCaptures:(NSArray *)captures;
- (NSDictionary *)dictionaryByMatchingRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions range:(NSRange)range error:(NSError **)error withKeys:(NSArray *)keys forCaptures:(NSArray *)captures;


#pragma mark - enumerateStringsMatchedByRegex:usingBlock:

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"

/**
 Enumerates the matches in the receiver by the regular expression regex and executes the block serially from left-to-right for each match found.
 
 @param pattern A NSString containing a valid regular expression.
 @param block The block that is executed for each match of regex in the receiver. The block takes four arguments:
 @param captureCount The number of strings that regex captured. captureCount is always at least 1.
 @param capturedStrings An array containing the substrings matched by each capture group present in regex. The size of the array is captureCount. If a capture group did not match anything, it will contain a pointer to a string that is equal to @"".
 @param capturedRanges An array containing the ranges matched by each capture group present in regex. The size of the array is captureCount. If a capture group did not match anything, it will contain a NSRange equal to {NSNotFound, 0}.
 @param stop A reference to a BOOL value that the block can use to stop the enumeration by setting *stop = YES;, otherwise it should not touch *stop.
 @return Returns YES if there was no error, otherwise returns NO and indirectly returns a NSError object if error is not NULL.
 */
- (BOOL)enumerateStringsMatchedByRegex:(NSString *)pattern usingBlock:(void (^)(NSInteger captureCount, NSArray *capturedStrings, const NSRange capturedRanges[captureCount], volatile BOOL * const stop))block;

/**
 Enumerates the matches in the receiver by the regular expression regex within range using options and matchingOptions and executes the block using enumerationOptions for each match found.
 
 @param pattern A NSString containing a valid regular expression.
 @param options A mask of options specified by combining RKLRegexOptions flags with the C bitwise OR operator. Either 0 or RKLNoOptions may be used if no options are required.
 @param matchingOptions A mask of options specified by combining NSMatchingOptions flags with the C bitwise OR operator. 0 may be used if no options are required.
 @param range The range of the receiver to search.
 @param error An optional parameter that if set and an error occurs, will contain a NSError object that describes the problem. This may be set to NULL if information about any errors is not required.
 @param enumerationOptions Options for block enumeration operations. Use 0 for serial forward operations (best with left-to-right languages). Use NSEnumerationReverse for right-to-left languages.
 @param block The block that is executed for each match of regex in the receiver. The block takes four arguments:
 @param captureCount The number of strings that regex captured. captureCount is always at least 1.
 @param capturedStrings An array containing the substrings matched by each capture group present in regex. The size of the array is captureCount. If a capture group did not match anything, it will contain a pointer to a string that is equal to @"".
 @param capturedRanges An array containing the ranges matched by each capture group present in regex. The size of the array is captureCount. If a capture group did not match anything, it will contain a NSRange equal to {NSNotFound, 0}.
 @param stop A reference to a BOOL value that the block can use to stop the enumeration by setting *stop = YES;, otherwise it should not touch *stop.
 @return Returns YES if there was no error, otherwise returns NO and indirectly returns a NSError object if error is not NULL.
 */
- (BOOL)enumerateStringsMatchedByRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions inRange:(NSRange)range error:(NSError **)error enumerationOptions:(NSEnumerationOptions)enumerationOptions usingBlock:(void (^)(NSInteger captureCount, NSArray *capturedStrings, const NSRange capturedRanges[captureCount], volatile BOOL * const stop))block;
#pragma clang diagnostic pop

#pragma mark - enumerateStringsSeparatedByRegex:usingBlock:

- (BOOL)enumerateStringsSeparatedByRegex:(NSString *)pattern usingBlock:(void (^)(NSInteger captureCount, NSArray *capturedStrings, const NSRange capturedRanges[captureCount], volatile BOOL * const stop))block;
- (BOOL)enumerateStringsSeparatedByRegex:(NSString *)pattern options:(RKLRegexOptions)options inRange:(NSRange)range error:(NSError **)error usingBlock:(void (^)(NSInteger captureCount, NSArray *capturedStrings, const NSRange capturedRanges[captureCount], volatile BOOL * const stop))block;
- (BOOL)enumerateStringsSeparatedByRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions inRange:(NSRange)range error:(NSError **)error usingBlock:(void (^)(NSInteger captureCount, NSArray *capturedStrings, const NSRange capturedRanges[captureCount], volatile BOOL * const stop))block;

#pragma mark - stringByReplacingOccurrencesOfRegex:usingBlock:

- (NSString *)stringByReplacingOccurrencesOfRegex:(NSString *)pattern usingBlock:(NSString *(^)(NSInteger captureCount, NSArray *capturedStrings, const NSRange capturedRanges[captureCount], volatile BOOL * const stop))block;
- (NSString *)stringByReplacingOccurrencesOfRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions inRange:(NSRange)range error:(NSError **)error usingBlock:(NSString *(^)(NSInteger captureCount, NSArray *capturedStrings, const NSRange capturedRanges[captureCount], volatile BOOL * const stop))block;

@end

@interface NSMutableString (DFRegexKitLite)

#pragma mark - replaceOccurrencesOfRegex:withString:

- (NSInteger)replaceOccurrencesOfRegex:(NSString *)pattern withString:(NSString *)replacement;
- (NSInteger)replaceOccurrencesOfRegex:(NSString *)pattern withString:(NSString *)replacement range:(NSRange)searchRange;
- (NSInteger)replaceOccurrencesOfRegex:(NSString *)pattern withString:(NSString *)replacement options:(RKLRegexOptions)options range:(NSRange)searchRange error:(NSError **)error;
- (NSInteger)replaceOccurrencesOfRegex:(NSString *)pattern withString:(NSString *)replacement options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions range:(NSRange)searchRange error:(NSError **)error;

#pragma mark - replaceOccurrencesOfRegex:usingBlock:

- (NSInteger)replaceOccurrencesOfRegex:(NSString *)pattern usingBlock:(NSString *(^)(NSInteger captureCount, NSArray *capturedStrings, const NSRange capturedRanges[captureCount], volatile BOOL * const stop))block;
- (NSInteger)replaceOccurrencesOfRegex:(NSString *)pattern options:(RKLRegexOptions)options inRange:(NSRange)range error:(NSError **)error usingBlock:(NSString *(^)(NSInteger captureCount, NSArray *capturedStrings, const NSRange capturedRanges[captureCount], volatile BOOL * const stop))block;
- (NSInteger)replaceOccurrencesOfRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions inRange:(NSRange)range error:(NSError **)error usingBlock:(NSString *(^)(NSInteger captureCount, NSArray *capturedStrings, const NSRange capturedRanges[captureCount], volatile BOOL * const stop))block;

@end

