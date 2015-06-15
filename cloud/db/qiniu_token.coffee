qiniu = require('qiniu')
CONFIG = require('cloud/config')

qiniu.conf.ACCESS_KEY = CONFIG.QINIU.KEY
qiniu.conf.SECRET_KEY = CONFIG.QINIU.SECRET


module.exports = (
    returnBody='{"name":$(fname),"size":$(fsize),"w":$(imageInfo.width),"h":$(imageInfo.height),"key":$(key)}'
)->
    putPolicy = new qiniu.rs.PutPolicy(CONFIG.QINIU.BUCKET)
    putPolicy.returnBody = returnBody
    return putPolicy.token()
