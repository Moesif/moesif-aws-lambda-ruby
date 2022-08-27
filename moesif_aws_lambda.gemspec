Gem::Specification.new do |s|
  s.name = 'moesif_aws_lamda'
  s.version = '1.0.0'
  s.summary = 'moesif_aws_lambda'
  s.description = 'Moesif aws lambda middleware to log API calls to Moesif API analytics and monitoring'
  s.authors = ['Moesif, Inc', 'Xing Wang']
  s.email = 'xing@moesif.com'
  s.homepage = 'https://moesif.com'
  s.license = 'Apache-2.0'
  s.add_development_dependency('test-unit', '~> 3.5', '>= 3.5.0')
  s.add_dependency('moesif_api', '~> 1.2.14')
  s.required_ruby_version = '>= 2.5'
  s.files = Dir['{bin,lib,moesif_capture_outgoing,man,test,spec}/**/*', 'README*', 'LICENSE*']
  s.require_paths = ['lib']
  s.metadata = {
    "bug_tracker_uri"   => "https://github.com/Moesif/moesif-rack/issues",
    "changelog_uri"     => "https://github.com/Moesif/moesif-rack/releases",
    "documentation_uri" => "https://www.moesif.com/docs/server-integration/rack/",
    "homepage_uri"      => "https://www.moesif.com",
    "mailing_list_uri"  => "https://github.com/Moesif/moesif-rack",
    "source_code_uri"   => "https://github.com/Moesif/moesif-rack",
    "wiki_uri"          => "https://github.com/Moesif/moesif-rack"
  }

end