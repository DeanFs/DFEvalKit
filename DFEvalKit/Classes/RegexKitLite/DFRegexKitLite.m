//
//  DFRegexKitLite.m
//  DFEvalKit
//
//  Created by Dean_F on 2017/6/7.
//  Copyright © 2017年 Dean_F. All rights reserved.
//

#import "DFRegexKitLite.h"

#define RKL_EXPECTED(cond, expect)       __builtin_expect((long)(cond), (expect))

@implementation NSString (EntireRange)

- (NSRange)stringRange
{
    return NSMakeRange(0, self.length);
}

@end

@implementation NSString (DFRegexKitLite)

#pragma mark - Caching Methods

+ (NSString *)cacheKeyForRegex:(NSString *)pattern options:(RKLRegexOptions)options
{
    NSString *key = [NSString stringWithFormat:@"%@_%lu", pattern, (unsigned long)options];
    return key;
}

+ (NSRegularExpression *)cachedRegexForPattern:(NSString *)patten options:(RKLRegexOptions)options error:(NSError **)error
{
    NSString *regexKey = [NSString cacheKeyForRegex:patten options:options];
    NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
    NSRegularExpression *regex = dictionary[regexKey];
    
    if (!regex) {
        NSRegularExpressionOptions regexOptions = (NSRegularExpressionOptions)options;
        regex = [NSRegularExpression regularExpressionWithPattern:patten options:regexOptions error:error];
        if (!regex) return nil;
        dictionary[regexKey] = regex;
    }
    
    return regex;
}

#pragma mark - componentsSeparatedByRegex:

- (NSArray *)componentsSeparatedByRegex:(NSString *)pattern
{
    return [self componentsSeparatedByRegex:pattern options:RKLNoOptions matchingOptions:0 range:[self stringRange] error:NULL];
}

- (NSArray *)componentsSeparatedByRegex:(NSString *)pattern range:(NSRange)range
{
    return [self componentsSeparatedByRegex:pattern options:RKLNoOptions matchingOptions:0 range:range error:NULL];
}

- (NSArray *)componentsSeparatedByRegex:(NSString *)pattern options:(RKLRegexOptions)options range:(NSRange)range error:(NSError **)error
{
    return [self componentsSeparatedByRegex:pattern options:options matchingOptions:0 range:range error:NULL];
}

- (NSArray *)componentsSeparatedByRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions range:(NSRange)range error:(NSError **)error
{
    if (error == NULL) {
        if (![pattern isRegexValid]) return nil;
    }
    
    // Repurposed from https://stackoverflow.com/a/9185677
    NSRegularExpression *regex = [NSString cachedRegexForPattern:pattern options:options error:error];
    if (error) return nil;
    NSArray *matchResults = [regex matchesInString:self options:matchingOptions range:range];
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:matchResults.count];
    __block NSUInteger pos = 0;
    
    [regex enumerateMatchesInString:self options:matchingOptions range:range usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
        NSRange substrRange = NSMakeRange(pos, [result range].location - pos);
        [returnArray addObject:[self substringWithRange:substrRange]];
        pos = [result range].location + [result range].length;
    }];
    
    if (pos < range.length) {
        [returnArray addObject:[self substringFromIndex:pos]];
    }
    
    return returnArray;
}

#pragma mark - isMatchedByRegex:

- (BOOL)isMatchedByRegex:(NSString *)pattern
{
    return [self isMatchedByRegex:pattern options:RKLNoOptions matchingOptions:0 inRange:[self stringRange] error:NULL];
}

- (BOOL)isMatchedByRegex:(NSString *)pattern inRange:(NSRange)range
{
    return [self isMatchedByRegex:pattern options:RKLNoOptions matchingOptions:0 inRange:range error:NULL];
}

- (BOOL)isMatchedByRegex:(NSString *)pattern options:(RKLRegexOptions)options inRange:(NSRange)range error:(NSError **)error
{
    return [self isMatchedByRegex:pattern options:options matchingOptions:0 inRange:range error:error];
}

- (BOOL)isMatchedByRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions inRange:(NSRange)range error:(NSError **)error;
{
    if (error == NULL) {
        if (![pattern isRegexValid]) return NO;
    }
    
    NSRegularExpression *regex = [NSString cachedRegexForPattern:pattern options:options error:error];
    if (error) return NO;
    NSUInteger matchCount = [regex numberOfMatchesInString:self options:matchingOptions range:range];
    
    return (matchCount > 0);
}

#pragma mark - rangeOfRegex:

- (NSRange)rangeOfRegex:(NSString *)pattern
{
    return [self rangeOfRegex:pattern options:RKLNoOptions matchingOptions:0 inRange:[self stringRange] capture:0 error:NULL];
}

- (NSRange)rangeOfRegex:(NSString *)pattern capture:(NSInteger)capture
{
    return [self rangeOfRegex:pattern options:RKLNoOptions matchingOptions:0 inRange:[self stringRange] capture:capture error:NULL];
}

