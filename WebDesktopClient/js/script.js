/**
 *
 * script.js
 * Main JavaScript code for DVC web client
 *
 * Written by Brennan Jones
 *
 * Last modified: 29 March 2015
 *
 */


var panLeftButton;
var panRightButton;
var zoomInButton;
var zoomOutButton;
var elevateUpButton;
var elevateDownButton;
var freezeButton;


jQuery(function()
{
	/* NOTE: Change this to the server's IP address / domain name and any port number you'd like.
	    (Maybe grab server information dynamically later.) */
	// var url = "http://10.11.78.44:8080";
	var url = "http://127.0.0.1:12345";
	
	var socket = io.connect(url);
	
	var doc = jQuery(document),
	    win = jQuery(window);
	
	
	panLeftButton = jQuery('#panLeftButton'),
	panRightButton = jQuery('#panRightButton'),
	zoomInButton = jQuery('#zoomInButton'),
	zoomOutButton = jQuery('#zoomOutButton'),
	elevateUpButton = jQuery('#elevateUpButton'),
	elevateDownButton = jQuery('#elevateDownButton'),
	freezeButton = jQuery('#freezeButton');
	
	panLeftButton.on('click', function() {		
		// Send clear message to server.
		socket.emit('PanLeft', {});
	});
	
	panRightButton.on('click', function() {		
		// Send clear message to server.
		socket.emit('PanRight', {});
	});
	
	zoomInButton.on('click', function() {		
		// Send clear message to server.
		socket.emit('ZoomIn', {});
	});
	
	zoomOutButton.on('click', function() {		
		// Send clear message to server.
		socket.emit('ZoomOut', {});
	});
	
	elevateUpButton.on('click', function() {		
		// Send clear message to server.
		socket.emit('ElevateUp', {});
	});
	
	elevateDownButton.on('click', function() {		
		// Send clear message to server.
		socket.emit('ElevateDown', {});
	});
	
	freezeButton.on('click', function() {		
		// Send clear message to server.
		socket.emit('Freeze', {});
	});
	
	
	var defaultConfig = {
        filter: "original",
        filterHorLuma: "optimized",
        filterVerLumaEdge: "optimized",
        getBoundaryStrengthsA: "optimized"
    };
		
	var div = jQuery('#videoFrameContainer');
	var canvas = document.createElement('canvas');
	canvas.style.background = 'black';
	var size = new Size(640, 368);
	var webGLCanvas = new YUVWebGLCanvas(canvas, size);
	div.append(canvas);
	
	var avc = new Avc();
	avc.configure(defaultConfig);
	avc.onPictureDecoded = function (buffer, width, height)
	{
		//console.log("onPictureDecoded: W: " + width + " H: " + height);
		
		// Paint decoded buffer.
		if (!buffer) {
            return;
        }
        var lumaSize = width * height;
        var chromaSize = lumaSize >> 2;

        webGLCanvas.YTexture.fill(buffer.subarray(0, lumaSize));
        webGLCanvas.UTexture.fill(buffer.subarray(lumaSize, lumaSize + chromaSize));
        webGLCanvas.VTexture.fill(buffer.subarray(lumaSize + chromaSize, lumaSize + 2 * chromaSize));
        webGLCanvas.drawScene();
	};
	
	
	/**
	 * SOCKET MESSAGE HANDLERS
	 */
	
	/* VIDEO */
	
	socket.on('DroneVideoFrame', function(data)
	{
		avc.decode(data.data);
	});
	
	/* COMMANDS */
	
	socket.on('PanLeft', function(data)
	{
		resetButtons();
		panLeftButton.className = "btn btn-primary";
	});
	
	socket.on('PanRight', function(data)
	{
		resetButtons();
		panRightButton.className = "btn btn-primary";
	});
	
	socket.on('ZoomIn', function(data)
	{
		resetButtons();
		zoomInButton.className = "btn btn-primary";
	});
	
	socket.on('ZoomOut', function(data)
	{
		resetButtons();
		zoomOutButton.className = "btn btn-primary";
	});
	
	socket.on('ElevateUp', function(data)
	{
		resetButtons();
		elevateUpButton.className = "btn btn-primary";
	});
	
	socket.on('ElevateDown', function(data)
	{
		resetButtons();
		elevateDownButton.className = "btn btn-primary";
	});
	
	socket.on('Freeze', function(data)
	{
		resetButtons();
		freezeButton.className = "btn btn-primary";
	});
});


/**
 * UTILITY FUNCTIONS
 */

resetButtons = function()
{
	panLeftButton.className = "btn btn-default";
	panRightButton.className = "btn btn-default";
	zoomInButton.className = "btn btn-default";
	zoomOutButton.className = "btn btn-default";
	elevateUpButton.className = "btn btn-default";
	elevateDownButton.className = "btn btn-default";
	freezeButton.className = "btn btn-default";
}
