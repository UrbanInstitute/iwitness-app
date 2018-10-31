typedef NS_ENUM(NSInteger, ButtonStyle) {
    ButtonStylePrimary = 0,
    ButtonStyleWarn
};

@interface DefaultButton : UIButton
@property (nonatomic) ButtonStyle style;
@end
