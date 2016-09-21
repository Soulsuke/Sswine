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
  @main_dir          # Main sswine directory, located in $HOME/.sswine
  @desktop_files_dir # Directory containing the .desktop files of sswine.
  @hams              # Each ham is a sub-directory of @main_dir

  # Constructor: no parameters are needed.
  def initialize
    @main_dir = Pathname.new "#{ENV["HOME"]}/.sswine"
    @desktop_files_dir = Pathname.new "#{ENV["HOME"]}/.local/share/" +
                                      "applications/sswine"
    @hams = Array.new

    # Gotta ensure the folder which will contain the desktop files exist.
    unless @desktop_files_dir.directory? then
      if @desktop_files_dir.exist? then
        @desktop_files_dir.delete
      end

      @desktop_files_dir.mkpath
    end

    # If the main folder does not exist, create it.
    unless @main_dir.directory? then
      if @main_dir.exist? then
        @main_dir.delete
      end

      @main_dir.mkpath

    # If it does, let's process the Hams!
    else
      @main_dir.each_child do |entry|
        pork = Ham.new entry

        # No error message is printed here, because Ham's constructor already
        # does so.
        if pork.edible then
          @hams.push pork
        end
      end
    end
  end

  # Creates the desktop entries for every edible Ham.
  public
  def writeDesktopFiles
    # TODO: create directories.

    # Process each Ham...
    @hams.each do |h|
      # Write the files!
      h.getDesktopEntries.each do |key, entry|
        File.open "#{@desktop_files_dir.realpath}/#{key}", "w" do |f|
          f.puts entry
        end
        puts "Created: #{@desktop_files_dir.realpath}/#{key}"
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

