util = require("util")
inspect = util.inspect
log = (obj) ->
  console.log "[PARSE] #{inspect(obj)}"
fs = require('fs')

class SessionImageCache
  @is_same: (req, url) ->
    noneMatchHeader = req.headers['if-none-match']
    unless noneMatchHeader
      return false

    urls = req.session.image_cache
    unless urls
      return false

    etag = urls[url]
    return noneMatchHeader is etag

  @store: (req, url) ->
    noneMatchHeader = req.headers['if-none-match']
    unless noneMatchHeader
      return
    urls = req.session.image_cache or {}
    urls[url] = noneMatchHeader
    req.session.image_cache = urls

class Parse
  constructor: (application_id, master_key) ->
    @application_id = application_id
    @master_key = master_key
    @api_protocol = request = require('request')
    @api_host = "api.parse.com"
    @api_port = 443
    #if process.env.http_proxy
    #  proxy = require('./proxy')
    #  parts = process.env.http_proxy.replace('http://','').split(':')
    #  @agent = proxy.createAgent(parts[0],parts[1])
    #else
    @agent = false

  parseRequest: (method, path, data, callback) ->
    auth = "Basic " + new Buffer(@application_id + ":" + @master_key).toString("base64")
    headers =
      Authorization: auth
      Connection: "Keep-alive"

    options =
      method: method
      uri: "https://api.parse.com:443" + path
      headers: headers
      json: method isnt "FILE"

    switch method
      when "GET"
        options.qs = data if data
      when "POST", "PUT"
        options.body = JSON.stringify(data)
        options.headers["Content-type"] = "application/json"
        options.headers["Content-length"] = options.body.length
      when "DELETE"
        options.headers["Content-length"] = 0
      when "FILE"
        options.method = "POST"
        options.headers["Content-length"] = data.size
        options.headers["Content-type"] = data.type
        options.body = fs.readFileSync(data.path)
        data = false
      else
        throw new Error("Unknown method, \"" + method + "\"")

    if @agent
      options.agent = @agent
    #options.tunnel = true

    msg = "[PARSE][#{method}] Calling #{options.uri}%s ->\n\t%s"
    console.log(msg, (if options.agent then ' with proxy' else ''), (if data then util.inspect(data) else ''))
    try
      req = @api_protocol(options, (error, res, body) ->
        unless callback
          callback = (err,body) ->
            {}

        if error
          console.log "[PARSE][ERROR] " + error
          return callback(error)

        if res.statusCode < 200 or res.statusCode >= 300
          msg = "HTTP error " + res.statusCode
          console.log "[PARSE][ERROR] " + msg
          err = new Error(msg)
          err.arguments = arguments
          err.type = res.statusCode
          err.options = options
          err.body = body
          return callback(err)

        #console.log "[PARSE][OK] #{util.inspect(body).replace("\n", " ")}"
        callback null, body
      )
    catch exc
      callback(exc)

  insert: (className, object, callback) ->
    this.parseRequest.call this, "POST", "/1/classes/" + className, object, callback

  list: (className, callback) ->
    this.parseRequest.call this, "GET", "/1/classes/" + className, null, callback

  find: (className, query, paging, callback) ->
    unless callback
      callback = paging
      paging = null
    if typeof query is "string"
      this.parseRequest.call this, "GET", "/1/classes/" + className + "/" + query, null, callback
    else
      obj =
        where: JSON.stringify(query)
      if paging
        obj.limit = paging.limit
      this.parseRequest.call this, "GET", "/1/classes/" + className, obj, callback

  update: (className, objectId, object, callback) ->
    this.parseRequest.call this, "PUT", "/1/classes/" + className + "/" + objectId, object, callback

  delete: (className, objectId, callback) ->
    this.parseRequest.call this, "DELETE", "/1/classes/" + className + "/" + objectId, null, callback

  uploadFile: (file_info, callback) ->
    this.parseRequest.call this, "FILE", "/1/files/#{file_info.name}", file_info, callback

  deleteFile: (name, callback) ->
    this.parseRequest.call this, "DELETE", "/1/files/#{name}", null, callback

  sendFile: (url, req, res) ->
    if @agent
      #options.agent = @agent
      return res.redirect 303, url

    try

      if SessionImageCache.is_same(req, url)
        log
          send: url
          cache: req.session.image_cache
          status: 304
        return res.send 304

      @api_protocol(url).pipe(res)
      SessionImageCache.store(req, url)
      log
        send: url
        cache: req.session.image_cache
        status: 200

    catch exc
      console.log "[PARSE][SEND_FILE] Exception: #{util.inspect(exc)}"
      res.send 500

  now_id: ->
    now = new Date();
    jsonDate = now.toJSON()
    return jsonDate

  noop: (className, object, callback) ->
    callback(null, 'NOOP:' + JSON.stringify(object) )

attach = (options) ->
  self = this
  self.parse = new Parse(process.env.ParseApplicationId, process.env.ParseMasterKey) # Set in your environment

exports.plugin =
  name: "parse.plugin"
  attach: attach