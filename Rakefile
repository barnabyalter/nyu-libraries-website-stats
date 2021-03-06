require File.join(File.dirname(__FILE__), 'lib', 'helper')
require 'nokogiri'
require 'yaml'

# Text files genereated with the following command, run on the server:
# =>  find $PWD -type f -mtime +365 -exec ls -lrt {} \;|awk '{printf "%s\t%s %s %s\n", $9, $8, $6, $7}'>lastmodified-servername.bobst.txt

config = YAML.load_file("config.yml")

# Default rake, run all
task :default => ["library_stats:lastmodifiedover1year", "library_stats:lasthitover1year", "library_stats:google_terms_to_csv", "library_stats:merge_library_servers"]

namespace :library_stats do
  
  # This task takes all files which haven't been modified in over a year
  # and format as  CSV file with the added file extension for sorting
  desc "Look through files last modified over a year ago and add file extension to CSV"
  task :lastmodifiedover1year do |task|
    servers = config["lastmodified"]["servers"] 
    servers.each do |server|
      files = []
      if File.exists? server['input_file']
        File.open(server['input_file']).each do |line|
          # Create array from each line, strip WS
          file_array = line.split("\t")
          file_array[0].strip!
          file_array[1].strip!
          # Get file extension
          extension = file_array[0].split(".").last.upcase
          # If the file has no extension the last part will be a path fragment, exclude this
          file_array.push(extension) unless extension.include? "/" 
          files.push(file_array)
        end
        # Create formatted output file from new array
        File.open(server['output_file'], "w") do |f|
          f.write "Filename, Date modified, File type\n"
          files.each do |file|
            file_ft = file[0].gsub("#{server['absolute_prefix']}",'')
            f.write "\"#{file_ft}\", #{file[1]}, #{file[2]}\n"
          end
        end
      end
    end
  end
  
  # This task compares all files on the server to those hit in the last year and returns a report of the difference
  # i.e. the pages that haven't been hit in over a year
  #
  # Last hit file generated by Urchin for all files hit in the last year
  # All-files file was generated by the following command to get all files on server and then run comparison:
  # => find $PWD -type f>allfiles-servername.bobst.txt
  desc "Find pages not hit in a year by comparing all files to those hit in the past year"
  task :lasthitover1year do |task|
    servers = config["lasthit"]["servers"] 

    servers.each do |server|
      if File.exists? server["input_lasthit"] and File.exists? server["input_allfiles"]
        # Create Ruby arrays from text files
        lasthit_array, allfiles_array = [], []
        File.open(server["input_lasthit"]).each { |line| lasthit_array.push(line.split("\t").first.strip) unless line.match(/^#/) }
        File.open(server["input_allfiles"]).each { |line| allfiles_array.push(line.strip.gsub(server["absolute_prefix"], "")) }
        # Add alias of files to
        apache_conf = Helper.hashify_apache_directives(server["apache_conf"]["absolute_prefix"], server["apache_conf"]["conf_file"], server["apache_conf"]["redirect_url_prefix"]) unless server["apache_conf"].nil?
        apache_conf.each do |conf|
          lasthit_array |= lasthit_array.map { |f| f.gsub(/^(\/)?#{conf["url_path"]}(\/)?$/,"#{conf['physical_path']}") }
        end unless apache_conf.nil?
        # Delete from array if file was hit in past year
        allfiles_array.delete_if { |f| lasthit_array.include? f }
        # Delete from array if file hit was root of directory, but allfiles file only contains physical files, i.e. index.*
        allfiles_array.delete_if { |f| lasthit_array.include? f.gsub(/index\.[\w\d]{2,4}/,"") }

        lasthit_over1year = allfiles_array
        File.open(server["output_file"], "w") do |f|
          f.write "Filename, File type\n"
          lasthit_over1year.each do |file|
            extension = file.split(".").last.upcase
            f.write "\"#{file}\", #{extension unless extension.include? "/"}\n"
          end
        end
      end
    end
  end
  
  # This task reads the raw XML stats from the google search and creates CSV
  desc "Format Google search terms into CSV"
  task :google_terms_to_csv do |task|
    files = config["googlesearch"]["files"]
    
    files.each do |fileset|
      File.open(fileset["output_file"], "w") do |f|
        f.write "Search type, Search term, Number of times searched\n"
        noresults_xml = Nokogiri::XML(File.open(fileset["input_file"]))
        noresults_xml.xpath("//summaryReport/topKeywords/topKeyword").each do |node|
          f.write "keyword, #{node['keyword']}, #{node.text}\n"
        end
        results_xml = Nokogiri::XML(File.open(fileset["input_file"]))
        results_xml.xpath("//summaryReport/topQueries/topQuery").each do |node|
          f.write "query, #{node['query']}, #{node.text}\n"
        end
      end
    end
    
  end
  
  desc "Merge the load balanced library servers reports into one"
  task :merge_library_servers do |task|
    files = config["merge_library_servers"]["files"]
        
    files.each do |file|
      merged = []
      file["merge_files"].each do |merge_file|
        array_file = []
        File.open(merge_file).each_line { |line| array_file.push(line) }
        merged |= array_file
      end
      File.open(file["output_file"], "w") do |f|
        merged.each do |line|
          f.write line
        end
      end
    end
  end
  
end

