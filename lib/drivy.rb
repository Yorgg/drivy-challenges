require "json"

module Drivy
  VERSION = '0.0.1'
end


file_loader = Object.new
class << file_loader 
  DIRECTORIES = %w(builders models reporter)

  def load_all
    DIRECTORIES.each do |dir| 
      abs_path = File.expand_path("#{dir}/*.rb", __dir__) 
      Dir[abs_path].each { |file| require file }
    end
  end
end

file_loader.load_all


