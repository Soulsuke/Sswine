require "pathname"
require "yaml"

class Ham
  @ham_folder     # Folder of the Ham. Duh.
  @edible         # Set to true if the config file is ok, false otherwise.
  @config_global  # Global options for all entries (if not overridden).
  @config_entries # Entry-specific options, which override global ones.

  # Constructor: takes the path of the ham's folder as the only parameter.
  def initialize( path )
    # Initialize instance variables:
    @ham_folder = Pathname.new path
    @edible = false
    @config_global = Hash.new
    @config_entries = Hash.new

    # Edible is false by default, so we only have to look for the case where
    # everything is ok.
    
    # The config file is ok:
    config_file = Pathname.new "#{@ham_folder}/config.yaml"

    # Config file permissions:
    if config_file.file? and config_file.readable? then
      # To avoid an odd crash...
      begin
        # Attempt to parse the YAML file...
        conf = YAML.load_file config_file
        conf.each_key do |key|
          # Only add valid entries:
          checked = checkEntry conf[key]
          unless checked.nil? then
            if "Global Values" == key then
                @config_global = checked

            else
              @config_entries[key] = checked
            end
          end
        end

        # If there are enough elements, go ahead:
        if false == @config_global["Path"].empty? and 
           0 < @config_entries.size then
          @edible = true
        end

      # I'm forced to put this in, but it really won't do anything.
      rescue
        @edible = false
      end
    end
  end

  # Checks if an entry is valid, and tweaks Path, Icon and Exec fields to make
  # them work for the .desktop file.
  def checkEntry( entry )
    # TODO: WIP!!!!
    return entry
  end

  # Sample method to create .desktop files: returns a hash containing the file
  # name as the key, and the file's content as its value.
  def getDesktopEntries
    desktop_entries = Hash.new

    @config_entries.each_key do |entry|
      new_entry_hash = Hash.new

      # Add all the global options:
      @config_global.each_key do |g|
        new_entry_hash[g] = @config_global[g]
      end

      # Addthe entry's options:
      new_entry_hash["Name"] = entry
      @config_entries[entry].each_key do |ent|
        new_entry_hash[ent] = @config_entries[entry][ent]
      end

      new_entry_name = "#{new_entry_hash["Name"]}.desktop"
      new_entry_content = "[Desktop Entry]\n"

      new_entry_hash.each_key do |key|
        new_entry_content += "#{key}=#{new_entry_hash[key]}\n"
      end
      new_entry_content += " "

      desktop_entries[new_entry_name] = new_entry_content
    end

    # TODO: TEMPORARY, LOGGING PURPOUSES.
    puts ""
    desktop_entries.each_key do |k|
      puts "File: #{k}"
      puts "#{desktop_entries[k]}"
    end

    return desktop_entries
  end

end

