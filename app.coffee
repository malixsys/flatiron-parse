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
session_helper        =  require path.join(modules, "session_helper.coffee")

ParamNotSet = (p,n) ->
    err = new Error("Environment Variable Not Set Error! Set #{p} or pass it in as the #{n} argument")
    throw err

app = flatiron.app
app.use flatiron.plugins.http

app.http.before.push cookieParser(process.env.CookieParserSecret or process.argv[2] or ParamNotSet("CookieParserSecret", "1st")) 
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
  ext: '.jshtml'

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
  session_helper.view_locals @req, {}, (options) =>
    app.render @res, 'index', options
    
app.router.get "/login", ->
  session_helper.view_locals @req,
    title: "login | aZoo.me"
    isLogin: true
  , (options) =>
    app.render @res, "login", options

app.router.post "/login",  ->
  session_helper.login app, @req.body.username, @req.body.password, (err,user) =>
    if err
      delete @req.session.user
      session_helper.redirect_with_error_number @req, @res, err, "/login"
    else
      @req.session.user = user
      session_helper.redirect_with_success_number @req, @res, 0, "/"

app.router.get "/logout",  ->
  delete @req.session.user
  session_helper.redirect_with_success_number @req, @res, 0, "/"

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
    
