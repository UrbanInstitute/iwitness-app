#import "ALTestAsset.h"

@interface ALTestAsset ()
@property (nonatomic, strong) NSURL *imageURL;
@end

@implementation ALTestAsset

- (instancetype)initWithImageURL:(NSURL *)imageURL {
    if (self = [super init]) {
        self.imageURL = imageURL;
    }
    return self;
}

- (NSURL *)valueForProperty:(NSString *)property {
    if ([property isEqualToString:ALAssetPropertyAssetURL]) {
        return self.imageURL;
    }
    return [super valueForProperty:property];
}

- (ALAssetRepresentation *)defaultRepresentation {
    ALAssetRepresentation *representation = nice_fake_for([ALAssetRepresentation class]);
    representation stub_method(@selector(fullScreenImage)).and_return([UIImage imageWithContentsOfFile:[self.imageURL path]].CGImage);
    return representation;
}

- (CGImageRef)thumbnail {
    return [UIImage imageWithContentsOfFile:[self.imageURL path]].CGImage;
}

- (CGImageRef)aspectRatioThumbnail {
    return [self thumbnail];
}

@end
