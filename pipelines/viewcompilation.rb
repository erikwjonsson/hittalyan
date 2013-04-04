# encoding: utf-8
#
# Note that this pipeline is dependent on application*.js and application*.css
# being present in the output directory.
#

require 'tilt'


class HamlFilter < Rake::Pipeline::Filter
  def initialize(options={:format => :html5}, &block)
    block ||= proc { |input| input.sub(/\.haml$/, '.html') }
    super(&block)
    @options = options
  end

  def generate_output(inputs, output)
    inputs.each do |input|
      output.write(Tilt::HamlTemplate.new(@options) { input.read }.render)
    end
  end
end

output "public"

input "views/" do
  match "**/*.haml" do
    filter HamlFilter
  end
end