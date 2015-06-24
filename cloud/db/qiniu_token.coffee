qiniu = require('qiniu')
CONFIG = require('cloud/config')

qiniu.conf.ACCESS_KEY = CONFIG.QINIU.KEY
qiniu.conf.SECRET_KEY = CONFIG.QINIU.SECRET


module.exports = (
    returnBody='{"w":$(imageInfo.width),"h":$(imageInfo.height),"key":$(key)}'
)->
    putPolicy = new qiniu.rs.PutPolicy2 {
        scope:CONFIG.QINIU.BUCKET
        returnBody
        #saveKey:"332322"
    }

    return putPolicy.token()
