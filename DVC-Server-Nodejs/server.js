/**
 *
 * server.js
 * Node.js Server
 *
 */

var app = require('http').createServer(handler),
	io = require('socket.io')(app),
	static = require('node-static'),
	fs = new static.Server('../DVC-DesktopClient-Web/'),
	filesystem = require('fs'),
	PeerServer = require('peer').PeerServer,
	server = PeerServer({port: 9876, path: '/dvc'});

// If the URL of the server is opened in a browser.
function handler(request, response)
{
	request.addListener('end', function() {
		fs.serve(request, response);
	}).resume();
}

app.listen(12345);

console.log('Server started.');


var numTimelinePhotosReceived = 0;

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
	
	socket.on('Command', function(data)
	{
		console.log('Command: ' + data);
		socket.broadcast.emit('Command', data);
	});

	socket.on('DronePhoto', function(data)
	{
		console.log('DronePhoto');

		filesystem.writeFile("./timelinePhotos/test" + numTimelinePhotosReceived++ + ".jpg", data, function(err) {
			if(err) {
		        return console.log(err);
		    }

		    console.log("The file was saved!");
		});

		socket.broadcast.emit('DronePhoto', data);
	});
});
