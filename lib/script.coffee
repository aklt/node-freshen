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
          uniqReloaders = {}
          for fileName in json.change
            reloaderName = /\.(\w+)$/.exec(fileName)[1]
            uniqReloaders[reloaderName] = 1
          for reloaderName of uniqReloaders
            reloader = reloaders[reloaderName]
            if reloader
              reloader new RegExp fileName
        return

    reloaders =
      js: (rxSrc) ->
        time = new Date().getTime()
        for elem in $get('script', ['src'])
          if not rxSrc.test elem.src
            continue

          newElem = doc.createElement 'script'
          if elem.src.indexOf('?') == -1
            newElem.src = "#{elem.src}?#{time}"
          else
            newElem.src = elem.src.replace /\?\d+$/, '?' + time

          remove elem
          doc.body.appendChild newElem
          console.log "Loaded #{newElem.src}"
        return

      css: (rxCss) ->
        time = new Date().getTime()
        for elem in $get('link', ['rel', 'stylesheet'])
          if not elem.href or not (rxCss or /.*/).test elem.href
            continue

          if elem.href.indexOf('?') == -1
            elem.href = "#{elem.href}?#{time}"
          else
            elem.href = elem.href.replace /\?\d+$/, '?' + time
          console.log "Loaded #{elem.href}"
        return

      html: (rxHtml) ->
        loc = location.href.replace /\?.*/, ''
        if loc[loc.length - 1] == '/'
          loc = 'index.html'
        if rxHtml.test loc
          location.reload true
          console.log "Reloaded #{loc}"

  window.$freshen = new ServerCom '<<URL>>'
