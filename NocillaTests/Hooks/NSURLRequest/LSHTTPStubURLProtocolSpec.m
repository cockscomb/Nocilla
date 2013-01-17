#import "Kiwi.h"
#import "LSHTTPStubURLProtocol.h"
#import "LSStubRequest.h"
#import "LSStubResponse.h"
#import "LSNocilla.h"

@interface NSHTTPURLResponse(UndocumentedInitializer)
- (id)initWithURL:(NSURL*)URL statusCode:(NSInteger)statusCode headerFields:(NSDictionary*)headerFields requestTime:(double)requestTime;
@end

@interface LSTestingNSURLProtocolClient : NSObject <NSURLProtocolClient>
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) NSData *body;
@end

@implementation LSTestingNSURLProtocolClient
- (void)URLProtocol:(NSURLProtocol *)protocol wasRedirectedToRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
    
}
- (void)URLProtocol:(NSURLProtocol *)protocol cachedResponseIsValid:(NSCachedURLResponse *)cachedResponse {
    
}
- (void)URLProtocol:(NSURLProtocol *)protocol didReceiveResponse:(NSURLResponse *)response cacheStoragePolicy:(NSURLCacheStoragePolicy)policy {
    self.response = response;
}
- (void)URLProtocol:(NSURLProtocol *)protocol didLoadData:(NSData *)data {
    self.body = data;
    
}
- (void)URLProtocolDidFinishLoading:(NSURLProtocol *)protocol {
    
}
- (void)URLProtocol:(NSURLProtocol *)protocol didFailWithError:(NSError *)error {
    
}
- (void)URLProtocol:(NSURLProtocol *)protocol didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
}
- (void)URLProtocol:(NSURLProtocol *)protocol didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
}


@end
SPEC_BEGIN(LSHTTPStubURLProtocolSpec)

describe(@"+canInitWithRequest", ^{
    context(@"when it is a HTTP request", ^{
        it(@"should return YES", ^{
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.example.com/dogs.json"]];
            
            BOOL result = [LSHTTPStubURLProtocol canInitWithRequest:request];
            
            [[theValue(result) should] beYes];
        });
    });
    context(@"when it is a HTTP request", ^{
        it(@"should return YES", ^{
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.example.com/cats.xml"]];
            
            BOOL result = [LSHTTPStubURLProtocol canInitWithRequest:request];
            
            [[theValue(result) should] beYes];
        });
    });
    
    context(@"when it is an FTP request", ^{
        it(@"should return NO", ^{
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"ftp://ftp.example.com/"]];
            
            BOOL result = [LSHTTPStubURLProtocol canInitWithRequest:request];
            
            [[theValue(result) should] beNo];
        });
    });
});

