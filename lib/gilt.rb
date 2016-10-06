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
    set_default_size 350, 300
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
    commands_list["check"] = "Check Sswine folder"
    commands_list["desktop"] = "Write menu entries"
    commands_list["gui"] = "GUI"
    commands_list["help"] = "Help"
    commands_list["kill"] = "Kill"
    commands_list["shell"] = "Shell"
    commands_list["update"] = "Update"
    commands_list["egg"] = "World domination"
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
    # Will execute @command.
    puts "Command: #{@command}"
  end

end