- (NSRange)rangeOfRegex:(NSString *)pattern inRange:(NSRange)range
{
    return [self rangeOfRegex:pattern options:RKLNoOptions matchingOptions:0 inRange:range capture:0 error:NULL];
}

- (NSRange)rangeOfRegex:(NSString *)pattern options:(RKLRegexOptions)options inRange:(NSRange)range capture:(NSInteger)capture error:(NSError **)error
{
    return [self rangeOfRegex:pattern options:options matchingOptions:0 inRange:range capture:capture error:error];
}

- (NSRange)rangeOfRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions inRange:(NSRange)range capture:(NSInteger)capture error:(NSError **)error
{
    NSCParameterAssert(capture >= 0);
    if (error == NULL) {
        if (![pattern isRegexValid]) return NSMakeRange(NSNotFound, NSIntegerMax);
    }
    
    NSRegularExpression *regex = [NSString cachedRegexForPattern:pattern options:options error:error];
    if (error) return NSMakeRange(NSNotFound, NSIntegerMax);
    
    if ([self isMatchedByRegex:pattern options:options matchingOptions:matchingOptions inRange:range error:error]) {
        NSArray *matches = [regex matchesInString:self options:matchingOptions range:range];
        NSTextCheckingResult *firstMatch = matches[0];
        return [firstMatch rangeAtIndex:capture];
    }
    
    return NSMakeRange(NSNotFound, 0);
}

#pragma mark - rangesOfRegex:

- (NSArray *)rangesOfRegex:(NSString *)pattern
{
    return [self rangesOfRegex:pattern options:RKLNoOptions matchingOptions:0 inRange:[self stringRange] error:NULL];
}

- (NSArray *)rangesOfRegex:(NSString *)pattern inRange:(NSRange)targetRange
{
    return [self rangesOfRegex:pattern options:RKLNoOptions matchingOptions:0 inRange:targetRange error:NULL];
}

- (NSArray *)rangesOfRegex:(NSString *)pattern options:(RKLRegexOptions)options inRange:(NSRange)targetRange error:(NSError **)error
{
    return [self rangesOfRegex:pattern options:options matchingOptions:0 inRange:targetRange error:error];
}

- (NSArray *)rangesOfRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions inRange:(NSRange)targetRange error:(NSError **)error
{
    if (error == NULL) {
        if (![pattern isRegexValid]) return nil;
    }
    
    NSMutableArray *ranges = [NSMutableArray array];
    NSRegularExpression *regex = [NSString cachedRegexForPattern:pattern options:options error:error];
    if (error) return nil;
    
    if ([self isMatchedByRegex:pattern options:options matchingOptions:matchingOptions inRange:targetRange error:error]) {
        [regex enumerateMatchesInString:self options:matchingOptions range:targetRange usingBlock:^(NSTextCheckingResult * _Nullable match, NSMatchingFlags flags, BOOL * _Nonnull stop) {
            for (NSInteger i = 0; i < match.numberOfRanges; i++) {
                NSRange matchRange = [match rangeAtIndex:i];
                [ranges addObject:[NSValue valueWithRange:matchRange]];
            }
        }];
        
        return [ranges copy];
    }
    
    return nil;
}

#pragma mark - stringByMatching:

- (NSString *)stringByMatching:(NSString *)pattern
{
    return [self stringByMatching:pattern options:RKLNoOptions matchingOptions:0 inRange:[self stringRange] capture:0 error:NULL];
}

- (NSString *)stringByMatching:(NSString *)pattern capture:(NSInteger)capture
{
    return [self stringByMatching:pattern options:RKLNoOptions matchingOptions:0 inRange:[self stringRange] capture:capture error:NULL];
}

- (NSString *)stringByMatching:(NSString *)pattern inRange:(NSRange)range
{
    return [self stringByMatching:pattern options:RKLNoOptions matchingOptions:0 inRange:range capture:0 error:NULL];
}

- (NSString *)stringByMatching:(NSString *)pattern options:(RKLRegexOptions)options inRange:(NSRange)range capture:(NSInteger)capture error:(NSError **)error
{
    return [self stringByMatching:pattern options:options matchingOptions:0 inRange:range capture:capture error:error];
}

- (NSString *)stringByMatching:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions inRange:(NSRange)range capture:(NSInteger)capture error:(NSError **)error
{
    NSCParameterAssert(capture >= 0);
    if (error == NULL) {
        if (![pattern isRegexValid]) return nil;
    }
    
    NSRegularExpression *regex = [NSString cachedRegexForPattern:pattern options:options error:error];
    if (error) return nil;
    __block NSTextCheckingResult *firstMatch = nil;
    
    [regex enumerateMatchesInString:self options:matchingOptions range:range usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
        firstMatch = result;
        *stop = YES;
    }];
    
    if (firstMatch) {
        NSString *result = [self substringWithRange:[firstMatch rangeAtIndex:capture]];
        return result;
    }
    
    return nil;
}

#pragma mark - stringByReplacincOccurrencesOfRegex:withString:


