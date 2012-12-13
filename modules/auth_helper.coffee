passwordHash = require('password-hash')

exports.login = (app, login, password, done) ->
    app.parse.find "Users", {login: login}, (err, data) ->
      if err
        return done(1)

      unless data and data.results and data.results.length and data.results[0]
        return done(2)

      found_user = data.results[0]
      unless passwordHash.verify password, found_user.password
        return done(2)

      return done(null,found_user)

