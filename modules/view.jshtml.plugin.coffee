fs      = require("fs")
path    = require("path")
jsHtml  = require('jshtml');

merge = (options, overrides) ->
  extend (extend {}, options), overrides
  
extend = exports.extend = (object, properties) ->
  for key, val of properties
    object[key] = val
  object

inner_render = (view, ctx, callback) ->
  str = fs.readFileSync(view, "utf8")
  fn = jsHtml.compile str, {}
  
  html = fn(ctx)
  callback null, html
  
  
attach = (options) ->
  self = this
  options.dir = options.dir or "./views"
  options.ext = options.ext or ".jshtml"

  self.redirect = (res, location) ->
    res.writeHead 302,
      Location: location
    res.end()

  self.render = (res, name, context) ->
    context = context or {}
    file = path.join(options.dir, name + options.ext)
    layout = path.join(options.dir, 'layout' + options.ext)

    inner_render file, context, (err, str) ->
      if err
        res.writeHead 200,
          "Content-Type": "text/plain"
        res.end err.toString()
      else
        if path.existsSync(layout) 
          inner_render layout, merge(context,{body: str}), (err, str2) ->        
            res.writeHead 200,
              "Content-Type": "text/html"
            res.end str2
                
        else
          res.writeHead 200,
            "Content-Type": "text/html"
          res.end str
        
exports.plugin =
  name: "jshtml.plugin"
  attach: attach