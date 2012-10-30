do ->
  doc = window.document

  if typeof window.console == 'undefined'
    window.console =
      log: ->
      warn: ->

  $get = (id, prop) ->
    elems = doc.getElementsByTagName id
    result = []
    for elem in elems
      if prop.length == 1 and elem[prop[0]]
        result.push elem
      else if prop.length == 2 and elem[prop[0]] == prop[1]
        result.push elem
    return result

  remove = (e) ->
    if e.parentNode
      e.parentNode.removeChild e

  class ServerCom
    constructor: (url) ->
      @ws = io.connect url
      @ws.on 'msg', (data) =>
        json = JSON.parse data
        if json.change
          fileNames = {}
          for fileName in json.change
            suffix = /\.(\w+)$/.exec(fileName)[1].toLowerCase()
            if not fileNames[suffix]
              fileNames[suffix] = []
            fileNames[suffix].push fileName

          if fileNames.html and reloaders.html fileNames.html
            return

          for suffix of fileNames
            reloaderFun = reloaders[suffix]
            if reloaderFun
              reloaderFun fileNames[suffix]

        return

    reloaders =
      js: (jsFiles) ->
        time = new Date().getTime()
        for elem in $get('script', ['src'])
          if not elem.src
            continue

          src = elem.src.replace /\?\d+$/, ''

          for file in jsFiles
            if rxEscape(file).test src
              newElem = doc.createElement 'script'
              newElem.src = "#{elem.src}?#{time}"
              remove elem
              doc.body.appendChild newElem
              console.log "Loaded #{newElem.src}"
        return

      css: (cssFiles) ->
        time = new Date().getTime()
        for elem in $get('link', ['rel', 'stylesheet'])
          if not elem.href
            continue

          href = elem.href.replace /\?\d+$/, ''

          for file in cssFiles
            if rxEscape(file).test href
              elem.href = "#{href}?#{time}"
              console.log "Loaded #{elem.href}"
        return

      html: (htmlFiles) ->
        loc = location.href.replace /\?.*$/, ''
        if loc[loc.length - 1] == '/'
          loc = loc + 'index.html'
        for file in htmlFiles
          if rxEscape(file).test loc
            location.reload true
            console.log "Reloaded #{loc}"
            return true
        return false

    rxEscape = (rx) ->
      new RegExp "#{rx.replace /([.^$\\\-])/g, '\\$1'}$"

  window.$freshen = new ServerCom '<<URL>>'
