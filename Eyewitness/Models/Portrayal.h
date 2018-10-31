#import <Foundation/Foundation.h>

@interface Portrayal : NSObject <NSCopying, NSCoding>

@property (nonatomic, readonly, strong) /*NSURL MOK*/NSArray *photoURL;
@property (nonatomic, readonly, strong) NSDate *date;

- (instancetype)initWithPhotoURL:(NSURL *)photoURL date:(NSDate *)date;
- (KSPromise *)getPhotoURLData;
- (NSArray * )setSusPhotoId:(NSArray *) pid;
@end