- (NSString *)stringByReplacingOccurrencesOfRegex:(NSString *)pattern withString:(NSString *)replacement
{
    return [self stringByReplacingOccurrencesOfRegex:pattern withString:replacement options:RKLNoOptions matchingOptions:0 range:[self stringRange] error:NULL];
}

- (NSString *)stringByReplacingOccurrencesOfRegex:(NSString *)pattern withString:(NSString *)replacement range:(NSRange)searchRange
{
    return [self stringByReplacingOccurrencesOfRegex:pattern withString:replacement options:RKLNoOptions matchingOptions:0 range:searchRange error:NULL];
}

- (NSString *)stringByReplacingOccurrencesOfRegex:(NSString *)pattern withString:(NSString *)replacement options:(RKLRegexOptions)options range:(NSRange)searchRange error:(NSError **)error
{
    return [self stringByReplacingOccurrencesOfRegex:pattern withString:replacement options:options matchingOptions:0 range:searchRange error:error];
}

- (NSString *)stringByReplacingOccurrencesOfRegex:(NSString *)pattern withString:(NSString *)replacement options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions range:(NSRange)searchRange error:(NSError **)error
{
    if (error == NULL) {
        if (![pattern isRegexValid]) return nil;
    }
    
    NSRegularExpression *regex = [NSString cachedRegexForPattern:pattern options:options error:error];
    if (error) return nil;
    NSArray *matches = [regex matchesInString:self options:matchingOptions range:searchRange];
    NSMutableString *target = [self mutableCopy];
    
    for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
        if (match.range.location != NSNotFound) {
            [target replaceCharactersInRange:match.range withString:replacement];
        }
    }
    
    return [target copy];
}

#pragma mark - captureCount:

- (NSInteger)captureCount
{
    NSError *error;
    return [self captureCountWithOptions:RKLNoOptions error:&error];
}

- (NSInteger)captureCountWithOptions:(RKLRegexOptions)options error:(NSError **)error
{
    if (error == NULL) {
        if (![self isRegexValid]) return -1;
    }
    
    NSRegularExpression *regex = [NSString cachedRegexForPattern:self options:options error:error];
    
    if (regex) {
        return regex.numberOfCaptureGroups;
    }
    
    return -1;
}

#pragma mark - isRegexValid

- (BOOL)isRegexValid
{
    return [self isRegexValidWithOptions:RKLNoOptions error:NULL];
}

- (BOOL)isRegexValidWithOptions:(RKLRegexOptions)options error:(NSError **)error
{
    if (error == NULL) {
        NSError *localError;
        [NSString cachedRegexForPattern:self options:options error:&localError];
        if (localError) return NO;
    }
    else {
        [NSString cachedRegexForPattern:self options:options error:error];
        if (*error) return NO;
    }
    
    return YES;
}

#pragma mark - componentsMatchedByRegex:

- (NSArray *)componentsMatchedByRegex:(NSString *)pattern
{
    return [self componentsMatchedByRegex:pattern options:RKLNoOptions matchingOptions:0 range:[self stringRange] capture:0 error:NULL];
}

- (NSArray *)componentsMatchedByRegex:(NSString *)pattern capture:(NSInteger)capture
{
    return [self componentsMatchedByRegex:pattern options:RKLNoOptions matchingOptions:0 range:[self stringRange] capture:capture error:NULL];
}

- (NSArray *)componentsMatchedByRegex:(NSString *)pattern range:(NSRange)range
{
    return [self componentsMatchedByRegex:pattern options:RKLNoOptions matchingOptions:0 range:range capture:0 error:NULL];
}

- (NSArray *)componentsMatchedByRegex:(NSString *)pattern options:(RKLRegexOptions)options range:(NSRange)range capture:(NSInteger)capture error:(NSError **)error
{
    return [self componentsMatchedByRegex:pattern options:options matchingOptions:0 range:range capture:capture error:error];
}

- (NSArray *)componentsMatchedByRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions range:(NSRange)range capture:(NSInteger)capture error:(NSError **)error
{
    NSCParameterAssert(capture >= 0);
    if (error == NULL) {
        if (![pattern isRegexValid]) return nil;
    }
    
    NSRegularExpression *regex = [NSString cachedRegexForPattern:pattern options:options error:error];
    if (error) return nil;
    
    if ([self isMatchedByRegex:pattern options:options matchingOptions:matchingOptions inRange:range error:error]) {
        NSArray *matches = [regex matchesInString:self options:matchingOptions range:range];
        NSMutableArray *finalCaptures = [NSMutableArray array];
        
        for (NSTextCheckingResult *match in matches) {
            NSMutableArray *captureArray = [NSMutableArray arrayWithCapacity:match.numberOfRanges];
            
            for (NSInteger i = 0; i < match.numberOfRanges; i++) {
                NSRange matchRange = [match rangeAtIndex:i];
                NSString *matchString = (matchRange.location != NSNotFound) ? [self substringWithRange:matchRange] : @"";
                [captureArray addObject:matchString];
            }
            
            [finalCaptures addObject:captureArray[capture]];
        }
        
        return [finalCaptures copy];
    }
    
    return nil;
}

