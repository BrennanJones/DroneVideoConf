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

jQuery(function()
{
	/* NOTE: Change this to the server's IP address / domain name and any port number you'd like.
	    (Maybe grab server information dynamically later.) */
	// var url = "http://10.11.78.44:8080";
	var url = "http://192.168.42.2:12345";
	
	var socket = io.connect(url);
	
	var doc = jQuery(document),
	    win = jQuery(window);
	
	
	var panLeftButton = jQuery('#panLeftButton'),
		panRightButton = jQuery('#panRightButton'),
		zoomInButton = jQuery('#zoomInButton'),
		zoomOutButton = jQuery('#zoomOutButton');
	
	panLeftButton.on('mousedown', function() {		
		// Send clear message to server.
		socket.emit('PanLeftStart', {});
	});
	panLeftButton.on('mouseup', function() {		
		// Send clear message to server.
		socket.emit('PanLeftEnd', {});
	});
	
	panRightButton.on('mousedown', function() {		
		// Send clear message to server.
		socket.emit('PanRightStart', {});
	});
	panRightButton.on('mouseup', function() {		
		// Send clear message to server.
		socket.emit('PanRightEnd', {});
	});
	
	zoomInButton.on('mousedown', function() {		
		// Send clear message to server.
		socket.emit('ZoomInStart', {});
	});
	zoomInButton.on('mouseup', function() {		
		// Send clear message to server.
		socket.emit('ZoomInEnd', {});
	});
	
	zoomOutButton.on('mousedown', function() {		
		// Send clear message to server.
		socket.emit('ZoomOutStart', {});
	});
	zoomOutButton.on('mouseup', function() {		
		// Send clear message to server.
		socket.emit('ZoomOutEnd', {});
	});
	
	
	var defaultConfig = {
        filter: "original",
        filterHorLuma: "optimized",
        filterVerLumaEdge: "optimized",
        getBoundaryStrengthsA: "optimized"
    };
		
	var div = jQuery('#videoFrameContainer');
	var canvas = document.createElement('canvas');
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
	
	
	/* SOCKET MESSAGE HANDLERS */
	
	socket.on('DroneVideoFrame', function(data)
	{
		//console.log('DroneVideoFrame received.');
		avc.decode(data.data);
	});
});
