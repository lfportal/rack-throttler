# Rack Throttler Middleware

`Rack::Throttler` is rack middleware that provides rate limiting for HTTP requests to rack applications.

## Prerequisite

Currently this middleware relies on Redis v2.6+ as it uses Lua scripts which were introduced in v2.6.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rack-throttler'
```

And then execute:

`$ bundle`

Or install it yourself as:

`$ gem install rack-throttler`

Tell your application to use the middleware.

For Rack applications:

```ruby
# config.ru
use Rack::Throttler
```

For Rails applications:

```ruby
# config/application.rb
config.middleware.use Rack::Throttler
```

## Configuration

To throttle a request, a throttling rule must be created. This rule is defined by a regexp pattern, a HTTP request method, a limit and a period (in seconds) for which the limit applies. Define these rules in an initializer.

The following rule limits GET requests to the root path to 10 requests every 60 seconds.

```ruby
Rack::Throttler.throttle(pattern: %r{^/$}, method: 'get', limit: 10, period: 60)
```

## How it works

When a request matches a defined throttling rule, it is tracked. If the client has passed the request limit of the rule (within the period), the request will be rejected. A response with status code `429` is returned to the client, along with a message describing how long the client should wait to retry the request:

```
Rate limit exceeded. Try again in 50 seconds.
```

### Caveat

Currently a request will only match one rule pattern (the first match). Throttling against multiple rules for a single request is not supported yet.

### Tracking Store

Currently the only store availble to use is Redis.

## Testing

To run the tests, Redis needs to be running locally.

Run the test suite by running:

`bundle exec rake`

## Contributing

Bug reports, feature requests and pull requests are welcome. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

