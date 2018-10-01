## Development

### Publishing as Ruby Gem

```bash
# [increment gem VERSION]
gem build live_record.gemspec
gem push live_record-X.X.X.gem
```

### Publishing as Node Module

```bash
# [increment gem VERSION]
bundle exec blade build
# see .blade.yml: which will sprockets-compile app/assets/javascripts/live_record.coffee into lib/assets/compile/live_record.js
npm publish --access=public
```

## Test

```bash
bundle exec rspec
```
