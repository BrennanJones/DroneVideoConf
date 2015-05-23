/**
 *
 * server.js
 * Node.js Server
 *
 * Last modified: 9 April 2015
 *
 */

var app = require('http').createServer(handler),
	io = require('socket.io').listen(app),
	static = require('node-static');

var fileServer = new static.Server('../WebDesktopClient/');

//var frameEchoed = false;
//var numFramesReceived = 0;

app.listen(12345);

// If the URL of the server is opened in a browser.
function handler(request, response)
{
	request.addListener('end', function() {
		fileServer.serve(request, response);
	}).resume();
}

// Comment this line to see debug messages.
io.set('log level', 1);

io.sockets.on('connection', function(socket)
{	
	console.log('A user connected.');
	socket.on('disconnect', function()
	{
		console.log('A user disconnected.');
	});
	
	
	/**
	 * SOCKET MESSAGE HANDLERS
	 */
	
	/* DEBUGGING */
	
	socket.on('Echo', function(data)
	{
		console.log(data.echo);
	});
	
	
	/* CONNECTION */
	
	socket.on('MobileClientConnect', function(data)
	{
		// do stuff here
	});
	
	socket.on('DesktopClientConnect', function(data)
	{
		// do stuff here
	});
	
	
	/* VIDEO */
	
	socket.on('DroneVideoFrame', function(data)
	{
		/*
		if (!frameEchoed)
		{
			frameEchoed = true;
			//console.log(data.videoData);
		}
		*/
		//numFramesReceived++;
		//console.log('Video frame received: ' + numFramesReceived);
		socket.broadcast.emit('DroneVideoFrame', data);
	});
	
	
	/* COMMANDS */
	
	socket.on('Command', function(data)
	{
		console.log('Command: ' + data.command);
		socket.broadcast.emit('Command', data);
	});
	
	socket.on('CommandAcknowledged', function(data)
	{
		console.log('Command acknowledged: ' + data.command);
		socket.broadcast.emit('CommandAcknowledged', data);
	});
	
	socket.on('EndCommand', function(data)
	{
		console.log('Command ended.');
		socket.broadcast.emit('EndCommand', data);
	});
});