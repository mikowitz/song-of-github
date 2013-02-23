express = require 'express'
routes  = require './routes'
http    = require 'http'
https   = require 'https'
path    = require 'path'
async   = require 'async'
coffee  = require 'coffee-script'

app = express()

app.configure () ->
  app.set 'port', (process.env.PORT || 4000)
  app.set 'views', (__dirname + '/views')
  app.set 'view engine', 'hjs'
  app.use express.favicon()
  app.use express.logger('dev')
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use require('less-middleware')({ src: __dirname + '/public' })
  app.use express.static(path.join(__dirname, 'public'))
  
app.configure 'development', () ->
  app.use express.errorHandler()
  
getGitHubData = (name) ->
  (callback) ->
    url = "https://github.com/users/#{name}/contributions_calendar_data"
    https.get url, (response) ->
      console.log(response.statusCode)
      if response.statusCode.toString() == '200'
        response.on 'data', (d) ->
          callback null, d
      else
        callback null, 'invalid'
 
app.get '/', (req, res) ->
  if req.query.username
    names = req.query.username.replace(/\s/g, '').split(',')
    allQueries = []
    validNames = []
    invalidNames = []
    for name in names
      allQueries.push getGitHubData(name)

    async.parallel allQueries, (err, results) ->
      returning = []
      for i of names
        if results[i] != 'invalid'
          returning.push({
            key: names[i],
            value: results[i]
          })
          validNames.push names[i]
        else
          invalidNames.push names[i]
          
      res.render 'index', {
        calendarData: returning,
        names: validNames, anyValidNames: validNames.length > 0,
        namesString: validNames.join(','), invalidNames: invalidNames.join(','),
        embeddable: req.query.embeddable
      }
  else
    res.render 'index'

http.createServer(app).listen app.get('port'), () ->
  console.log "Express server listening on port #{app.get('port')}"
