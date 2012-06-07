class Helper
  # Create an array of hashes with data from the apache conf file
  def self.hashify_apache_directives(absolute_prefix = "/web/library.nyu.edu/htdocs", conf_file = "raw/vhosts-shared.conf", redirect_url_prefix = "library.nyu.edu")
    confs = []
    if File.exists? conf_file
      File.open(conf_file).each do |f|
        if f.strip!.match(/^(Redirect(Permanent|Temporary)?|Alias) /)
          conf_parts = f.split(" ")
          confs.push({
            :directive => conf_parts[0],
            :url_path => conf_parts[1],
            :physical_path => conf_parts[2].gsub("#{absolute_prefix}","").gsub("http://#{redirect_url_prefix}","")
          }) unless conf_parts[0].match(/redirect/i) and !conf_parts[2].match(redirect_url_prefix)
        end
      end
    end
    return confs
  end
end