#pragma mark - captureComponentsMatchedByRegex:

- (NSArray *)captureComponentsMatchedByRegex:(NSString *)pattern;
{
    return [self captureComponentsMatchedByRegex:pattern options:RKLNoOptions range:[self stringRange] error:NULL];
}

- (NSArray *)captureComponentsMatchedByRegex:(NSString *)pattern range:(NSRange)range;
{
    return [self captureComponentsMatchedByRegex:pattern options:RKLNoOptions range:range error:NULL];
}

- (NSArray *)captureComponentsMatchedByRegex:(NSString *)pattern options:(RKLRegexOptions)options range:(NSRange)range error:(NSError **)error
{
    return [self captureComponentsMatchedByRegex:pattern options:options range:range error:error];
}

- (NSArray *)captureComponentsMatchedByRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions range:(NSRange)range error:(NSError **)error
{
    if (error == NULL) {
        if (![pattern isRegexValid]) return nil;
    }
    
    NSRegularExpression *regex = [NSString cachedRegexForPattern:pattern options:options error:error];
    if (error) return nil;
    NSArray *matches = [regex matchesInString:self options:matchingOptions range:range];
    NSTextCheckingResult *firstMatch = matches[0];
    NSMutableArray *captureArray = [NSMutableArray arrayWithCapacity:firstMatch.numberOfRanges];
    
    for (NSInteger i = 0; i < firstMatch.numberOfRanges; i++) {
        NSRange matchRange = [firstMatch rangeAtIndex:i];
        NSString *matchString = (matchRange.location != NSNotFound) ? [self substringWithRange:matchRange] : @"";
        [captureArray addObject:matchString];
    }
    
    return [captureArray copy];
}

#pragma mark - arrayOfCaptureComponentsMatchedByRegex:
// Eventually use this: https://gist.github.com/kamiro/3902122

- (NSArray *)arrayOfCaptureComponentsMatchedByRegex:(NSString *)pattern
{
    return [self arrayOfCaptureComponentsMatchedByRegex:pattern options:RKLNoOptions range:[self stringRange] error:NULL];
}

- (NSArray *)arrayOfCaptureComponentsMatchedByRegex:(NSString *)pattern range:(NSRange)range
{
    return [self arrayOfCaptureComponentsMatchedByRegex:pattern options:RKLNoOptions range:range error:NULL];
}

- (NSArray *)arrayOfCaptureComponentsMatchedByRegex:(NSString *)pattern options:(RKLRegexOptions)options range:(NSRange)range error:(NSError **)error
{
    return [self arrayOfCaptureComponentsMatchedByRegex:pattern options:options range:range error:NULL];
}

- (NSArray *)arrayOfCaptureComponentsMatchedByRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions range:(NSRange)range error:(NSError **)error;
{
    if (error == NULL) {
        if (![pattern isRegexValid]) return nil;
    }
    
    NSRegularExpression *regex = [NSString cachedRegexForPattern:pattern options:options error:error];
    if (error) return nil;
    NSArray *matches = [regex matchesInString:self options:matchingOptions range:range];
    NSMutableArray *matchCaptures = [NSMutableArray array];
    
    for (NSTextCheckingResult *match in matches) {
        NSMutableArray *captureArray = [NSMutableArray arrayWithCapacity:match.numberOfRanges];
        
        for (NSInteger i = 0; i < match.numberOfRanges; i++) {
            NSRange matchRange = [match rangeAtIndex:i];
            NSString *matchString = (matchRange.location != NSNotFound) ? [self substringWithRange:matchRange] : @"";
            [captureArray addObject:matchString];
        }
        
        [matchCaptures addObject:captureArray];
    }
    
    return [matchCaptures copy];
}

#pragma mark - arrayOfDictionariesByMatchingRegex:

- (NSArray *)arrayOfDictionariesByMatchingRegex:(NSString *)pattern withKeysAndCaptures:(id)firstKey, ... NS_REQUIRES_NIL_TERMINATION
{
    va_list varArgsList;
    va_start(varArgsList, firstKey);
    NSArray *captureKeyIndexes;
    NSArray *captureKeys = [self _keysForVarArgsList:varArgsList withFirstKey:firstKey andIndexes:&captureKeyIndexes];
    NSArray *dictArray = [self arrayOfDictionariesByMatchingRegex:pattern options:RKLNoOptions matchingOptions:0 range:[self stringRange] error:NULL withKeys:captureKeys forCaptures:captureKeyIndexes];
    va_end(varArgsList);
    
    return dictArray;
}

- (NSArray *)arrayOfDictionariesByMatchingRegex:(NSString *)pattern range:(NSRange)range withKeysAndCaptures:(id)firstKey, ... NS_REQUIRES_NIL_TERMINATION
{
    va_list varArgsList;
    va_start(varArgsList, firstKey);
    NSArray *captureKeyIndexes;
    NSArray *captureKeys = [self _keysForVarArgsList:varArgsList withFirstKey:firstKey andIndexes:&captureKeyIndexes];
    NSArray *dictArray = [self arrayOfDictionariesByMatchingRegex:pattern options:RKLNoOptions matchingOptions:0 range:range error:NULL withKeys:captureKeys forCaptures:captureKeyIndexes];
    va_end(varArgsList);
    
    return dictArray;
}

