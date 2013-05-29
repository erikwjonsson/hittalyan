# Internet Explorer has joined forces with Ming,
# using evil caching strategies.
class DeathToMing
  def initialize(app)
    @app = app
  end

  def call(env)
    zap_ming!(env)
    @app.call(env)
  end

  private

  def zap_ming!(env)
    env['REQUEST_URI'] = env['REQUEST_URI'].gsub(/[?&]*ming.*mongo/, "")
    env['QUERY_STRING'] = env['QUERY_STRING'].gsub(/[?&]*ming.*mongo/, "")
  end

end