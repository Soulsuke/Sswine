require "fileutils"
require "pathname"
require "./lib/ham.rb"

=begin
Sswine stands for "Sswine: split wine", where wine stands for "wine is not (an)
emulator".  
This class is designed to handle Hams located in $HOME/.sswine. Each Ham must
be composed of:  
config.yaml:: Ham configuration file.  
wine_env:: Folder containing the wine bottle.  
Additionally, the following folders can also be present:  
icons:: Folder containing the Ham-specific icons.  
custom_wine:: Folder containing a Ham-specific version of wine to be used.  
=end

class Sswine
  @main_dir # Main Sswine directory, located in $HOME/.sswine.
  @hams     # Each Ham is a sub-directory of @main_dir.
  @verbose  # Verbose logs enabled/disabled.

  # Constructor: takes the verbosity (true/false) is needed as .
  def initialize( verbose )
    @main_dir = Pathname.new "#{ENV["HOME"]}/.sswine"
    @hams = Array.new
    @verbose = verbose

    # If the main folder does not exist, create it.
    unless @main_dir.directory? then
      if @main_dir.exist? then
        @main_dir.delete
      end

      @main_dir.mkpath

    # If it does, let's process the Hams!
    else
      # In alphabetical order.
      @main_dir.children.sort.each do |entry|
        pork = Ham.new entry, @verbose

        # No error message is printed here, because Ham's constructor already
        # does so.
        if pork.edible then
          @hams.push pork
        end
      end
    end
  end

  # Creates a menu folder for Sswine, and adds to it an entry for each valid
  # one of each Ham.
  public
  def writeMenuEntries
    # This is to make a decent log:
    created = Hash.new

    # Create a new folder for sswine's .desktop files (to both ensure it does
    # exist and to remove unnecessary .desktop files):
    desktop_files_folder = Pathname.new "#{ENV["HOME"]}/.local/share/" +
                                      "applications/sswine"
    if desktop_files_folder.exist? then
      FileUtils.rm_r desktop_files_folder
    end
    desktop_files_folder.mkpath


    # Ensure the folder file exists:
    folder_file = Pathname.new "#{ENV["HOME"]}/.local/share/" +
                               "desktop-directories/sswine.directory"
    folder_file.dirname.mkpath

    # Write the folder file:
    File.open folder_file, "w" do |f|
      f.puts "[Desktop Entry]"
      f.puts "Version=1.0"
      f.puts "Type=Directory"
      f.puts "Name=Sswine"
      f.puts "Icon=wine"
    end

    # Ensure the menu file exists:
    menu_file = Pathname.new "#{ENV["HOME"]}/.config/menus/" +
                             "applications-merged/sswine.menu"
    menu_file.dirname.mkpath

    # Write the first part of the menu file:
    File.open menu_file, "w" do |f|
      f.puts "<Menu>"
      f.puts "  <Name>Applications</Name>"
      f.puts "  <Menu>"
      f.puts "    <AppDir>#{desktop_files_folder.realpath}</AppDir>"
      f.puts "    <Name>Sswine</Name>"
      f.puts "    <Directory>#{folder_file.basename}</Directory>"
      f.puts "    <Include>"
    end

    # Now, process each Ham...
    @hams.each do |h|
      # Take note of what this Ham has created:
      created[h.ham_folder.basename] = Array.new

      # And each of its entries...
      h.getDesktopEntries.each do |key, entry|
        # Write the entry's .desktop file:
        File.open "#{desktop_files_folder.realpath}/#{key}", "w" do |f|
          f.puts entry
        end

        # Add it to Sswine's menu file:
        File.open menu_file, "a" do |f|
          f.puts "      <Filename>#{key}</Filename>"
        end

        # Take note of this for the log:
        created[h.ham_folder.basename].push key
      end
    end

    # Write the last part of the menu file:
    File.open menu_file, "a" do |f|
      f.puts "    </Include>"
      f.puts "  </Menu>"
      f.puts "</Menu>"
    end

    # If verbose, log what entries have been written:
    if true == @verbose then
      # Header:
      puts "Created entries in \e[33m#{desktop_files_folder.realpath}\e[0m " +
           "for:"

      created.each do |key, entries|
        # Show the Ham's name:
        puts " > \e[34m#{key}\e[0m"

        # Show what this Ham has generated:
        entries.each do |entry|
          puts "     #{entry}"
        end
      end
    end
  end

  # Terminates every Ham (alive or not).
  public
  def killAllHams
    @hams.each do |h|
      `env WINEPREFIX=#{h.ham_folder.realpath}/wine_env wineserver -k`
    end
  end

  # Attempts to update every Ham.
  public
  def updateAllHams
    @hams.each do |h|
      `env WINEPREFIX=#{h.ham_folder.realpath}/wine_env wineboot`
    end
  end

  # Prints a list of all the available hams, then makes the user chose one.
  # A shell will be opened in such Ham's directory, with the WINEPREFIX
  # varialbe correctly set. The shell to use will be the user's default one.
  public
  def openShell
    # This will store the user input:
    choice = -1

    unless @hams.size > 0 then
      puts "No Hams found. Nothing to do."

    else
      # It has to be user-interactive!
      while true do
        # Print the selection menu:
        puts "Edible hams:"
        @hams.each_with_index do |h, idx|
          puts "[#{idx + 1}] - #{h.ham_folder.basename}"
        end
        print "Choose one: "

        # Get the user input:
        choice = STDIN.gets.chomp.to_i - 1

        # Input error check:
        if @hams[choice].nil? or 0 > choice then
          puts "Invalid value. Please, try again."
          puts ""

        # Valid choice: out of the loop!
        else
          break
        end
      end

      # Open the desired shell!
      @hams[choice].openShell
    end
  end

end

