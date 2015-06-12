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
	/* NOTE: Change this to the server's IP address/domain name and any port number you'd like.
	    (Maybe grab server information dynamically later.) */
	// var url = "http://10.11.78.44:8080";
	var url = "http://127.0.0.1:12345";
	
	var socket = io.connect(url);
	
	var doc = jQuery(document),
	    win = jQuery(window);
	
	
	var camLeftButton = jQuery('#camLeftButton');
	var camRightButton = jQuery('#camRightButton');
	var camUpButton = jQuery('#camUpButton');
	var camDownButton = jQuery('#camDownButton');
	
	camLeftButton.on('click', function() {
		socket.emit('Command', 'CamLeft');
	});

	camRightButton.on('click', function() {
		socket.emit('Command', 'CamRight');
	});

	camUpButton.on('click', function() {
		socket.emit('Command', 'CamUp');
	});

	camDownButton.on('click', function() {
		socket.emit('Command', 'CamDown');
	});
	
	
	var div = jQuery('#videoFrameContainer');
	var canvas = document.createElement('canvas');
	canvas.style.cssText = "background:black; width: 960px; height: 532px;";
	var size = new Size(640, 368);
	var webGLCanvas = new YUVWebGLCanvas(canvas, size);
	div.append(canvas);
	
	var avc = new Avc();
	avc.configure({
        filter: "original",
        filterHorLuma: "optimized",
        filterVerLumaEdge: "optimized",
        getBoundaryStrengthsA: "optimized"
    });
	avc.onPictureDecoded = function(buffer, width, height)
	{
		console.log("onPictureDecoded: W: " + width + " H: " + height);
		
		// Paint decoded buffer.

		if (!buffer)
		{
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
		avc.decode(new Uint8Array(data));
	});
	
	/* SEQUENTIAL PHOTOS */
	
	socket.on('DronePhoto', function(data)
	{
		console.log("DronePhoto");
	});
});
