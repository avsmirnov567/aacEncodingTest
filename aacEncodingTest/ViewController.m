//
//  ViewController.m
//  aacEncodingTest
//
//  Created by Aleksandr Smirnov on 13.03.17.
//  Copyright © 2017 Line App. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) NSData *fileBytes;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)playButtonAction:(id)sender {
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *myFile = [mainBundle pathForResource: @"testaudio" ofType: @"aac"];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:myFile]) {
        self.fileBytes = [[NSFileManager defaultManager] contentsAtPath:myFile];
        NSLog(@"File read, number of bytes: %ul", [self.fileBytes length]);
    } else {
        NSLog(@"File not exits");
    }
}

@end
