(in /Users/pdcawley/Projects/ruby_announcements)
Gem::Specification.new do |s|
  s.name = %q{announcements}
  s.version = "0.0.1"

  s.specification_version = 2 if s.respond_to? :specification_version=

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Piers Cawley"]
  s.date = %q{2008-06-29}
  s.description = "Announcements is a ruby port of the VW smalltalk announcements framework"
  s.email = ["pdcawley@bofh.org.uk"]
  s.extra_rdoc_files = ["History.txt", "License.txt", "Manifest.txt", "PostInstall.txt", "README.txt"]
  s.files = ["History.txt", "License.txt", "Manifest.txt", "PostInstall.txt", "README.txt", "Rakefile", "config/hoe.rb", "config/requirements.rb", "lib/announcements.rb", "lib/announcements/announcement.rb", "lib/announcements/announcement_set.rb", "lib/announcements/announcer.rb", "lib/announcements/delivery_destination.rb", "lib/announcements/subscription.rb", "lib/announcements/subscription_collection.rb", "lib/announcements/subscription_registry.rb", "lib/announcements/support.rb", "lib/announcements/version.rb", "script/console", "script/destroy", "script/generate", "script/txt2html", "setup.rb", "spec/announcements/delivery_destination_spec.rb", "spec/announcements/subscription_collection_spec.rb", "spec/announcements/subscription_registry_spec.rb", "spec/announcements/subscription_spec.rb", "spec/announcements_spec.rb", "spec/spec.opts", "spec/spec_helper.rb", "tasks/deployment.rake", "tasks/environment.rake", "tasks/rspec.rake", "tasks/website.rake"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/pdcawley/announcemnts}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.1.1}
end
