desc "Clean the pipe, pour in those assets, then rack it up!"
task :serve do
  Rake::Task['assets:rebuild'].invoke
  exec('rackup')
end

namespace :assets do
  PUBLIC_PATH = File.expand_path(File.join(File.dirname(__FILE__), 'public/'))

  desc "Compile assets."
  task :precompile do
    compile_assets = 'bundle exec rakep build --assetfile=pipelines/assetcompilation.rb'
    fingerprint_assets = 'bundle exec rakep build --assetfile=pipelines/fingerprinting.rb'
    system("#{compile_assets} && #{fingerprint_assets}")
    case $?.to_i
    when 0
      File.delete(File.join(PUBLIC_PATH, 'application.js'))
      File.delete(File.join(PUBLIC_PATH, 'application.css'))
      puts 'Assets compiled.'
    else
      puts "Error! Precompile was unsuccessful."  
    end
  end

  desc "Clean output directory (but only files passed through the pipeline)."
  task :clean do
    def application_css_files
      Dir["#{PUBLIC_PATH}/application*.css"]
    end

    def application_js_files
      Dir["#{PUBLIC_PATH}/application*.js"]
    end

    application_css_files.each {|f| File.delete(f)}
    application_js_files.each {|f| File.delete(f)}

    clean_output_dir = 'bundle exec rakep clean --assetfile=pipelines/assetcompilation.rb && bundle exec rakep clean --assetfile=pipelines/fingerprinting.rb'
    system(clean_output_dir)
    case $?.to_i
    when 0
      puts 'Asset directory cleaned.'
      files_in_dir_and_subdirs = Dir["#{PUBLIC_PATH}/**/*"].reject {|fn| File.directory?(fn) }
      if (files_in_dir_and_subdirs.length) > 0
        puts "Warning! After clean there are still files/directories remaining."
        puts "This is probably because files have been put in public/ manually."
        puts "Those files should be put in one of the subdirectories to asset/."
        puts "The asset pipeline will find and process the files. If no "
        puts "processing should be done the files should be put in the "
        puts "assets/static directory."
        puts
        puts "The remaining files are:"
        puts "#{files_in_dir_and_subdirs.join("\n")}"
      end
    else
      puts "Error! Precompile was unsuccessful."  
    end
  end

  desc "Clean and precompile."
  task :rebuild => [:clean, :precompile] do
  end
end
