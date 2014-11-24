//
//  HYPTextField.m

//
//  Created by Elvis Nunez on 07/10/14.
//  Copyright (c) 2014 Hyper. All rights reserved.
//

#import "HYPTextFormField.h"

#import "UIColor+REMAColors.h"
#import "UIColor+ANDYHex.h"
#import "UIFont+REMAStyles.h"
#import "HYPTextFieldTypeManager.h"

@interface HYPTextFormField () <UITextFieldDelegate>

@property (nonatomic, getter = isModified) BOOL modified;

@end

@implementation HYPTextFormField

@synthesize rawText = _rawText;

#pragma mark - Initializers

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.layer.borderWidth = 1.0f;
    self.layer.borderColor = [UIColor colorFromHex:@"3DAFEB"].CGColor;
    self.layer.cornerRadius = 5.0f;

    self.delegate = self;

    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    self.backgroundColor = [UIColor colorFromHex:@"E1F5FF"];
    self.font = [UIFont REMATextFieldFont];
    self.textColor = [UIColor colorFromHex:@"455C73"];

    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 10.0f, 20.0f)];
    self.leftView = paddingView;
    self.leftViewMode = UITextFieldViewModeAlways;

    [self addTarget:self action:@selector(textFieldDidUpdate:) forControlEvents:UIControlEventEditingChanged];
    [self addTarget:self action:@selector(textFieldDidReturn:) forControlEvents:UIControlEventEditingDidEndOnExit];

    self.returnKeyType = UIReturnKeyDone;

    return self;
}

#pragma mark - Setters

- (NSRange)currentRange
{
    NSInteger startOffset = [self offsetFromPosition:self.beginningOfDocument
                                          toPosition:self.selectedTextRange.start];
    NSInteger endOffset = [self offsetFromPosition:self.beginningOfDocument
                                        toPosition:self.selectedTextRange.end];
    NSRange range = NSMakeRange(startOffset, endOffset-startOffset);

    return range;
}

- (void)setText:(NSString *)text
{
    UITextRange *textRange = self.selectedTextRange;
    NSString *newRawText = [self.formatter formatString:text reverse:YES];
    NSRange range = [self currentRange];

    BOOL didAddText  = (newRawText.length > self.rawText.length);
    BOOL didFormat   = (text.length > super.text.length);
    BOOL cursorAtEnd = (newRawText.length == range.location);

    if ((didAddText && didFormat) || (didAddText && cursorAtEnd)) {
        self.selectedTextRange = textRange;
        [super setText:text];
    } else {
        [super setText:text];
        self.selectedTextRange = textRange;
    }
}

- (void)setActive:(BOOL)active
{
    _active = active;

    if (active) {
        self.backgroundColor = [UIColor colorFromHex:@"C0EAFF"];
        self.layer.borderColor = [UIColor colorFromHex:@"3DAFEB"].CGColor;
    } else {
        self.backgroundColor = [UIColor colorFromHex:@"E1F5FF"];
        self.layer.borderColor = [UIColor colorFromHex:@"3DAFEB"].CGColor;
    }
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];

    if (enabled) {
        self.backgroundColor = [UIColor colorFromHex:@"E1F5FF"];
        self.layer.borderColor = [UIColor colorFromHex:@"3DAFEB"].CGColor;
    } else {
        self.backgroundColor = [UIColor colorFromHex:@"F5F5F8"];
        self.layer.borderColor = [UIColor colorFromHex:@"DEDEDE"].CGColor;
    }
}

- (void)setRawText:(NSString *)rawText
{
    BOOL shouldFormat = (self.formatter && (rawText.length >= _rawText.length ||
                                            ![rawText isEqualToString:_rawText]));

    if (shouldFormat) {
        self.text = [self.formatter formatString:rawText reverse:NO];
    } else {
        self.text = rawText;
    }

    _rawText = rawText;
}

- (void)setValid:(BOOL)valid
{
    _valid = valid;

    if (!self.isEnabled) return;

    if (valid) {
        self.backgroundColor = [UIColor colorFromHex:@"E1F5FF"];
        self.layer.borderColor = [UIColor colorFromHex:@"3DAFEB"].CGColor;
    } else {
        self.backgroundColor = [UIColor REMAFieldBackgroundInvalid];
        self.layer.borderColor = [UIColor colorFromHex:@"EC3031"].CGColor;
    }
}