- (NSArray *)arrayOfDictionariesByMatchingRegex:(NSString *)pattern options:(RKLRegexOptions)options range:(NSRange)range error:(NSError **)error withKeysAndCaptures:(id)firstKey, ... NS_REQUIRES_NIL_TERMINATION
{
    va_list varArgsList;
    va_start(varArgsList, firstKey);
    NSArray *captureKeyIndexes;
    NSArray *captureKeys = [self _keysForVarArgsList:varArgsList withFirstKey:firstKey andIndexes:&captureKeyIndexes];
    NSArray *dictArray = [self arrayOfDictionariesByMatchingRegex:pattern options:options matchingOptions:0 range:range error:error withKeys:captureKeys forCaptures:captureKeyIndexes];
    va_end(varArgsList);
    
    return dictArray;
}

- (NSArray *)arrayOfDictionariesByMatchingRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions range:(NSRange)range error:(NSError **)error withKeysAndCaptures:(id)firstKey, ... NS_REQUIRES_NIL_TERMINATION
{
    va_list varArgsList;
    va_start(varArgsList, firstKey);
    NSArray *captureKeyIndexes;
    NSArray *captureKeys = [self _keysForVarArgsList:varArgsList withFirstKey:firstKey andIndexes:&captureKeyIndexes];
    NSArray *dictArray = [self arrayOfDictionariesByMatchingRegex:pattern options:options matchingOptions:0 range:range error:error withKeys:captureKeys forCaptures:captureKeyIndexes];
    va_end(varArgsList);
    
    return dictArray;
}

- (NSArray *)arrayOfDictionariesByMatchingRegex:(NSString *)pattern options:(RKLRegexOptions)options range:(NSRange)range error:(NSError **)error withKeys:(NSArray *)keys forCaptures:(NSArray *)captures
{
    return [self arrayOfDictionariesByMatchingRegex:pattern options:options matchingOptions:0 range:range error:error withKeys:keys forCaptures:captures];
}

- (NSArray *)arrayOfDictionariesByMatchingRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions range:(NSRange)range error:(NSError **)error withKeys:(NSArray *)keys forCaptures:(NSArray *)captures
{
    if (error == NULL) {
        if (![pattern isRegexValid]) return nil;
    }
    else {
        [NSString cachedRegexForPattern:pattern options:options error:error];
        if (error) return nil;
    }
    
    NSMutableArray *arrayOfDicts = [NSMutableArray array];
    
    [self enumerateStringsMatchedByRegex:pattern options:options matchingOptions:matchingOptions inRange:range error:error enumerationOptions:0 usingBlock:^(NSInteger captureCount, NSArray *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
        NSString *mainString = capturedStrings[0];
        NSDictionary *dict = [mainString dictionaryByMatchingRegex:pattern options:options matchingOptions:matchingOptions range:[mainString stringRange] error:error withKeys:keys forCaptures:captures];
        [arrayOfDicts addObject:dict];
    }];
    
    return [arrayOfDicts copy];
}

#pragma mark - dictionaryByMatchingRegex:

- (NSArray *)_keysForVarArgsList:(va_list)varArgsList withFirstKey:(id)firstKey andIndexes:(NSArray **)captureIndexes
{
    NSMutableArray *captureKeys = [NSMutableArray arrayWithCapacity:64];
    NSMutableArray *captureKeyIndexes = [NSMutableArray arrayWithCapacity:64];
    NSUInteger captureKeysCount = 0UL;
    
    if (varArgsList != NULL) {
        while (captureKeysCount < 62UL) {
            id  thisCaptureKey = (captureKeysCount == 0) ? firstKey : va_arg(varArgsList, id);
            if (RKL_EXPECTED(thisCaptureKey == NULL, 0L)) { break; }
            int thisCaptureKeyIndex = va_arg(varArgsList, int);
            [captureKeys addObject:thisCaptureKey];
            [captureKeyIndexes addObject:@(thisCaptureKeyIndex)];
            captureKeysCount++;
        }
    }
    
    *captureIndexes = [captureKeyIndexes copy];
    return [captureKeys copy];
}

- (NSDictionary *)dictionaryByMatchingRegex:(NSString *)pattern withKeysAndCaptures:(id)firstKey, ... NS_REQUIRES_NIL_TERMINATION
{
    va_list varArgsList;
    va_start(varArgsList, firstKey);
    NSArray *captureKeyIndexes;
    NSArray *captureKeys = [self _keysForVarArgsList:varArgsList withFirstKey:firstKey andIndexes:&captureKeyIndexes];
    NSDictionary *dict = [self dictionaryByMatchingRegex:pattern options:RKLNoOptions matchingOptions:0 range:[self stringRange] error:NULL withKeys:captureKeys forCaptures:captureKeyIndexes];
    va_end(varArgsList);
    return dict;
}

