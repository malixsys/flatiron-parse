 
fs = require("fs")
path = require("path")
Bliss = require("bliss")

bliss = new Bliss
    ext: ".bliss",
    cacheEnabled: false,
    context: {}

inner_render = (view, ctx, callback) ->
  # str = require("fs").readFileSync(view, "utf8")
  html = bliss.render view,
    context: ctx
  callback null, html
  
attach = (options) ->
  self = this
  options.dir = options.dir or "./views"
  options.ext = options.ext or ".bliss"

  self.redirect = (res, location) ->
    res.writeHead 302,
      Location: location
    res.end()

  self.render = (res, name, context) ->
    context = context or {}
    file = path.join(options.dir, name + options.ext)
    inner_render file, context, (err, str) ->
      if err
        res.writeHead 200,
          "Content-Type": "text/plain"
        res.end err.toString()
      else
        res.writeHead 200,
          "Content-Type": "text/html"
        res.end str
        
exports.plugin =
  name: "bliss.plugin"
  attach: attach