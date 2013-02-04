# Freshen - Update browser(s) while editing

This program monitors files for changes, runs build scripts and tells browsers
to reload files when changes are made.  This makes it possible to create a whole
site from your editor without having to reload the browser.

This is done by
[fs.watch](http://nodejs.org/api/fs.html#fs_fs_watch_filename_options_listener)ing
files and reporting changes to the browser through a [socket.io](https://github.com/learnboost/socket.io)
connection.

## Installation

Assuming you have a recent version of node installed you can get started by
running the following commands:

```bash
    $ npm install -g freshen
    $ cd /location/of/my/static/site
    $ freshen 
    22:15:56 Creating .freshenrc from /somewhere/freshen/freshenrc-example
    22:15:56 Running freshen version 0.1.0
    22:15:56 Listening to http://localhost:5005
    22:15:56 make: Nothing to be done for 'all'.
    22:15:56 Watching /location/of/my/static/site
```

Point your browser at `http://localhost:5005` and start editing the files that
make up the site.  You will probably also want to change the `.freshenrc` file.

## Configuration

The directory being monitored should contain a `.freshenrc` file that configures
when build scripts should be run or when the browser should reload files. It is
created from the default configuration if it does not exist.

If the file `${HOME}/.freshenrc` is present it is used as a template instead of
the default configuration that comes with freshen.

The default configuration file looks like this:

```coffee
    # Example of a .freshenrc configuration file
    #
    # Place a file like this in the root of the directory you wish freshen to serve

    # Send at most 1 message to browsers in this amount of milliseconds
    # This is useful to avoid sending a lot of seperate requests to load
    # files to browsers when the build process changes many files
    delay: 150

    # Should terminal logging be in color?
    color: true

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
    url: 'http://localhost:5005'

    ## Supply a custom mimetypes file
    # mimeTypesFile: "mime.types"
```