- (NSDictionary *)dictionaryByMatchingRegex:(NSString *)pattern range:(NSRange)range withKeysAndCaptures:(id)firstKey, ... NS_REQUIRES_NIL_TERMINATION
{
    va_list varArgsList;
    va_start(varArgsList, firstKey);
    NSArray *captureKeyIndexes;
    NSArray *keys = [self _keysForVarArgsList:varArgsList withFirstKey:firstKey andIndexes:&captureKeyIndexes];
    NSDictionary *dict = [self dictionaryByMatchingRegex:pattern options:RKLNoOptions matchingOptions:0 range:range error:NULL withKeys:keys forCaptures:captureKeyIndexes];
    va_end(varArgsList);
    return dict;
}

- (NSDictionary *)dictionaryByMatchingRegex:(NSString *)pattern options:(RKLRegexOptions)options range:(NSRange)range error:(NSError **)error withKeysAndCaptures:(id)firstKey, ... NS_REQUIRES_NIL_TERMINATION
{
    va_list varArgsList;
    va_start(varArgsList, firstKey);
    NSArray *captureKeyIndexes;
    NSArray *captureKeys = [self _keysForVarArgsList:varArgsList withFirstKey:firstKey andIndexes:&captureKeyIndexes];
    NSDictionary *dict = [self dictionaryByMatchingRegex:pattern options:options matchingOptions:0 range:range error:error withKeys:captureKeys forCaptures:captureKeyIndexes];
    va_end(varArgsList);
    return dict;
}

- (NSDictionary *)dictionaryByMatchingRegex:(NSString *)pattern options:(RKLRegexOptions)options range:(NSRange)range error:(NSError **)error withKeys:(NSArray *)keys forCaptures:(NSArray *)captures
{
    return [self dictionaryByMatchingRegex:pattern options:options matchingOptions:0 range:range error:error withKeys:keys forCaptures:captures];
}

- (NSDictionary *)dictionaryByMatchingRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions range:(NSRange)range error:(NSError **)error withKeys:(NSArray *)keys forCaptures:(NSArray *)captures
{
    if (error == NULL) {
        if (![pattern isRegexValid]) return nil;
    }
    else {
        [NSString cachedRegexForPattern:pattern options:options error:error];
        if (error) return nil;
    }
    
    NSUInteger count = [keys count];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:count];
    
    for (NSUInteger i = 0; i < count; i++) {
        id key = keys[i];
        NSInteger capture = [captures[i] integerValue];
        NSRange captureRange = [self rangeOfRegex:pattern options:options matchingOptions:matchingOptions inRange:range capture:capture error:error];
        if (captureRange.location == NSNotFound && captureRange.length == NSIntegerMax) return nil;
        dict[key] = (captureRange.location != NSNotFound) ? [self substringWithRange:captureRange] : @"";
    }
    
    return [dict copy];
}

#pragma mark - enumerateStringsMatchedByRegex:usingBlock:

- (BOOL)enumerateStringsMatchedByRegex:(NSString *)pattern usingBlock:(void (^)(NSInteger captureCount, NSArray *capturedStrings, const NSRange capturedRanges[captureCount], volatile BOOL * const stop))block
{
    return [self enumerateStringsMatchedByRegex:pattern options:RKLNoOptions matchingOptions:0 inRange:[self stringRange] error:NULL enumerationOptions:0 usingBlock:block];
}

- (BOOL)enumerateStringsMatchedByRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions inRange:(NSRange)range error:(NSError **)error enumerationOptions:(NSEnumerationOptions)enumerationOptions usingBlock:(void (^)(NSInteger captureCount, NSArray *capturedStrings, const NSRange capturedRanges[captureCount], volatile BOOL * const stop))block
{
    if (error == NULL) {
        if (![pattern isRegexValid]) return NO;
    }
    
    NSRegularExpression *regex = [NSString cachedRegexForPattern:pattern options:options error:error];
    if (error) return NO;
    NSArray *matches = [regex matchesInString:self options:matchingOptions range:range];
    __block BOOL blockStop = NO;
    
    [matches enumerateObjectsWithOptions:enumerationOptions usingBlock:^(NSTextCheckingResult *match, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger captureCount = (NSInteger)match.numberOfRanges;
        NSMutableArray *captures = [NSMutableArray array];
        NSRange rangeCaptures[captureCount];
        
        for (NSUInteger rangeIndex = 0; rangeIndex < captureCount; rangeIndex++) {
            NSRange subrange = [match rangeAtIndex:rangeIndex];
            rangeCaptures[rangeIndex] = subrange;
            NSString *substring = (subrange.location != NSNotFound) ? [self substringWithRange:subrange] : @"";
            [captures addObject:substring];
        }
        
        rangeCaptures[captureCount] = NSMakeRange(NSNotFound, NSIntegerMax);
        block(captureCount, [captures copy], rangeCaptures, &blockStop);
        *stop = blockStop;
    }];
    
    return YES;
}

