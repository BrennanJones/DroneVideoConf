/**
 *
 * script.js
 * Main JavaScript code for DVC web client
 *
 * Written by Brennan Jones
 *
 */


jQuery(function()
{
	/* NOTE: Change this to the server's IP address / domain name and any port number you'd like.
	    (Maybe grab server information dynamically later.) */
	// var url = "http://10.11.78.44:8080";
	var url = "http://127.0.0.1:12345";
	
	var socket = io.connect(url);
	
	var doc = jQuery(document),
	    win = jQuery(window);
	
	//var numFramesReceived = 0;
	
	var peer = new Peer({key: 'lwjd5qra8257b9'});
	
	
	var panLeftButton = jQuery('#panLeftButton');
	var panRightButton = jQuery('#panRightButton');
	var zoomInButton = jQuery('#zoomInButton');
	var zoomOutButton = jQuery('#zoomOutButton');
	var elevateUpButton = jQuery('#elevateUpButton');
	var elevateDownButton = jQuery('#elevateDownButton');
	
	var currentCommandText = document.getElementById('currentCommandText');
	
	panLeftButton.on('click', function() {		
		socket.emit('Command', { 'command': 'PanLeft' });
	});
	
	panRightButton.on('click', function() {		
		socket.emit('Command', { 'command': 'PanRight' });
	});
	
	zoomInButton.on('click', function() {		
		socket.emit('Command', { 'command': 'ZoomIn' });
	});
	
	zoomOutButton.on('click', function() {		
		socket.emit('Command', { 'command': 'ZoomOut' });
	});
	
	elevateUpButton.on('click', function() {		
		socket.emit('Command', { 'command': 'ElevateUp' });
	});
	
	elevateDownButton.on('click', function() {		
		socket.emit('Command', { 'command': 'ElevateDown' });
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
		//numFramesReceived++;
		//console.log('Video frame received: ' + numFramesReceived);
		
		/*
		for (var i = 0; i < 4; i++)
			avc.decode(data.videoData[i]);
		*/
		avc.decode(data.videoData);
	});
	
	/* COMMANDS */
	
	socket.on('CommandAcknowledged', function(data)
	{
		console.log('Command acknowledged: ' + data.command);
		
		// Reset the buttons.
		panLeftButton.css({"background-color":""}).css({"background-color":"#FFFFFF"});
		panRightButton.css({"background-color":""}).css({"background-color":"#FFFFFF"});
		zoomInButton.css({"background-color":""}).css({"background-color":"#FFFFFF"});
		zoomOutButton.css({"background-color":""}).css({"background-color":"#FFFFFF"});
		elevateUpButton.css({"background-color":""}).css({"background-color":"#FFFFFF"});
		elevateDownButton.css({"background-color":""}).css({"background-color":"#FFFFFF"});
		
		switch(data.command)
		{
			case 'PanLeft':
				panLeftButton.css({"background-color":""}).css({"background-color":"lightgray"});
				currentCommandText.innerHTML = "<p>Left (CW) circular track underway.</p>";
				break;
			case 'PanRight':
				panRightButton.css({"background-color":""}).css({"background-color":"lightgray"});
				currentCommandText.innerHTML = "<p>Right (CCW) circular track underway.</p>";
				break;
			case 'ZoomIn':
				zoomInButton.css({"background-color":""}).css({"background-color":"lightgray"});
				currentCommandText.innerHTML = "<p>Track in underway.</p>";
				break;
			case 'ZoomOut':
				zoomOutButton.css({"background-color":""}).css({"background-color":"lightgray"});
				currentCommandText.innerHTML = "<p>Track out underway.</p>";
				break;
			case 'ElevateUp':
				elevateUpButton.css({"background-color":""}).css({"background-color":"lightgray"});
				currentCommandText.innerHTML = "<p>Elevate up underway.</p>";
				break;
			case 'ElevateDown':
				elevateDownButton.css({"background-color":""}).css({"background-color":"lightgray"});
				currentCommandText.innerHTML = "<p>Elevate down underway.</p>";
				break;
			default:
				break;
		}
		
		// Disable the buttons.
		panLeftButton.attr('disabled', true);
		panRightButton.attr('disabled', true);
		zoomInButton.attr('disabled', true);
		zoomOutButton.attr('disabled', true);
		elevateUpButton.attr('disabled', true);
		elevateDownButton.attr('disabled', true);
	});
	
	socket.on('EndCommand', function(data)
	{
		// Reset the buttons.
		panLeftButton.css({"background-color":""}).css({"background-color":"#FFFFFF"});
		panRightButton.css({"background-color":""}).css({"background-color":"#FFFFFF"});
		zoomInButton.css({"background-color":""}).css({"background-color":"#FFFFFF"});
		zoomOutButton.css({"background-color":""}).css({"background-color":"#FFFFFF"});
		elevateUpButton.css({"background-color":""}).css({"background-color":"#FFFFFF"});
		elevateDownButton.css({"background-color":""}).css({"background-color":"#FFFFFF"});
		
		// Re-enable the buttons.
		panLeftButton.attr('disabled', false);
		panRightButton.attr('disabled', false);
		zoomInButton.attr('disabled', false);
		zoomOutButton.attr('disabled', false);
		elevateUpButton.attr('disabled', false);
		elevateDownButton.attr('disabled', false);
		
		currentCommandText.innerHTML = "<p></p>";
	});
	
	
	/**
	 * PEERJS WEBRTC HANDLERS
	 */
	
	peer.on('open', function(id) {
		console.log('My peer ID is: ' + id);
	});
});
