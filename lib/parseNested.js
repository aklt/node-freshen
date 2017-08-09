function parseNested(text) {
  var result = [{ key: 'top', indent: -1 }]
  var scope = result
  var scopes = [scope]
  var re = /^([ ]*)(\S.*)$/gm
  var m

  while ((m = re.exec(text)) !== null) {
    var indent = m[1].length

    if (scope[0].indent >= indent) {
      for (var i = scopes.length - 1; i >= 0; i -= 1) {
        if (scopes[i][0].indent < indent) {
          scope = scopes[i]
          break
        }
      }
    }

    var n = /^(\S+)\s*(.*)$/.exec(m[2])
    if (n) {
      scopes.push(scope)
      scope.push([{ key: n[1], val: n[2], indent: indent }])
      scope = scope[scope.length - 1]
    } else {
      if (scope.length >= 1) {
        if (m[0][m[0].length - 1] === '\\') {
          scope.push(m[0].replace(/\\$/, '').trim())
        } else {
          scope.push(m[0].trim())
        }
      } else {
        scope.push(m[2])
      }
    }
  }
  return result
}

function createJson(ast, res) {
  for (var i = 0; i < ast.length; i += 1) {
    var n = ast[i]
    if (n.key) n.key = n.key.replace(/:$/, '')
    // eslint-disable-next-line no-eval
    if (n.val) n.val = eval(n.val)
    if (Array.isArray(ast[i])) {
      createJson(n, res)
    } else {
      if (!n.val) res = res[n.key] = {}
      else res[n.key] = n.val
    }
  }
  return res
}

function readNested(text) {
  var d1 = parseNested(text.replace(/^\s*#.*$\n/gm, ''))
  return createJson(d1, {})
}

module.exports = readNested
