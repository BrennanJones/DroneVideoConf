/**
 *
 * server.js
 * Node.js Server
 *
 * Last modified: 20 March 2015
 *
 */

var app = require('http').createServer(handler),
    io = require('socket.io').listen(app),
	static = require('node-static');

var fileServer = new static.Server('./');

app.listen(12345);

// If the URL of the server is opened in a browser.
function handler(request, response)
{
	request.addListener('end', function() {
		fileServer.serve(request, response);
	});
}

// Comment this line to see debug messages.
io.set('log level', 1);

io.sockets.on('connection', function(socket)
{	
	console.log('connection');
	
	/* HANDLERS */
	
	socket.on('Echo', function(data)
	{
		console.log(data.echo);
	});
	
	socket.on('MobileClientConnect', function(data)
	{
		// do stuff here
	});
	
	socket.on('DesktopClientConnect', function(data)
	{
		// do stuff here
	});
	
	socket.on('DroneVideoFrame', function(data)
	{
		// do stuff here
	});
});
