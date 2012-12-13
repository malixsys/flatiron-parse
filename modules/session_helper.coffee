util         =  require("util")

merge = (options, overrides) ->
  extend (extend {}, options), overrides
  
extend = exports.extend = (object, properties) ->
  for key, val of properties
    object[key] = val
  object

exports.redirect_with_error_number = (req, res, number, location) ->
  req.session.flash = 
    type: 'error',
    message: req.url + "#" + number
  req.session.save (err) =>  
    console.log "[SESSION.SAVE.ERROR] #{util.inspect(err)}"
    res.writeHead 302,
      Location: location
    res.end()
    
exports.redirect_with_success_number  = (req, res, number, location) ->
  req.session.flash = 
    type: 'success',
    message: req.url + "#" + number
  req.session.save (err) =>  
    if err
      console.log "[SESSION.SAVE.ERROR] #{util.inspect(err)}"
    res.writeHead 302,
      Location: location
    res.end()

# cheap flash support for now...
flashes = 
  "success#/login#0": "Login successful!"
  "success#/logout#0": "Logout successful!"
  "error#/login#1": "ERROR: Problem with database. Please try again or contact your administrator..."
  "error#/login#2": "ERROR: Invalid username or password!"
  
get_flash = (flash) ->
  return "" unless flash
  key = flash.type + "#" + flash.message
  if flashes[key]
    return flashes[key]
  return "??" + key

exports.view_locals = (req, locals, done) ->
  info = 
    flash: get_flash(req.session.flash),
    user: req.session.user,
    version: '0.0.1'
    
  delete req.session.flash
  options = merge locals, info
  req.session.save (err) =>  
    if err
      console.log "[SESSION.SAVE.ERROR] #{util.inspect(err)}"
    done(options)
  