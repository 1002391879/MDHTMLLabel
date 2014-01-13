//
//  MDHTMLLabel.m
//  MDHTMLLabel
//
//  Copyright (c) 2013 Matt Donnelly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "MDHTMLLabel.h"

#define kMDLineBreakWordWrapTextWidthScalingFactor (M_PI / M_E)

static CGFloat const MDFLOAT_MAX = 100000;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
const NSTextAlignment MDTextAlignmentLeft = NSTextAlignmentLeft;
const NSTextAlignment MDTextAlignmentCenter = NSTextAlignmentCenter;
const NSTextAlignment MDTextAlignmentRight = NSTextAlignmentRight;
const NSTextAlignment MDTextAlignmentJustified = NSTextAlignmentJustified;
const NSTextAlignment MDTextAlignmentNatural = NSTextAlignmentNatural;

const NSLineBreakMode MDLineBreakByWordWrapping = NSLineBreakByWordWrapping;
const NSLineBreakMode MDLineBreakByCharWrapping = NSLineBreakByCharWrapping;
const NSLineBreakMode MDLineBreakByClipping = NSLineBreakByClipping;
const NSLineBreakMode MDLineBreakByTruncatingHead = NSLineBreakByTruncatingHead;
const NSLineBreakMode MDLineBreakByTruncatingMiddle = NSLineBreakByTruncatingMiddle;
const NSLineBreakMode MDLineBreakByTruncatingTail = NSLineBreakByTruncatingTail;

typedef NSTextAlignment MDTextAlignment;
typedef NSLineBreakMode MDLineBreakMode;
#else
const UITextAlignment MDTextAlignmentLeft = NSTextAlignmentLeft;
const UITextAlignment MDTextAlignmentCenter = NSTextAlignmentCenter;
const UITextAlignment MDTextAlignmentRight = NSTextAlignmentRight;
const UITextAlignment MDTextAlignmentJustified = NSTextAlignmentJustified;
const UITextAlignment MDTextAlignmentNatural = NSTextAlignmentNatural;

const UITextAlignment MDLineBreakByWordWrapping = NSLineBreakByWordWrapping;
const UITextAlignment MDLineBreakByCharWrapping = NSLineBreakByCharWrapping;
const UITextAlignment MDLineBreakByClipping = NSLineBreakByClipping;
const UITextAlignment MDLineBreakByTruncatingHead = NSLineBreakByTruncatingHead;
const UITextAlignment MDLineBreakByTruncatingMiddle = NSLineBreakByTruncatingMiddle;
const UITextAlignment MDLineBreakByTruncatingTail = NSLineBreakByTruncatingTail;

typedef UITextAlignment MDTextAlignment;
typedef UILineBreakMode MDLineBreakMode;
#endif

static inline CTTextAlignment CTTextAlignmentFromMDTextAlignment(MDTextAlignment alignment)
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    switch (alignment)
    {
		case NSTextAlignmentLeft: return kCTLeftTextAlignment;
		case NSTextAlignmentCenter: return kCTCenterTextAlignment;
		case NSTextAlignmentRight: return kCTRightTextAlignment;
		default: return kCTNaturalTextAlignment;
	}
#else
    switch (alignment)
    {
		case UITextAlignmentLeft: return kCTLeftTextAlignment;
		case UITextAlignmentCenter: return kCTCenterTextAlignment;
		case UITextAlignmentRight: return kCTRightTextAlignment;
		default: return kCTNaturalTextAlignment;
	}
#endif
}

static inline CTLineBreakMode CTLineBreakModeFromMDLineBreakMode(MDLineBreakMode lineBreakMode)
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
	switch (lineBreakMode)
    {
		case NSLineBreakByWordWrapping: return kCTLineBreakByWordWrapping;
		case NSLineBreakByCharWrapping: return kCTLineBreakByCharWrapping;
		case NSLineBreakByClipping: return kCTLineBreakByClipping;
		case NSLineBreakByTruncatingHead: return kCTLineBreakByTruncatingHead;
		case NSLineBreakByTruncatingTail: return kCTLineBreakByTruncatingTail;
		case NSLineBreakByTruncatingMiddle: return kCTLineBreakByTruncatingMiddle;
		default: return 0;
	}
#else
    return CTLineBreakModeFromUILineBreakMode(lineBreakMode);
#endif
}

static inline CTLineBreakMode CTLineBreakModeFromUILineBreakMode(UILineBreakMode lineBreakMode)
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    switch (lineBreakMode)
    {
        case UILineBreakModeWordWrap: return kCTLineBreakByWordWrapping;
        case UILineBreakModeCharacterWrap: return kCTLineBreakByCharWrapping;
        case UILineBreakModeClip: return kCTLineBreakByClipping;
        case UILineBreakModeHeadTruncation: return kCTLineBreakByTruncatingHead;
        case UILineBreakModeTailTruncation: return kCTLineBreakByTruncatingTail;
        case UILineBreakModeMiddleTruncation: return kCTLineBreakByTruncatingMiddle;
        default: return 0;
    }
#pragma clang diagnostic pop
}

static inline UILineBreakMode UILineBreakModeFromMDLineBreakMode(MDLineBreakMode lineBreakMode)
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	switch (lineBreakMode)
    {
		case NSLineBreakByWordWrapping: return UILineBreakModeWordWrap;
		case NSLineBreakByCharWrapping: return UILineBreakModeCharacterWrap;
		case NSLineBreakByClipping: return UILineBreakModeClip;
		case NSLineBreakByTruncatingHead: return UILineBreakModeHeadTruncation;
		case NSLineBreakByTruncatingTail: return UILineBreakModeMiddleTruncation;
		case NSLineBreakByTruncatingMiddle: return UILineBreakModeTailTruncation;
		default: return 0;
	}
#pragma clang diagnostic pop
#else
    return lineBreakMode;
#endif
}

static inline NSArray * CGColorComponentsForHex(NSString *hexColor)
{
	hexColor = [[hexColor stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];

    NSRange range;
    range.location = 0;
    range.length = 2;

    NSString *rString = [hexColor substringWithRange:range];

    range.location = 2;
    NSString *gString = [hexColor substringWithRange:range];

    range.location = 4;
    NSString *bString = [hexColor substringWithRange:range];

    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];

	NSArray *components = @[[NSNumber numberWithFloat:((float) r / 255.0f)],
                            [NSNumber numberWithFloat:((float) g / 255.0f)],
                            [NSNumber numberWithFloat:((float) b / 255.0f)],
                            [NSNumber numberWithFloat:1.0]];

    return components;
}

static inline CGFLOAT_TYPE CGFloat_ceil(CGFLOAT_TYPE cgfloat)
{
#if defined(__LP64__) && __LP64__
    return ceil(cgfloat);
#else
    return ceilf(cgfloat);
#endif
}

static inline CGFLOAT_TYPE CGFloat_floor(CGFLOAT_TYPE cgfloat)
{
#if defined(__LP64__) && __LP64__
    return floor(cgfloat);
#else
    return floorf(cgfloat);
#endif
}

static inline NSAttributedString * NSAttributedStringByScalingFontSize(NSAttributedString *attributedString,
                                                                       CGFloat scale)
{
    NSMutableAttributedString *mutableAttributedString = [attributedString mutableCopy];
    [mutableAttributedString enumerateAttribute:(NSString *)kCTFontAttributeName inRange:NSMakeRange(0, [mutableAttributedString length])
                                        options:0
                                     usingBlock:^(id value, NSRange range, BOOL * __unused stop)
     {
         UIFont *font = (UIFont *)value;
         if (font)
         {
             NSString *fontName;
             CGFloat pointSize;

             if ([font isKindOfClass:[UIFont class]])
             {
                 fontName = font.fontName;
                 pointSize = font.pointSize;
             }
             else
             {
                 fontName = (NSString *)CFBridgingRelease(CTFontCopyName((__bridge CTFontRef)font, kCTFontPostScriptNameKey));
                 pointSize = CTFontGetSize((__bridge CTFontRef)font);
             }

             [mutableAttributedString removeAttribute:(NSString *)kCTFontAttributeName range:range];
             CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)fontName, CGFloat_floor(pointSize * scale), NULL);
             [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)fontRef range:range];
             CFRelease(fontRef);
         }
     }];

    return mutableAttributedString;
}

