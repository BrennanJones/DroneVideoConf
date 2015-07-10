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
	var url = "http://" + window.location.hostname + ":12345";
	
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
	
	
	var div = jQuery('.videoFrameContainer');
	var canvas = document.createElement('canvas');
	canvas.className = 'videoFrameCanvas';
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
		
		var binary = '';
		var bytes = new Uint8Array(data);
		var len = bytes.byteLength;
		for (var i = 0; i < len; i++)
		{
			binary += String.fromCharCode(bytes[i]);
		}
		
		var div = jQuery('.cover-container');
		var img = document.createElement('img');
		img.src = "data:image/jpg;base64," + window.btoa(binary);
		img.className = 'cover-item';
		div.prepend(img);
	});


	/**
	 * PHONE VIDEO CHAT
	 */

	var phoneVideo = jQuery('.phoneVideo');
	var desktopVideo = jQuery('.desktopVideo');
	var remoteStream;

	// Compatibility shim
    navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia;

    // PeerJS object
    var peer = new Peer('0', { key: 's51s84ud22jwz5mi', debug: 3 });

    peer.on('open', function()
    {
    	//$('#my-id').text(peer.id);
    });

    // Receiving a call
    peer.on('call', function(call)
    {
	    // Answer the call automatically (instead of prompting user) for demo purposes
	    call.answer(window.localStream);
	    step3(call);
    });
    peer.on('error', function(err)
    {
	    alert(err.message);
	    // Return to step 2 if error occurs
	    step2();
    });

    step1();

    function step1 ()
    {
	    // Get audio/video stream
	    navigator.getUserMedia({audio: true, video: true}, function(stream)
	    {
		    // Set your video displays
		    desktopVideo.prop('src', URL.createObjectURL(stream));

		    window.localStream = stream;
		    step2();
	    },
	    function()
	    {
	    	//$('#step1-error').show();
	    });
    }

    function step2 ()
    {
    	//$('#step1, #step3').hide();
    	//$('#step2').show();
    }

    function step3 (call)
    {
	    // Hang up on an existing call if present
	    if (window.existingCall)
	    {
	    	window.existingCall.close();
	    }

	    // Wait for stream on the call, then set peer video display
	    call.on('stream', function(stream)
	    {
	    	phoneVideo.prop('src', URL.createObjectURL(stream));
	    	remoteStream = stream;

	    	stream.onaddtrack = function()
	    	{
	    		console.log("onaddtrack");
	    	};

	    	stream.onremovetrack = function()
	    	{
	    		console.log("onremovetrack");
	    	};
	    });

	    // UI stuff
	    window.existingCall = call;
	    //$('#their-id').text(call.peer);
	    call.on('close', step2);
	    //$('#step1, #step2').hide();
	    //$('#step3').show();
    }
});
