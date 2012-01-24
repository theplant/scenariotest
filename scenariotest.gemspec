# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name     = "scenariotest"
  s.version  = "0.1.1"
  s.date     = "2010-05-07"

  s.authors = ["Felix Sun"]
  s.email   = %q{felix@theplant.jp}

  s.homepage    = %q{http://github.com/theplant/senariotest}
  s.summary     = %q{Senario Test}
  s.description = %q{Senario Test}

  s.files         = Dir["{app,lib,public,config}/**/*"] + %w{LICENSE README.rdoc}
  s.require_path = "lib"

  s.required_ruby_version = ">= 1.8.7"

  s.extra_rdoc_files = ["README.rdoc"]

end
