# Sswine
Sswine, which stands for "Sswine: split wine".

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
sswine -c/--check: checks each entry of each Ham for errors. No output means
                   that everything is ok.
sswine -d/--desktop: writes .desktop files for each valid entry of each
                     edible Ham.  
sswine -h/--help: shows this help reference.  
sswine -k/--kill: runs 'wineserver -k' for each Ham.  
sswine -s/--shell: prompts the user to choose an edible Ham. Then, the user's
                   default shell is opened in the choosen entry's folder, with
                   the WINEPREFIX variable correctly set.  
sswine -u/--update: runs 'wineboot' for each edible Ham. This is supposed to
                    update wine files on each of them.  

### config.yaml
This file must always contain at least an entry.  
Each entry must be composed of a name and a series of values, using the
following syntax:  
`Entry Name:`  
&emsp;`Key1: "Value1"`  
&emsp;`Key2: "Value2"`  

The entry's name will be used for the name of both the menu entry and of the
desktop file.

To create a usable menu entry, you must specify the keys needed to create a
valid .desktop file according to freedesktop.org's specification.  

If more entries would use the same value for some keys, you can specify global
values to use for all entries (which are overridden by entry-specific values)
in the following way:  
`Global Values:`  
&emsp;`Key1: "Value1"`  
&emsp;`Key2: "Value2"`  

**IMPORTANT**: The value of key "Path", if specified, must be relative to
"$HOME/.sswine/<Ham>/wine_env/drive_c", which is pretty much an unavoidable
path while using wine.  

A sample config.yaml is:  
`Global Values:`  
&emsp;`Encoding: "UTF-8"`  
&emsp;`Version: "1.0"`  
&emsp;`Type: "Application"`  
&emsp;`Terminal: "false"`  
&emsp;`Categories: "Games;"`  
&emsp;`Icon: "global_icon.png"`  
&emsp;`Path: "global/path"`  
&emsp;`Hidden: "false"`  
&emsp;`NoDisplay: "false"`  

`Program Name:`  
&emsp;`Exec: "wine exec.exe"`  
&emsp;`Icon: "entry_icon.png"`  

