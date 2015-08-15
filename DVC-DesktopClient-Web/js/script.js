/**
 *
 * script.js
 * Main JavaScript code for DVC web client
 *
 */


jQuery(function()
{
	var url = "http://" + window.location.hostname + ":8081";
	
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

	/* DRONE STATUSES */

	socket.on('DroneConnectionUpdate', function(droneConnectionState)
	{
		console.log('DroneConnectionUpdate: ' + droneConnectionState);

		if (!droneConnectionState)
	    {
	    	jQuery('.droneVideoFrameTitle').show();
	    }
	});

	socket.on('DroneBatteryUpdate', function(newBatteryPercentage)
	{
		console.log('DroneBatteryUpdate: ' + newBatteryPercentage);

		jQuery('.droneBatteryStatus').html("<p>Battery: " + newBatteryPercentage + "%</p>");
		if (newBatteryPercentage <= 20)
		{
			if (newBatteryPercentage <= 10)
			{
				jQuery('.droneBatteryStatus p').css('color', 'red');
			}
			else
			{
				jQuery('.droneBatteryStatus p').css('color', 'orange');
			}
		}
	});

	socket.on('DroneCameraUpdate', function(newCameraPosition)
	{
		console.log('DroneCameraUpdate: pan: ' + newCameraPosition['pan'] + ', tilt: ' + newCameraPosition['tilt']);

		var leftPercent = 50 - newCameraPosition['pan'];
		var topPercent = 50 + newCameraPosition['tilt'];
		jQuery('.crosshair p').css('left', leftPercent + '%').css('left', '-=33px');
		jQuery('.crosshair p').css('top', topPercent + '%').css('top', '-=33px');
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
	});


	/**
	 * PHONE VIDEO CHAT
	 */

	/*
	var numLocalAudioFiles = 0,
		numLocalVideoFiles = 0,
		numRemoteAudioFiles = 0,
		numRemoteVideoFiles = 0;

	var localAudioFiles = {},
		localVideoFiles = {},
		remoteAudioFiles = {},
		remoteVideoFiles = {};

	var localVideoRecorder;
	var remoteVideoRecorder;
	*/

	// Compatibility shim
    navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia;

    var peer;
    var videoChatWindow;
    //var savedFilesWindow;

    // PeerJS object
    //var peer = new Peer('0', { key: 's51s84ud22jwz5mi', debug: 3 });
    peer = new Peer(
    	{ host: window.location.hostname, port: 9001, path: '/dvc', secure: false, debug: 3 },
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

    videoChatWindow = window.open('video_chat_window.html', 'secondary', 'width=640,height=480');
    
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
	    		videoChatWindow.remoteStream = stream;

	    		/*
	    		localVideoRecorder = new MultiStreamRecorder(videoChatWindow.localStream);
			    localVideoRecorder.video = videoChatWindow.desktopVideo;
			    localVideoRecorder.audioChannels = 1;
			    localVideoRecorder.ondataavailable = function (blobs)
			    {
			        localAudioFiles[numLocalAudioFiles++] = blobs.audio;
			        localVideoFiles[numLocalVideoFiles++] = blobs.video;
			    };
			    localVideoRecorder.start(60 * 60 * 1000);	// 60 minutes

			    remoteVideoRecorder = new MultiStreamRecorder(videoChatWindow.remoteStream);
			    localVideoRecorder.video = videoChatWindow.phoneVideo
			    remoteVideoRecorder.audioChannels = 1;
			    remoteVideoRecorder.ondataavailable = function (blobs)
			    {
			        remoteAudioFiles[numRemoteAudioFiles++] = blobs.audio;
			        remoteVideoFiles[numRemoteVideoFiles++] = blobs.video;
			    };
			    remoteVideoRecorder.start(60 * 60 * 1000);	// 60 minutes
			    */
	    	}
	    });

	    videoChatWindow.existingCall = call;
	    call.on('close', function() {
	    	//localVideoRecorder.stop();
	    	//remoteVideoRecorder.stop();
	    });
    }


    /**
     * WINDOW CLOSING
     */

    videoChatWindow.onbeforeunload = function (e)
	{
	    //localVideoRecorder.stop();
	    //remoteVideoRecorder.stop();

	    videoChatWindow.existingCall.close();
	};

    window.onbeforeunload = function (e)
    {
	    /*e = e || window.event;

	    var message = 'Are you sure you want to leave this page?';

	    // For IE and Firefox prior to version 4
	    if (e) {
	        e.returnValue = message;
	    }

	    // For Safari
	    return message;*/

	    if (videoChatWindow)
    	{
    		videoChatWindow.close();
    	}

	    /*savedFilesWindow = window.open('saved_files_window.html', 'secondary', 'width=640,height=480');

	    var i;
	    for (i = 0; i < numLocalAudioFiles; i++)
	    {
	    	appendLink(localAudioFiles[i], 'localAudio' + i);
	    }
	    for (i = 0; i < numLocalVideoFiles; i++)
	    {
	    	appendLink(localVideoFiles[i], 'localVideo' + i);
	    }
	    for (i = 0; i < numRemoteAudioFiles; i++)
	    {
	    	appendLink(remoteAudioFiles[i], 'remoteAudio' + i);
	    }
	    for (i = 0; i < numRemoteVideoFiles; i++)
	    {
	    	appendLink(remoteVideoFiles[i], 'remoteVideo' + i);
	    }*/
	};

	/*function appendLink(blob, name)
	{
        var a = document.createElement('a');
        a.target = '_blank';
        a.innerHTML = 'Open Recorded (name: ' + name + ') ' + (blob.type == 'audio/ogg' ? 'Audio' : 'Video') + ' No. ' + (index++) + ' (Size: ' + bytesToSize(blob.size) + ') Time Length: ' + getTimeLength(timeInterval);
        a.href = URL.createObjectURL(blob);
        savedFilesWindow.fileListContainer.appendChild(a);
        savedFilesWindow.fileListContainer.appendChild(document.createElement('hr'));
    }*/
});
