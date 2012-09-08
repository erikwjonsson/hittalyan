#encoding: utf-8
require 'cuba'
# require 'rack/protection'
# require 'mongoid'
# require 'rack/logger'
require 'haml'
require 'cuba/render'
# require 'securerandom'

Cuba.plugin Cuba::Render

# require_relative 'helpers'
# require_from_directory 'extensions'
# require_from_directory 'models'

# Mongoid.load!('mongoid.yml')


# Cuba.use Rack::Session::Cookie
# Cuba.use Rack::Protection
# Cuba.use Rack::Protection::RemoteReferrer
# Cuba.use Rack::Logger

def render_haml(view, content)
  res.write render(File.join('views', "#{view}.haml"), content: content)
end

Cuba.define do

  #GET-----------------------------------------
  on get do
    on "medlemssidor" do
      on "filtersettings" do
        render_haml "filtersettings", ""
      end
      #res.write "Hej #{user.name}. Ditt sessionsid är: #{req.session[:sid]}"
      render_haml "medlemssidor"
    end
    
    on ":catchall" do
      res.write "Nu kom du allt fel din jävel!"
    end
  end
  
  #POST----------------------------------------
  on post do
	
  end
  
end