static inline CGSize CTFramesetterSuggestFrameSizeForAttributedStringWithConstraints(CTFramesetterRef framesetter,
                                                                                     NSAttributedString *attributedString,
                                                                                     CGSize size,
                                                                                     NSUInteger numberOfLines)
{
    CFRange rangeToSize = CFRangeMake(0, (CFIndex)attributedString.length);
    CGSize constraints = CGSizeMake(size.width, MDFLOAT_MAX);

    if (numberOfLines == 1)
    {
        // If there is one line, the size that fits is the full width of the line
        constraints = CGSizeMake(MDFLOAT_MAX, MDFLOAT_MAX);
    }
    else if (numberOfLines > 0)
    {
        // If the line count of the label more than 1, limit the range to size to the number of lines that have been set
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0.0f, 0.0f, constraints.width, MDFLOAT_MAX));
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
        CFArrayRef lines = CTFrameGetLines(frame);

        if (CFArrayGetCount(lines) > 0)
        {
            NSInteger lastVisibleLineIndex = MIN((CFIndex)numberOfLines, CFArrayGetCount(lines)) - 1;
            CTLineRef lastVisibleLine = CFArrayGetValueAtIndex(lines, lastVisibleLineIndex);

            CFRange rangeToLayout = CTLineGetStringRange(lastVisibleLine);
            rangeToSize = CFRangeMake(0, rangeToLayout.location + rangeToLayout.length);
        }

        CFRelease(frame);
        CFRelease(path);
    }

    CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, rangeToSize, NULL, constraints, NULL);

    return CGSizeMake(CGFloat_ceil(suggestedSize.width), CGFloat_ceil(suggestedSize.height));
}

#pragma mark - MDHTMLComponent

@interface MDHTMLComponent : NSObject

@property (nonatomic, assign) NSInteger componentIndex;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *htmlTag;

@property (nonatomic) NSMutableDictionary *attributes;

@property (nonatomic, assign) NSInteger position;

- (id)initWithString:(NSString *)string
             htmlTag:(NSString *)htmlTag
          attributes:(NSMutableDictionary *)attributes;

- (id)initWithTag:(NSString *)htmlTag
         position:(NSInteger)position
       attributes:(NSMutableDictionary *)attributes;

@end

@implementation MDHTMLComponent

- (id)initWithString:(NSString *)string
             htmlTag:(NSString *)htmlTag
          attributes:(NSMutableDictionary *)attributes
{
    self = [super init];

	if (self)
    {
		self.text = string;
        self.htmlTag = htmlTag;
		self.attributes = attributes;
	}

	return self;
}

- (id)initWithTag:(NSString *)htmlTag
         position:(NSInteger)position
       attributes:(NSMutableDictionary *)attributes
{
    self = [super init];

    if (self)
    {
        self.htmlTag = htmlTag;
		self.position = position;
		self.attributes = attributes;
    }

    return self;
}

- (NSString *)description
{
	NSMutableString *desc = [NSMutableString string];
	[desc appendFormat:@"Text: %@", self.text];
	[desc appendFormat:@"\nPosition: %li", (long)_position];

    if (_htmlTag)
    {
        [desc appendFormat:@"\nHTML Tag: %@", self.htmlTag];
    }

    if (_attributes)
    {
        [desc appendFormat:@"\nAttributes: %@", _attributes];
    }

	return desc;
}

@end

#pragma mark - MDHTMLLabel

@interface MDHTMLLabel ()

@property (nonatomic, copy) NSString *plainText;

@property (nonatomic, copy) NSAttributedString *inactiveAttributedText;

@property (nonatomic, assign) BOOL needsFramesetter;

@property (nonatomic, strong) NSDataDetector *dataDetector;
@property (nonatomic, strong) NSMutableArray *links;
@property (nonatomic, strong) NSTextCheckingResult *activeLink;

@property (nonatomic, strong) NSTimer *holdGestureTimer;

@property (nonatomic, strong) NSMutableArray *styleComponents;
@property (nonatomic, strong) NSMutableArray *highlightedStyleComponents;

- (NSString *)detectURLsInText:(NSString *)text;
- (void)extractStyleFromText:(NSString *)text;

- (void)setNeedsFramesetter;

- (NSAttributedString *)applyStylesToString:(NSString *)string;

- (void)applyItalicStyleToText:(CFMutableAttributedStringRef)text
                    atPosition:(NSInteger)position
                    withLength:(NSInteger)length;

- (void)applyBoldStyleToText:(CFMutableAttributedStringRef)text
                  atPosition:(NSInteger)position
                  withLength:(NSInteger)length;

- (void)applyBoldItalicStyleToText:(CFMutableAttributedStringRef)text
                        atPosition:(NSInteger)position
                        withLength:(NSInteger)length;

- (void)applyColor:(id)value
            toText:(CFMutableAttributedStringRef)text
        atPosition:(NSInteger)position
        withLength:(NSInteger)length;

- (void)applyUnderlineColor:(NSString *)value
                     toText:(CFMutableAttributedStringRef)text
                 atPosition:(NSInteger)position
                 withLength:(NSInteger)length;

- (void)applyFontAttributes:(NSDictionary *)attributes
                     toText:(CFMutableAttributedStringRef)text
                 atPosition:(NSInteger)position
                 withLength:(NSInteger)length;

- (void)applyParagraphStyleToText:(CFMutableAttributedStringRef)text
                       attributes:(NSMutableDictionary *)attributes
                       atPosition:(NSInteger)position
                       withLength:(NSInteger)length;

@end

@implementation MDHTMLLabel
{
@private
    NSAttributedString *_htmlAttributedText;
    BOOL _needsFramesetter;
    CTFramesetterRef _framesetter;
    CTFramesetterRef _highlightFramesetter;
}

#pragma mark - Initialization

- (id)init
{
    self = [super init];

    if (self)
	{
		[self commonInit];
    }

    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
	{
		[self commonInit];
    }

    return self;
}

- (void)commonInit
{
    self.userInteractionEnabled = YES;
    self.multipleTouchEnabled = NO;

    self.textInsets = UIEdgeInsetsZero;

    self.links = [NSMutableArray array];
    self.minimumPressDuration = 0.5;

    self.linkAttributes = [NSDictionary dictionary];
    self.activeLinkAttributes = [NSDictionary dictionary];
    self.inactiveLinkAttributes = [NSDictionary dictionary];
}

- (void)dealloc
{
    if (_framesetter)
    {
        CFRelease(_framesetter);
    }
}

#pragma mark - Accessors

- (void)setText:(NSString *)text
{
    self.htmlText = nil;
    [super setText:text];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    self.htmlText = nil;
    [super setAttributedText:attributedText];
}

- (void)setHtmlText:(NSString *)htmlText
{
    if ([_htmlText isEqualToString:htmlText])
    {
        return;
    }

    _htmlText = [htmlText copy];

    if (_htmlText)
    {
        _htmlText = [_htmlText stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
        _htmlText = [self detectURLsInText:_htmlText];

        [self extractStyleFromText:_htmlText];
    }
    else
    {
        self.styleComponents = nil;
        self.plainText = nil;
    }

    [self setNeedsFramesetter];
    [self setNeedsDisplay];
    [self invalidateIntrinsicContentSize];
}

- (NSAttributedString *)htmlAttributedText
{
    if (!_htmlAttributedText)
    {
        _htmlAttributedText = [self applyStylesToString:_plainText];
    }

    return _htmlAttributedText;
}

- (void)setHtmlAttributedText:(NSAttributedString *)htmlAttributedText
{
    if ([_htmlAttributedText isEqualToAttributedString:htmlAttributedText])
    {
        return;
    }

    _htmlAttributedText = [htmlAttributedText copy];

    [self setNeedsFramesetter];
    [self setNeedsDisplay];
}

- (void)setNeedsFramesetter
{
    _needsFramesetter = YES;
}

- (CTFramesetterRef)framesetter
{
    if (_needsFramesetter)
    {
        @synchronized(self)
        {
            CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.htmlAttributedText);
            self.framesetter = framesetter;
            _needsFramesetter = NO;

            if (framesetter)
            {
                CFRelease(framesetter);
            }
        }
    }

    return _framesetter;
}

- (CTFramesetterRef)highlightFramesetter
{
    return _highlightFramesetter;
}

