//
//  DemoViewController.m
//  MDHTMLLabel
//
//  Created by Matt Donnelly on 07/11/2013.
//  Copyright (c) 2013 Matt Donnelly. All rights reserved.
//

#import "DemoViewController.h"
#import "MDHTMLLabel.h"

static const CGFloat kPadding = 10.0;

NSString *const kDemoText =
@"<a href='http://gihub.com/mattdonnelly/MDHTMLLabel'>MDHTMLLabel</a> is a lightweight, easy to \
use class for rendering text containing HTML tags on iOS 6.0+. It behaves almost <i>exactly</i> the \
same as <b>UILabel</b>, allows you to fully customise its appearence with added features thanks to \
<b>CoreText</b> and lets you handle when a user taps or holds down a link in the label unlike many \
similar libraries.";

@interface DemoViewController () <MDHTMLLabelDelegate>

@end

@implementation DemoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    MDHTMLLabel *htmlLabel = [[MDHTMLLabel alloc] init];
    htmlLabel.text = kDemoText;
    htmlLabel.delegate = self;
    htmlLabel.preferredMaxLayoutWidth = self.view.frame.size.width - kPadding - kPadding;
    htmlLabel.linkAttributes = @{MDHTMLLabelAttributeColorName: [UIColor blueColor],
                                 MDHTMLLabelAttributeFontName: [UIFont boldSystemFontOfSize:16.0f],
                                 MDHTMLLabelAttributeUnderlineName: @(1)};
    htmlLabel.selectedLinkAttributes = @{MDHTMLLabelAttributeColorName: @"#ff0000",
                                         MDHTMLLabelAttributeFontName: [UIFont boldSystemFontOfSize:16.0f]};
    htmlLabel.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:htmlLabel];

    NSDictionary *views = @{@"htmlLabel": htmlLabel,
                            @"topLayoutGuide": self.topLayoutGuide};

    NSDictionary *metrics = @{@"padding": @(kPadding)};

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(padding)-[htmlLabel]-(padding)-|"
                                                                      options:0
                                                                      metrics:metrics
                                                                        views:views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide]-(padding)-[htmlLabel]-(padding)-|"
                                                                      options:0
                                                                      metrics:metrics
                                                                        views:views]];
}

#pragma mark - MDHTMLLabelDelegate methods

- (void)HTMLLabel:(MDHTMLLabel *)label didSelectLinkWithURL:(NSURL *)URL
{
    NSLog(@"Did select link with URL: %@", URL.absoluteString);
}

- (void)HTMLLabel:(MDHTMLLabel *)label didHoldLinkWithURL:(NSURL *)URL
{
    NSLog(@"Did hold link with URL: %@", URL.absoluteString);
}

@end