- (void)setTypeString:(NSString *)typeString
{
    _typeString = typeString;

    HYPTextFieldType type;
    if ([typeString isEqualToString:@"name"]) {
        type = HYPTextFieldTypeName;
    } else if ([typeString isEqualToString:@"username"]) {
        type = HYPTextFieldTypeUsername;
    } else if ([typeString isEqualToString:@"phone"]) {
        type = HYPTextFieldTypePhoneNumber;
    } else if ([typeString isEqualToString:@"number"]) {
        type = HYPTextFieldTypeNumber;
    } else if ([typeString isEqualToString:@"float"]) {
        type = HYPTextFieldTypeFloat;
    } else if ([typeString isEqualToString:@"address"]) {
        type = HYPTextFieldTypeAddress;
    } else if ([typeString isEqualToString:@"email"]) {
        type = HYPTextFieldTypeEmail;
    } else if ([typeString isEqualToString:@"date"]) {
        type = HYPTextFieldTypeDate;
    } else if ([typeString isEqualToString:@"select"]) {
        type = HYPTextFieldTypeDropdown;
    } else if ([typeString isEqualToString:@"text"]) {
        type = HYPTextFieldTypeDefault;
    } else if (!typeString.length) {
        type = HYPTextFieldTypeDefault;
    } else {
        type = HYPTextFieldTypeUnknown;
    }

    self.type = type;
}

- (void)setType:(HYPTextFieldType)type
{
    _type = type;

    HYPTextFieldTypeManager *typeManager = [[HYPTextFieldTypeManager alloc] init];
    [typeManager setUpType:type forTextField:self];
}

#pragma mark - Getters

- (NSString *)rawText
{
    if (_rawText && self.formatter) {
        return [self.formatter formatString:_rawText reverse:YES];
    }

    return _rawText;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(HYPTextFormField *)textField
{
    BOOL selectable = (textField.type == HYPTextFieldTypeDropdown ||
                       textField.type == HYPTextFieldTypeDate);

    if (selectable && [self.formFieldDelegate respondsToSelector:@selector(textFormFieldDidBeginEditing:)]) {
        [self.formFieldDelegate textFormFieldDidBeginEditing:self];
    }

    return !selectable;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.active = YES;
    self.modified = NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.active = NO;
    if ([self.formFieldDelegate respondsToSelector:@selector(textFormFieldDidEndEditing:)]) {
        [self.formFieldDelegate textFormFieldDidEndEditing:self];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (!string) return YES;

    BOOL validator = (self.inputValidator && [self.inputValidator respondsToSelector:@selector(validateReplacementString:withText:withRange:)]);

    if (validator) return [self.inputValidator validateReplacementString:string withText:self.rawText withRange:range];

    return YES;
}

#pragma mark - UIResponder Overwritables

- (BOOL)becomeFirstResponder
{
    if (self.type == HYPTextFieldTypeDropdown || self.type == HYPTextFieldTypeDate) {
        if ([self.formFieldDelegate respondsToSelector:@selector(textFormFieldDidBeginEditing:)]) {
            [self.formFieldDelegate textFormFieldDidBeginEditing:self];
        }
    }

    return [super becomeFirstResponder];
}

- (BOOL)canBecomeFirstResponder
{
    if (self.type == HYPTextFieldTypeDropdown || self.type == HYPTextFieldTypeDate) return NO;

    return [super canBecomeFirstResponder];
}

#pragma mark - Notifications

- (void)textFieldDidUpdate:(UITextField *)textField
{
    if (!self.isValid) {
        self.valid = YES;
    }

    self.modified = YES;
    self.rawText = self.text;

    if ([self.formFieldDelegate respondsToSelector:@selector(textFormField:didUpdateWithText:)]) {
        [self.formFieldDelegate textFormField:self didUpdateWithText:self.rawText];
    }
}

- (void)textFieldDidReturn:(UITextField *)textField
{
    if ([self.formFieldDelegate respondsToSelector:@selector(textFieldDidReturn:)]) {
        [self.formFieldDelegate textFieldDidReturn:self];
    }
}

@end