- (void)setHighlightFramesetter:(CTFramesetterRef)highlightFramesetter
{
    if (highlightFramesetter)
    {
        CFRetain(highlightFramesetter);
    }

    if (_highlightFramesetter)
    {
        CFRelease(_highlightFramesetter);
    }

    _highlightFramesetter = highlightFramesetter;
}

- (void)setFramesetter:(CTFramesetterRef)framesetter
{
    if (framesetter)
    {
        CFRetain(framesetter);
    }

    if (_framesetter)
    {
        CFRelease(_framesetter);
    }

    _framesetter = framesetter;
}

- (void)setActiveLink:(NSTextCheckingResult *)activeLink
{
    _activeLink = activeLink;

    if (_activeLink && [_activeLinkAttributes count] > 0)
    {
        if (!_inactiveAttributedText)
        {
            self.inactiveAttributedText = [self.htmlAttributedText copy];
        }

        NSMutableAttributedString *mutableAttributedString = [_inactiveAttributedText mutableCopy];
        if (NSLocationInRange(NSMaxRange(_activeLink.range), NSMakeRange(0, [_inactiveAttributedText length])))
        {
            NSMutableDictionary *mutableActiveLinkAttributes = [_activeLinkAttributes mutableCopy];
            if (!mutableActiveLinkAttributes[(NSString *)kCTForegroundColorAttributeName] && !mutableActiveLinkAttributes[NSForegroundColorAttributeName])
            {
                mutableActiveLinkAttributes[(NSString *)kCTForegroundColorAttributeName] = [UIColor redColor];
            }

            [self applyFontAttributes:mutableActiveLinkAttributes
                               toText:(__bridge CFMutableAttributedStringRef)mutableAttributedString
                           atPosition:_activeLink.range.location
                           withLength:_activeLink.range.length];
        }

        self.htmlAttributedText = mutableAttributedString;
        [self setNeedsDisplay];
    }
    else if (self.inactiveAttributedText)
    {
        self.htmlAttributedText = self.inactiveAttributedText;
        self.inactiveAttributedText = nil;

        [self setNeedsDisplay];
    }
}

#pragma mark - Drawing

- (void)drawTextInRect:(CGRect)rect
{
    if (!_htmlText)
    {
        return [super drawTextInRect:rect];
    }

    NSAttributedString *originalAttributedText = nil;

    // Adjust the font size to fit width, if necessarry
    if (self.adjustsFontSizeToFitWidth && self.numberOfLines > 0)
    {
        // Use infinite width to find the max width, which will be compared to availableWidth if needed.
        CGSize maxSize = (self.numberOfLines > 1) ? CGSizeMake(MDFLOAT_MAX, MDFLOAT_MAX) : CGSizeZero;

        CGFloat textWidth = [self sizeThatFits:maxSize].width;
        CGFloat availableWidth = self.frame.size.width * self.numberOfLines;
        if (self.numberOfLines > 1 && self.lineBreakMode == MDLineBreakByWordWrapping)
        {
            textWidth *= kMDLineBreakWordWrapTextWidthScalingFactor;
        }

        if (textWidth > availableWidth && textWidth > 0.0f)
        {
            originalAttributedText = [self.htmlAttributedText copy];
            self.htmlAttributedText = NSAttributedStringByScalingFontSize(self.htmlAttributedText, availableWidth / textWidth);
        }
    }

    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSaveGState(c);
    {
        CGContextSetTextMatrix(c, CGAffineTransformIdentity);

        // Inverts the CTM to match iOS coordinates (otherwise text draws upside-down; Mac OS's system is different)
        CGContextTranslateCTM(c, 0.0f, rect.size.height);
        CGContextScaleCTM(c, 1.0f, -1.0f);

        CFRange textRange = CFRangeMake(0, (CFIndex)_htmlAttributedText.length);

        // First, get the text rect (which takes vertical centering into account)
        CGRect textRect = [self textRectForBounds:rect limitedToNumberOfLines:self.numberOfLines];

        // CoreText draws it's text aligned to the bottom, so we move the CTM here to take our vertical offsets into account
        CGContextTranslateCTM(c, rect.origin.x, rect.size.height - textRect.origin.y - textRect.size.height);

        // Second, trace the shadow before the actual text, if we have one
        if (self.shadowColor && !self.highlighted)
        {
            CGContextSetShadowWithColor(c, self.shadowOffset, _shadowRadius, self.shadowColor.CGColor);
        }
        else if (self.highlightedShadowColor)
        {
            CGContextSetShadowWithColor(c, _highlightedShadowOffset, _highlightedShadowRadius, _highlightedShadowColor.CGColor);
        }

        // Finally, draw the text or highlighted text itself (on top of the shadow, if there is one)
        if (self.highlighted && self.highlightedTextColor)
        {
            NSMutableAttributedString *highlightAttributedString = [self.htmlAttributedText mutableCopy];

            [highlightAttributedString addAttribute:(__bridge NSString *)kCTForegroundColorAttributeName
                                              value:(id)[self.highlightedTextColor CGColor]
                                              range:NSMakeRange(0, highlightAttributedString.length)];

            if (!self.highlightFramesetter)
            {
                CTFramesetterRef highlightFramesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)highlightAttributedString);
                [self setHighlightFramesetter:highlightFramesetter];
                CFRelease(highlightFramesetter);
            }

            [self drawFramesetter:self.highlightFramesetter attributedString:highlightAttributedString textRange:textRange inRect:textRect context:c];
        }
        else
        {
            [self drawFramesetter:self.framesetter attributedString:self.htmlAttributedText textRange:textRange inRect:textRect context:c];
        }

        // If we adjusted the font size, set it back to its original size
        if (originalAttributedText)
        {
            // Use ivar directly to avoid clearing out framesetter and renderedAttributedText
            _htmlAttributedText = originalAttributedText;
        }
    }
    CGContextRestoreGState(c);
}

