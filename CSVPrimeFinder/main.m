//
//  main.m
//  CSVPrimeFinder
//
//  Created by Sergei Epatov on 2/21/17.
//  Copyright © 2017 Sergei Epatov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SECSVPrimeFinder.h"

static const NSInteger  SECSVMinArgCount        = 3;
static NSString * const SECSVMultiThreadedKey   = @"--multi-threaded";
static const char       *usageTemplate          = "Usage: %s [--multi-threaded] in_csv_file_1 [in_csv_file_2 [...]] out_csv_file\n";

BOOL parseArgs(BOOL *multiThreaded, NSArray **inFileNames, NSString **outFileName) {
    if (!multiThreaded || !inFileNames || !outFileName) {
        return NO;
    }
    
    NSProcessInfo *procInfo = [NSProcessInfo processInfo];
    NSArray *arguments = [procInfo arguments];
    NSInteger argsCount = arguments.count;
    
    *multiThreaded = NO;
    if (argsCount > 1 && [arguments[1] isEqualToString:SECSVMultiThreadedKey]) {
        *multiThreaded = YES;
    }
    
    NSInteger actualMinArgsCount = SECSVMinArgCount + (*multiThreaded ? 1 : 0);
    if (argsCount < actualMinArgsCount) {
        fprintf(stderr, usageTemplate, procInfo.processName.UTF8String);
        return NO;
    }
    
    NSRange actualInputRange = *multiThreaded ? NSMakeRange(2, argsCount - 3) : NSMakeRange(1, argsCount - 2);
    *inFileNames = [arguments subarrayWithRange:actualInputRange];
    *outFileName = arguments.lastObject;
    
    return YES;
}

void run() {
    BOOL multiThreaded = NO;
    NSArray *inFileNames = nil;
    NSString *outFileName = nil;
    
    if (!parseArgs(&multiThreaded, &inFileNames, &outFileName)) {
        return;
    }
    
    SECSVPrimeFinder *finder = [SECSVPrimeFinder new];
    finder.forceSingleThreaded = !multiThreaded;
    NSError *error = [finder findPrimesInFilesNamed:inFileNames storeToFileNamed:outFileName];
    if (error) {
        fprintf(stderr, "%s\n", [[finder printableDescriptionFromError:error] UTF8String]);
    }
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        run();
    }
    
    return 0;
}
