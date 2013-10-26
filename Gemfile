source 'https://rubygems.org'

as_version = ENV["ACTIVESUPPORT_VERSION"] || "default"

as = case as_version
        when "master"
          {:github => "rails/rails"}
        when "default"
          "~> 3.2.0"
        else
          "~> #{as_version}"
        end

gem "activesupport", as

# Specify your gem's dependencies in mongo_cache_store.gemspec
gemspec

