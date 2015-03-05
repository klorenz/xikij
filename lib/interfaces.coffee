# # Interfaces
#
# A Xiki context can influence behaviour of child operations.  As an example
# running pwd in two different directories.
#
# ```bash
#  /foo/bar
#    $ pwd
#      /foo/bar
#  /tmp
#    $ pwd
#      /tmp
# ```
#
# In this case directory context set working directory, which made child
# operations to be run in different working directories.
#
# The final xiki context class is composed by a mix of various interfaces,
# which are specified in this file.
#
module.exports = (Interface) ->
  Interface
    .load("./interfaces/subprocess")
    .load("./interfaces/namespace")
    .load("./interfaces/filesystem")
    .load("./interfaces/actions")
    .load("./interfaces/request")
    .load("./interfaces/environment")
    .load("./interfaces/contexts")
    .load("./interfaces/logger")
    .load("./interfaces/packages")
