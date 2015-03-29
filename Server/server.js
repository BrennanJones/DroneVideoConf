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
	
	socket.on('PanLeftStart', function(data)
	{
		console.log('PanLeftStart');
		socket.broadcast.emit('PanLeftStart', data);
	});
	
	socket.on('PanLeftEnd', function(data)
	{
		console.log('PanLeftEnd');
		socket.broadcast.emit('PanLeftEnd', data);
	});
	
	socket.on('PanRightStart', function(data)
	{
		console.log('PanRightStart');
		socket.broadcast.emit('PanRightStart', data);
	});
	
	socket.on('PanRightEnd', function(data)
	{
		console.log('PanRightEnd');
		socket.broadcast.emit('PanRightEnd', data);
	});
	
	socket.on('ZoomInStart', function(data)
	{
		console.log('ZoomInStart');
		socket.broadcast.emit('ZoomInStart', data);
	});
	
	socket.on('ZoomInEnd', function(data)
	{
		console.log('ZoomInEnd');
		socket.broadcast.emit('ZoomInEnd', data);
	});
	
	socket.on('ZoomOutStart', function(data)
	{
		console.log('ZoomOutStart');
		socket.broadcast.emit('ZoomOutStart', data);
	});
	
	socket.on('ZoomOutEnd', function(data)
	{
		console.log('ZoomOutEnd');
		socket.broadcast.emit('ZoomOutEnd', data);
	});
});
