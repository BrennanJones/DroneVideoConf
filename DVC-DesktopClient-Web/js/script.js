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
	
	camLeftButton.on('click', function()
	{
		socket.emit('Command', 'CamLeft');
	});

	camRightButton.on('click', function()
	{
		socket.emit('Command', 'CamRight');
	});

	camUpButton.on('click', function()
	{
		socket.emit('Command', 'CamUp');
	});

	camDownButton.on('click', function()
	{
		socket.emit('Command', 'CamDown');
	});

	jQuery('body').keydown(function(e)
	{
		if (e.which == 37) // left
		{
	    	socket.emit('Command', 'CamLeft');
	  	}
	  	else if (e.which == 39) // right
	  	{
	    	socket.emit('Command', 'CamRight');
	  	}
	  	else if (e.which == 38) // up
	  	{
	  		socket.emit('Command', 'CamUp');
	  	}
	  	else if (e.which == 40) // down
	  	{
	  		socket.emit('Command', 'CamDown');
	  	}
	});
	
	
	var div = jQuery('.droneVideoFrameContainer');
	var canvas = document.createElement('canvas');
	canvas.className = 'droneVideoFrameCanvas';
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

	/* CONNECTION */

	socket.on('connect', function()
	{
		console.log('socket.io connected');

		socket.emit('DesktopClientConnect', null);
	});

	socket.on('disconnect', function()
	{
		console.log('socket.io disconnected');

		alert("Connection with server failed.")
	});

	/* PEER */

	socket.on('CallCommand', function(mobileClientPeerID)
	{
		console.log('CallCommand');

		// Wait 8 seconds, then try calling the mobile client.
		setTimeout(function () {
    		var call = peer.call(mobileClientPeerID, videoChatWindow.localStream);
			step3(call);
    	}, 8000);
	});
	
	/* VIDEO */
	
	socket.on('DroneVideoFrame', function(data)
	{
		avc.decode(new Uint8Array(data));
		jQuery('.droneVideoFrameTitle').hide();
	});
	
	/* SEQUENTIAL PHOTOS */
	
	socket.on('DronePhoto', function(data)
	{
		console.log('DronePhoto');
		
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

	/* OTHER */

	socket.on('ClientDisconnect', function(clientType)
	{
		console.log('ClientDisconnect: ' + clientType);

		if (clientType == 'Mobile')
	    {
	    	jQuery('.droneVideoFrameTitle').show();

	    	if (videoChatWindow.existingCall)
	    	{
		    	videoChatWindow.existingCall.close();
		    }
	    }
	})


	/**
	 * PHONE VIDEO CHAT
	 */

	// Compatibility shim
    navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia;

    var peer;
    var videoChatWindow;

    // PeerJS object
    //var peer = new Peer('0', { key: 's51s84ud22jwz5mi', debug: 3 });
    peer = new Peer(
    	{ host: window.location.hostname, port: 9876, path: '/dvc', secure: false, debug: 3 },
    	{ config: {'iceServers': [
        	{
				url: 'turn:numb.viagenie.ca',
				credential: 'dvc',
				username: 'brennandgj@gmail.com',
				password: 'dvcchat'
    		}
    	]}});

    peer.on('open', function()
    {
    	console.log('open');
    });

    // Receiving a call
    peer.on('call', function(call)
    {
	    console.log('call');

	    call.answer(videoChatWindow.localStream);
	    step3(call);
    });
    
    peer.on('error', function(err)
    {
	    console.log("error");
	    
	    //alert(err.message);
	    step2();
    });

    window.onbeforeunload = function()
    {
    	if (videoChatWindow)
    	{
    		videoChatWindow.close();
    	}
	}
    videoChatWindow = window.open('video_chat_window.html','secondary','width=640,height=480');
    
    step1();

    function step1()
    {
	    // Get audio/video stream
	    navigator.getUserMedia({audio: true, video: true}, function(stream)
	    {
		    socket.emit('DesktopClientPeerID', peer.id);

		    if (videoChatWindow)
		    {
		    	// Set your video displays
			    videoChatWindow.desktopVideo.prop('src', URL.createObjectURL(stream));

			    videoChatWindow.localStream = stream;
			    step2();
		    }
	    },
	    function()
	    {
	    	console.log("step 1 error");
	    });
    }

    function step2()
    {
    	// ...
    }

    function step3(call)
    {
	    // Hang up on an existing call if present
	    if (videoChatWindow.existingCall)
	    {
	    	videoChatWindow.existingCall.close();
	    }

	    // Wait for stream on the call, then set peer video display
	    call.on('stream', function(stream)
	    {
	    	console.log('stream');

	    	if (videoChatWindow)
	    	{
	    		videoChatWindow.phoneVideo.prop('src', URL.createObjectURL(stream));
	    	}
	    });

	    videoChatWindow.existingCall = call;
	    call.on('close', step2);
    }
});
