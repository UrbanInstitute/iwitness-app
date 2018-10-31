#import <Foundation/Foundation.h>

@class ImportingPhotoPickerViewController;

@protocol ImportingPhotoPickerViewControllerDelegate <NSObject>
- (NSUInteger)maximumSelectionCountForPhotoPickerViewController:(ImportingPhotoPickerViewController *)controller;
- (void)photoPickerViewController:(ImportingPhotoPickerViewController *)controller didImportPhotoURLs:(NSArray *)photoURLs;
- (void)photoPickerViewControllerDidCancel:(ImportingPhotoPickerViewController *)controller;
@end
