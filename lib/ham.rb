require "pathname"
require "yaml"

=begin
Ham class.  
A ham is a chunk of a swine. So, every sub-directory of .sswine is, by
definition a Ham. Edible hams are those which have a usable config file contain
a wine_env folder.
=end

class Ham
  @folder         # Folder of the Ham. Duh.
  @edible         # Set to true if the config file is ok, false otherwise.
  @config_global  # Global options for all entries (if not overridden).
  @config_entries # Entry-specific options, which override global ones.
  @logs           # Logs modality, either on, off or gui.
  @logs_gui       # Logs to be used by the GUI.

  # Folder of the Ham.
  attr_reader :folder

  # Set to true if the Ham is usable, false otherwise.
  attr_reader :edible

  # Logs to be used by the GUI.
  attr_reader :logs_gui

  # Constructor. To work properly, the following should be provided:
  # :path => path to the folder which should become a Ham.
  # :logs => on/off/gui, modality to use for logging.
  def initialize( options = {} )
    # Initialize instance variables:
    @folder = Pathname.new options[:path]
    @edible = true
    @config_global = Hash.new
    @config_entries = Hash.new
    @logs = "#{options[:logs]}".downcase
    @logs_gui = Array.new

    # If there's no wine_env folder, it's not edible.
    unless Pathname.new( "#{@folder}/wine_env" ).directory? then
      @edible = false
      if "on" == @logs then
        puts "\e[31m!!! Ignored:\e[0m #{@folder.basename}"
        puts " > Sub-folder wine_env not found."

      elsif "gui" == @logs then
        @logs_gui.push "!!! Ignored: #{@folder.basename}" 
        @logs_gui.push " > Sub-folder wine_env not found."
      end
    end

    # If there's no config file, it's not edible:
    config_file = Pathname.new "#{@folder}/config.yaml"

    unless !@edible or config_file.file? or config_file.readable? then
      @edible = false
      if "on" == @logs then
        puts "\e[31m!!! Ignored:\e[0m #{@folder.basename}"
        puts " > Config.yaml not found."

      elsif "gui" == @logs then
        @logs_gui.push "!!! Ignored: #{@folder.basename}"
        @logs_gui.push " > Config.yaml not found."
      end
    end

    # Now, if the Ham is stll edible, go ahead!
    if @edible then
      # To avoid odd crashes...
      begin
        # Attempt to parse the YAML file...
        conf = YAML.load_file config_file

        # First off, handle "Global Values" if present:
        if conf.key? "Global Values" then
          @config_global = checkEntry (conf.delete "Global Values"),
                           "Global Values"
        end

        # Now, handle entries:
        conf.each_key do |key|
          # checked will be empty if the entry is invalid, and checkEntry
          # already handles error messages.
          checked = checkEntry conf[key], key

          unless checked.empty? then
            @config_entries[key] = checked
          end
        end

      # I'm forced to put this in, but it really won't do anything.
      rescue
        @edible = false
      end

      # If there are no entries, it is not edible.
      if 0 == @config_entries.size then
        @edible = false
        if "on" == @logs then
          puts "\e[31m!!! Ignored:\e[0m #{@folder.basename}"
          puts " > Not enough entries in config.yaml."

        elsif "gui" == @logs then
          @logs_gui.push "!!! Ignored: #{@folder.basename}"
          @logs_gui.push " > Not enough entries in config.yaml."
        end
      end
    end
  end

  # Checks if the given entry is valid, and makes sure the Path and Icon 
  # keys will point to, respectively, an existing folder or file.
  # Returns a valid tweaked entry on success, or an empty one otherwise.
  private
  def checkEntry( entry, key )
    # This will be the container of the return value:
    ret = entry.sort.to_h

    # If this is not a "Global Values" entry, some checks must be performed:
    if "Global Values" != key then
      # First: there must be a "Path" key in either this entry or in
      # "Global Values".
      if entry["Path"].nil? and @config_global["Path"].nil? then
        ret = Hash.new

        # If we are supposed to log:
        if "on" == @logs then
          puts "\e[31m!!! Ignored entry of #{@folder.basename}:\e[0m " +
               "\"#{key}\""
          puts " > No valud value for \"Path\" key in neither \"#{key}\" " +
               "nor \"Global Values\"."

        elsif "gui" == @logs then
          @logs_gui.push "!!! Ignored entry of #{@folder.basename}:" +
                         " \"#{key}\""
          @logs_gui.push " > No valud value for \"Path\" key in neither " +
                         "\"#{key}\" nor \"Global Values\"."
        end

      # If we are supposed to log:
      elsif entry["Exec"].nil? then
        ret = Hash.new

        # If we are supposed to log:
        if "on" == @logs then
          puts "\e[31m!!! Ignored entry of #{@folder.basename}:\e[0m " +
               "\"#{key}\""
          puts " > No value for \"Exec\" key."

        elsif "gui" == @logs then
          @logs_gui.push "!!! Ignored entry of #{@folder.basename}:" +
                         " \"#{key}\""
          @logs_gui.push " > No value for \"Exec\" key."
        end

      # Last but not least: if there is no "Name" key, the desired .desktop
      # is used as the menu entry name.
      elsif entry["Name"].nil? then
        ret["Name"] = key
      end
    end

    # Make sure the folder Path points to exists, and make it absolute:
    if false == ret.nil? and entry.key? "Path" then
      complete_path = Pathname.new "#{@folder}/wine_env/drive_c/" +
                                   "#{entry["Path"]}"

      if complete_path.directory? then
        ret["Path"] = complete_path.realpath

      else
        ret = Hash.new

        # If we are supposed to log:
        if "on" == @logs then
          puts "\e[31m!!! Ignored entry of #{@folder.basename}:\e[0m " +
               "\"#{key}\""
          puts " > \"Path\" key points to a non existing location."

        elsif "gui" == @logs then
          @logs_gui.push "!!! Ignored entry of #{@folder.basename}:" +
                         " \"#{key}\""
          @logs_gui.push " > \"Path\" key points to a non existing location."
        end
      end
    end

    # Check if the icon is the one within @folder}/icons. If so, make its
    # path absolute, so it will not be shadowed by system ones with the same
    # name.
    if false == ret.nil? and entry.key? "Icon" then
      complete_path = Pathname.new "#{@folder}/icons/#{entry["Icon"]}"

      if complete_path.file? then
        ret["Icon"] = complete_path.realpath
      end   
    end

    return ret
  end

  # Returns a string containing the "env <variables>" command needed to run
  # wine binaries without issues, to avoid code duplication.
  private
  def getHamEnv
    # This will be the container of the return value:
    ret = "env "

    # If there is a custom_wine folder inside the Ham's directory which
    # contains a wine binary, it should be used instead of the system-wide
    # version (along with other wine binaries).
    custom_wine = Pathname.new "#{@folder.realpath}/custom_wine/" +
                               "bin/wine"

    # To do so, add custom_wine/bin to the PATH variable. Whatever happens
    # next is on the user who put the binaries there.
    if custom_wine.executable? and custom_wine.file? then
      ret += "PATH=#{custom_wine.dirname.realpath}:#{ENV["PATH"]} "
    end

    # Add the WINEPREFIX variable:
    ret += "WINEPREFIX=#{@folder.realpath}/wine_env"

    return ret
  end

  # Generates .desktop files for every entry in the config file (of course, 
  # except for Global Values), then returns a hash containing the file
  # name as the key, and the file's content as its value.
  public
  def getDesktopEntries
    # This will contain all the .desktop files to write for this Ham. 
    # The key will be the file name, and the value the contentit should have.
    desktop_entries = Hash.new

    # Process every config entry!
    @config_entries.each_key do |entry|
      # A temporary container for both global and entry-specific values:
      new_entry_hash = Hash.new

      # First add the global values:
      @config_global.each_key do |g|
        new_entry_hash[g] = @config_global[g]
      end

      # Then add the entry-specific values, so they will override the global
      # ones if needed:
      @config_entries[entry].each_key do |e|
        new_entry_hash[e] = @config_entries[entry][e]
      end

      # Sort it up!
      new_entry_hash = new_entry_hash.sort.to_h

      # Now, let's start putting stuff into desktop_entries!
      file_name = "#{entry}.desktop"
      desktop_entries[file_name] =  "[Desktop Entry]\n"

      new_entry_hash.each_key do |key|
        # Add WINEPREFIX to the command:
        if "Exec" == key then
          # Put in the right env for the Exec key:
          desktop_entries[file_name] += "#{key}=#{getHamEnv} " +
                                        "#{new_entry_hash[key]}\n"

        # Check if the icon is located in the icons sub-folder:
        elsif "Icon" == key then
          # It always starts like this:
          desktop_entries[file_name] += "#{key}="

          icon = Pathname.new "#{@folder.realpath}/icons/" +
                              "#{new_entry_hash[key]}"

          # If there's an icon sub-folder and the icon file is in there,
          # use it:
          if icon.file? then
            desktop_entries[file_name] += "#{icon.realpath}\n"

          # Else, try using a system-wide one:
          else
            desktop_entries[file_name] += "#{new_entry_hash[key]}\n"
          end

        # Every other option: it's ok as it is.
        else
          desktop_entries[file_name] += "#{key}=#{new_entry_hash[key]}\n"
        end
      end
    end

    return desktop_entries
  end

  # Opens a shell for this Ham in its wine_env/drive_c folder.
  public
  def openShell
    # Directory to start the shell in:
    Dir.chdir "#{@folder.realpath}/wine_env/drive_c"

    # Default shell for the current user:
    shell = `getent passwd #{ENV["USER"]}`.chomp.split( ":" ).pop

    # Run the shell!
    system "#{getHamEnv} #{shell}"
  end

  # Runs "wineserver -k" to kill any wine process for this Ham's wine bottle.
  public
  def killHam
    # Kill command:
    `#{getHamEnv} wineserver -k`
  end

  # Runs wineboot, to attempt to update this Ham's wine bottle without making
  # other changes.
  public
  def updateHam
    # Update command:
    `#{getHamEnv} wineboot`
  end
end

