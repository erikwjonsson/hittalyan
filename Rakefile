require 'rake/testtask'
require 'fileutils'
require 'securerandom'

def strip_gemfile_of_development_gems(dir)
  gemfile_path = File.join(dir, "Gemfile")
  lines = File.readlines(gemfile_path)

  production_lines = lines.take_while {|line| !line.downcase.include?('--development gems--')}
  File.open(gemfile_path, 'w') do |file|
    file.write(production_lines.join(''))
  end

end

def set_up_deployment_directory
  # Fix for Gonza. Ugly, brutish and working.
  system('env RACK_ENV="production" bundle install')

  # Create deployment directory
  current_dir = File.expand_path(File.dirname(__FILE__), 'public/')
  deployment_directory_path = File.join(current_dir, "tmp/deploy-#{SecureRandom.hex}")
  puts "Will deploy from #{deployment_directory_path}"
  Dir.mkdir(deployment_directory_path)

  # Copy files to deployment directory
  directories_to_exclude = %w[tmp]
  files = Dir.glob('*') - directories_to_exclude
  FileUtils.cp_r(files, deployment_directory_path)

  # Fix Gemfile
  strip_gemfile_of_development_gems(deployment_directory_path)

  return deployment_directory_path
end

def in_a_deployment_directory
  deployment_directory_path = set_up_deployment_directory
  Dir.chdir deployment_directory_path do
    yield
  end
  FileUtils.rm_rf(deployment_directory_path)
end

def branch
  `git rev-parse --abbrev-ref HEAD`.chomp
end

def master?
  branch == "master"
end

def appfog_app_name
  if master?
    "hittalyan"
  else
    "cubancabal"
  end
end

Rake::TestTask.new do |t|
  t.pattern = "tests/*_test.rb"
end

desc "Clean the pipe, pour in those assets, then rack it up!"
task :serve do
  Rake::Task['assets:rebuild'].invoke
  exec('rackup -p 4856')
end

desc "Deploy to Appfog."
task :deploy do
  Rake::Task['assets:rebuild'].invoke

  in_a_deployment_directory do
    system('af login lingonberryprod@gmail.com')
    system("env RACK_ENV=\"production\" af update #{appfog_app_name}")
    system("af start #{appfog_app_name}")
    # Resetting Gemfile.lock. Messes up git otherwise.
    system('bundle install --quiet')
  end
end

task :bundle do
  system('pwd')
  puts "Bundling..."
  system('bundle install --quiet')
end

task :mail do
  require_relative 'init'

  users = []
  to = ENV['to']
  subject = ENV['subject']
  file = ENV['file']

  LOG.info "To: #{to}"
  LOG.info "Subject: #{subject}"
  LOG.info "Source File: #{file}"

  if to == :everyone
    users = User.all
  else
    users = [User.find_by(email: to)]
  end

  users.each do |user|
    @user = user
    LOG.info "Shooting mail to: #{user.email}"
    Manmailer.shoot_email(user,
                          subject,
                          render_mail(file, binding),
                          INFO_EMAIL,
                          INFO_NAME,
                          'html')
  end
end

namespace :assets do
  PUBLIC_PATH = File.expand_path(File.join(File.dirname(__FILE__), 'public/'))

  class PipelineError < StandardError
  end

  desc "Compile assets."
  task :precompile => [:bundle] do
    pipelines = %w[assetcompilation.rb fingerprinting.rb viewcompilation.rb]
    pipelines.each do |pipeline|
      puts "Running the #{pipeline.sub('.rb', '')} pipeline."
      system("bundle exec rakep build --assetfile=pipelines/#{pipeline}")
      raise PipelineError unless $?.to_i == 0
    end
    File.delete(File.join(PUBLIC_PATH, 'application.js'))
    File.delete(File.join(PUBLIC_PATH, 'application.css'))
    puts 'Assets and views compiled.'
  end

  desc "Clean output directory (but only files passed through the pipeline)."
  task :clean => [:bundle] do
    def application_css_files
      Dir["#{PUBLIC_PATH}/application*.css"]
    end

    def application_js_files
      Dir["#{PUBLIC_PATH}/application*.js"]
    end

    def remove_fingerprinted_files
      application_css_files.each {|f| File.delete(f)}
      application_js_files.each {|f| File.delete(f)}
    end

    def remove_empty_directories
      Dir.glob(PUBLIC_PATH + "/**/*").select do |d|
          File.directory?(d)
        end.reverse_each do |d|
          if (Dir.entries(d) - %w[ . .. ]).empty?
            Dir.rmdir(d)
          end
        end
    end

    pipelines = %w[viewcompilation.rb fingerprinting.rb assetcompilation.rb]
    pipelines.each do |pipeline|
      puts "Cleaning the #{pipeline.sub('.rb', '')} pipeline."
      system("bundle exec rakep clean --assetfile=pipelines/#{pipeline}")
      raise PipelineError unless $?.to_i == 0
    end
    remove_fingerprinted_files
    remove_empty_directories
    puts 'public/ directory cleaned.'

    files_in_dir_and_subdirs = Dir["#{PUBLIC_PATH}/**/*"].reject {|fn| File.directory?(fn) }
    if files_in_dir_and_subdirs.length > 0
      puts "Warning! After cleanup there are still files/directories remaining."
      puts "This is probably because files have been put in public/ manually."
      puts "Those files should be put in one of the subdirectories to asset/."
      puts "The asset pipeline will find and process the files. If no "
      puts "processing should be done the files should be put in the "
      puts "assets/static directory."
      puts
      puts "The remaining files are:"
      puts "#{files_in_dir_and_subdirs.join("\n")}"
    end
  end

  desc "Clean and precompile."
  task :rebuild => [:clean, :precompile] do
  end
end

namespace :db do
  desc 'Create database indexes.'
  task :create_indexes do
    require_relative 'init'
    mongoid_models = [Apartment, Filter, User, EmailHash]
    mongoid_models.each do |m|
      puts "Will create indexes specified in #{m.to_s.downcase}.rb."
      m.create_indexes
    end
    puts "Indexes created"
  end

  desc 'Backup all collections for database.'
  task :backup, [:db_env] do |t, args|
    collections = ['apartments', 'coupons', 'packages', 'payments', 'resets',
                   'sessions', 'users', 'email_hashes']
    databases = {test: {host: 'ds037647.mongolab.com:37647',
                        name: 'hittalyan-test'},
                 production: {host: 'ds047217.mongolab.com:47217',
                              name: 'hittalyan-production'}}
    database = databases[args.db_env.to_sym]
    time = Time.now.strftime("%Y%m%d%H%M")
    puts "Backing up \"#{database[:name]}\""
    collections.each do |collection|
      print "#{collection.capitalize}   \t"
      `mongoexport -h #{database[:host]} -d #{database[:name]} -c #{collection} -u af_cubancabal-lingonberryprod -p dpoqovae4grh52dr22fulu0569 -o backups/#{args.db_env}/#{time}/#{args.db_env}-#{time}-#{collection}.json`
    end
    puts ''
    puts 'Created these backups:'
    query = "backups/#{args.db_env}/#{time}/#{args.db_env}-#{time}-*.json"
    system("ls -1 #{query}")
  end
end
