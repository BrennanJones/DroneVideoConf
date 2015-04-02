/**
 *
 * server.js
 * Node.js Server
 *
 * Last modified: 29 March 2015
 *
 */

var app = require('http').createServer(handler),
	io = require('socket.io').listen(app),
	static = require('node-static');

var fileServer = new static.Server('../WebDesktopClient/');

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
		socket.broadcast.emit('DroneVideoFrame', data);
	});
	
	
	/* COMMANDS */
	
	socket.on('PanLeft', function(data)
	{
		console.log('PanLeft');
		socket.broadcast.emit('PanLeft', data);
		socket.emit('PanLeft', data);
	});
	
	socket.on('PanRight', function(data)
	{
		console.log('PanRight');
		socket.broadcast.emit('PanRight', data);
		socket.emit('PanRight', data);
	});
	
	socket.on('ZoomIn', function(data)
	{
		console.log('ZoomIn');
		socket.broadcast.emit('ZoomIn', data);
		socket.emit('ZoomIn', data);
	});
	
	socket.on('ZoomOut', function(data)
	{
		console.log('ZoomOut');
		socket.broadcast.emit('ZoomOut', data);
		socket.emit('ZoomOut', data);
	});
	
	socket.on('ElevateUp', function(data)
	{
		console.log('ElevateUp');
		socket.broadcast.emit('ElevateUp', data);
		socket.emit('ElevateUp', data);
	});
	
	socket.on('ElevateDown', function(data)
	{
		console.log('ElevateDown');
		socket.broadcast.emit('ElevateDown', data);
		socket.emit('ElevateDown', data);
	});
	
	socket.on('Freeze', function(data)
	{
		console.log('Freeze');
		socket.broadcast.emit('Freeze', data);
		socket.emit('Freeze', data);
	});
});