- (void)drawFramesetter:(CTFramesetterRef)framesetter
       attributedString:(NSAttributedString *)attributedString
              textRange:(CFRange)textRange
                 inRect:(CGRect)rect
                context:(CGContextRef)c
{
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, rect);
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, textRange, path, NULL);

    CFArrayRef lines = CTFrameGetLines(frame);
    NSInteger numberOfLines = self.numberOfLines > 0 ? MIN(self.numberOfLines, CFArrayGetCount(lines)) : CFArrayGetCount(lines);
    BOOL truncateLastLine = (self.lineBreakMode == MDLineBreakByTruncatingHead
                             || self.lineBreakMode == MDLineBreakByTruncatingMiddle
                             || self.lineBreakMode == MDLineBreakByTruncatingTail);

    CGPoint lineOrigins[numberOfLines];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, numberOfLines), lineOrigins);

    for (CFIndex lineIndex = 0; lineIndex < numberOfLines; lineIndex++)
    {
        CGPoint lineOrigin = lineOrigins[lineIndex];
        CGContextSetTextPosition(c, lineOrigin.x, lineOrigin.y);
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);

        if (lineIndex == numberOfLines - 1 && truncateLastLine)
        {
            // Check if the range of text in the last line reaches the end of the full attributed string
            CFRange lastLineRange = CTLineGetStringRange(line);

            if (!(lastLineRange.length == 0 && lastLineRange.location == 0) && lastLineRange.location + lastLineRange.length < textRange.location + textRange.length)
            {
                // Get correct truncationType and attribute position
                CTLineTruncationType truncationType;
                CFIndex truncationAttributePosition = lastLineRange.location;
                NSLineBreakMode lineBreakMode = self.lineBreakMode;

                // Multiple lines, only use NSLineBreakByTruncatingTail
                if (numberOfLines != 1)
                {
                    lineBreakMode = NSLineBreakByTruncatingTail;
                }

                switch (lineBreakMode)
                {
                    case NSLineBreakByTruncatingHead:
                        truncationType = kCTLineTruncationStart;
                        break;
                    case NSLineBreakByTruncatingMiddle:
                        truncationType = kCTLineTruncationMiddle;
                        truncationAttributePosition += (lastLineRange.length / 2);
                        break;
                    case NSLineBreakByTruncatingTail:
                    default:
                        truncationType = kCTLineTruncationEnd;
                        truncationAttributePosition += (lastLineRange.length - 1);
                        break;
                }

                NSString *truncationTokenString = self.truncationTokenString;
                if (!truncationTokenString)
                {
                    truncationTokenString = @"\u2026"; // Unicode Character 'HORIZONTAL ELLIPSIS' (U+2026)
                }

                NSDictionary *truncationTokenStringAttributes = self.truncationTokenStringAttributes;
                if (!truncationTokenStringAttributes)
                {
                    truncationTokenStringAttributes = [attributedString attributesAtIndex:(NSUInteger)truncationAttributePosition
                                                                           effectiveRange:NULL];
                }

                NSAttributedString *attributedTokenString = [[NSAttributedString alloc] initWithString:truncationTokenString
                                                                                            attributes:truncationTokenStringAttributes];
                CTLineRef truncationToken = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)attributedTokenString);

                // Append truncationToken to the string
                // because if string isn't too long, CT wont add the truncationToken on it's own
                // There is no change of a double truncationToken because CT only add the token if it removes characters (and the one we add will go first)
                NSMutableAttributedString *truncationString = [[attributedString attributedSubstringFromRange:NSMakeRange((NSUInteger)lastLineRange.location,
                                                                                                                          (NSUInteger)lastLineRange.length)] mutableCopy];
                if (lastLineRange.length > 0)
                {
                    // Remove any newline at the end (we don't want newline space between the text and the truncation token). There can only be one, because the second would be on the next line.
                    unichar lastCharacter = [truncationString.string characterAtIndex:(NSUInteger)(lastLineRange.length - 1)];
                    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:lastCharacter])
                    {
                        [truncationString deleteCharactersInRange:NSMakeRange((NSUInteger)(lastLineRange.length - 1), 1)];
                    }
                }

                [truncationString appendAttributedString:attributedTokenString];
                CTLineRef truncationLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)truncationString);

                // Truncate the line in case it is too long.
                CTLineRef truncatedLine = CTLineCreateTruncatedLine(truncationLine, rect.size.width, truncationType, truncationToken);
                if (!truncatedLine)
                {
                    // If the line is not as wide as the truncationToken, truncatedLine is NULL
                    truncatedLine = CFRetain(truncationToken);
                }

                // Adjust pen offset for flush depending on text alignment
                CGFloat flushFactor = 0.0f;
                switch (self.textAlignment)
                {
                    case NSTextAlignmentCenter:
                        flushFactor = 0.5f;
                        break;
                    case NSTextAlignmentRight:
                        flushFactor = 1.0f;
                        break;
                    case NSTextAlignmentLeft:
                    default:
                        break;
                }

                CGFloat penOffset = (CGFloat)CTLineGetPenOffsetForFlush(truncatedLine, flushFactor, rect.size.width);
                CGContextSetTextPosition(c, penOffset, lineOrigin.y);

                CTLineDraw(truncatedLine, c);

                CFRelease(truncatedLine);
                CFRelease(truncationLine);
                CFRelease(truncationToken);
            }
            else
            {
                CTLineDraw(line, c);
            }
        }
        else
        {
            CTLineDraw(line, c);
        }
    }

    CFRelease(frame);
    CFRelease(path);
}

#pragma mark - Styling methods

- (NSAttributedString *)applyStylesToString:(NSString *)string
{
    if (!string)
    {
        return [[NSAttributedString alloc] init];
    }

    // Create attributed string ref for text
    CFMutableAttributedStringRef attrString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
    CFAttributedStringReplaceString (attrString, CFRangeMake(0, 0), (__bridge CFStringRef)string);

    // Apply text color to text
    CFMutableDictionaryRef styleDict = CFDictionaryCreateMutable(0, 0, 0, 0);
    CFDictionaryAddValue(styleDict, kCTForegroundColorAttributeName, self.textColor.CGColor);
    CFAttributedStringSetAttributes(attrString, CFRangeMake( 0, CFAttributedStringGetLength(attrString)), styleDict, 0);

    CFRelease(styleDict);

    // Apply default paragraph text style
    [self applyParagraphStyleToText:attrString attributes:nil atPosition:0 withLength:CFAttributedStringGetLength(attrString)];

    // Apply font to text
    CTFontRef font = CTFontCreateWithName ((__bridge CFStringRef)self.font.fontName, self.font.pointSize, NULL);
    CFAttributedStringSetAttribute(attrString, CFRangeMake(0, CFAttributedStringGetLength(attrString)), kCTFontAttributeName, font);

    CFRelease(font);

    NSMutableArray *styleComponents = nil;

    if (self.highlighted)
    {
        styleComponents = self.highlightedStyleComponents;
    }
    else
    {
        styleComponents = self.styleComponents;
    }

    // Loop through each component and apply its style to the text
    for (MDHTMLComponent *component in styleComponents)
    {
        NSInteger index = [styleComponents indexOfObject:component];
        component.componentIndex = index;

        if ([component.htmlTag caseInsensitiveCompare:@"i"] == NSOrderedSame)
        {
            [self applyItalicStyleToText:attrString
                              atPosition:component.position
                              withLength:component.text.length];
        }
        else if ([component.htmlTag caseInsensitiveCompare:@"b"] == NSOrderedSame
                 || [component.htmlTag caseInsensitiveCompare:@"strong"] == NSOrderedSame)
        {
            [self applyBoldStyleToText:attrString
                            atPosition:component.position
                            withLength:[component.text length]];
        }
        else if ([component.htmlTag caseInsensitiveCompare:@"bi"] == NSOrderedSame)
        {
            [self applyBoldItalicStyleToText:attrString
                                  atPosition:component.position
                                  withLength:component.text.length];
        }
        else if ([component.htmlTag caseInsensitiveCompare:@"a"] == NSOrderedSame)
        {
            NSMutableDictionary *mutableLinkAttributes = [_linkAttributes mutableCopy];
            if (!_linkAttributes[(NSString *)kCTForegroundColorAttributeName] && !mutableLinkAttributes[NSForegroundColorAttributeName])
            {
                if ([self respondsToSelector:@selector(tintColor)])
                {
                    mutableLinkAttributes[(NSString *)kCTForegroundColorAttributeName] = self.tintColor;
                }
                else
                {
                    mutableLinkAttributes[(NSString *)kCTForegroundColorAttributeName] = [UIColor blueColor];
                }
            }

            [self applyFontAttributes:mutableLinkAttributes
                               toText:attrString
                           atPosition:component.position
                           withLength:component.text.length];
        }
        else if ([component.htmlTag caseInsensitiveCompare:@"u"] == NSOrderedSame || [component.htmlTag caseInsensitiveCompare:@"uu"] == NSOrderedSame)
        {
            if ([component.htmlTag caseInsensitiveCompare:@"u"] == NSOrderedSame)
            {
                CFAttributedStringSetAttribute(attrString, CFRangeMake(component.position, component.text.length),
                                               kCTUnderlineStyleAttributeName,  (__bridge CFNumberRef)[NSNumber numberWithInt:kCTUnderlineStyleSingle]);
            }
            else if ([component.htmlTag caseInsensitiveCompare:@"uu"] == NSOrderedSame)
            {
                CFAttributedStringSetAttribute(attrString, CFRangeMake(component.position, component.text.length),
                                               kCTUnderlineStyleAttributeName,  (__bridge CFNumberRef)[NSNumber numberWithInt:kCTUnderlineStyleDouble]);
            }

            if ([component.attributes objectForKey:(NSString *)kCTForegroundColorAttributeName])
            {
                id value = [component.attributes objectForKey:(NSString *)kCTForegroundColorAttributeName];
                [self applyUnderlineColor:value
                                   toText:attrString
                               atPosition:component.position
                               withLength:[component.text length]];
            }
        }
        else if ([component.htmlTag caseInsensitiveCompare:@"font"] == NSOrderedSame)
        {
            [self applyFontAttributes:component.attributes
                               toText:attrString
                           atPosition:component.position
                           withLength:[component.text length]];
        }
        else if ([component.htmlTag caseInsensitiveCompare:@"p"] == NSOrderedSame)
        {
            [self applyParagraphStyleToText:attrString
                                 attributes:component.attributes
                                 atPosition:component.position
                                 withLength:[component.text length]];
        }
        else if ([component.htmlTag caseInsensitiveCompare:@"center"] == NSOrderedSame)
        {
            [self applyCenterStyleToText:attrString
                              attributes:component.attributes
                              atPosition:component.position
                              withLength:[component.text length]];
        }
    }


    return (__bridge NSAttributedString *)attrString;
}

