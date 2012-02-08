# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '1.3.5'

  s.platform = Gem::Platform::RUBY

  s.name     = "scenariotest"
  s.version  = "0.1.0"
  s.date     = "2012-02-07"

  s.authors = ["Felix Sun"]
  s.email   = %q{felix@theplant.jp}

  s.homepage    = %q{http://github.com/theplant/senariotest}
  s.summary     = %q{Senario Test}
  s.description = %q{Senario Test}

  s.files         = Dir["{app,lib,public,config}/**/*"] + %w{LICENSE README.markdown}
  s.require_path = "lib"

  s.required_ruby_version = ">= 1.8.7"

  s.extra_rdoc_files = ["README.markdown"]

  s.test_files = s.files.select { |path| path =~ /^test\/test_.*\.rb/ }
  # = MANIFEST =
  s.files = %w[
    LICENSE
    README.markdown
    Rakefile
    lib/scenariotest.rb
    lib/scenariotest/driver.rb
    lib/scenariotest/log_subscriber.rb
    scenariotest.gemspec
  ]
  # = MANIFEST =

end
