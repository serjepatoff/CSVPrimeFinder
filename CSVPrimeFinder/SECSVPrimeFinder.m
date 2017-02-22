//
//  CSVPrimeFinder.m
//  CSVPrimeFinder
//
//  Created by Sergei Epatov on 2/22/17.
//  Copyright © 2017 Sergei Epatov. All rights reserved.
//

#import "SECSVPrimeFinder.h"
#import "NSArray+SECSVExt.h"
#import "SEGMPPrimeProbe.h"

static NSString * const CSVPrimeFinderErrorDomain = @"PrimeFinderError";
static NSString * const CSVPrimeFinderErrorFilenameKey = @"filename";

@implementation SECSVPrimeFinder

#pragma mark - Public

- (NSError *)findPrimesInFilesNamed:(NSArray<NSString *> *)inputFileNames storeToFileNamed:(NSString *)outputFileName {
    NSError *error = ([self checkInputFilesNamed:inputFileNames] ?:
                      [self checkOutputFileNamed:outputFileName] ?:
                      [self checkOutputFileNamed:outputFileName containedInInputFilesNamed:inputFileNames]);
    if (error) {
        return error;
    }
    
    NSInteger concurrency = 1;
    if (!self.forceSingleThreaded) {
        concurrency = [[NSProcessInfo processInfo] activeProcessorCount] ?: 1;
    }
    
    NSArray *results = [inputFileNames parallelMapObjectsWithThreadCount:concurrency usingBlock:^id(NSString *fname) {
        NSArray *components = [self commaSeparatedComponentsOfFileNamed:fname];
        
        NSIndexSet *passed = [components indexesOfObjectsPassingTest:^BOOL(NSString *str, NSUInteger idx, BOOL *stop) {
            return SEGMPIsPrime([str UTF8String]);
        }];

        return [components objectsAtIndexes:passed];
    }];
    
    results = [results flattenArrayOfSubarrays];
    if (results.count) {
        NSString *outContent = [results componentsJoinedByString:@",\n"];
        [outContent writeToFile:outputFileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    
    return nil;
}

- (NSString *)printableDescriptionFromError:(NSError *)error {
    NSInteger actualErrCode = [error.domain isEqualToString:CSVPrimeFinderErrorDomain] ? error.code : -1;
    
    NSDictionary *codeToDesc = @{@(CSVPrimeFinderErrorCodeNone) : @"No error",
                                 @(CSVPrimeFinderErrorCodeNoInputFiles) : @"No input files",
                                 @(CSVPrimeFinderErrorCodeInputFileOpenError) : @"Error opening input file",
                                 @(CSVPrimeFinderErrorCodeInputFileReadError) : @"Error reading from input file",
                                 @(CSVPrimeFinderErrorCodeNoOutputFile) : @"No output file",
                                 @(CSVPrimeFinderErrorCodeOutputFileOpenError) : @"Error opening output file",
                                 @(CSVPrimeFinderErrorCodeOutputFileWriteError) : @"Error writing to output file",
                                 @(CSVPrimeFinderErrorCodeOutputFileContainsInInput): @"Output intersects with input"};
    
    NSString *desc = codeToDesc[@(actualErrCode)] ?: @"Unknown error";
    NSMutableString *mutableDesc = [desc mutableCopy];
    [error.userInfo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL * _Nonnull stop) {
        if (key && obj) {
            [mutableDesc appendFormat:@"\n\t%@: %@", key, obj];
        }
    }];
    
    return [mutableDesc copy];
}

#pragma mark - Error checking

- (NSError *)checkInputFilesNamed:(NSArray<NSString *> *)fileNames {
    return ([self checkCountOfFilesNamed:fileNames] ?:
            [self checkExistenceOfFilesNamed:fileNames] ?:
            [self checkReadabilityOfFilesNamed:fileNames] ?:
            nil);
}

- (NSError *)checkCountOfFilesNamed:(NSArray<NSString *> *)fileNames {
    return fileNames.count == 0 ? [self errorWithCode:CSVPrimeFinderErrorCodeNoInputFiles filename:nil] : nil;
}

- (NSError *)checkExistenceOfFilesNamed:(NSArray<NSString *> *)fileNames {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSInteger failIndex = [fileNames indexOfObjectPassingTest:^BOOL(NSString *fileName, NSUInteger idx, BOOL *stop) {
        BOOL isDir = NO;
        BOOL exists = fileName.length > 0 && [fileManager fileExistsAtPath:fileName isDirectory:&isDir];
        return isDir || !exists;
    }];
    
    if (failIndex != NSNotFound) {
        return [self errorWithCode:CSVPrimeFinderErrorCodeInputFileOpenError filename:fileNames[failIndex]];
    }
    
    return nil;
}

- (NSError *)checkReadabilityOfFilesNamed:(NSArray<NSString *> *)fileNames {
    NSInteger failIndex = [fileNames indexOfObjectPassingTest:^BOOL(NSString *fileName, NSUInteger idx, BOOL *stop) {
        const char *filenamePtr = fileName.UTF8String;
        int fd = open(filenamePtr, O_RDONLY);
        if (fd < 0) {
            return YES;
        }
        
        char dummy;
        ssize_t readResult = read(fd, &dummy, 1);
        close(fd);
        if (readResult < 0) {
            return YES;
        }
        
        return NO;
    }];
    
    if (failIndex != NSNotFound) {
        return [self errorWithCode:CSVPrimeFinderErrorCodeInputFileReadError filename:fileNames[failIndex]];
    }
    
    return nil;
}

- (NSError *)checkOutputFileNamed:(NSString *)outputFileName {
    if (outputFileName.length == 0) {
        return [self errorWithCode:CSVPrimeFinderErrorCodeOutputFileOpenError filename:@"<empty>"];
    }
    
    const char *filenamePtr = outputFileName.UTF8String;
    int fd = open(filenamePtr, O_CREAT | O_WRONLY, 0666);
    if (fd < 0) {
        return [self errorWithCode:CSVPrimeFinderErrorCodeOutputFileOpenError filename:outputFileName];
    }
    
    char dummy;
    ssize_t readResult = write(fd, &dummy, 0);
    close(fd);
    if (readResult < 0) {
        return [self errorWithCode:CSVPrimeFinderErrorCodeOutputFileWriteError filename:outputFileName];
    }
    
    return nil;
}

- (NSError *)checkOutputFileNamed:(NSString *)outputName containedInInputFilesNamed:(NSArray<NSString *> *)inputNames {
    if ([inputNames containsObject:outputName]) {
        return [self errorWithCode:CSVPrimeFinderErrorCodeOutputFileContainsInInput filename:outputName];
    }
    
    return nil;
}

- (NSError *)errorWithCode:(NSInteger)code filename:(NSString *)fileName {
    NSDictionary *userInfo = fileName ? @{CSVPrimeFinderErrorFilenameKey: fileName} : @{};
    return [NSError errorWithDomain:CSVPrimeFinderErrorDomain code:code userInfo:userInfo];
}

#pragma mark - Util

- (NSArray *)commaSeparatedComponentsOfFileNamed:(NSString *)fileName {
    NSString *strContent = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:nil];
    NSCharacterSet *delimCharset = [NSCharacterSet characterSetWithCharactersInString:@",\r\n \t"];
    NSArray *components = [strContent componentsSeparatedByCharactersInSet:delimCharset];
    return components ?: @[];
}

@end
