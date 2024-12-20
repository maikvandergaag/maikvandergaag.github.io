source "https://rubygems.org"

gem "jekyll-remote-theme"
gem "github-pages", group: :jekyll_plugins
gem "jekyll-include-cache", group: :jekyll_plugins

group :jekyll_plugins do
  gem "jekyll-feed"
  gem "jekyll-redirect-from"
  gem "jekyll-target-blank"
end

platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end

gem "wdm", :platforms => [:mingw, :x64_mingw, :mswin]
gem "http_parser.rb", :platforms => [:jruby]
gem "webrick"
gem "open_uri_redirections"
gem "faraday-retry"