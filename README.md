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
    11:05:34 PM Creating .freshenrc from /home/me/src/freshen/freshenrc-example
    11:05:34 PM Running freshen version 0.6.4-dev
    11:05:34 PM Listening to http://myhost:1024
    11:05:34 PM lessc style.less > style.css
    11:05:34 PM cat header.html  > index.html
    11:05:34 PM markdown index.md     >> index.html
    11:05:34 PM cat footer.html >> index.html
    11:05:34 PM cat header.html  > en/foo.html
    11:05:34 PM markdown en/foo.md     >> en/foo.html
    11:05:34 PM cat footer.html >> en/foo.html
    11:05:34 PM Watching /home/me/src/freshen/example
    11:05:35 PM Connection from Mozilla/5.0 (X11; Linux x86_64; rv:54.0) Gecko/20100101 Firefox/54.0
    11:05:38 PM Connection from Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36
    11:05:55 PM GET /index.html
    11:05:55 PM GET /style.css
    11:05:55 PM GET /test.js
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

# Port to access server at
port: 1024

# # http proxy - note that this requires http-proxy to be installed so that
# # freshen can require it
# ############
# proxy:
#   # If a request matches this url
#   from:  '^/api/(.*)$'
#   # rewite it to this url and send it returning the result
#   to:    'http://localhost:8080/${1}'
#   # retry this amount of times before bailing
#   retry: 20

# Defaulted config values that can be overridden
################################################

# # Send at most 1 message to browsers in this amount of milliseconds This is
# # useful to avoid sending a lot of seperate requests to load files to browsers
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
