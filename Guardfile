# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'bundler' do
  watch('Gemfile')
  # Uncomment next line if Gemfile contain `gemspec' command
  # watch(/^.+\.gemspec/)
end

#guard 'rails' do
#  watch('Gemfile.lock')
#  watch(%r{^(config|lib)/.*})
#end


guard :rspec, cmd: 'bin/zeus rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }

  # Rails example
  watch(%r{^app/(.+)\.rb$})                           { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^app/(.*)(\.erb|\.haml)$})                 { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
  watch(%r{^app/controllers/(.+)_(controller)\.rb$})  { |m| [
    "spec/routing/#{m[1]}_routing_spec.rb", 
    "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", 
    "spec/acceptance/#{m[1]}_spec.rb",
    "spec/requests/#{m[1]}_spec.rb"
  ] }
  watch(%r{^spec/support/(.+)\.rb$})                  { "spec" }
  watch('config/routes.rb')                           { "spec/routing" }
  watch('app/controllers/application_controller.rb')  { "spec/controllers" }

  # Capybara features specs
  watch(%r{^app/views/(.+)/.*\.(erb|haml)$})          { |m| "spec/features/#{m[1]}_spec.rb" }

  # Turnip features and steps
  watch(%r{^spec/acceptance/(.+)\.feature$})
  watch(%r{^spec/acceptance/steps/(.+)_steps\.rb$})   { |m| Dir[File.join("**/#{m[1]}.feature")][0] || 'spec/acceptance' }
end


guard 'zeus', cli: '> /dev/null' do
  #require 'ostruct'

  #rspec = OpenStruct.new
  #rspec.spec_dir = 'spec'
  #rspec.spec = ->(m) { "#{rspec.spec_dir}/#{m}_spec.rb" }
  #rspec.spec_helper = "#{rspec.spec_dir}/spec_helper.rb"

  ## matchers
  #rspec.spec_files = /^#{rspec.spec_dir}\/.+_spec\.rb$/

  ## Ruby apps
  #ruby = OpenStruct.new
  #ruby.lib_files = /^(lib\/.+)\.rb$/

  #watch(rspec.spec_files)
  #watch(rspec.spec_helper) { rspec.spec_dir }
  #watch(ruby.lib_files) { |m| rspec.spec.call(m[1]) }

  ## Rails example
  #rails = OpenStruct.new
  #rails.app_files = /^app\/(.+)\.rb$/
  #rails.views_n_layouts = /^app\/(.+(?:\.erb|\.haml|\.slim))$/
  #rails.controllers = %r{^app/controllers/(.+)_controller\.rb$}

  #watch(rails.app_files) { |m| rspec.spec.call(m[1]) }
  #watch(rails.views_n_layouts) { |m| rspec.spec.call(m[1]) }
  #watch(rails.controllers) do |m|
  #  [
  #    rspec.spec.call("routing/#{m[1]}_routing"),
  #    rspec.spec.call("controllers/#{m[1]}_controller"),
  #    rspec.spec.call("acceptance/#{m[1]}")
  #  ]
  #end

  # TestUnit
  # watch(%r|^test/(.*)_test\.rb$|)
  # watch(%r|^lib/(.*)([^/]+)\.rb$|)     { |m| "test/#{m[1]}test_#{m[2]}.rb" }
  # watch(%r|^test/test_helper\.rb$|)    { "test" }
  # watch(%r|^app/controllers/(.*)\.rb$|) { |m| "test/functional/#{m[1]}_test.rb" }
  # watch(%r|^app/models/(.*)\.rb$|)      { |m| "test/unit/#{m[1]}_test.rb" }
end
