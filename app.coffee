util         =  require("util")
path         =  require("path")
modules      =  path.join __dirname, 'modules'
connect      =  require("connect")
session      =  connect.session
cookieParser =  connect.cookieParser
flatiron     =  require("flatiron")
director     =  require "director"
ecstatic     =  require "ecstatic"
#jade         = require "jade.plugin"
#bliss        = require "./lib/view.bliss.plugin.coffee"
jshtml       =  require path.join(modules, "view.jshtml.plugin.coffee")
parse        =  require path.join(modules, "parse.plugin.coffee")
sessions     =  require path.join(modules, "session_helper.coffee")
auths		 =  require path.join(modules, "auth_helper.coffee")

app = flatiron.app
app.use flatiron.plugins.http

app.http.before.push cookieParser(process.env.CookieParserSecret) # Set in your Environment...
app.http.before.push session()

#app.use jade.plugin, 
#  dir: "" + __dirname + "/views",
#  ext: '.jade'

#app.use bliss.plugin, 
#  dir: "" + __dirname + "/views",
#  ext: '.bliss'

app.use parse.plugin
  
app.use jshtml.plugin, 
  dir: "" + __dirname + "/views",
  ext: '.jshtml' #.jade .bliss

app.http.before.push ecstatic(
        root: __dirname+'/assets',
        baseDir: 'public' 
        )

app.http.before.push (req,res) ->
  unless req.session.user
    req.session.user = false
  msg = util.inspect 
    url: req.url
    session: req.session
  console.log "[REQUEST] #{msg}"

  res.emit 'next'

app.router.get "/",  ->
  sessions.view_locals @req, {}, (options) =>
    app.render @res, 'index', options
    
app.router.get "/login", ->
  sessions.view_locals @req,
    title: "login | aZoo.me"
    isLogin: true
  , (options) =>
    app.render @res, "login", options

app.router.post "/login",  ->
  auths.login app, @req.body.username, @req.body.password, (err,user) =>
    if err
      delete @req.session.user
      sessions.redirect_with_error_number @req, @res, err, "/login"
    else
      @req.session.user = user
      sessions.redirect_with_success_number @req, @res, 0, "/"

app.router.get "/logout",  ->
  delete @req.session.user
  sessions.redirect_with_success_number @req, @res, 0, "/"

port = process.env.PORT or 3000
host = process.env.IP

app.start port, host, (err) ->
    console.log "[SERVER] Started at #{host}:#{port}..."
    properties = (prop for prop of app)
    app.parse.list "Users", (err, data) ->
      app.users = data.results
      console.log "[SERVER] Loaded #{app.users.length} users"
      #for property of app.users
      #  console.log property    
    
