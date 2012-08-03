#
# General helpers
#

# Require all files in a given subdirectory
def require_from_directory(directory)
  Dir[File.join(File.dirname(__FILE__), directory, '*')].each {|file| require file }
end

# Call this method like this:
# log.info(msg)
# log.warn(msg)
# log.error(msg)
def log
  env['rack.logger']
end
