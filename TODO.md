# TODO

## Create Xikij Runner

Create a context for running xikij sheets:
```
<<<<
  This text will be passed
  through

  - hostname |
  $ echo

  Listing of home dir
  $ ls
  $ pwd
  /foo/bar
     $ ls
  /foo/bar
     $ cat <<
       input

<<<< is equiv for

<< run <<

```

With following following syntax:

- line starting with "<<" means replace this with output of
  following.

  empty name is short for "run"

- line ending with "<<" means take this as input


- if a line ends with "|", its output will be passed into
  next command

- if a line ends with "<<", it gets input from following
  indented lines.

## Create Recipes

Recipes are sequences of xikij commands, which can be
recalled later.

### Define a Recipe

```
  recipe/<name> <<
    $ first command
    /some/path
      $ second command
      $ third command in same context
```

If a command fails, entire recipe fails.

You can call a recipe later like this

```
  recipe/<name>
```


## Create Cache

```
  cached
    - @some/other/thing
```

caches the output of some/other/thing by this key.  Each
time some/other/thing is called in cached context, it is
retrieved from cache.


## Remove Entry

Need a keyboard shortcut to remove a line. ``ctrl+shift+entf`` ?
Need a keyboard shortcut to remove a line. ``ctrl+entf`` ?


## Quick Open

Need a list of all titles to open a menu entry quickly.
Maybe from completion?
Autocomplete-plus extension?


## Newline after entry on collapse

If an entry is collapsed and next line is indented less than entry, insert an
empty line after collapsed entry.


## on running a command put the cursor right after the output mark

... then cursor scrolls with output :)


## create imap client

```
    imap://user@host/
      - INBOX/<search>
        - <storedsearch>/move/done
        -      1 | 2015-03-14 12:00 | Kay-Uwe Lorenz <kiw... | Subject is here ...
        - 100003 |
      - Sent/
      - shared.afolder/

    imap/
      - add account
        URL: ...
        ...
        [submit] [cancel]
      - remove account
        - imap://user@....
        - ...
      - imap://user@host/

    mail/"""
      From: <identity>
      To: recipient
      Cc:
      Bcc:
      Subject: <subject>

      Hello Mr. Foo,

      Sincerly, ...

      --
      <signature for identity>
      """

    mail <<
      From: <identity>
      To: recipient
      Cc:
      Bcc:
      Subject: <subject>

      Hello Mr. Foo,

      Sincerly, ...

      --
      <signature for identity>

```

## create password manager

store passwords in a CSON like this (mode 600):

    "imap://user@host": mypass
    "imap://user@another-host": anotherpass


## create commandline interface

Need commandline interface, which manages basic issues


## need package interface

```
xikij package/link
```

Link a package into .xikij/package folder.
