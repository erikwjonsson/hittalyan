require 'rake-pipeline-web-filters'

output "public"

class Rake::Pipeline::DSL::PipelineDSL
  def production?
    ENV['RAKEP_MODE'] == 'production'
  end
end

input "assets/javascripts" do
  match "app/**/*.js" do
    #uglify if production?
    concat "application.js"
  end

  match "vendor/**/*.js" do
    concat %w[
      vendor/jquery-1.8.3.min.js
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

