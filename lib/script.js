/* global ReconnectingWebSocket location */
;(function() {
  var doc = window.document
  if (typeof window.console === 'undefined') {
    window.console = {
      log: function() {},
      warn: function() {}
    }
  }
  function $get(id, prop) {
    var elem, elems, i, len, result
    elems = doc.getElementsByTagName(id)
    result = []
    for (i = 0, len = elems.length; i < len; i++) {
      elem = elems[i]
      if (prop.length === 1 && elem[prop[0]]) {
        result.push(elem)
      } else if (prop.length === 2 && elem[prop[0]] === prop[1]) {
        result.push(elem)
      }
    }
    return result
  }
  function remove(e) {
    if (e.parentNode) {
      return e.parentNode.removeChild(e)
    }
  }

  function documentResources() {
    var loc = new RegExp('^' + window.location.protocol, 'i')
    var res = {}
    res.img = [].slice
      .call(document.getElementsByTagName('img'))
      .filter(function(el) {
        return loc.test(el.src)
      })
      .map(function(el) {
        return el.src
      })
    res.css = [].slice
      .call(document.styleSheets)
      .filter(function(ss) {
        return loc.test(ss.href)
      })
      .map(function(el) {
        return el.href
      })
    // TODO embed iframe
    return res
  }

  function ServerCom(url, conf) {
    this.ws = new ReconnectingWebSocket(url)
    this.ws.onmessage = function(ev) {
      if (conf.debug) console.log('message', ev)
      var json, reloaderFun, suffix
      try {
        json = JSON.parse(ev.data)
      } catch (e) {
        console.warn('Error', e.stack)
        json = { error: e }
      }
      console.warn('got', json)
      // TODO use server api to reload only once freshen is back online
      if (json.reload) {
        return location.reload(true)
      }
      if (json.change) {
        //
        // 1. which resources do we have?
        //
        //
        //
        console.warn('BOOB', documentResources())
        console.warn('BOOB', {
          a: 1,
          b: {
            aaa: [
              1,
              2,
              3,
              {
                ff: 33
              }
            ]
          }
        })
        var fileNames = {}
        for (var i = 0; i < json.change.length; i++) {
          suffix = /\.(\w+)$/.exec(json.change[i])[1].toLowerCase()
          if (!fileNames[suffix]) fileNames[suffix] = []
          fileNames[suffix].push(json.change[i])
        }
        console.warn(fileNames)
        // XXX persist state behind iframe?
        // if (fileNames.html && reloaders.html(fileNames.html)) return
        // reload full page if one changed resource is not in hot load list
        for (suffix in fileNames) {
          if (!conf.load[suffix]) {
            if (conf.debug) console.log('reload page')
            return location.reload(true)
          }
        }
        for (suffix in fileNames) {
          if (conf.debug) console.log('hot load ', suffix)
          reloaderFun = reloaders[suffix]
          if (reloaderFun) {
            reloaderFun(fileNames[suffix])
          }
        }
      }
    }
  }

  function imgReloader(imgFiles) {
    var elem, i, imgFilesRx, j, len, len1, ref, rx, src, time
    time = new Date().getTime()
    imgFilesRx = makeFileMatchRegexes(imgFiles)
    ref = $get('img', ['src'])
    for (i = 0, len = ref.length; i < len; i++) {
      elem = ref[i]
      src = elem.src.replace(/\?\d+$/, '')
      for (j = 0, len1 = imgFilesRx.length; j < len1; j++) {
        rx = imgFilesRx[j]
        if (rx.test(src)) {
          elem.src = src + '?' + time
          console.log('Loaded ' + src)
        }
      }
    }
  }

  var reloaders = {
    js: function(jsFiles) {
      var elem, i, j, jsFilesRx, len, len1, newElem, ref, rx, src, time
      time = new Date().getTime()
      jsFilesRx = makeFileMatchRegexes(jsFiles)
      ref = $get('script', ['src'])
      for (i = 0, len = ref.length; i < len; i++) {
        elem = ref[i]
        src = elem.src.replace(/\?\d+$/, '')
        for (j = 0, len1 = jsFilesRx.length; j < len1; j++) {
          rx = jsFilesRx[j]
          if (rx.test(src)) {
            newElem = doc.createElement('script')
            newElem.src = src + '?' + time
            remove(elem)
            doc.body.appendChild(newElem)
            console.log('Loaded ' + newElem.src)
          }
        }
      }
    },
    css: function(cssFiles) {
      var cssFilesRx, elem, href, i, j, len, len1, ref, rx, time
      time = new Date().getTime()
      cssFilesRx = makeFileMatchRegexes(cssFiles)
      ref = $get('link', ['rel', 'stylesheet'])
      for (i = 0, len = ref.length; i < len; i++) {
        elem = ref[i]
        if (!elem.href) {
          continue
        }
        href = elem.href.replace(/\?\d+$/, '')
        for (j = 0, len1 = cssFilesRx.length; j < len1; j++) {
          rx = cssFilesRx[j]
          if (rx.test(href)) {
            elem.href = href + '?' + time
            console.log('Loaded ' + elem.href)
          }
        }
      }
    },
    html: function(htmlFiles) {
      var htmlFilesRx, i, len, loc, rx
      htmlFilesRx = makeFileMatchRegexes(htmlFiles)
      console.warn('xx', htmlFilesRx)
      loc = location.href.replace(/\?.*$/, '')
      if (loc[loc.length - 1] === '/') {
        // TODO default loc
        loc = loc + 'index.html'
      }
      for (i = 0, len = htmlFilesRx.length; i < len; i++) {
        rx = htmlFilesRx[i]
        if (rx.test(loc)) {
          location.reload(true)
          return true
        }
      }
      return false
    },
    png: imgReloader,
    jpg: imgReloader,
    jpeg: imgReloader,
    gif: imgReloader,
    svg: imgReloader
  }

  function makeFileMatchRegexes(stringArray) {
    var i, len, results, str
    results = []
    for (i = 0, len = stringArray.length; i < len; i++) {
      str = stringArray[i]
      results.push(
        new RegExp(str.replace(/([[\]/{}()*+?.\\^$|-])/g, '$$1') + '$$')
      )
    }
    return results
  }

  window.$freshen = new ServerCom(
    location.href.toString().replace(/^http/, 'ws') /* <<CONF>> */
  )
})()
