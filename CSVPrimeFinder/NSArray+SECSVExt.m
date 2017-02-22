//
//  NSArray+SECSVExt.m
//  CSVPrimeFinder
//
//  Created by Sergei Epatov on 2/22/17.
//  Copyright © 2017 Sergei Epatov. All rights reserved.
//

#import "NSArray+SECSVExt.h"

@implementation NSArray (SECSVExt)

- (instancetype)mapObjectsUsingBlock:(id (^)(id obj, NSUInteger idx))block {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id item = block(obj, idx);
        if (item) {
            [result addObject:item];
        }
    }];
    
    return result;
}

- (instancetype)parallelMapObjectsWithThreadCount:(NSUInteger)threadCount usingBlock:(id(^)(id obj))block {
    NSParameterAssert(block);
    
    if (self.count == 0 || !block) {
        return @[];
    }
    
    dispatch_group_t group = dispatch_group_create();
    
    uintptr_t *plainArr = calloc(sizeof(uintptr_t), self.count);
    [self enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        plainArr[idx] = (uintptr_t)(__bridge void*)obj;
    }];
    
    for (NSUInteger taskCtr = 0; taskCtr < threadCount; taskCtr++) {
        dispatch_group_enter(group);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
            for (NSUInteger pos = taskCtr; pos < self.count; pos += threadCount) {
                id obj = (__bridge id)(void *)plainArr[pos];
                id mappedObj = block(obj);
                plainArr[pos] = (uintptr_t)(__bridge_retained void*)(mappedObj ?: [NSNull null]);
            }
            
            dispatch_group_leave(group);
        });
    }
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    NSMutableArray *result = nil;
    result = [NSMutableArray arrayWithObjects:(__unsafe_unretained id *)(void *)plainArr count:self.count];
    [result removeObjectIdenticalTo:[NSNull null]];
    
    for (NSUInteger i = 0; i < self.count; i ++) {
        id obj = (__bridge_transfer id)(void *)plainArr[i];
        obj = nil;
    }
    
    free(plainArr);
    
    return [result copy];
}

- (instancetype)flattenArrayOfSubarrays {
    NSMutableArray* flatArray = [NSMutableArray array];
    for (NSArray *subarr in self) {
        if ([subarr isKindOfClass:[NSArray class]]) {
            [flatArray addObjectsFromArray:subarr];
        }
    }
    
    return [flatArray copy];
}

@end
