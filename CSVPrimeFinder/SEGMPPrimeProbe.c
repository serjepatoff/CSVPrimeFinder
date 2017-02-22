//
//  SEGMPPrimeProbe.c
//  CSVPrimeFinder
//
//  Created by Sergei Epatov on 2/22/17.
//  Copyright © 2017 Sergei Epatov. All rights reserved.
//

#include "SEGMPPrimeProbe.h"

#include <stdio.h>
#include <string.h>
#include <gmp.h>

const int SEGMPPrimeProbeBase = 10;
const int SEGMPPrimeProbeAccuracy = 50;

int SEGMPIsPrime(const char *bignumStr) {
    if (!bignumStr) {
        return 0;
    }
    
    mpz_t mpNum;
    mpz_init(mpNum);
    mpz_set_str(mpNum, bignumStr, SEGMPPrimeProbeBase);
    int result = mpz_probab_prime_p(mpNum, SEGMPPrimeProbeAccuracy);
    mpz_clear(mpNum);
    return result;
}