- (void)applyParagraphStyleToText:(CFMutableAttributedStringRef)text
                       attributes:(NSMutableDictionary *)attributes
                       atPosition:(NSInteger)position
                       withLength:(NSInteger)length
{
	CFMutableDictionaryRef styleDict = ( CFDictionaryCreateMutable( (0), 0, (0), (0) ) );

	CGFloat lineSpacing = self.leading;
    CGFloat lineSpacingAdjustment = CGFloat_ceil(self.font.lineHeight - self.font.ascender + self.font.descender);
    CGFloat lineHeightMultiple = self.lineHeightMultiple;
    CGFloat topMargin = self.textInsets.top;
    CGFloat bottomMargin = self.textInsets.bottom;
    CGFloat leftMargin = self.textInsets.left;
    CGFloat rightMargin = -self.textInsets.right;
    CGFloat firstLineIndent = self.firstLineIndent + leftMargin;

    CTLineBreakMode lineBreakMode = kCTLineBreakByWordWrapping;
    if (self.numberOfLines == 1)
    {
        lineBreakMode = CTLineBreakModeFromMDLineBreakMode(self.lineBreakMode);
    }

    CTTextAlignment textAlignment = CTTextAlignmentFromMDTextAlignment(self.textAlignment);

	for (NSUInteger i = 0; i < attributes.allKeys.count; i++)
	{
		NSString *key = [[attributes allKeys] objectAtIndex:i];
		id value = [attributes objectForKey:key];

		if ([key caseInsensitiveCompare:@"align"] == NSOrderedSame)
		{
			if ([value caseInsensitiveCompare:@"left"] == NSOrderedSame)
			{
				textAlignment = kCTLeftTextAlignment;
			}
			else if ([value caseInsensitiveCompare:@"right"] == NSOrderedSame)
			{
				textAlignment = kCTRightTextAlignment;
			}
			else if ([value caseInsensitiveCompare:@"justify"] == NSOrderedSame)
			{
				textAlignment = kCTJustifiedTextAlignment;
			}
			else if ([value caseInsensitiveCompare:@"center"] == NSOrderedSame)
			{
				textAlignment = kCTCenterTextAlignment;
			}
		}
		else if ([key caseInsensitiveCompare:@"indent"] == NSOrderedSame)
		{
			firstLineIndent = [value floatValue];
		}
		else if ([key caseInsensitiveCompare:@"linebreakmode"] == NSOrderedSame)
		{
			if ([value caseInsensitiveCompare:@"wordwrap"] == NSOrderedSame)
			{
				lineBreakMode = kCTLineBreakByWordWrapping;
			}
			else if ([value caseInsensitiveCompare:@"charwrap"] == NSOrderedSame)
			{
				lineBreakMode = kCTLineBreakByCharWrapping;
			}
			else if ([value caseInsensitiveCompare:@"clipping"] == NSOrderedSame)
			{
				lineBreakMode = kCTLineBreakByClipping;
			}
			else if ([value caseInsensitiveCompare:@"truncatinghead"] == NSOrderedSame)
			{
				lineBreakMode = kCTLineBreakByTruncatingHead;
			}
			else if ([value caseInsensitiveCompare:@"truncatingtail"] == NSOrderedSame)
			{
				lineBreakMode = kCTLineBreakByTruncatingTail;
			}
			else if ([value caseInsensitiveCompare:@"truncatingmiddle"] == NSOrderedSame)
			{
				lineBreakMode = kCTLineBreakByTruncatingMiddle;
			}
		}
	}

	CTParagraphStyleSetting settings[] =
    {
        { kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &textAlignment },
		{ kCTParagraphStyleSpecifierLineBreakMode, sizeof(CTLineBreakMode), &lineBreakMode  },
		{ kCTParagraphStyleSpecifierLineSpacing, sizeof(CGFloat), &lineSpacing },
        { kCTParagraphStyleSpecifierLineSpacingAdjustment, sizeof(CGFloat), &lineSpacingAdjustment },
        { kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(CGFloat), &lineHeightMultiple },
        { kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(CGFloat), &topMargin },
        { kCTParagraphStyleSpecifierParagraphSpacing, sizeof(CGFloat), &bottomMargin },
		{ kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(CGFloat), &firstLineIndent },
		{ kCTParagraphStyleSpecifierHeadIndent, sizeof(CGFloat), &leftMargin },
		{ kCTParagraphStyleSpecifierTailIndent, sizeof(CGFloat), &rightMargin },
	};


	CTParagraphStyleRef paragraphRef = CTParagraphStyleCreate(settings, sizeof(settings) / sizeof(CTParagraphStyleSetting));
	CFDictionaryAddValue(styleDict, kCTParagraphStyleAttributeName, paragraphRef);

	CFAttributedStringSetAttributes(text, CFRangeMake(position, length), styleDict, 0);

	CFRelease(paragraphRef);
    CFRelease(styleDict);
}

- (void)applyCenterStyleToText:(CFMutableAttributedStringRef)text
                    attributes:(NSMutableDictionary *)attributes
                    atPosition:(NSInteger)position
                    withLength:(NSInteger)length
{
	CFMutableDictionaryRef styleDict = CFDictionaryCreateMutable(0, 0, 0, 0) ;

	CGFloat lineSpacing = self.leading;
    CGFloat lineSpacingAdjustment = CGFloat_ceil(self.font.lineHeight - self.font.ascender + self.font.descender);
    CGFloat lineHeightMultiple = self.lineHeightMultiple;
    CGFloat topMargin = self.textInsets.top;
    CGFloat bottomMargin = self.textInsets.bottom;
    CGFloat leftMargin = self.textInsets.left;
    CGFloat rightMargin = -self.textInsets.right;
    CGFloat firstLineIndent = self.firstLineIndent + leftMargin;

    CTLineBreakMode lineBreakMode = kCTLineBreakByWordWrapping;
    if (self.numberOfLines == 1)
    {
        lineBreakMode = CTLineBreakModeFromMDLineBreakMode(self.lineBreakMode);
    }

    CTTextAlignment textAlignment = kCTCenterTextAlignment;

	CTParagraphStyleSetting settings[] =
    {
        { kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &textAlignment },
		{ kCTParagraphStyleSpecifierLineBreakMode, sizeof(CTLineBreakMode), &lineBreakMode  },
		{ kCTParagraphStyleSpecifierLineSpacing, sizeof(CGFloat), &lineSpacing },
        { kCTParagraphStyleSpecifierLineSpacingAdjustment, sizeof(CGFloat), &lineSpacingAdjustment },
        { kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(CGFloat), &lineHeightMultiple },
        { kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(CGFloat), &topMargin },
        { kCTParagraphStyleSpecifierParagraphSpacing, sizeof(CGFloat), &bottomMargin },
		{ kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(CGFloat), &firstLineIndent },
		{ kCTParagraphStyleSpecifierHeadIndent, sizeof(CGFloat), &leftMargin },
		{ kCTParagraphStyleSpecifierTailIndent, sizeof(CGFloat), &rightMargin },
	};

	CTParagraphStyleRef paragraphRef = CTParagraphStyleCreate(settings, sizeof(settings) / sizeof(CTParagraphStyleSetting));
	CFDictionaryAddValue(styleDict, kCTParagraphStyleAttributeName, paragraphRef);

	CFAttributedStringSetAttributes( text, CFRangeMake(position, length), styleDict, 0 );

	CFRelease(paragraphRef);
    CFRelease(styleDict);
}

- (void)applyItalicStyleToText:(CFMutableAttributedStringRef)text
                    atPosition:(NSInteger)position
                    withLength:(NSInteger)length
{
    CFTypeRef actualFontRef = CFAttributedStringGetAttribute(text, position, kCTFontAttributeName, NULL);
    CTFontRef italicFontRef = CTFontCreateCopyWithSymbolicTraits(actualFontRef, 0.0, NULL, kCTFontItalicTrait, kCTFontItalicTrait);

    if (!italicFontRef)
    {
        UIFont *font = [UIFont italicSystemFontOfSize:CTFontGetSize(actualFontRef)];
        italicFontRef = CTFontCreateWithName ((__bridge CFStringRef)[font fontName], [font pointSize], NULL);
    }

    CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTFontAttributeName, italicFontRef);

    CFRelease(italicFontRef);
}

