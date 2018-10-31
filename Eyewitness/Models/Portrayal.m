#import "Portrayal.h"

@interface Portrayal ()
@property (nonatomic, readwrite, strong) NSArray *photoURL;
@property (nonatomic, readwrite, strong) NSDate *date;
@property (nonatomic, strong) NSData *imageData;
@end

@implementation Portrayal

- (instancetype)initWithPhotoURL:(NSArray *)photoURL date:(NSDate *)date {
    if (self = [super init]) {
        self.date = date;
        self.photoURL = photoURL;

    }
    return self;
}

-(NSArray *)setSusPhotoId:(NSArray *)pid  //MOK adds
{
    self.photoURL = pid;
    return pid;
}

- (KSPromise *)getPhotoURLData {
    KSDeferred *deferred = [KSDeferred defer];
    if (self.imageData) {
        [deferred resolveWithValue:self.imageData];
    } else {
        /*
        [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:self.photoURL]
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                   if (connectionError) {
                                       [deferred rejectWithError:connectionError];
                                   } else if ([response isKindOfClass:[NSHTTPURLResponse class]] && [(NSHTTPURLResponse *)response statusCode] / 100 != 2) {
                                       [deferred rejectWithError:nil];
                                   } else {
                                       self.imageData = data;
                                       [deferred resolveWithValue:data];
                                   }
                               }];
         */  //MOK believes this is deaad code
    }
    return deferred.promise;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.photoURL = [aDecoder decodeObjectForKey:@"photoURL"];
        self.date = [aDecoder decodeObjectForKey:@"date"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.photoURL forKey:@"photoURL"];
    [aCoder encodeObject:self.date forKey:@"date"];
}

-(BOOL)isEqual:(Portrayal *)otherPortrayal {
    if(![self isKindOfClass:[otherPortrayal class]]) { return NO; }
    if(![self.date isEqual:otherPortrayal.date] && (self.date != otherPortrayal.date)) { return NO; }
    if(![self.photoURL isEqual:otherPortrayal.photoURL] && (self.photoURL != otherPortrayal.photoURL)) { return NO; }
    return YES;
}

- (NSUInteger)hash {
    NSUInteger prime = 31;
    NSUInteger result = 1;
    result += prime * [self.date hash];
    result += prime * [self.photoURL hash];
    return result;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"photoURL: %@, date: %@", self.photoURL, self.date];
}

- (id)copyWithZone:(NSZone *)zone {
    NSURL * susPhotoUrl = (NSURL *)self.photoURL;//MOK
    return  [[Portrayal allocWithZone:zone] initWithPhotoURL:susPhotoUrl date:self.date];
}

@end
