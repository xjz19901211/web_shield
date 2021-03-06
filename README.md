# WebShield

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'web_shield'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install web_shield

## Usage


```
config = WebShield::Config.new
config.store = WebShield::MemoryStore.new # or WebShield::RedisStore.new(redis: Redis.current)
config.user_parser = Proc.new {|request| request.params[:token] || request.ip }

config.build_shield("*", {
  whitelist: %w{127.0.0.1, 192.168.10.1/8},
  blacklist: %w{123.123.123.123 222.222.222.0/8}
}, WebShield::IPShield)
config.build_shield "/api/:ver/*", {period: 30, limit: 10}
```

More see `exmaples/*_config.rb`

### Config options

* `store`: 请求记录存储位置
* `logger`: Logger instance
* `user_parser`: 每个请求的限制都是按用户来的
* `blocked_response`: 当 block 时返回的内容
* `build_shield`: 构建防御，一个请求过来请会按构建的顺序去一一检查，如果有一个未通过，直接拒绝请求，如果指定了 dictatorial，当此 shield 被匹配时，如果通过则执行正常的业务，如果不通过则拒绝请求

### Build ThrottleShield options

* `period`: required, 配合 limit ，在此周期内，如果请求数达到 limit 定义的上限，则 block 此次请求
* `limit`: required, 周期内请求数上限
* `method`: optional, default: nil, 匹配 request method, 比如 'get', 'post' 等
* `dictatorial`: optional, default: false, 如果 request.path 与 rails_routes_matcher 匹配，那么无论是否有 block 此请求，都不再执行之后的 shields
* `path_sensitive`: optional, default: false, 针对每个 request.path 来设置防护，防止同一个 path 被刷

### Build IPShield optoins

* `whitelist`: optional, default []
* `blacklist`: optional, default []


## TODO

* RedisStore
* Optimize IPShield#ip_in_list?
* HoneypotShield: 
* Auto block request:

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/web_shield. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

