//
//  CSVPrimeFinder.h
//  CSVPrimeFinder
//
//  Created by Sergei Epatov on 2/22/17.
//  Copyright © 2017 Sergei Epatov. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CSVPrimeFinderErrorCode) {
    CSVPrimeFinderErrorCodeNone = 0,
    CSVPrimeFinderErrorCodeNoInputFiles,
    CSVPrimeFinderErrorCodeInputFileOpenError,
    CSVPrimeFinderErrorCodeInputFileReadError,
    CSVPrimeFinderErrorCodeNoOutputFile,
    CSVPrimeFinderErrorCodeOutputFileOpenError,
    CSVPrimeFinderErrorCodeOutputFileWriteError,
    CSVPrimeFinderErrorCodeOutputFileContainsInInput
};

@interface SECSVPrimeFinder : NSObject

@property (assign) BOOL forceSingleThreaded;

- (NSError *)findPrimesInFilesNamed:(NSArray<NSString *> *)inputFileNames storeToFileNamed:(NSString *)outputFileName;
- (NSString *)printableDescriptionFromError:(NSError *)error;

@end