- (void)applyFontAttributes:(NSDictionary *)attributes
                     toText:(CFMutableAttributedStringRef)text
                 atPosition:(NSInteger)position
                 withLength:(NSInteger)length
{
	for (NSString *key in attributes.allKeys)
	{
		id value = attributes[key];

        if ([value isKindOfClass:[NSString class]])
        {
            value = [value stringByReplacingOccurrencesOfString:@"'" withString:@""];
        }

        if ([key caseInsensitiveCompare:@"face"] == NSOrderedSame)
        {
            CGFloat size = self.font.pointSize;

            if (attributes[@"size"])
            {
                size = [attributes[@"size"] floatValue];
            }

            UIFont *font = [UIFont fontWithName:value size:size];

            if (font)
            {
                [attributes setValue:font forKey:(NSString *)kCTFontNameAttribute];
            }
        }
        else if ([key caseInsensitiveCompare:@"size"] == NSOrderedSame && !attributes[@"face"] && !attributes[@"FACE"])
        {
            CGFloat size = [attributes[@"size"] floatValue];
            UIFont *font = [UIFont systemFontOfSize:size];
            [attributes setValue:font forKey:(NSString *)kCTFontNameAttribute];
        }
        else if ([key isEqualToString:(NSString *)kCTParagraphStyleAttributeName])
        {
            CFAttributedStringSetAttribute(text, CFRangeMake(position, length),
                                           kCTParagraphStyleAttributeName, (CTParagraphStyleRef)value);
        }
        else if ([key isEqualToString:NSParagraphStyleAttributeName])
        {
            NSMutableAttributedString *mutableText = [value mutableCopy];
            [mutableText addAttribute:NSParagraphStyleAttributeName value:(NSParagraphStyle *)value range:NSMakeRange(position, length)];
        }
		else if ([key isEqualToString:(NSString *)kCTForegroundColorAttributeName]
                 || [key isEqualToString:NSForegroundColorAttributeName]
                 || [key caseInsensitiveCompare:@"color"] == NSOrderedSame)
		{
			[self applyColor:value toText:text atPosition:position withLength:length];
		}
		else if ([key isEqualToString:(NSString *)kCTStrokeWidthAttributeName]
                 || [key isEqualToString:NSStrokeWidthAttributeName])
		{
			CFAttributedStringSetAttribute(text,
                                           CFRangeMake(position, length),
                                           kCTStrokeWidthAttributeName,
                                           (__bridge CFTypeRef)([attributes objectForKey:(NSString *)kCTStrokeWidthAttributeName]));
		}
        else if ([key isEqualToString:(NSString *)kCTStrokeColorAttributeName]
                 || [key isEqualToString:NSStrokeColorAttributeName])
		{
			[self applyStrokeColor:value toText:text atPosition:position withLength:length];
		}
		else if ([key isEqualToString:(NSString *)kCTKernAttributeName]
                 || [key isEqualToString:NSKernAttributeName])
		{
			CFAttributedStringSetAttribute(text,
                                           CFRangeMake(position, length),
                                           kCTKernAttributeName,
                                           (__bridge CFTypeRef)([attributes objectForKey:(NSString *)kCTKernAttributeName]));
		}
		else if ([key isEqualToString:(NSString *)kCTUnderlineStyleAttributeName]
                 || [key isEqualToString:NSUnderlineStyleAttributeName])
		{
            CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTUnderlineStyleAttributeName,  (__bridge CFNumberRef)value);
		}
	}

	UIFont *font = [attributes objectForKey:(NSString *)kCTFontNameAttribute];

	if (font)
	{
		CTFontRef customFont = CTFontCreateWithName ((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
		CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTFontAttributeName, customFont);
		CFRelease(customFont);
        return;
	}

    font = [attributes objectForKey:NSFontAttributeName];

    if (font)
	{
		CTFontRef customFont = CTFontCreateWithName ((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
		CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTFontAttributeName, customFont);
		CFRelease(customFont);
	}
}

- (void)applyBoldStyleToText:(CFMutableAttributedStringRef)text
                  atPosition:(NSInteger)position
                  withLength:(NSInteger)length
{
    CFTypeRef actualFontRef = CFAttributedStringGetAttribute(text, position, kCTFontAttributeName, NULL);
    CTFontRef boldFontRef = CTFontCreateCopyWithSymbolicTraits(actualFontRef, 0.0, NULL, kCTFontBoldTrait, kCTFontBoldTrait);

    if (!boldFontRef)
    {
        UIFont *font = [UIFont boldSystemFontOfSize:CTFontGetSize(actualFontRef)];
        boldFontRef = CTFontCreateWithName((__bridge CFStringRef)font.fontName, self.font.pointSize, NULL);
    }

    CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTFontAttributeName, boldFontRef);

    CFRelease(boldFontRef);
}

- (void)applyBoldItalicStyleToText:(CFMutableAttributedStringRef)text
                        atPosition:(NSInteger)position
                        withLength:(NSInteger)length
{
    CFTypeRef actualFontRef = CFAttributedStringGetAttribute(text, position, kCTFontAttributeName, NULL);
    CTFontRef boldItalicFontRef = CTFontCreateCopyWithSymbolicTraits(actualFontRef, 0.0, NULL, kCTFontBoldTrait | kCTFontItalicTrait , kCTFontBoldTrait | kCTFontItalicTrait);

    if (!boldItalicFontRef)
    {
        NSString *fontName = [NSString stringWithFormat:@"%@-BoldOblique", self.font.fontName];
        boldItalicFontRef = CTFontCreateWithName((__bridge CFStringRef)fontName, self.font.pointSize, NULL);
    }

    if (boldItalicFontRef)
    {
        CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTFontAttributeName, boldItalicFontRef);
        CFRelease(boldItalicFontRef);
    }
}

- (void)applyColor:(id)value
            toText:(CFMutableAttributedStringRef)text
        atPosition:(NSInteger)position
        withLength:(NSInteger)length
{
    if ([value isKindOfClass:[UIColor class]])
    {
        UIColor *color = (UIColor *)value;
        CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTForegroundColorAttributeName, color.CGColor);
    }
    else if ([value isKindOfClass:[NSString class]])
    {
        if ([value rangeOfString:@"#"].location == 0)
        {
            if ([value rangeOfString:@"#"].location == 0)
            {
                value = [value stringByReplacingOccurrencesOfString:@"#" withString:@""];
            }

            CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();

            NSArray *colorComponents = CGColorComponentsForHex(value);

            CGFloat components[] = {[[colorComponents objectAtIndex:0] floatValue],
                [[colorComponents objectAtIndex:1] floatValue],
                [[colorComponents objectAtIndex:2] floatValue],
                [[colorComponents objectAtIndex:3] floatValue]};

            CGColorRef color = CGColorCreate(rgbColorSpace, components);
            CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTForegroundColorAttributeName, color);

            CFRelease(color);
            CGColorSpaceRelease(rgbColorSpace);
        }
    }
}

- (void)applyStrokeColor:(id)value
                  toText:(CFMutableAttributedStringRef)text
              atPosition:(NSInteger)position
              withLength:(NSInteger)length
{
    if ([value isKindOfClass:[UIColor class]])
    {
        UIColor *color = (UIColor *)value;
        CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTStrokeColorAttributeName, color.CGColor);
    }
    else if ([value isKindOfClass:[NSString class]])
    {
        if ([value rangeOfString:@"#"].location == 0)
        {
            value = [value stringByReplacingOccurrencesOfString:@"#" withString:@""];
        }

        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();

        NSArray *colorComponents = CGColorComponentsForHex(value);

        CGFloat components[] = {[[colorComponents objectAtIndex:0] floatValue],
            [[colorComponents objectAtIndex:1] floatValue],
            [[colorComponents objectAtIndex:2] floatValue],
            [[colorComponents objectAtIndex:3] floatValue]};

        CGColorRef color = CGColorCreate(rgbColorSpace, components);
        CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTStrokeColorAttributeName, color);

        CFRelease(color);
        CGColorSpaceRelease(rgbColorSpace);
    }
}

