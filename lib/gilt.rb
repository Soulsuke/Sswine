require "gtk3"
require "./lib/sswine.rb"

=begin
Gilt: a GTK3 GUI for Sswine.
I'm doing this against my better judgement. I do not like GUIs, i believe they
are buggy, slow and, most importantly, hard to design. But I sort of have to
lose my Ruby-GUI anal virginity, so here it goes.  
For the record: a gilt is a female pig at the age of breeding.
=end

class Gilt < Gtk::Window
  @command # Currently selected Sswine command.

  # Constructor. It is supposed to initialize and show the GUI.
  def initialize
    super

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
    output_buffer = Gtk::TextBuffer.new
    output_scroller = Gtk::ScrolledWindow.new
    output_view = Gtk::TextView.new output_buffer
    output_view.editable = false
    output_scroller.add output_view
    grid.attach output_scroller, 0, 2, 3, 5

    # Execution button:
    execute = Gtk::Button.new :label => "Execute!"
    execute.signal_connect "clicked" do
      # On click, call the function which will handle the logic:
      output_buffer.text = executeCommand
    end
    grid.attach execute, 2, 1, 1, 1

    # Add the grid:
    add grid

    # Finally, show everything and start!
    show_all
    Gtk.main
  end

  # Private method. Handles the logic of the "Execute!" button.
  # Returns the text to show on the GUI.
  private
  def executeCommand
    s = nil
    ret = ""

    # Depending on the command, do the right thing:
    case @command
      when "check" then
        s = Sswine.new :logs => "gui"

      when "desktop" then
        s = Sswine.new :logs => "gui"
        s.writeMenuEntries

      when "kill" then
        s = Sswine.new
        s.killAllHams
        ret = "All Hams have been killed."

      when "shell" then
        s = Sswine.new

        if s.invisible then
          ret = "No Hams found. Nothing to do."

        else
          # gnome-terminal is mandatory for now:
          if `which gnome-terminal 2> /dev/null`.empty? then
            ret = "Please install gnome-terminal and try again."

          else
            `gnome-terminal -e "/home/arch/Sswine/sswine -s"`
          end
        end

      when "update" then
        s = Sswine.new
        s.updateAllHams
        ret = "All Hams have been updated."
    end

    # Make sure there's an output to show:
    if ret.empty? then
      if s.nil? or s.logs_gui.empty? then
        ret = "No errors occurred, everything is fine."

      else
        ret = s.logs_gui.join "\n"
      end
    end

    return ret
  end

end

