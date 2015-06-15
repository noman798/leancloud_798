express = require('express')
path = require('path')
cookieParser = require('cookie-parser')
bodyParser = require('body-parser')
app = express()

# 设置 view 引擎
app.set 'views', path.join(__dirname, 'ejs')
app.set 'view engine', 'ejs'
app.use express.static('public')

module.exports = app


#todos = require('./routes/todos')
#cloud = require('./cloud')
## 加载云代码方法
#app.use cloud
#app.use bodyParser.json()
#app.use bodyParser.urlencoded(extended: false)
#app.use cookieParser()
## 可以将一类的路由单独保存在一个文件中
#app.use '/todos', todos

# 如果任何路由都没匹配到，则认为 404
# 生成一个异常让后面的 err handler 捕获

