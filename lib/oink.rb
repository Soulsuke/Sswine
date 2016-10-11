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

  # This function will handle the logs.
  def oink( *logs )
    # This only has a meaning if logs are not disabled:
    unless "off" == @logs then
      # For each given log...
      logs.each do |entry|
        case @logs
          # GUI logs: save them into @logs_gui
          when "gui" then
            # Replace shell colors with GUI ones:
            @@colors[:shell].each_key do |color|
              entry.gsub! @@colors[:shell][color], @@colors[:gui][color]
            end

            @logs_gui.push entry

          # Normal logs: simply print them
          when "on" then
            puts entry
        end
      end
    end
  end

end
