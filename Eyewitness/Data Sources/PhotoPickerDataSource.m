#import "PhotoPickerDataSource.h"
#import "PhotoPickerCell.h"
#import "FaceLocator.h"
#import "UIImageView+FocusOnRect.h"

@interface PhotoPickerDataSource ()
@property (nonatomic, strong) NSArray *currentAlbumAssets;

@property (nonatomic, strong, readwrite) ALAssetsLibrary *assetsLibrary;
@property (nonatomic, readwrite) PhotoPickerAlbumType albumType;

@property (nonatomic, strong) FaceLocator *faceLocator;
@property (nonatomic, strong) NSCache *faceCache;

@end

@implementation PhotoPickerDataSource

- (void)configureWithAssetsLibrary:(ALAssetsLibrary *)assetsLibrary faceLocator:(FaceLocator *)faceLocator faceCache:(NSCache *)faceCache {
    self.albumType = PhotoPickerAlbumTypeCameraRoll; //MOK ADDS to make default
    self.assetsLibrary = assetsLibrary;
    self.faceLocator = faceLocator;
    self.faceCache = faceCache;
    [self enumerateAssets];
}

- (KSPromise *)changeAlbumType:(PhotoPickerAlbumType)albumType {
    self.albumType = albumType;
    return [self enumerateAssets];
}

- (KSPromise *)assetsForAssetURLs:(NSArray *)assetURLs {
    KSDeferred *deferred = [KSDeferred defer];
    if (![assetURLs count]) {
        [deferred resolveWithValue:nil];
    }
    NSMutableSet *mutableAssetURLs = [NSMutableSet setWithArray:assetURLs];
    NSMutableSet *mutableAssets = [NSMutableSet set];
    for (NSURL *assetURL in assetURLs) {
        [self.assetsLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
            [mutableAssetURLs removeObject:assetURL];

            if (asset) {
                [mutableAssets addObject:asset];
            }

            if (mutableAssetURLs.count <= 0) {
                [deferred resolveWithValue:[mutableAssets copy]];
            }
        } failureBlock:^(NSError *error) {
            [mutableAssetURLs removeObject:assetURL];
            if (mutableAssetURLs.count <= 0) {
                [deferred rejectWithError:error];
            }
        }];
    }
    return deferred.promise;
}

- (ALAssetsLibrary *)assetsLibrary {
    if (!_assetsLibrary) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"PhotoPickerDataSource must be configured with an ALAssetsLibrary" userInfo:nil];
    }
    return _assetsLibrary;
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.currentAlbumAssets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PhotoPickerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoPickerCell"
                                                                      forIndexPath:indexPath];

    cell.imageView.image = nil;

    void (^showImage)(UIImage *, CGRect, BOOL) = ^(UIImage *image, CGRect faceRect, BOOL fadeIn) {
        cell.imageView.image = image;

        [cell.imageView focusOnImageRect:faceRect];

        if (fadeIn) {
            cell.imageView.alpha = 0;
            [UIView animateWithDuration:0.1f animations:^{
                cell.imageView.alpha = 1;
            }];
        }
    };

    ALAsset *asset = self.currentAlbumAssets[indexPath.item];
    UIImage *image = [UIImage imageWithCGImage:asset.aspectRatioThumbnail];

    NSValue *cachedFaceRect = [self.faceCache objectForKey:indexPath];
    if (cachedFaceRect) {
        showImage(image, [cachedFaceRect CGRectValue], NO);
    } else if (self.faceLocator) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            CGRect faceRect = [self.faceLocator locateLargestFaceInImage:image];

            dispatch_async(dispatch_get_main_queue(), ^{
                if (indexPath.item < self.currentAlbumAssets.count && self.currentAlbumAssets[indexPath.item] == asset) {
                    [self.faceCache setObject:[NSValue valueWithCGRect:faceRect] forKey:indexPath];

                    if ([[collectionView indexPathForCell:cell] isEqual:indexPath]) {
                        showImage(image, faceRect, YES);
                    }
                }
            });
        });
    }

    return cell;
}

#pragma mark - Private

- (KSPromise *)enumerateAssets {
    KSDeferred *deferred = [KSDeferred defer];
    NSMutableArray *allAssets = [[NSMutableArray alloc] init];

    [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            if ([self assetsGroupMatchesCurrentAlbumType:group]) {
                [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                    if (result) {
                        [allAssets addObject:result];
                    }
                }];
            }
        }
        else {
            self.currentAlbumAssets = allAssets;
            [self.faceCache removeAllObjects];
            [deferred resolveWithValue:self.currentAlbumAssets];
        }
    } failureBlock:^(NSError *error) {
        NSLog(@"Failed to enumerate asset groups: %@", error);
    }];
    return deferred.promise;
}

- (BOOL)assetsGroupMatchesCurrentAlbumType:(ALAssetsGroup *)group {
    NSString *groupName = [group valueForProperty:ALAssetsGroupPropertyName];
    switch (self.albumType) {
        case PhotoPickerAlbumTypeLastImport:
            return [groupName isEqualToString:@"Last Import"];
        case PhotoPickerAlbumTypeAllImported:
            return [groupName isEqualToString:@"All Imported"];
        case PhotoPickerAlbumTypeCameraRoll:
//#if TARGET_IPHONE_SIMULATOR
//            return [groupName isEqualToString:@"Saved Photos"];
//#else
            return [groupName isEqualToString:@"Camera Roll"];
//#endif
        default:
            return NO;
    }
}

#pragma mark - Accessing Assets

- (ALAsset *)assetAtIndexPath:(NSIndexPath *)indexPath {
    return self.currentAlbumAssets[indexPath.item];
}

- (NSIndexPath *)indexPathForAsset:(ALAsset *)asset {
    NSInteger indexOfAsset = [self.currentAlbumAssets indexOfObjectPassingTest:^BOOL(ALAsset *obj, NSUInteger idx, BOOL *stop) {
        NSURL *assetURL = [obj valueForProperty:ALAssetPropertyAssetURL];
        return [[asset valueForProperty:ALAssetPropertyAssetURL] isEqual:assetURL];
    }];

    if (indexOfAsset != NSNotFound) {
        return [NSIndexPath indexPathForItem:indexOfAsset inSection:0];
    }
    return nil;
}

@end