- (void)applyUnderlineColor:(id)value
                     toText:(CFMutableAttributedStringRef)text
                 atPosition:(NSInteger)position withLength:(NSInteger)length
{
    if ([value isKindOfClass:[UIColor class]])
    {
        UIColor *color = (UIColor *)value;
        CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTForegroundColorAttributeName, color.CGColor);
    }
    else if ([value isKindOfClass:[NSString class]])
    {
        value = [value stringByReplacingOccurrencesOfString:@"'" withString:@""];

        if ([value rangeOfString:@"#"].location==0)
        {
            CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
            value = [value stringByReplacingOccurrencesOfString:@"#" withString:@""];

            NSArray *colorComponents = CGColorComponentsForHex(value);

            CGFloat components[] = {[[colorComponents objectAtIndex:0] floatValue],
                [[colorComponents objectAtIndex:1] floatValue],
                [[colorComponents objectAtIndex:2] floatValue],
                [[colorComponents objectAtIndex:3] floatValue]};

            CGColorRef color = CGColorCreate(rgbColorSpace, components);
            CFAttributedStringSetAttribute(text, CFRangeMake(position, length),kCTUnderlineColorAttributeName, color);
            CGColorRelease(color);
            CGColorSpaceRelease(rgbColorSpace);
        }
    }
}

#pragma mark - Parsing methods

- (void)extractStyleFromText:(NSString *)data
{
    // Replace html entities
    if (data)
    {
        data = [data stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
        data = [data stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
        data = [data stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
        data = [data stringByReplacingOccurrencesOfString:@"&apos;" withString:@"'"];
        data = [data stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
    }

	NSMutableArray *components = [NSMutableArray array];
    NSInteger last_position = 0;
    NSString *text = nil;
	NSString *htmlTag = nil;

    NSScanner *scanner = [NSScanner scannerWithString:data];

    while (!scanner.isAtEnd)
    {
        // Get position of scanner, used to check if <p> tags are at the start of the text
        NSInteger tagStartPosition = scanner.scanLocation;

        // Capture tag text
		[scanner scanUpToString:@"<" intoString:NULL];
		[scanner scanUpToString:@">" intoString:&text];

		NSString *fullTag = [NSString stringWithFormat:@"%@>", text];

        NSInteger position = [data rangeOfString:fullTag].location;
		if (position != NSNotFound)
		{
            // Remove tag from text and replace occurences of paragraph tags
			if ([fullTag rangeOfString:@"<p"].location == 0 && tagStartPosition != 0)
			{
				data = [data stringByReplacingOccurrencesOfString:fullTag
                                                       withString:@"\n"
                                                          options:NSCaseInsensitiveSearch
                                                            range:NSMakeRange(last_position, position + fullTag.length - last_position)];
			}
			else
			{
				data = [data stringByReplacingOccurrencesOfString:fullTag
                                                       withString:@""
                                                          options:NSCaseInsensitiveSearch
                                                            range:NSMakeRange(last_position, position + fullTag.length - last_position)];
			}
		}

        // Found closing tag
		if ([text rangeOfString:@"</"].location == 0)
		{
            // Get just the html tag value
			htmlTag = [text substringFromIndex:2];

			if (position != NSNotFound)
			{
                // Find the the corresponding component for the closing tag
				for (NSInteger i = components.count - 1; i >= 0; i--)
				{
					MDHTMLComponent *component = components[i];
					if (component.text == nil && [component.htmlTag isEqualToString:htmlTag])
					{
						NSString *componentText = [data substringWithRange:NSMakeRange(component.position, position - component.position)];
						component.text = componentText;

                        if ([component.htmlTag caseInsensitiveCompare:@"a"] == NSOrderedSame)
                        {
                            NSTextCheckingResult *result = [NSTextCheckingResult linkCheckingResultWithRange:NSMakeRange(component.position, component.text.length)
                                                                                                         URL:[NSURL URLWithString:component.attributes[@"href"]]];
                            [_links addObject:result];
                        }
						break;
					}
				}
			}
		}
		else
		{
            // Get text components without the opening '<'
			NSArray *textComponents = [[text substringFromIndex:1] componentsSeparatedByString:@" "];

            // Capture html tag for later
            htmlTag = textComponents[0];

            // Capture the tag's attributes
			NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
			for (NSUInteger i = 1; i < textComponents.count; i++)
			{
				NSArray *pair = [[textComponents objectAtIndex:i] componentsSeparatedByString:@"="];
				if (pair.count > 0)
                {
					NSString *key = [[pair objectAtIndex:0] lowercaseString];

					if (pair.count >= 2)
                    {
						NSString *value = [[pair subarrayWithRange:NSMakeRange(1, [pair count] - 1)] componentsJoinedByString:@"="];
						value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, 1)];
						value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@"" options:NSLiteralSearch range:NSMakeRange([value length]-1, 1)];
                        value = [value stringByReplacingOccurrencesOfString:@"'" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, 1)];
						value = [value stringByReplacingOccurrencesOfString:@"'" withString:@"" options:NSLiteralSearch range:NSMakeRange([value length]-1, 1)];

						[attributes setObject:value forKey:key];
					}
                    else if (pair.count == 1)
                    {
						[attributes setObject:key forKey:key];
					}
				}
			}

            // Create component from tag and attributes, we'll know the text once we reach the closing tag
            MDHTMLComponent *component = [[MDHTMLComponent alloc] initWithString:nil htmlTag:htmlTag attributes:attributes];
			component.position = position;

			[components addObject:component];
		}

		last_position = position;
	}

    self.styleComponents = components;
    _plainText = data;
}

#pragma mark - UILabel

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
}

// Fixes crash when loading from a UIStoryboard
- (UIColor *)textColor
{
	UIColor *color = [super textColor];
	if (!color)
    {
		color = [UIColor blackColor];
	}

	return color;
}

- (CGRect)textRectForBounds:(CGRect)bounds
     limitedToNumberOfLines:(NSInteger)numberOfLines
{
    if (!_htmlText)
    {
        return [super textRectForBounds:bounds limitedToNumberOfLines:numberOfLines];
    }

    CGRect textRect = bounds;

    // Calculate height with a minimum of double the font pointSize, to ensure that CTFramesetterSuggestFrameSizeWithConstraints doesn't return CGSizeZero, as it would if textRect height is insufficient.
    textRect.size.height = MAX(self.font.pointSize * 2.0f, bounds.size.height);

    // Adjust the text to be in the center vertically, if the text size is smaller than bounds
    CGSize textSize = CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter, CFRangeMake(0, (CFIndex)self.htmlAttributedText.length), NULL, textRect.size, NULL);
    textSize = CGSizeMake(CGFloat_ceil(textSize.width), CGFloat_ceil(textSize.height)); // Fix for iOS 4, CTFramesetterSuggestFrameSizeWithConstraints sometimes returns fractional sizes

    if (textSize.height < textRect.size.height)
    {
        CGFloat yOffset = 0.0f;
        switch (self.verticalAlignment)
        {
            case MDHTMLLabelVerticalAlignmentCenter:
                yOffset = CGFloat_floor((bounds.size.height - textSize.height) / 2.0f);
                break;
            case MDHTMLLabelVerticalAlignmentBottom:
                yOffset = bounds.size.height - textSize.height;
                break;
            case MDHTMLLabelVerticalAlignmentTop:
            default:
                break;
        }

        textRect.origin.y += yOffset;
    }

    return textRect;
}

#pragma mark - UIView

+ (CGFloat)sizeThatFitsHTMLString:(NSString *)htmlString
                         withFont:(UIFont *)font
                      constraints:(CGSize)size
           limitedToNumberOfLines:(NSUInteger)numberOfLines
{
    MDHTMLLabel *label = [[MDHTMLLabel alloc] initWithFrame:CGRectMake(0.0, 0.0, size.width, size.height)];
    label.htmlText = htmlString;
    label.font = font;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;

    return [label sizeThatFits:size].height;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    if (!self.htmlAttributedText)
    {
        return [super sizeThatFits:size];
    }

    return CTFramesetterSuggestFrameSizeForAttributedStringWithConstraints(self.framesetter, self.htmlAttributedText, size, (NSUInteger)self.numberOfLines);
}

- (CGSize)intrinsicContentSize
{
    // There's an implicit width from the original UILabel implementation
    return [self sizeThatFits:[super intrinsicContentSize]];
}

