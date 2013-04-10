def get_environment
  raise RackEnvNotSet unless ENV['RACK_ENV']
  environment = ENV['RACK_ENV'].to_sym

  allowed_environments = [:development, :test, :production]
  if allowed_environments.include?(environment)
    environment
  else
    raise UnallowedEnvironmentException.new(ENV['RACK_ENV'], allowed_environments)
  end
end

class UnallowedEnvironmentError < StandardError
  def initialize(incorrent_environment, allowed_environments)
    @incorrent_environment = incorrent_environment
    @allowed_environments = allowed_environments
  end

  def message
    "The environment #{@incorrent_environment} is not allowed. Allowed"\
    "environments are #{@allowed_environments.join(', ')}."
  end
end

class RackEnvNotSet < StandardError
  def message
    "The environment variable RACK_ENV is not set."
  end
end

def production?
  if ENVIRONMENT == :production
    return true
  else
    return false
  end
end