describe(@"#startLoading", ^{
    context(@"when the protocol receives a request", ^{
        __block NSString *stringUrl = nil;
        __block NSString *bodyString = nil;
        __block LSHTTPStubURLProtocol *protocol = nil;
        __block LSTestingNSURLProtocolClient *client = nil;
        beforeEach(^{
            stringUrl = @"http://api.example.com/dogs.xml";
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:stringUrl]];
            
            client = [[LSTestingNSURLProtocolClient alloc] init];
                        
            protocol = [[LSHTTPStubURLProtocol alloc] initWithRequest:request cachedResponse:nil client:client]; 
        });
        context(@"that matches an stubbed request", ^{
            beforeEach(^{
                LSStubRequest *stubRequest = [[LSStubRequest alloc] initWithMethod:@"GET" url:stringUrl];
                LSStubResponse *stubResponse = [[LSStubResponse alloc] initWithStatusCode:403];
                [stubResponse setHeader:@"Content-Type" value:@"application/xml"];
                bodyString = @"<error>Error</error>" ;
                stubResponse.body = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
                stubRequest.response = stubResponse;
                
                [[LSNocilla sharedInstance] stub:@selector(stubbedRequests) andReturn:@[stubRequest]];
            });
            
            it(@"should pass to the client the correct response", ^{
                [[client should] receive:@selector(URLProtocol:didReceiveResponse:cacheStoragePolicy:) withArguments:protocol, any(), theValue(NSURLCacheStorageNotAllowed)];
                
                [protocol startLoading];
                
                [[client.response should] beKindOfClass:[NSHTTPURLResponse class]];
                NSHTTPURLResponse *response = (NSHTTPURLResponse *)client.response;
                [[response.URL should] equal:[NSURL URLWithString:stringUrl]];
                [[theValue(response.statusCode) should] equal:theValue(403)];
                [[response.allHeaderFields should] equal:@{ @"Content-Type": @"application/xml"}];
            });
            it(@"should pass the body to the client", ^{
                
                [[client should] receive:@selector(URLProtocol:didLoadData:) withArguments:protocol, [bodyString dataUsingEncoding:NSUTF8StringEncoding]];
                
                [protocol startLoading];
                
            });
            
            it(@"should notify the client that it finished loading", ^{
                [[client should] receive:@selector(URLProtocolDidFinishLoading:)];
                
                [protocol startLoading];
                
            });
        });
        context(@"that doesn't match any stubbed request", ^{
            it(@"should pass to the client a 500", ^{
                [[client should] receive:@selector(URLProtocol:didReceiveResponse:cacheStoragePolicy:) withArguments:protocol, any(), theValue(NSURLCacheStorageNotAllowed)];
                
                [protocol startLoading];
                
                [[client.response should] beKindOfClass:[NSHTTPURLResponse class]];
                NSHTTPURLResponse *response = (NSHTTPURLResponse *)client.response;
                [[response.URL should] equal:[NSURL URLWithString:stringUrl]];
                [[theValue(response.statusCode) should] equal:theValue(500)];
                [[response.allHeaderFields should] equal:@{ @"X-Nocilla": @"Unexpected Request"}];
            });
            it(@"should pass the body to the client with a meaninful message", ^{
                NSString *expectedMessage = @"An unexcepted HTTP request was fired.\n\nUse this snippet to stub the request:\nstubRequest(@\"GET\", @\"http://api.example.com/dogs.xml\");\n";
                [[client should] receive:@selector(URLProtocol:didLoadData:) withArguments:protocol, [expectedMessage dataUsingEncoding:NSUTF8StringEncoding]];
                
                [protocol startLoading];
                
            });
            
            it(@"should notify the client that it finished loading", ^{
                [[client should] receive:@selector(URLProtocolDidFinishLoading:)];
                
                [protocol startLoading];
                
            });
        });
    });

    context(@"when the protocol response have a cookie", ^{
        
        __block NSString *stringUrl;
        __block LSHTTPStubURLProtocol *protocol = nil;
        __block LSTestingNSURLProtocolClient *client = nil;
        
        beforeEach(^{
            
            stringUrl = @"http://www.example.com/path";
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:stringUrl]];
            
            client = [[LSTestingNSURLProtocolClient alloc] init];
            
            protocol = [[LSHTTPStubURLProtocol alloc] initWithRequest:request cachedResponse:nil client:client];
        });
        
        context(@"that matches the stubbed pair", ^{
            
            __block NSString *cookieName;
            __block NSString *cookieValue;
            
            __block NSHTTPCookieAcceptPolicy previousPolicy;
            
            beforeEach(^{
                
                NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
                previousPolicy = [cookieStorage cookieAcceptPolicy];
                [cookieStorage setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain];
                
                cookieName = @"SESSIONID";
                cookieValue = [[NSProcessInfo processInfo] globallyUniqueString];
                
                LSStubRequest *stubRequest = [[LSStubRequest alloc] initWithMethod:@"GET" url:stringUrl];
                LSStubResponse *stubResponse = [[LSStubResponse alloc] initWithStatusCode:200];
                [stubResponse setHeader:@"Content-Type" value:@"text/html"];
                
                NSString *cookie = [NSString stringWithFormat:@"%@=%@;", cookieName, cookieValue];
                [stubResponse setHeader:@"Set-Cookie" value:cookie];
                stubRequest.response = stubResponse;
                
                [[LSNocilla sharedInstance] stub:@selector(stubbedRequests) andReturn:@[stubRequest]];
            });
            
            afterEach(^{
                [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:previousPolicy];
            });
            
            it(@"should be found the cookie", ^{
                [protocol startLoading];
                
                NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
                
                NSArray *cookies = [cookieStorage cookiesForURL:[NSURL URLWithString:stringUrl]];
                BOOL cookieFound = NO;
                for (NSHTTPCookie *cookie in cookies) {
                    if ([cookie.name isEqualToString:cookieName]) {
                        cookieFound = YES;
                        [[cookie.value should] equal:cookieValue];
                    }
                }
                [[theValue(cookieFound) should] equal:theValue(YES)];
            });
        });
    });
});

SPEC_END