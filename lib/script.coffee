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

    imgReloader = (imgFiles) ->
      time = new Date().getTime()
      imgFilesRx = makeFileMatchRegexes imgFiles
      for elem in $get 'img', ['src']
        src = elem.src.replace /\?\d+$/, ''
        for rx in imgFilesRx
          if rx.test src
            elem.src = "#{src}?#{time}"
            console.log "Loaded #{src}"
      return

    reloaders =
      js: (jsFiles) ->
        time = new Date().getTime()
        jsFilesRx = makeFileMatchRegexes jsFiles
        for elem in $get('script', ['src'])
          src = elem.src.replace /\?\d+$/, ''
          for rx in jsFilesRx
            if rx.test src
              newElem = doc.createElement 'script'
              newElem.src = "#{src}?#{time}"
              remove elem
              doc.body.appendChild newElem
              console.log "Loaded #{newElem.src}"
        return

      css: (cssFiles) ->
        time = new Date().getTime()
        cssFilesRx = makeFileMatchRegexes cssFiles
        for elem in $get('link', ['rel', 'stylesheet'])
          if not elem.href
            continue

          href = elem.href.replace /\?\d+$/, ''

          for rx in cssFilesRx
            if rx.test href
              elem.href = "#{href}?#{time}"
              console.log "Loaded #{elem.href}"
        return

      html: (htmlFiles) ->
        htmlFilesRx = makeFileMatchRegexes htmlFiles
        loc = location.href.replace /\?.*$/, ''
        if loc[loc.length - 1] == '/'
          loc = loc + 'index.html'
        for rx in htmlFilesRx
          if rx.test loc
            location.reload true
            console.log "Reloaded #{loc}"
            return true
        return false

      png: imgReloader
      jpg: imgReloader
      jpeg: imgReloader
      gif:  imgReloader
      svg:  imgReloader

    makeFileMatchRegexes = (stringArray) ->
      for str in stringArray
        new RegExp "#{str.replace(/([\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|])/g, \
                                                                '\\$1')}$"

  window.$freshen = new ServerCom '<<URL>>'