#pragma mark - enumerateStringsSeparatedByRegex:usingBlock:

- (BOOL)enumerateStringsSeparatedByRegex:(NSString *)pattern usingBlock:(void (^)(NSInteger captureCount, NSArray *capturedStrings, const NSRange capturedRanges[captureCount], volatile BOOL * const stop))block
{
    return [self enumerateStringsSeparatedByRegex:pattern options:RKLNoOptions matchingOptions:0 inRange:[self stringRange] error:NULL usingBlock:block];
}

- (BOOL)enumerateStringsSeparatedByRegex:(NSString *)pattern options:(RKLRegexOptions)options inRange:(NSRange)range error:(NSError **)error usingBlock:(void (^)(NSInteger captureCount, NSArray *capturedStrings, const NSRange capturedRanges[captureCount], volatile BOOL * const stop))block
{
    return [self enumerateStringsSeparatedByRegex:pattern options:options matchingOptions:0 inRange:range error:error usingBlock:block];
}

- (BOOL)enumerateStringsSeparatedByRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions inRange:(NSRange)range error:(NSError **)error usingBlock:(void (^)(NSInteger captureCount, NSArray *capturedStrings, const NSRange capturedRanges[captureCount], volatile BOOL * const stop))block
{
    if (error == NULL) {
        if (![pattern isRegexValid]) return NO;
    }
    
    NSRegularExpression *regex = [NSString cachedRegexForPattern:pattern options:options error:error];
    if (error) return NO;
    NSString *cloneString = [NSString stringWithString:self];
    NSArray *matches = [regex matchesInString:self options:matchingOptions range:range];
    __block BOOL blockStop = NO;
    __block NSRange remainderRange;
    
    [matches enumerateObjectsUsingBlock:^(NSTextCheckingResult *match, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger captureCount = (NSInteger)match.numberOfRanges;
        NSMutableArray *captures = [NSMutableArray array];
        NSRange rangeCaptures[captureCount];
        
        for (NSUInteger rangeIndex = 0; rangeIndex < captureCount; rangeIndex++) {
            NSRange subrange = [match rangeAtIndex:rangeIndex];
            
            if (![captures count]) {
                NSString *targetString;
                NSRange targetRange;
                
                if (idx == 0) {
                    targetString = [cloneString substringToIndex:subrange.location];
                    targetRange = [cloneString rangeOfString:targetString];
                }
                else {
                    targetRange = NSMakeRange(remainderRange.location, (subrange.location - remainderRange.location));
                    targetString = [cloneString substringWithRange:targetRange];
                }
                
                [captures addObject:targetString];
                rangeCaptures[rangeIndex] = targetRange;
                NSUInteger newLocation = subrange.location + subrange.length;
                NSString *remainderString = [cloneString substringFromIndex:newLocation];
                remainderRange = [cloneString rangeOfString:remainderString];
            }
            else {
                rangeCaptures[rangeIndex] = subrange;
                NSString *substring = (subrange.location != NSNotFound) ? [self substringWithRange:subrange] : @"";
                [captures addObject:substring];
            }
        }
        
        rangeCaptures[captureCount] = NSMakeRange(NSNotFound, NSIntegerMax);
        block(captureCount, [captures copy], rangeCaptures, &blockStop);
        *stop = blockStop;
    }];
    
    return YES;
}


#pragma mark - stringByReplacingOccurrencesOfRegex:usingBlock:

- (NSString *)stringByReplacingOccurrencesOfRegex:(NSString *)pattern usingBlock:(NSString *(^)(NSInteger captureCount, NSArray *capturedStrings, const NSRange capturedRanges[captureCount], volatile BOOL * const stop))block
{
    return [self stringByReplacingOccurrencesOfRegex:pattern options:RKLNoOptions matchingOptions:0 inRange:[self stringRange] error:NULL usingBlock:block];
}

- (NSString *)stringByReplacingOccurrencesOfRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions inRange:(NSRange)range error:(NSError **)error usingBlock:(NSString *(^)(NSInteger captureCount, NSArray *capturedStrings, const NSRange capturedRanges[captureCount], volatile BOOL * const stop))block
{
    if (error == NULL) {
        if (![pattern isRegexValid]) return nil;
    }
    
    NSRegularExpression *regex = [NSString cachedRegexForPattern:pattern options:options error:error];
    if (error) return nil;
    NSArray *matches = [regex matchesInString:self options:matchingOptions range:range];
    NSMutableString *target = [NSMutableString stringWithString:self];
    BOOL stop = NO;
    
    if (![matches count]) {
        return [NSString stringWithString:self];
    }
    
    for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
        NSInteger captureCount = (NSInteger)match.numberOfRanges;
        NSMutableArray *captures = [NSMutableArray array];
        NSRange rangeCaptures[captureCount];
        
        for (NSUInteger rangeIndex = 0; rangeIndex < captureCount; rangeIndex++) {
            NSRange subrange = [match rangeAtIndex:rangeIndex];
            rangeCaptures[rangeIndex] = subrange;
            NSString *substring = (subrange.location != NSNotFound) ? [self substringWithRange:subrange] : @"";
            [captures addObject:substring];
        }
        
        rangeCaptures[captureCount] = NSMakeRange(NSNotFound, NSIntegerMax);
        NSString *replacement = block(captureCount, [captures copy], rangeCaptures, &stop);
        [target replaceCharactersInRange:match.range withString:replacement];
        
        if (stop == YES) {
            break;
        }
    }
    
    return [target copy];
}

