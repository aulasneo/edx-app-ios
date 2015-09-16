//
//  OEXDateFormattingTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/27/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "OEXDateFormatting.h"

@interface OEXDateFormattingTests : XCTestCase

@end

static NSTimeZone *actualLocalTimeZone;

@implementation OEXDateFormattingTests

- (void)setUp {
    [super setUp];
    actualLocalTimeZone = [NSTimeZone defaultTimeZone];
}

- (void)testZero {
    XCTAssertEqualObjects(@"00:00", [OEXDateFormatting formatSecondsAsVideoLength:0]);
}

- (void)testUnderHour {
    XCTAssertEqualObjects(@"59:59", [OEXDateFormatting formatSecondsAsVideoLength:61 * 59]);
}

- (void)testOverHour {
    XCTAssertEqualObjects(@"01:00:00", [OEXDateFormatting formatSecondsAsVideoLength:60 * 60]);
}

- (void)testLong {
    XCTAssertEqualObjects(@"35:00:10", [OEXDateFormatting formatSecondsAsVideoLength:60 * 60 * 35 + 10]);
}

- (void)testValidDateString {
    NSDate* date = [OEXDateFormatting dateWithServerString:@"2014-11-06T20:16:45Z"];
    [NSTimeZone setDefaultTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    
    NSDateComponents* components = [[NSCalendar calendarWithIdentifier:NSGregorianCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitSecond fromDate:date];
    XCTAssertEqual(components.year, 2014);
    XCTAssertEqual(components.month, 11);
    XCTAssertEqual(components.day, 6);
    XCTAssertEqual(components.hour, 20);
    XCTAssertEqual(components.minute, 16);
    XCTAssertEqual(components.second, 45);
}

- (void)testNilDateString {
    XCTAssertNil([OEXDateFormatting dateWithServerString:nil]);
}

- (void)testGPlusDate {
    NSDate* date = [OEXDateFormatting dateWithGPlusBirthDate:@"1984-12-07"];
    NSDateComponents* components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
    XCTAssertEqual(components.year, 1984);
    XCTAssertEqual(components.month, 12);
    XCTAssertEqual(components.day, 7);
}

- (void)tearDown {
    [NSTimeZone setDefaultTimeZone:actualLocalTimeZone];
    [super tearDown];
}

@end
