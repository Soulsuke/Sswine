=begin
This module's purpose to handle logs on behalf of the other classes.  
To work as intended, it requires the class which implements it to have 
instance variables called @logs and @logs_gui.
=end

module Oink
  # This is a list of all managed colors. Ideally, logs should contain colors
  # in the :shell format. Oink's functions will then use this hash to replace
  # them with other ones, if needed.
  @@colors = {
    :shell => {
      :blue => "\e[34m",
      :cyan => "",
      :default => "\e[0m",
      :red => "\e[31m",
      :yellow => "\e[33m"
    },
    :gui => {
      :blue => "",
      :cyan => "",
      :default => "",
      :red => "",
      :yellow => ""
    }
  }

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

      @@colors[:shell].each do |key, entry|
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
            # Replace shell colors with GUI ones:
            @@colors[:shell].each_key do |color|
              entry.gsub! @@colors[:shell][color], @@colors[:gui][color]
            end

            @logs_gui.push entry

          # Normal logs: simply print them
          when :on then
            puts digest( :entry => entry, :cap => `tput cols` )
        end
      end
    end
  end

end
