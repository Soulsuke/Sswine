=begin
This module's purpose is to handle logs on behalf of the other classes.  
Any class that includes this module should call oink_initialize somewhere 
within their constructor.
=end

module Oink
  @colors   # This is the list of managed colors.
  @logs_gui # This is the container of logs formatted for the GTK3 GUI.

  # This is the list of managed colors.  
  attr_reader :colors

  # This is the container of logs formatted for the GTK3 GUI.  
  # It is an array of Hashes, each with the fields :text and :tags.
  attr_reader :logs_gui

  # Mandatory to initialize instance variables. Sort of a constructor.
  public
  def oink_initialize
    @colors = {
      :blue => "\e[34m",
      :cyan => "\e[36m",
      :red => "\e[31m",
      :yellow => "\e[33m",
      # Always keep this one last:
      :default => "\e[0m"
    }
    @logs_gui = Array.new

    # Unless otherwise specified, logs are on. This is to allow classes without
    # @logs instance variables to still use Oink to log.
    unless defined? @logs then
      @logs = :on
    end
  end

  # Private method. Caps a single line to the given length. To work properly,
  # the following should be provided:
  # :entry => line of text to split (if needed).
  # :cap => max characters per single line.
  private
  def digest( options = {} )
    # Complete container of all composed lines:
    composed_container = Array.new

    # To preserve formatting, gotta check how many spaces there are at the
    # beginning of the line, and add them back to the first composed line:
    spaces = "#{options[:entry]}".length - "#{options[:entry]}".lstrip.length
    composed_line = " " * spaces

    # Split each message string on spaces:
    "#{options[:entry]}".split( " " ).each do |word|
      # This is needed to avoid counting colors escape sequences for the max
      # length:
      composed_bare = ""

      # Do not add a space right after another one:
      if " " == composed_line[-1] then
        composed_bare += word
      else
        composed_bare += composed_line + " " + word
      end

      @colors.each do |key, entry|
        composed_bare.gsub! entry, ""
      end

      # If composed_bare exceeds is within term_size, keep composing:
      if "#{options[:cap]}".to_i >= composed_bare.length then
        # Add a space if needed:
        unless composed_line.empty? then
          composed_line += " "
        end

        # Always add the word:
        composed_line += "#{word}"

      # If the current word would not fit in within term_size, add the
      # current composed_line to the composed_container.push, and start
      # composing the next one with an indentation of 1 space.
      else
        composed_container.push composed_line

        composed_line = " " * (spaces + 1) + "#{word}"
      end
    end

    # Be sure not to skip the last one:
    composed_container.push composed_line

    # Finally, return the composed message:
    return composed_container.join "\n"
  end

  # This function will handle the logs.
  public
  def oink( *logs )
    # This only has a meaning if logs are not disabled:
    unless :off == @logs then
      # For each given log...
      logs.each do |entry|
        case @logs
          # GUI logs: save them into @logs_gui
          when :gui then
            # Create a temporary Hash to house this entry:
            tmp = Hash.new

            tmp[:text] = entry
            tmp[:tags] = Array.new

            # For now, this will only save one tag per entry. It should be
            # changed later on.
            tmp_tag = Hash.new

            # Replace shell colors with GUI ones:
            @colors.each_key do |color|
              # Create a tag only if this color has been found:
              unless tmp[:text].index( @colors[color]).nil? then
                # End of GTK3 tag:
                if :default == color then
                  tmp_tag[:end] = tmp[:text].index @colors[color]
                # Beginning of GTK3 tag and its color:
                else
                  tmp_tag[:begin] = tmp[:text].index @colors[color]
                  tmp_tag[:color] = "#{color}"
                end
              end

              tmp[:text].gsub! @colors[color], ""
            end

            tmp[:tags].push tmp_tag
            @logs_gui.push tmp

          # Normal logs: simply print them
          when :on then
            puts digest( :entry => entry, :cap => `tput cols` )
        end
      end
    end
  end

  # Appends the value of element.logs_gui to our @logs_gui.
  public
  def logs_gui_append( element )
    # Only has a meaning if the given element actually has this property:
    if element.methods.include? :logs_gui and
      @logs_gui += element.logs_gui
    end
  end

  # Clears the content of @logs_gui
  public
  def logs_gui_clear
    @logs_gui = Array.new
  end

end
