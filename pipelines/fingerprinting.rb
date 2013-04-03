require 'rake-pipeline-web-filters'

output "public"

input "public" do
  match "application.js" do
    filter Rake::Pipeline::Web::Filters::CacheBusterFilter
  end

  match "application.css" do
  	filter Rake::Pipeline::Web::Filters::CacheBusterFilter
  end
end