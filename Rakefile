desc "Clean the pipe, pour in those assets, then rack it up!"
task :serve do
  Rake::Task['assets:rebuild'].invoke
  exec('rackup')
end

namespace :assets do
  PUBLIC_PATH = File.expand_path(File.join(File.dirname(__FILE__), 'public/'))

  class PipelineError < StandardError
  end

  desc "Compile assets."
  task :precompile do
    pipelines = %w[assetcompilation.rb fingerprinting.rb viewcompilation.rb ]
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
  task :clean do
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
