# Freshen - Update browser(s) while editing

This program monitors files for changes, runs build scripts and tells browsers
to reload files when changes are made.  This makes it possible to create a whole
site from your editor without having to reload the browser!

The directory being monitored should contain a `.freshenrc` file that configures
when build scripts should be run or when the browser should reload files. The
file is created if it does not exist.

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

    # Files to reload in the browser when they change. The value of `change` should
    # be either a string of suffix names separated by whitespace or an array of
    # regular expressions.
    report:
      change: 'css html js'

    # Run a command each time a file with one of the suffixes in deps change.
    # The value of `deps` can be a string of suffix names or an Array of RegExps
    build:
      command: 'make'
      deps: 'less md html'

    # Where to access server
    url: 'http://localhost:5005'

    ## Supply a custom mimetypes file
    # mimeTypesFile: "mime.types"
```
