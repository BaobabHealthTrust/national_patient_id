# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{national_patient_id}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Baobab Health"]
  s.date = %q{2012-08-01}
  s.description = %q{Generate nationally unique patient IDs}
  s.email = %q{developers@baobabhealth.org}
  s.extra_rdoc_files = ["LICENSE", "README.rdoc", "lib/national_patient_id.rb"]
  s.files = ["LICENSE", "README.rdoc",
             "lib/national_patient_id.rb",
             "test/test_national_patient_id.rb",
             "national_patient_id.gemspec"]
  s.homepage = %q{http://github.com/baobabhealthtrust/national_patient_id}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "National Patient ID",
                    "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  #s.rubyforge_project = %q{national_patient_id}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{National Unique Patient Identification}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
