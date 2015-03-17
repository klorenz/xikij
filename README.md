Xikij
=====

Xikij (read "zicitch") is a Xiki clone.  It is written in coffee and
initially intended to be used with atom.

It is under development, so is this readme very short for now.

This is not yet a program running on its own.  It is a library still.

```
/home/kiwi
  $ ls
```

TODO
----

- xikij does not work on untitled file, because tries to read file path (atom-xikij)
- auto append path to context, if nothing else given

  ```
    $ svn ls some_url
       a
       b
       c
  ```

  selecting b => means executing ``$ svn ls some_url/b`` at b

  Having ``$ ls`` selecting an entry under it, results in ``$ ls entry``
  selecting subentry in this, does a ``$ ls entry/subentry`` and so on.





Features
--------

- command line execution works
- SSH works


/home/kiwi
  @ foo = bar


+ a script {

  }

a script/"""
    this is
    loads of
    text
    """
    /"""
    next parameter
    """

a script
  @ foo
  @ bar
  @ glork

a path
  / foo
  / bar
  / glork
  @ test
    / x
    / y
  @
