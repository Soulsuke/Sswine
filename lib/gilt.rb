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
    set_default_size 290, 290
    set_window_position :center

    # Main grid container:
    grid = Gtk::Grid.new 
    grid.set_column_spacing 10
    grid.set_row_spacing 10

    # Header:
    header = Gtk::Label.new "Choose what to do:"
    grid.attach header, 0, 0, 1, 1

    # Sswine commands list:
    commands = Gtk::ComboBoxText.new
    # List of available commands:
    commands_list = Hash.new
    commands_list["check"] = "Check for invalid Hams"
    commands_list["desktop"] = "Create menu entries"
    commands_list["help"] = "Help"
    commands_list["kill"] = "Kill all Hams"
    commands_list["shell"] = "Open a shell for a Ham"
    commands_list["update"] = "Update all Hams"
    # Set the listener for the "changed" event:
    commands.signal_connect "changed" do |sender|
      # Use the key, not the name.
      @command = commands_list.key sender.active_text
    end
    # Add each entry of commands_list to command:
    commands_list.each do |key, entry|
      commands.append_text entry
    end
    # This is to make sure @command is never empty:
    commands.set_active 0
    # Finally, attach it to the grid:
    grid.attach commands, 0, 1, 6, 1

    # Execution button:
    execute = Gtk::Button.new :label => "Execute!"
    execute.signal_connect "clicked" do
      # On click, call the function which will handle the logic:
      executeCommand
    end
    grid.attach execute, 7, 1, 1, 1

    # Add the grid:
    add grid

    # Finally, show everything and start!
    show_all
    Gtk.main
  end

  # Private method. Handles the logic of the "Execute!" button.
  private
  def executeCommand
    # Depending on the command, do the right thing:
    case @command
    when "check" then
      s = Sswine.new :logs => "gui"

    when "desktop" then
      s = Sswine.new :logs => "gui"
      s.writeMenuEntries

    when "help" then
      # Is it really necessary??

    when "kill" then
      s = Sswine.new
      s.killAllHams
      # Print an "all done" message.

    when "shell" then
      s = Sswine.new
      # s.openShell
      # Should this be done at all? Maybe open a terminal emulator?

    when "update" then
      s = Sswine.new
      s.updateAllHams
      # Print an "all done" message.
    end

    puts "Executed command for: #{@command}"
  end

end

