require "pathname"
require "./lib/ham.rb"

=begin
Sswine class.
This handles many things.
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
        @hams.push Ham.new entry
      end
    end
  end

  # Creates the desktop entries for every edible Ham.
  public
  def writeDesktopEntries
    # Process each Ham...
    @hams.each do |h|
      # But ignore non-edible ones:
      unless h.edible then
        puts "Invalid Ham: #{h.ham_folder}"

      # Write the files!
      else
        h.getDesktopEntries.each do |key, entry|
          File.open "#{@desktop_files_dir.realpath}/#{key}", "w" do |f|
            f.puts entry
          end
        end
      end
    end
  end

  # Terminates every Ham (alive or not).
  public
  def killAllHams
    @hams.each do |h|
      `env WINEPATH=#{h.ham_folder.realpath}/wine_env wineserver -k`
    end
  end

end

