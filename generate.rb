#!/usr/bin/env ruby

require 'yaml'
require 'erb'
require 'ostruct'

# Semi-hack to pass the correct bindings to ERB
class ErbBinding < OpenStruct
    def get_binding
        return binding()
    end
end

# Load the resume YAML files
resume = YAML::load( File.open("resume.yaml") )

if ARGV.size < 1
  puts "usage: ./generate.rb <extension> [public]"
  puts "\n"
  puts "\t <extension> specifies the template, eg 'html' or 'tex'"
  puts "\t use option [public] for public-version, default is full resume"
  exit 0
end

# Figure out which template we're using
extension = ARGV[0].downcase
template_file = "templates/resume." + extension + ".erb"

# Does the template actually exist?
abort("Error: template #{template_file} doesn't exist!") unless File.exists?( template_file )

if ARGV[1] == "public"
  output_file = "output/resume-public." + extension
else
  output_file = "output/resume." + extension

  # Load and merge contact information (for full resume)
  # private.yml contains contact information I don't want posted
  private_yml = YAML::load( File.open("private.yaml") )
  resume["contact"] = resume["contact"].merge(private_yml["contact"])
end

# Load the escape function and run it on resume hash (if escape function exists)
escape_defn = File.join( File.dirname(__FILE__), 'templates', '/escape_' + extension + '.rb' )
require escape_defn if File.exists?(escape_defn)
escape(resume) if defined?(escape)

# Load the ERB template
template = ERB.new( File.new(template_file).read, 0, "<>" )

namespace = ErbBinding.new resume
result = template.result namespace.send(:get_binding)

# Create 'output' directory if it doesn't exist
Dir.mkdir("output") unless File.exists?("output") && File.directory?("output")

# Write to output file
File.open( output_file, "w" ) do |file|
  file.write result
end
puts "Created #{output_file}"