- (void)tintColorDidChange
{
    BOOL isInactive = (CGColorSpaceGetModel(CGColorGetColorSpace([self.tintColor CGColor])) == kCGColorSpaceModelMonochrome);

    NSMutableDictionary *mutableLinkAttributes = [_linkAttributes mutableCopy];
    if (!_linkAttributes[(NSString *)kCTForegroundColorAttributeName] && !mutableLinkAttributes[NSForegroundColorAttributeName])
    {
        if ([self respondsToSelector:@selector(tintColor)])
        {
            mutableLinkAttributes[(NSString *)kCTForegroundColorAttributeName] = self.tintColor;
        }
        else
        {
            mutableLinkAttributes[(NSString *)kCTForegroundColorAttributeName] = [UIColor blueColor];
        }
    }

    NSMutableDictionary *mutableInactiveLinkAttributes = [_inactiveLinkAttributes mutableCopy];
    if (!mutableInactiveLinkAttributes[(NSString *)kCTForegroundColorAttributeName] && !mutableInactiveLinkAttributes[NSForegroundColorAttributeName])
    {
        mutableInactiveLinkAttributes[(NSString *)kCTForegroundColorAttributeName] = [UIColor grayColor];
    }

    if (!mutableInactiveLinkAttributes[(NSString *)kCTFontAttributeName] && !mutableInactiveLinkAttributes[NSFontAttributeName])
    {
        if (mutableLinkAttributes[(NSString *)kCTFontAttributeName] && mutableLinkAttributes[NSFontAttributeName])
        {
            mutableInactiveLinkAttributes[(NSString *)kCTFontAttributeName] = mutableLinkAttributes[(NSString *)kCTFontAttributeName];
        }
        else
        {
            mutableInactiveLinkAttributes[(NSString *)kCTFontAttributeName] = self.font;
        }
    }

    NSDictionary *attributesToRemove = isInactive ? mutableLinkAttributes : mutableInactiveLinkAttributes;
    NSDictionary *attributesToAdd = isInactive ? mutableInactiveLinkAttributes : mutableLinkAttributes;

    NSMutableAttributedString *mutableAttributedString = [self.htmlAttributedText mutableCopy];
    for (NSTextCheckingResult *result in self.links)
    {
        [attributesToRemove enumerateKeysAndObjectsUsingBlock:^(NSString *name, __unused id value, __unused BOOL *stop)
        {
            [mutableAttributedString removeAttribute:name range:result.range];
        }];

        if (attributesToAdd)
        {
            [mutableAttributedString addAttributes:attributesToAdd range:result.range];
        }
    }

    self.htmlAttributedText = mutableAttributedString;
    [self setNeedsDisplay];
}

#pragma mark - Data Detection

- (NSString *)detectURLsInText:(NSString *)text
{
    return text;
}

- (NSTextCheckingResult *)linkAtCharacterIndex:(CFIndex)idx
{
    NSEnumerator *enumerator = [self.links reverseObjectEnumerator];
    NSTextCheckingResult *result = nil;
    while ((result = [enumerator nextObject]))
    {
        if (NSLocationInRange((NSUInteger)idx, result.range))
        {
            return result;
        }
    }

    return nil;
}

- (NSTextCheckingResult *)linkAtPoint:(CGPoint)p
{
    CFIndex idx = [self characterIndexAtPoint:p];

    return [self linkAtCharacterIndex:idx];
}

- (CFIndex)characterIndexAtPoint:(CGPoint)p
{
    if (!CGRectContainsPoint(self.bounds, p))
    {
        return NSNotFound;
    }

    CGRect textRect = [self textRectForBounds:self.bounds limitedToNumberOfLines:self.numberOfLines];
    if (!CGRectContainsPoint(textRect, p))
    {
        return NSNotFound;
    }

    // Offset tap coordinates by textRect origin to make them relative to the origin of frame
    p = CGPointMake(p.x - textRect.origin.x, p.y - textRect.origin.y);
    // Convert tap coordinates (start at top left) to CT coordinates (start at bottom left)
    p = CGPointMake(p.x, textRect.size.height - p.y);

    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, textRect);
    CTFrameRef frame = CTFramesetterCreateFrame([self framesetter], CFRangeMake(0, (CFIndex)[self.htmlAttributedText length]), path, NULL);
    if (frame == NULL)
    {
        CFRelease(path);
        return NSNotFound;
    }

    CFArrayRef lines = CTFrameGetLines(frame);
    NSInteger numberOfLines = self.numberOfLines > 0 ? MIN(self.numberOfLines, CFArrayGetCount(lines)) : CFArrayGetCount(lines);
    if (numberOfLines == 0)
    {
        CFRelease(frame);
        CFRelease(path);
        return NSNotFound;
    }

    CFIndex idx = NSNotFound;

    CGPoint lineOrigins[numberOfLines];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, numberOfLines), lineOrigins);

    for (CFIndex lineIndex = 0; lineIndex < numberOfLines; lineIndex++)
    {
        CGPoint lineOrigin = lineOrigins[lineIndex];
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);

        // Get bounding information of line
        CGFloat ascent = 0.0f, descent = 0.0f, leading = 0.0f;
        CGFloat width = (CGFloat)CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        CGFloat yMin = (CGFloat)floor(lineOrigin.y - descent);
        CGFloat yMax = (CGFloat)ceil(lineOrigin.y + ascent);

        // Check if we've already passed the line
        if (p.y > yMax)
        {
            break;
        }
        // Check if the point is within this line vertically
        if (p.y >= yMin)
        {
            // Check if the point is within this line horizontally
            if (p.x >= lineOrigin.x && p.x <= lineOrigin.x + width) {
                // Convert CT coordinates to line-relative coordinates
                CGPoint relativePoint = CGPointMake(p.x - lineOrigin.x, p.y - lineOrigin.y);
                idx = CTLineGetStringIndexForPosition(line, relativePoint);
                break;
            }
        }
    }

    CFRelease(frame);
    CFRelease(path);

    return idx;
}

#pragma mark - UIResponder

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)canPerformAction:(SEL)action
              withSender:(__unused id)sender
{
    return (action == @selector(copy:));
}

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];

    self.activeLink = [self linkAtPoint:[touch locationInView:self]];

    if (self.activeLink)
    {
        self.holdGestureTimer = [NSTimer scheduledTimerWithTimeInterval:_minimumPressDuration
                                                                 target:self
                                                               selector:@selector(handleDidHoldTouch:)
                                                               userInfo:touch
                                                                repeats:NO];
    }
    else
    {
        [super touchesBegan:touches withEvent:event];
        self.highlighted = YES;
    }
}

- (void)touchesMoved:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    if (self.activeLink)
    {
        UITouch *touch = [touches anyObject];

        if (self.activeLink != [self linkAtPoint:[touch locationInView:self]])
        {
            self.activeLink = nil;
            [_holdGestureTimer invalidate];
        }
    }
    else
    {
        [super touchesMoved:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    self.highlighted = NO;

    if (self.activeLink)
    {
        NSTextCheckingResult *result = self.activeLink;
        self.activeLink = nil;
        [_holdGestureTimer invalidate];
        
        if ([_delegate respondsToSelector:@selector(HTMLLabel:didSelectLinkWithURL:)])
        {
            [_delegate HTMLLabel:self didSelectLinkWithURL:result.URL];
            return;
        }
    }
    else
    {
        [super touchesEnded:touches withEvent:event];
    }
}

- (void)touchesCancelled:(NSSet *)touches
               withEvent:(UIEvent *)event
{
    if (self.activeLink)
    {
        self.activeLink = nil;
    }
    else
    {
        [super touchesCancelled:touches withEvent:event];
    }
}

- (void)handleDidHoldTouch:(NSTimer *)timer
{
    self.highlighted = NO;

    [_holdGestureTimer invalidate];
    
    if ([_delegate respondsToSelector:@selector(HTMLLabel:didHoldLinkWithURL:)])
    {
        NSTextCheckingResult *result = self.activeLink;
        self.activeLink = nil;
        
        [_delegate HTMLLabel:self didHoldLinkWithURL:result.URL];
    }
}

#pragma mark - UIResponderStandardEditActions

- (void)copy:(id)sender
{
    if (_htmlText)
    {
        [[UIPasteboard generalPasteboard] setString:_plainText];
    }
    else
    {
        [super copy:sender];
    }
}

@end

