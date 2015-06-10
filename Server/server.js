/**
 *
 * server.js
 * Node.js Server
 *
 */

var app = require('http').createServer(handler),
	io = require('socket.io')(app),
	static = require('node-static'),
	fs = new static.Server('../WebDesktopClient/');

// If the URL of the server is opened in a browser.
function handler(request, response)
{
	request.addListener('end', function() {
		fs.serve(request, response);
	}).resume();
}

app.listen(12345);

console.log('Server started.');


//var numFramesReceived = 0;

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
		//numFramesReceived++;
		//if (numFramesReceived == 1)
		//{
		//	console.log(data);
		//}
		//console.log('Video frame received: ' + numFramesReceived);

		socket.broadcast.emit('DroneVideoFrame', data);
	});
	
	
	/* COMMANDS */
	
	socket.on('Command', function(data)
	{
		console.log('Command: ' + data);
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

	socket.on('DronePhoto', function(data))
	{
		console.log('DronePhoto ' + data);
		socket.broadcast.emit('DronePhoto', data);
	}
});
