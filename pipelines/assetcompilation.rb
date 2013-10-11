require 'rake-pipeline-web-filters'

class AGsubFilter < Filter
  def initialize(*args, &block)
    @args, @block = args, block
    super() { |input| input }
  end

  def generate_output(inputs, output)
    inputs.each do |input|
      if @block
        content = input.read.gsub(*@args) do |match|
          @block.call match, *$~.captures
        end
        output.write content
      else
        output.write input.read.gsub(*@args)
      end
    end
  end
end


output "public"

class Rake::Pipeline::DSL::PipelineDSL
  def production?
    ENV['RAKEP_MODE'] == 'production'
  end

  def airbrake_api_key
    api_key = if ENV['RACK_ENV'] == 'production'
                '065fc39876e58a98d0059e488341161e'
              else
                'e1c9156a53c7a026a6875d8321c4d367'
              end
    "var AIRBRAKE_API_KEY = '#{api_key}';"
  end

  def airbrake_url
    if ENV['RACK_ENV'] == 'production'
      'http://errbiter.eu01.aws.af.cm'
    else
       'http://errbiter-test.eu01.aws.af.cm'
    end
  end
end

input "assets/javascripts" do
  match "app/**/*.js" do
    #uglify if production?
    concat "application.js"
  end

  match "vendor/**/*.js" do
    filter(AGsubFilter, 
           'airbrake_api_key_to_be_replaced_by_rake_pipeline',
           airbrake_api_key)
    filter(AGsubFilter, 
           'airbrake_url_to_be_replaced_by_rake_pipeline',
           airbrake_url)
    filter(AGsubFilter, 
           'environment_to_be_replaced_by_rake_pipeline',
           ENV['RACK_ENV'])

    concat %w[
      vendor/airbrake.notifier.min.js
      vendor/jquery-1.8.3.min.js
      vendor/jquery.backstretch.js
      vendor/bootstrap.min.js
      vendor/angular.min.js
      vendor/angular-resource.min.js
      vendor/angular-sanitize.min.js
    ], "application.js"
  end
end

input "assets/stylesheets" do
  match "**/*.sass" do
    sass
  end

  match "vendor/**/*.css" do
    concat %w[
      vendor/bootstrap.min.css
      vendor/bootstrap-responsive.min.css
      vendor/font-awesome.min.css
    ], "application.css"
  end

  match "**/*.css" do
    yui_css if production?
    concat "application.css"
  end
end

# Finally, we keep our static assets that don't need any processing
  # in a `static/` directory.
input "assets/static" do
  match "**/*" do
    # The block we pass to `concat` lets us adjust the output path
    # of any files it matches. Here we take each input and strip
    # off the `static/` prefix, so `app/static/index.html` ends up
    # in `public/index.html`.
    concat do |input|
      input.sub(/static\//, '')
    end
  end
end

