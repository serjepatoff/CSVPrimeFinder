//
//  NSArray+SECSVExt.h
//  CSVPrimeFinder
//
//  Created by Sergei Epatov on 2/22/17.
//  Copyright © 2017 Sergei Epatov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (SECSVExt)

- (instancetype)mapObjectsUsingBlock:(id (^)(id obj, NSUInteger idx))block;
- (instancetype)parallelMapObjectsWithThreadCount:(NSUInteger)threadCount usingBlock:(id(^)(id obj))block;
- (instancetype)flattenArrayOfSubarrays;

@end
