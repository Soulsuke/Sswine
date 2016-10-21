# Sswine
Sswine, which stands for "Sswine: split wine".  
It is licensed under GPLv3.

### General
This program, written in Ruby, is made to handle multiple wine bottles located
in $HOME/.sswine.  
Such folder must be populated with sub-folders, named Hams. Each Ham's name
should give a clue about what its purpouse is for.  
A valid Ham folder must contain at least:  
- config.yaml: a configuration entry (see below for a reference)  
- wine_env: a wine bottle  

Optionally, it can also contain:  
- icons: a folder containing Ham-specific icons (any image file supported by
         your desktoop manager's menu)  
- custom_wine: a folder containing a custom version of wine, to be used for
               this Ham.

### Usage
Sswine's current functionalities are (as shown in its help reference):  
- sswine -c/--check: checks each entry of each Ham for errors. No output means
                     that everything is ok.  
- sswine -d/--desktop: writes .desktop files for each valid entry of each
                       edible Ham.  
- sswine -g/--gui: launches the GTK3 GUI.  
- sswine -h/--help: shows this help reference.  
- sswine -k/--kill: runs 'wineserver -k' for each Ham.  
- sswine -s/--shell: prompts the user to choose an edible Ham. Then, the user's
                     default shell is opened in the choosen entry's folder,
                     with the WINEPREFIX variable correctly set.  
- sswine -u/--update: runs 'wineboot' for each edible Ham. This is supposed to
                      update wine files on each of them.  

**WARNING:** Although it's already implied, I'd like to state that to use the
GTK3 GUI, the ruby gem "gtk3" has to be installed.  

### config.yaml
This file must always contain at least an entry.  
Each entry must be composed of a name and a series of values, using the
following syntax:  
>`Entry Name:`  
>&emsp;`Key1: "Value1"`  
>&emsp;`Key2: "Value2"`  

The entry's name will be the .desktop file's one. If no "Name" key is provided,
it will fill in for it as well.  

To create a usable menu entry, you must specify the keys needed to create a
valid .desktop file according to freedesktop.org's specification.  

If more entries would use the same value for some keys, you can specify global
values to use for all entries (which are overridden by entry-specific values)
in the following way:  
>`Global Values:`  
>&emsp;`Key1: "Value1"`  
>&emsp;`Key2: "Value2"`  

**WARNING:** The value of key "Path", if specified, must be relative to
"$HOME/.sswine/<Ham>/wine_env/drive_c", which is pretty much an unavoidable
path while using wine.  
**WARNING:** If the value of key "Exec" contains spaces other than the ones
separating commands, they have to be escaped. Also "\" character needs to be
escaped. To put it shortly: you have to put two \ before any space which does
not separate two different commands.  

A sample config.yaml is:  
>`Global Values:`  
>&emsp;`Encoding: "UTF-8"`  
>&emsp;`Version: "1.0"`  
>&emsp;`Type: "Application"`  
>&emsp;`Terminal: "false"`  
>&emsp;`Categories: "Games;"`  
>&emsp;`Icon: "global_icon.png"`  
>&emsp;`Path: "global/path"`  
>&emsp;`Hidden: "false"`  
>&emsp;`NoDisplay: "false"`  
>
>`Program Name:`  
>&emsp;`Exec: "wine exec.exe"`  
>&emsp;`Icon: "entry_icon.png"`  
>
>`Other Program:`  
>&emsp;`Exec: "wine exec\\ with\\ spaces.exe"`  
>&emsp;`Name: "Other/Program"`  

Will generate "Program Name.desktop":  
>`[Desktop Entry]`  
>`Categories=Games;`  
>`Encoding=UTF-8`  
>`Exec=env WINEPREFIX=/home/<user>/.sswine/test/wine_env wine exec.exe`  
>`Hidden=false`  
>`Icon=/home/<user>/.sswine/test/icons/entry_icon.png`  
>`NoDisplay=false`  
>`Path=/home/<user>/.sswine/test/wine_env/drive_c/global/path`  
>`Terminal=false`  
>`Type=Application`  
>`Version=1.0`  

And "Other Program.desktop":  
>`[Desktop Entry]`  
>`Categories=Games;`  
>`Encoding=UTF-8`  
>`Exec=env WINEPREFIX=/home/<user>/.sswine/test/wine_env wine exec\ with\ spaces.exe`  
>`Hidden=false`  
>`Icon=/home/<user>/.sswine/test/icons/global_icon.png`  
>`Name=Other/Program`  
>`NoDisplay=false`  
>`Path=/home/<user>/.sswine/test/wine_env/drive_c/global/path`  
>`Terminal=false`  
>`Type=Application`  
>`Version=1.0`  

