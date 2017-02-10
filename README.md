[![Build Status](https://travis-ci.org/aklt/node-freshen.svg?branch=master)](https://travis-ci.org/aklt/node-freshen)

# Freshen - Update browser(s) while editing

This program monitors files for changes, runs build scripts and tells browsers
to reload files when changes are made.  This makes it possible to create a whole
site from your editor without having to reload the browser.

Files are monitored for changes with
[fs.watch](http://nodejs.org/api/fs.html#fs_fs_watch_filename_options_listener)
changes are reported to the browser through a websocket connection.

## Installation

Assuming you have a recent version of node installed you can get started by
running the following commands:

```bash
    $ npm install -g freshen
    $ cd location/of/my/static/site
    $ freshen
    [2012-10-24T22:34:05] Creating .freshenrc from /some/path/node-freshen/freshenrc-example
    [2012-10-24T22:34:05] Listening to http://localhost:5005
```

Point your browser at `http://localhost:5005` and start editing the files that
make up the site.  You will probably also want to change the `.freshenrc` file.

## Configuration

The directory being monitored should contain a `.freshenrc` file that configures
when build scripts should be run or when the browser should reload files. It is
created from the default configuration if it does not exist.

The default configuration file looks like this:

```coffee
# Example of a .freshenrc configuration file
#
# Place a file like this in the root of the directory you wish freshen to serve

# All directories below the directory that freshen is started in will be
# watched. Use this option to set a regular expression matching directories that
# should not be watched.  Note that the root dir will always be included.
# exclude: /__foo/

# Files to reload in the browser when they change. The value of `change` should
# be either a string of suffix names separated by whitespace or an array of
# regular expressions.
report:
  change: 'css html js'

# Run command each time a file matching one of the suffixes or regular
# expressions in deps changes.
# The value of `deps` can be a string of suffix names or an Array of RegExps
build:
  command: 'make'
  deps: 'less md html'

# Where to access server
url: 'http://localhost:1024'

# http proxy - note that this requires http-proxy to be installed so that
# freshen can require it
############
proxy:
  # If a request matches this url
  from:  '^/api/(.*)$'
  # rewrite it to this url and send it returning the result
  to:    'http://localhost:8080/${1}'
  # retry this amount of times before bailing
  retry: 20


# Defaulted config values that can be overridden
################################################

# # Send at most 1 message to browsers in this amount of milliseconds This is
# # useful to avoid sending a lot of separate requests to load files to browsers
# # when the build process changes many files
# delay: 150

# # Should terminal logging be in color?
# color: true

# # The whole page is loaded when change is reported. Set the following to true
# # to attempt to hot load only the changed resource
# load:
#   js: true
#   css: true
#   png: true

# # Supply a custom mimetypes file
# mimeTypesFile: "mime.types"

# # Merge additional mime types that files can be served with
# mimeAdd:
#   php: 'text/html'

# # How many retries the client attempts before giving up
# retries: 20

# # Help debugging
# debug: true
```
