module.exports = function(match, req, res, headers) {
  res.$send(null, [match, headers], headers)
}
