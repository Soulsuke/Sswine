require "pathname"
require "yaml"

=begin
Ham class.
A ham is a chunk of a swine. So, every sub-directory of .sswine is, by
definition a Ham.
=end

class Ham
  @ham_folder     # Folder of the Ham. Duh.
  @edible         # Set to true if the config file is ok, false otherwise.
  @config_global  # Global options for all entries (if not overridden).
  @config_entries # Entry-specific options, which override global ones.

  attr_accessor :ham_folder, :edible

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

          checked = checkEntry conf[key], key
          # checked will be nil if the configuration is invalid:
          unless checked.nil? then
            if "Global Values" == key then
              @config_global = checked

            else
              @config_entries[key] = checked
            end

          # Error message, in case:
          else
            puts "Invalid config entry: #{key}"
          end
        end

      # I'm forced to put this in, but it really won't do anything.
      rescue
        @edible = false
      end

      # If there are enough elements, go ahead:
      if 0 < @config_entries.size and 0 < @config_entries.size then
        # This is important: the Ham must contain the wine_env folder!
        if Pathname.new( "#{@ham_folder}/wine_env" ).directory? then
          @edible = true
        end
      end
    end
  end

  # Checks if the given entry is valid, and makes sure the Path and Icon 
  # keys will point to, respectively, an existing folder or file.
  # Returns a valid tweaked entry on success, nil otherwise.
  private
  def checkEntry( entry, key )
    # This will be the container of the return value:
    ret = entry

    # Some specific checks are required for Global Values:
    if "Global Values" == key then
      # Must contain: Type, Categories, Icon, Path
      unless entry.key? "Type" and entry.key? "Categories" and
             entry.key? "Icon" and entry.key? "Path" then
        ret = nil
      end
    end

    # Make sure the folder Path points to exists, and make it absolute:
    if entry.key? "Path" then
      complete_path = Pathname.new "#{@ham_folder}/wine_env/drive_c/" +
                                   "#{entry["Path"]}"
      if complete_path.directory? then
        entry["Path"] = complete_path.realpath

      else
        ret = nil
      end
    end

    # Make sure the file Icon points to exists, and make it absolute:
    if entry.key? "Icon" then
      complete_path = Pathname.new "#{@ham_folder}/icons/#{entry["Icon"]}"

      if complete_path.file? then
        entry["Icon"] = complete_path.realpath

      else
        ret = nil
      end   
    end

    return ret
  end

  # Sample method to create .desktop files: returns a hash containing the file
  # name as the key, and the file's content as its value.
  public
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
        # Add WINEPATH to the command:
        if "Exec" == key then
          new_entry_content += "#{key}=env WINEPATH=" +
                               "#{@ham_folder.realpath}/wine_env " +
                               "#{new_entry_hash[key]}\n"
        else
          new_entry_content += "#{key}=#{new_entry_hash[key]}\n"
        end
      end
      new_entry_content += " "

      desktop_entries[new_entry_name] = new_entry_content
    end

    return desktop_entries
  end

end

