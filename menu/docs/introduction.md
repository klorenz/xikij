# Getting Started

## Expand Nodes (run Actions)

You can expand and collapse things with `ctrl+return`.  Try it on following
line, this will browse your home directory:

```
    ~/
```

## Get Help

Create a new line and enter a single "?".  Hit `ctrl+return`.  Try it here:
```
    ?
```

If you need help on a menu item, type it followed by "?":
```
    hostname?
```

## Expand Nodes Passing Input

You can collapse things with `ctrl+shift+return`, which will
pass nested (indented) content as input to collapsed thing.  Result of
running this action will be the new nested content.

```
    echo
       hello world

```

## List Root Items

Hit `ctrl+return` on an empty line to get a list of available menu items.


## Contexts

"@" creates a new context.

```
  ../
     @pwd
```

Difference between "../pwd" and "../@pwd" is that in first case the file
"pwd" in parent directory is addressed, and in second case the menu "pwd"
in context of "../" is run.
