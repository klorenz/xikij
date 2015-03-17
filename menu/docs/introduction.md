# Getting Started

## Expand Nodes (run Actions)

You can expand and collapse things with `ctrl+enter`.  Try it on following
line, this will browse your home directory:

```
    ~/
```

## Get Help

Create a new line and enter a single "?".  Hit `ctrl+enter`.  Try it here:
```
    ?
```

If you need help on a menu item, type it followed by "?":
```
    hostname?
```

There is also a shortcut do get help without appending the "?" `ctrl-j h`.



## Expand Nodes Passing Input

You can collapse things with `ctrl+shift+enter`, which will
pass nested (indented) content as input to collapsed thing.  Result of
running this action will be the new nested content.

```
    echo
       hello world

```

## List Root Items

Hit `ctrl+enter` on an empty line to get a list of available menu items.


## Contexts

"@" creates a new context.

```
  ../
     @pwd
```

Difference between "../pwd" and "../@pwd" is that in first case the file
"pwd" in parent directory is addressed, and in second case the menu "pwd"
in context of "../" is run.