@end

@implementation NSMutableString (DFRegexKitLite)

#pragma mark - replaceOccurrencesOfRegex:withString:


- (NSInteger)replaceOccurrencesOfRegex:(NSString *)pattern withString:(NSString *)replacement
{
    return [self replaceOccurrencesOfRegex:pattern withString:replacement options:RKLNoOptions matchingOptions:0 range:[self stringRange] error:NULL];
}

- (NSInteger)replaceOccurrencesOfRegex:(NSString *)pattern withString:(NSString *)replacement range:(NSRange)searchRange
{
    return [self replaceOccurrencesOfRegex:pattern withString:replacement options:RKLNoOptions matchingOptions:0 range:searchRange error:NULL];
}

- (NSInteger)replaceOccurrencesOfRegex:(NSString *)pattern withString:(NSString *)replacement options:(RKLRegexOptions)options range:(NSRange)searchRange error:(NSError **)error
{
    return [self replaceOccurrencesOfRegex:pattern withString:replacement options:options matchingOptions:0 range:searchRange error:error];
}

- (NSInteger)replaceOccurrencesOfRegex:(NSString *)pattern withString:(NSString *)replacement options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions range:(NSRange)searchRange error:(NSError **)error
{
    if (error == NULL) {
        if (![pattern isRegexValid]) return -1;
    }
    
    NSRegularExpression *regex = [NSString cachedRegexForPattern:pattern options:options error:error];
    if (error) return -1;
    NSArray *matches = [regex matchesInString:self options:matchingOptions range:searchRange];
    NSInteger count = 0;
    
    for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
        if (match.range.location != NSNotFound) {
            [self replaceCharactersInRange:match.range withString:replacement];
            count++;
        }
    }
    
    return count;
}


#pragma mark - replaceOccurrencesOfRegex:usingBlock:

- (NSInteger)replaceOccurrencesOfRegex:(NSString *)pattern usingBlock:(NSString *(^)(NSInteger captureCount, NSArray *capturedStrings, const NSRange capturedRanges[captureCount], volatile BOOL * const stop))block
{
    return [self replaceOccurrencesOfRegex:pattern options:RKLNoOptions matchingOptions:0 inRange:[self stringRange] error:NULL usingBlock:block];
}

- (NSInteger)replaceOccurrencesOfRegex:(NSString *)pattern options:(RKLRegexOptions)options inRange:(NSRange)range error:(NSError **)error usingBlock:(NSString *(^)(NSInteger captureCount, NSArray *capturedStrings, const NSRange capturedRanges[captureCount], volatile BOOL * const stop))block
{
    return [self replaceOccurrencesOfRegex:pattern options:options matchingOptions:0 inRange:range error:error usingBlock:block];
}

- (NSInteger)replaceOccurrencesOfRegex:(NSString *)pattern options:(RKLRegexOptions)options matchingOptions:(NSMatchingOptions)matchingOptions inRange:(NSRange)range error:(NSError **)error usingBlock:(NSString *(^)(NSInteger captureCount, NSArray *capturedStrings, const NSRange capturedRanges[captureCount], volatile BOOL * const stop))block
{
    if (error == NULL) {
        if (![pattern isRegexValid]) return -1;
    }
    
    NSRegularExpression *regex = [NSString cachedRegexForPattern:pattern options:options error:error];
    if (error) return -1;
    NSArray *matches = [regex matchesInString:self options:matchingOptions range:range];
    NSInteger count = 0;
    BOOL stop = NO;
    
    if (![matches count]) {
        return 0;
    }
    
    for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
        NSInteger captureCount = (NSInteger)match.numberOfRanges;
        NSMutableArray *captures = [NSMutableArray array];
        NSRange rangeCaptures[captureCount];
        
        for (NSUInteger rangeIndex = 0; rangeIndex < captureCount; rangeIndex++) {
            NSRange subrange = [match rangeAtIndex:rangeIndex];
            rangeCaptures[rangeIndex] = subrange;
            NSString *substring = (subrange.location != NSNotFound) ? [self substringWithRange:subrange] : @"";
            [captures addObject:substring];
        }
        
        rangeCaptures[captureCount] = NSMakeRange(NSNotFound, NSIntegerMax);
        NSString *replacement = block(captureCount, [captures copy], rangeCaptures, &stop);
        [self replaceCharactersInRange:match.range withString:replacement];
        count++;
        
        if (stop == YES) {
            break;
        }
    }
    
    return count;
}

@end



