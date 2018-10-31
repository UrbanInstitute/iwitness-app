#import <Foundation/Foundation.h>

@class PhotoPickerViewController;

@protocol PhotoPickerViewControllerDelegate <NSObject>
- (NSUInteger)maximumSelectionCountForPhotoPickerViewController:(PhotoPickerViewController *)controller;
- (void)photoPickerViewController:(PhotoPickerViewController *)controller didSelectAssets:(NSArray *)assets;
- (void)photoPickerViewControllerDidCancel:(PhotoPickerViewController *)controller;
@end
