# HTTP2 Investigation on Roku firmware 7.7

## Summary

I did an investigation into HTTP/2 support on Roku since it was added in firmware 7.6 under [ifUrlTransfer.SetHttpVersion()](https://sdkdocs.roku.com/display/sdkdoc/ifUrlTransfer#ifUrlTransfer-SetHttpVersion(versionasString)asVoid).


## Conclusion
In my results, it appears that not only does it not help but it makes our request times about 50% worse.  As a test I set up a loop to request all our categories (48) simultaneously and in batches of 5 and 10 at a time.  Test data is included [below](#data).

Without investigating further, I suspect that Roku already optimizes requests to the same host (connection reuse, SSL session reuse) which is why the HTTP/1.1 is already quite performant.  It could also be that HTTP2 has extra overhead to negotiate or Roku aren't implementing it well at the libcurl API.


## Data

Notes:

- test URLS were SSL requests to https://uapi.adrise.tv/cms/categories...
- 48 requests in total (current category count on Roku)
- measured on Roku Express 3710X
- no parsing of responses in order to measure just network time
- timings collected per batch followed by a total time for all requests to complete
- urls within a batch were sent simultaneously, all responses collected for a batch before starting the next batch

### non-batched (all requests simultaneous)

non-http2

	Finished  48 requests in  3160 ms
	Finished all requests in  3188 ms

http2

	Finished  48 requests in  4781 ms
	Finished all requests in  4809 ms

### batches of 10 requests

non-http2

	Finished  10 requests in  1063 ms
	Finished  10 requests in  604 ms
	Finished  10 requests in  658 ms
	Finished  10 requests in  509 ms
	Finished  8 requests in  467 ms
	Finished all requests in  3333 ms

http2

	Finished  10 requests in  1055 ms
	Finished  10 requests in  1209 ms
	Finished  10 requests in  1257 ms
	Finished  10 requests in  854 ms
	Finished  8 requests in  665 ms
	Finished all requests in  5071 ms


### batches of 5 requests

non-http2

	Finished  5 requests in  821 ms
	Finished  5 requests in  355 ms
	Finished  5 requests in  319 ms
	Finished  5 requests in  469 ms
	Finished  5 requests in  474 ms
	Finished  5 requests in  502 ms
	Finished  5 requests in  374 ms
	Finished  5 requests in  283 ms
	Finished  5 requests in  358 ms
	Finished  3 requests in  179 ms
	Finished all requests in  4168 ms

http2

	Finished  5 requests in  1069 ms
	Finished  5 requests in  782 ms
	Finished  5 requests in  558 ms
	Finished  5 requests in  931 ms
	Finished  5 requests in  1015 ms
	Finished  5 requests in  510 ms
	Finished  5 requests in  389 ms
	Finished  5 requests in  610 ms
	Finished  5 requests in  490 ms
	Finished  3 requests in  462 ms
	Finished all requests in  6848 ms


## Test code

See code in `src/experiments/TestHTTP2.brs` that was used to collect the above timings.
