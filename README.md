This is a demo app for https://github.com/newrelic/rpm/pull/302

# Instructions

You will need to configure Newrelic to report to your own application. Once that is done if you run bundle exec rails server and visit http://localhost:3000/demo you should see text that looks like JSON slowly appear in chunks over ~10 seconds. If you look at your Newrelic trace you will not see any calls to expensive_method_call.

Stop rails and restart it with NEWRELIC_PATCH=true bundle exec rails server. When you reload the page you will still see it appear in chunks. When you look at your Newrelic trace you will now see a segment for body_each and inside that you will see 100 calls to expensive_method_call. Moreover, the Newrelic trace will show a time of ~10 seconds whereas before it showed a time of <10 ms.