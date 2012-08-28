#import "Kiwi.h"
#import "LSHTTPRequest.h"
#import "LSHTTPRequestDiff.h"
#import "LSStubRequest.h"

SPEC_BEGIN(LSHTTPRequestDiffSpec)
describe(@"diffing two LSHTTPRequests", ^{
    __block LSStubRequest *oneRequest = nil;
    __block LSStubRequest *anotherRequest = nil;
    __block LSHTTPRequestDiff *diff = nil;
    context(@"when both represent the same request", ^{
        beforeEach(^{
            NSString *urlString = @"http://www.google.com";
            oneRequest = [[LSStubRequest alloc] initWithMethod:@"GET" url:urlString];
            anotherRequest = [[LSStubRequest alloc] initWithMethod:@"GET" url:urlString];
            diff = [[LSHTTPRequestDiff alloc] initWithRequest:oneRequest andRequest:anotherRequest];
        });
        
        it(@"should result in an empty diff", ^{
            [[theValue(diff.isEmpty) should] beYes];
        });
        it(@"should an empty description", ^{
            [[[diff description] should] equal:@""];
        });
    });
    context(@"when the request differ in the method", ^{
        beforeEach(^{
            NSString *urlString = @"http://www.google.com";
            oneRequest = [[LSStubRequest alloc] initWithMethod:@"GET" url:urlString];
            anotherRequest = [[LSStubRequest alloc] initWithMethod:@"POST" url:urlString];
        });
        it(@"should not be empty", ^{
            diff = [[LSHTTPRequestDiff alloc] initWithRequest:oneRequest andRequest:anotherRequest];
            [[theValue(diff.isEmpty) should] beNo];
        });
        context(@"in one direction", ^{
            beforeEach(^{
                diff = [[LSHTTPRequestDiff alloc] initWithRequest:oneRequest andRequest:anotherRequest];
            });
            it(@"should have a description representing the diff", ^{
                NSString *expected = @"- Method: GET\n+ Method: POST\n";
                [[[diff description] should] equal:expected];
            });

        });
        context(@"in the other direction", ^{
            beforeEach(^{
                diff = [[LSHTTPRequestDiff alloc] initWithRequest:anotherRequest andRequest:oneRequest];
            });
            it(@"should have a description representing the diff", ^{
                NSString *expected = @"- Method: POST\n+ Method: GET\n";
                [[[diff description] should] equal:expected];
            });

        });
    });
    
    context(@"when the requests differ in the URL", ^{
        beforeEach(^{
            oneRequest = [[LSStubRequest alloc] initWithMethod:@"GET" url:@"http://www.google.com"];
            anotherRequest = [[LSStubRequest alloc] initWithMethod:@"GET" url:@"http://www.luissolano.com"];
        });
        it(@"should not be empty", ^{
            diff = [[LSHTTPRequestDiff alloc] initWithRequest:oneRequest andRequest:anotherRequest];
            [[theValue(diff.isEmpty) should] beNo];
        });
        context(@"in one direction", ^{
            beforeEach(^{
                diff = [[LSHTTPRequestDiff alloc] initWithRequest:oneRequest andRequest:anotherRequest];
            });
            it(@"should have a description representing the diff", ^{
                NSString *expected = @"- URL: http://www.google.com\n+ URL: http://www.luissolano.com\n";
                [[[diff description] should] equal:expected];
            });
        });
        context(@"in the other direction", ^{
            beforeEach(^{
                diff = [[LSHTTPRequestDiff alloc] initWithRequest:anotherRequest andRequest:oneRequest];
            });
            it(@"should have a description representing the diff", ^{
                NSString *expected = @"- URL: http://www.luissolano.com\n+ URL: http://www.google.com\n";
                [[[diff description] should] equal:expected];
            });
        });
    });
    context(@"when the request differ in one header", ^{
        beforeEach(^{
            oneRequest = [[LSStubRequest alloc] initWithMethod:@"GET" url:@"http://www.google.com"];
            [oneRequest setHeader:@"Content-Type" value:@"application/json"];
            anotherRequest = [[LSStubRequest alloc] initWithMethod:@"GET" url:@"http://www.google.com"];
        });
        it(@"should not be empty", ^{
            diff = [[LSHTTPRequestDiff alloc] initWithRequest:oneRequest andRequest:anotherRequest];
            [[theValue(diff.isEmpty) should] beNo];
        });
        context(@"in one direction", ^{
            beforeEach(^{
                diff = [[LSHTTPRequestDiff alloc] initWithRequest:oneRequest andRequest:anotherRequest];
            });
            it(@"should have a description representing the diff", ^{
                NSString *expected = @"Headers:\n-\t\"Content-Type\": \"application/json\"\n";
                [[[diff description] should] equal:expected];
            });

        });
        context(@"in the other direction", ^{
            beforeEach(^{
                diff = [[LSHTTPRequestDiff alloc] initWithRequest:anotherRequest andRequest:oneRequest];
            });
            it(@"should have a description representing the diff", ^{
                NSString *expected = @"Headers:\n+\t\"Content-Type\": \"application/json\"\n";
                [[[diff description] should] equal:expected];
            });

        });

    });
    
    context(@"when the request differ in one header each", ^{
        beforeEach(^{
            oneRequest = [[LSStubRequest alloc] initWithMethod:@"GET" url:@"http://www.google.com"];
            [oneRequest setHeader:@"Content-Type" value:@"application/json"];
            anotherRequest = [[LSStubRequest alloc] initWithMethod:@"GET" url:@"http://www.google.com"];
            [anotherRequest setHeader:@"Accept" value:@"text/plain"];
        });
        it(@"should not be empty", ^{
            diff = [[LSHTTPRequestDiff alloc] initWithRequest:oneRequest andRequest:anotherRequest];
            [[theValue(diff.isEmpty) should] beNo];
        });
        context(@"in one direction", ^{
            beforeEach(^{
                diff = [[LSHTTPRequestDiff alloc] initWithRequest:oneRequest andRequest:anotherRequest];
            });
            it(@"should have a description representing the diff", ^{
                NSString *expected = @"Headers:\n-\t\"Content-Type\": \"application/json\"\n+\t\"Accept\": \"text/plain\"\n";
                [[[diff description] should] equal:expected];
            });
        });
        context(@"in the other direction", ^{
            beforeEach(^{
                diff = [[LSHTTPRequestDiff alloc] initWithRequest:anotherRequest andRequest:oneRequest];
            });
            it(@"should have a description representing the diff", ^{
                NSString *expected = @"Headers:\n-\t\"Accept\": \"text/plain\"\n+\t\"Content-Type\": \"application/json\"\n";
                [[[diff description] should] equal:expected];
            });

        });
    });
    context(@"when the requests differ in the body", ^{
        beforeEach(^{
            oneRequest = [[LSStubRequest alloc] initWithMethod:@"GET" url:@"http://www.google.com"];
            oneRequest.body = [@"this is a body" dataUsingEncoding:NSUTF8StringEncoding];
            anotherRequest = [[LSStubRequest alloc] initWithMethod:@"GET" url:@"http://www.google.com"];
        });
        it(@"should not be empty", ^{
            diff = [[LSHTTPRequestDiff alloc] initWithRequest:oneRequest andRequest:anotherRequest];
            [[theValue(diff.isEmpty) should] beNo];
        });
        context(@"in one direction", ^{
            beforeEach(^{
                diff = [[LSHTTPRequestDiff alloc] initWithRequest:oneRequest andRequest:anotherRequest];
            });
            it(@"should have a description representing the diff", ^{
                NSString *expected = @"- Body: \"this is a body\"\n";
                [[[diff description] should] equal:expected];
            });
        });
        context(@"in the other direction", ^{
            beforeEach(^{
                diff = [[LSHTTPRequestDiff alloc] initWithRequest:anotherRequest andRequest:oneRequest];
            });
            it(@"should have a description representing the diff", ^{
                NSString *expected = @"+ Body: \"this is a body\"\n";

                [[[diff description] should] equal:expected];
            });

        });
    });
    context(@"when the requests differ in the Method and the URL", ^{
        beforeEach(^{
            oneRequest = [[LSStubRequest alloc] initWithMethod:@"GET" url:@"http://www.google.com"];
            anotherRequest = [[LSStubRequest alloc] initWithMethod:@"PUT" url:@"http://www.luissolano.com"];
        });
    });
});
SPEC_END