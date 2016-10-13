require "gtk3"
require "#{Pathname.new( $0 ).realpath.dirname}/lib/oink.rb"
require "#{Pathname.new( $0 ).realpath.dirname}/lib/sswine.rb"

=begin
Gilt: a GTK3 GUI for Sswine.  
I'm doing this against my better judgement. I do not like GUIs, I believe they
are buggy, slow and, most importantly, inefficient. But I sort of have to get
used to designing them, so here we are.
=end

class Gilt < Gtk::Window
  @command # Currently selected Sswine command.
  @logs    # Logs modality, either on, off or gui.

  # Our logger: 
  include Oink

  # Constructor. It is supposed to initialize and show the GUI.
  def initialize
    super
    @logs = :gui
    oink_initialize

    # Quit icon:
    signal_connect "destroy" do
      Gtk.main_quit
    end

    # Window properties:
    set_title "Sswine"
    set_border_width 10
    set_default_size 585, 400
    set_window_position :center
    set_resizable false

    # Main grid container:
    grid = Gtk::Grid.new 
    grid.set_column_spacing 10
    grid.set_row_spacing 10
    grid.set_property "row-homogeneous", true
    grid.set_property "column-homogeneous", true

    # Header:
    header = Gtk::Label.new "Hover over a command to show what it does."
    grid.attach header, 0, 0, 3, 1

    # Sswine commands list:
    commands = Gtk::ComboBoxText.new
    # List of available commands, and the relative tooltips:
    commands_list = Array.new
    commands_list.push(
      :name => "check",
      :label => "Check for invalid Hams",
      :tooltip => "Check each folder within #{ENV["HOME"]}/.sswine for " +
                  "malformed entries."
    )
    commands_list.push(
      :name => "desktop",
      :label => "Create menu entries",
      :tooltip => "Add the Sswine menu folder and populates it with the " +
                  "relative entries."
    )
    commands_list.push(
      :name => "kill",
      :label =>"Kill all Hams",
      :tooltip => "Run `wineserver -k` for each Sswine managed entry, to " +
                  "ensure wine is not running."
    )
    commands_list.push(
      :name => "shell",
      :label => "Open a shell for a Ham",
      :tooltip => "I'll probably remove this one."
    )
    commands_list.push(
      :name => "update",
      :label => "Update all Hams",
      :tooltip => "Run `wineboot` for each Sswine managed entry, to ensure " +
                  "it is updated to work with the current wine version."
    )
    # Set the listener for the "changed" event:
    commands.signal_connect "changed" do
      @command = commands_list[commands.active][:name]
      commands.set_tooltip_text commands_list[commands.active][:tooltip]
    end
    # Add each entry of commands_list to command:
    commands_list.each do |entry|
      commands.append_text entry[:label]
    end

    # This is to make sure @command is never empty:
    commands.active = 0
    # Finally, attach it to the grid:
    grid.attach commands, 0, 1, 2, 1

    # Area where Sswine's output will be shown:
    output_scroller = Gtk::ScrolledWindow.new
    output_view = Gtk::TextView.new
    output_view.editable = false
    output_view.set_monospace  true
    output_scroller.add output_view
    grid.attach output_scroller, 0, 2, 3, 5

    # Execution button:
    execute = Gtk::Button.new :label => "Execute!"
    execute.signal_connect "clicked" do
      # On click, call the function which will handle the logic, and set the
      # resulting TextBuffer in use for our TextView:
      executeCommand
      output_view.set_buffer generateTextBuffer
    end
    grid.attach execute, 2, 1, 1, 1

    # Add the grid:
    add grid

    # Finally, show everything and start!
    show_all
    Gtk.main
  end

  # Private method. Generates and return a Gtk::TextBuffer from @logs_gui.
  private
  def generateTextBuffer
    # This will countain the TextBuffer to show:
    buffer = Gtk::TextBuffer.new

    # This is the list of tags to use, ideally one per color:
    tags = Hash.new
    @colors.each_key do |key|
      unless :default == key then
        tags["#{key}"] = buffer.create_tag "#{key}"
        tags["#{key}"].set_foreground "#{key}"
      end
    end

    # These will be the places where to apply each tag once the final buffer
    # text has been composed:
    tags_to_apply = Array.new

    # Now, for each entry of logs_gui....
    @logs_gui.each_with_index do |entry, idx|
      # First, let's handle the tag:
      # Be sure this is not a malformed tag due to some kind of error:
      if entry[:tag].key? :color and entry[:tag].key? :begin and 
         entry[:tag].key? :end then
        # Turn the relative :begin and :end informations into absolute ones
        # regarding the current buffer:
        tags_to_apply.push :begin => buffer.text.length + entry[:tag][:begin],
                           :end => buffer.text.length + entry[:tag][:end],
                           :tag => tags[entry[:tag][:color]]
      end

      # Text part: this is easy, simply append it.
      # NOTE: gotta add an extra "  " at the end of each line, plus a "\n"
      # at the end of the last line, to avoid some text being obscured by
      # the window scrollers in some GTK3 themes.
      buffer.text += entry[:text] + "  \n"
    end

    # Finally, apply each tag that we have processed!
    tags_to_apply.each do |tag|
      iter_begin = buffer.get_iter_at :offset => tag[:begin]
      iter_end = buffer.get_iter_at :offset => tag[:end]
      buffer.apply_tag tag[:tag], iter_begin, iter_end
    end

    return buffer
  end

  # Private method. Handles the logic of the "Execute!" button.
  private
  def executeCommand
    # This is to clear logs:
    logs_gui_clear

    # Later on, this will contain our Sswine instance:
    sswine = nil

    # Depending on the command, do the right thing:
    case @command
      when "check" then
        sswine = Sswine.new :logs => :gui

      when "desktop" then
        sswine = Sswine.new :logs => :gui
        sswine.writeMenuEntries

      when "kill" then
        sswine = Sswine.new
        sswine.killAllHams
        oink "All Hams have been killed."

      when "shell" then
        sswine = Sswine.new

        if sswine.invisible then
          oink "No Hams found. Nothing to do."

        else
          # I found no way to get the default terminal emulator in a distro
          # independant way, so this is the best I came up with.

          # 1. Put all the terminal emulators known to wikipedia into an 
          #    array.
          terminal_emulators = [
            "aterm",
            "eterm",
            "gnome-terminal",
            "konsole",
            "mrxvt",
            "terminator",
            "terminology",
            "rxvt",
            "rxvt-unicode",
            "wterm",
            "xfce4-terminal",
            "xterm"
          ]

          # 2. Check which one is installed:
          terminal_emulators.each do |term|
            # 3. If a terminal has been found, use it:
            unless `which #{term} 2> /dev/null`.empty? then
              `#{term} -e "#{$0} -s" &> /dev/null`
              oink "Used terminal emulator: #{`which #{term}`}"
              break
            end

            # 4. If no terminal has been found, return an error:
            oink "No terminal emulator found in the system's path.\n" +
                 "Please, install one of the following:\n" +
                 terminal_emulators.join( "\n" )
          end
        end

      when "update" then
        sswine = Sswine.new
        sswine.updateAllHams
        oink "All Hams have been updated."
    end

    # If Glit generated no logs, then it gotta be taken elsewhere:
    if logs_gui.empty? then
      # If even the Sswine instance contains no logs, then show a "no errors"
      # message:
      if sswine.nil? or sswine.logs_gui.empty? then
        oink "No errors occurred, everything is fine."

      # Else, appende the logs of our Sswine instance:
      else
        logs_gui_append sswine
      end
    end
  end

end

