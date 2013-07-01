require('coffee-script');
require('source-map-support').install();

module.exports = {
    Server:     require('./Server'),
    Watcher:    require('./Watcher'),
    conf:       require('./conf'),
    logger:     require('./logger'),
    start:      require('./start'),
    utils:      require('./utils')
};
