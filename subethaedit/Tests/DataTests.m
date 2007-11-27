//
//  DataTests.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 18.09.06.
//  Copyright (c) 2006 TheCodingMonkeys. All rights reserved.
//

#import "DataTests.h"
#import "TCMBencodingUtilities.h"
#import "NSDataTCMAdditions.h"
#import <Sparkle/SUUtilities.h>

@implementation DataTests

- (void)setUp {}

- (void)testSparkleVersionChecking {
    STAssertEquals(
        SUStandardVersionComparison(@"10.4.7",@"10.4.7"),
        NSOrderedSame,
        @"comparing 10.4.7 with 10.4.7");
    STAssertEquals(
        SUStandardVersionComparison(@"10.4.7",@"10.5"),
        NSOrderedDescending,
        @"comparing 10.4.7 with 10.5");
    STAssertEquals(
        SUStandardVersionComparison(@"10.4.7",@"10.3.9"),
        NSOrderedAscending,
        @"comparing 10.4.7 with 10.3.9");
}

- (void)testUTF8BOMDataAdditions {
    NSData *utf8StringData=[@"foo bar" dataUsingEncoding:NSUTF8StringEncoding];

    STAssertFalse(
        [utf8StringData startsWithUTF8BOM],
        @"NSString conversion doesn't contain a utf8 bom");
    STAssertTrue(
        [[utf8StringData dataPrefixedWithUTF8BOM] startsWithUTF8BOM],
        @"if we add a bom we recognize it");
    char utf8_bom[3];
    utf8_bom[0]=0xef;
    utf8_bom[1]=0xbb;
    utf8_bom[2]=0xbf;
    NSData *utf8BOMData = [NSData dataWithBytes:utf8_bom length:3];
    STAssertTrue(
        [utf8BOMData dataPrefixedWithUTF8BOM],
        @"if we make a bom we recognize it");
}

- (void)roundtripBencode:(id)anObject {
    STAssertEqualObjects(
        TCM_BdecodedObjectWithData(TCM_BencodedObject(anObject)),
        anObject,
        @"round-trip bencoding of %@", anObject);
}

- (void)bdecode:(NSData *)anData shouldFail:(BOOL)aFlag{
    id result = TCM_BdecodedObjectWithData(anData);
    STAssertTrue(
        aFlag ? (result == nil) : (result != nil),
        @"decoding of %@",[[[NSString alloc] initWithData:anData encoding:NSMacOSRomanStringEncoding] autorelease]);
}

- (void)testBencoding {
    [self roundtripBencode:[NSNumber numberWithInt:5]];
    [self roundtripBencode:@"Sample text"];
    STAssertEqualObjects(
        TCM_BdecodedObjectWithData(TCM_BencodedObject([NSNumber numberWithFloat:2.2])),
        [NSNumber numberWithInt:[[NSNumber numberWithFloat:2.2] intValue]],
        @"round-trip bencoding of %@",[NSNumber numberWithFloat:2.2]);
    long long i=0;
    for (i=LLONG_MAX; i>0; i=i/10) {
        [self roundtripBencode:[NSNumber numberWithLongLong:i]];
    }
    for (i=LLONG_MIN; i<0; i=i/10) {
        [self roundtripBencode:[NSNumber numberWithLongLong:i]];
    }
    NSLog(@"%qd",2147483607);
    [self roundtripBencode:[NSNumber numberWithLongLong:-2147483607]];
    [self roundtripBencode:[NSArray arrayWithObjects:@"one",@"two",@"three",nil]];
    [self roundtripBencode:[NSDictionary dictionaryWithObjectsAndKeys:@"content one",@"key one",@"content 2",@"key 2",nil]];
    [self roundtripBencode:[NSArray arrayWithObjects:@"one",@"two",[NSDictionary dictionaryWithObjectsAndKeys:@"content one",@"key one",@"content 2",@"key 2",nil],nil]];
    [self roundtripBencode:[NSDictionary dictionaryWithObjectsAndKeys:@"content one",@"key one",[NSArray arrayWithObjects:@"one",@"two",@"three",nil],@"key 2",nil]];
    
    
    [self bdecode:[@":one3:twod7" dataUsingEncoding:NSMacOSRomanStringEncoding]                                                             shouldFail:YES];
    [self bdecode:[@"d7:key one11:content one5:key 2l3:one3:two5:threeee" dataUsingEncoding:NSMacOSRomanStringEncoding]                     shouldFail:NO];
    [self bdecode:[@"d7:key one11:content one:5:key 2l3:on" dataUsingEncoding:NSMacOSRomanStringEncoding]                                   shouldFail:YES];
    [self bdecode:[@"l3:one3:two3:shouldfail" dataUsingEncoding:NSMacOSRomanStringEncoding]                                                 shouldFail:YES];
    [self bdecode:[@"d3:cnti133029683e4:name4:Cecy3:uID16...A.8..........$e" dataUsingEncoding:NSMacOSRomanStringEncoding]                  shouldFail:NO];
    [self bdecode:[@"d6:rendez4:vous3:uid36:DDC5EF9E-A818-11D8-BF7B-00039398A6244:vers3:200e" dataUsingEncoding:NSMacOSRomanStringEncoding] shouldFail:NO];
}

- (void)tearDown {}

@end