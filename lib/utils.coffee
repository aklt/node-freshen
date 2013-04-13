escapeRegExp = (str) ->
  str.replace(/([\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|])/g, '\\$1')

module.exports = {escapeRegExp}
