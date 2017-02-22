# CSVPrimeFinder

* Executable is in the Build/Products/Debug subdir, if you don't want to build. 
There are also csv files there.

* Before actual processing I've implemented error pre–checks, 
like input files existence and readability, output file writability, output filename containment in inputs.
Checks are chained with short variant of ternary operator, ?:, 
to find first fail if it exist.

* Naive algorithm, like Eratosphene sieve on small 32 or 64-bit integers, 
seemed too boring for me to use.
Complicated ones are definitely not a matter of one hour.
So, to be able to process arbitrary-length numbers, 
I've picked an industry-standard GMP lib.
You should have it in /usr/local before build,
the easiest way is "brew install gmp".

* Massive prime number probing is typical CPU–bound task, 
so I didn't bother with memory and I/O efficiency,
and simply read the whole files into NSString, and then splitted it. 
After processing, I joined the flatten array with ',' and written the content to file in the same dumb way. 
I know this is very lame approach, but
 (1) it is adequate for this task, because I/O, copying, intermediate objects construction 
     are less cheaper than computations
 (2) fancy async stream processing with zero–copy, engaging heavy machinery like boost::asio, 
     etc, is definitely not a matter of one hour too.

* To make the task more interesting and to demonstrate the speed gain, I engaged multi–core processing.
You can compare the performance:
 
time ./CSVPrimeFinder --multi-threaded a.csv b.csv huge.csv out.csv
time ./CSVPrimeFinder a.csv b.csv huge.csv out.csv

* Simple and dirty parallelMap was implemented. It has explicit concurrency level,
contrary to stock [NSArray enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:...]).

* There are intentional garbage in the input files, like non–numeric fields, spaces, different variants of line breaks.
All of this stuff is filtered out. 

* I intentionally use C-styled stuff like fprintf(stderr..) or low-level open/read/write calls for probing, 
because in some cases they are better and more convenient than Objective-C counterparts.