Hapi = require 'hapi'
status = require 'hapi-status'
http = require 'q-io/http'

player_uri = "http://localhost:8042"

scores = {}

server = new Hapi.Server()

server.connection(
  {
    host: 'localhost'
    port: '8043'
  }
)

server.route(
  {
    method: 'POST'
    path: '/score'
    handler: (request, reply) ->
      body = request.payload
      playername = body.name
      http.request("#{player_uri}/player/#{playername}")
      .then( (response) =>
        if response.status == 200
          scr = scores[ "#{playername}" ]
          if scr
            scr.push(body.score)
          else
            scores[ "#{playername}" ] = [ body.score ]

          reply( { "#{playername}": scores[ playername ] } )
        else if response.status == 404
          status.badRequest(reply, "Player does not exist")
        else
          status.serviceUnavailable(reply, "Player service is down")
      )
      .catch( (err) =>
        console.log err
        status.internalServerError(reply)
      )
  }
)

server.route(
  {
    method: 'GET'
    path: '/score/{playername}'
    handler: (request, reply) ->
      playername = request.params.playername
      scr = scores[playername] || []
      reply(scr)
  }
)

server.start( (err) =>
    throw err if err
    console.log("Score Service launched at #{server.info.uri}");
)