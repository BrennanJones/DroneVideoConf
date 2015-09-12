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

	function camButtonPress(button)
	{
		if (button == 'left')
		{
			camLeftButton.css('opacity', 1.00);
			camLeftButton.css('content', 'url(/images/buttons/cam-arrows/left_highlighted.png)');
			socket.emit('Command', 'CamLeft');
		}
		else if (button == 'right')
		{
			camRightButton.css('opacity', 1.00);
			camRightButton.css('content', 'url(/images/buttons/cam-arrows/right_highlighted.png)');
			socket.emit('Command', 'CamRight');
		}
		else if (button == 'up')
		{
			camUpButton.css('opacity', 1.00);
			camUpButton.css('content', 'url(/images/buttons/cam-arrows/up_highlighted.png)');
			socket.emit('Command', 'CamUp');
		}
		else if (button == 'down')
		{
			camDownButton.css('opacity', 1.00);
			camDownButton.css('content', 'url(/images/buttons/cam-arrows/down_highlighted.png)');
			socket.emit('Command', 'CamDown');
		}

		setTimeout(function () {
    		camLeftButton.css('opacity', 0.5);
			camRightButton.css('opacity', 0.5);
			camUpButton.css('opacity', 0.5);
			camDownButton.css('opacity', 0.5);

			camLeftButton.css('content', 'url(/images/buttons/cam-arrows/left.png)');
			camRightButton.css('content', 'url(/images/buttons/cam-arrows/right.png)');
			camUpButton.css('content', 'url(/images/buttons/cam-arrows/up.png)');
			camDownButton.css('content', 'url(/images/buttons/cam-arrows/down.png)');
    	}, 100);
	}
	
	camLeftButton.on('click', function()
	{
		camButtonPress('left');
	});

	camRightButton.on('click', function()
	{
		camButtonPress('right');
	});

	camUpButton.on('click', function()
	{
		camButtonPress('up');
	});

	camDownButton.on('click', function()
	{
		camButtonPress('down');
	});

	jQuery('body').keydown(function(e)
	{
		if (e.which == 37) // left
		{
	    	camButtonPress('left');
	  	}
	  	else if (e.which == 39) // right
	  	{
	    	camButtonPress('right');
	  	}
	  	else if (e.which == 38) // up
	  	{
	  		camButtonPress('up');
	  	}
	  	else if (e.which == 40) // down
	  	{
	  		camButtonPress('down');
	  	}
	});


	var altitudeSettingIncreaseButton = jQuery('.droneAltitudeSettingIncreaseButton');
	var altitudeSettingDecreaseButton = jQuery('.droneAltitudeSettingDecreaseButton');
	var followingDistanceSettingIncreaseButton = jQuery('.droneFollowingDistanceSettingIncreaseButton');
	var followingDistanceSettingDecreaseButton = jQuery('.droneFollowingDistanceSettingDecreaseButton');

	function settingButtonPress(button)
	{
		if (button == 'altitudeIncrease')
		{
			altitudeSettingIncreaseButton.css('opacity', 1.00);
			jQuery('.droneAltitudeSettingIncreaseButton p').css('color', 'red');
			socket.emit('Command', 'MoveUp');
		}
		else if (button == 'altitudeDecrease')
		{
			altitudeSettingDecreaseButton.css('opacity', 1.00);
			jQuery('.droneAltitudeSettingDecreaseButton p').css('color', 'red');
			socket.emit('Command', 'MoveDown');
		}
		else if (button == 'followingDistanceIncrease')
		{
			followingDistanceSettingIncreaseButton.css('opacity', 1.00);
			jQuery('.droneFollowingDistanceSettingIncreaseButton p').css('color', 'red');
			socket.emit('Command', 'MoveBack');
		}
		else if (button == 'followingDistanceDecrease')
		{
			followingDistanceSettingDecreaseButton.css('opacity', 1.00);
			jQuery('.droneFollowingDistanceSettingDecreaseButton p').css('color', 'red');
			socket.emit('Command', 'MoveForward');
		}

		setTimeout(function () {
    		altitudeSettingIncreaseButton.css('opacity', 0.7);
			altitudeSettingDecreaseButton.css('opacity', 0.7);
			followingDistanceSettingIncreaseButton.css('opacity', 0.7);
			followingDistanceSettingDecreaseButton.css('opacity', 0.7);

			jQuery('.droneAltitudeSettingIncreaseButton p').css('color', 'white');
			jQuery('.droneAltitudeSettingDecreaseButton p').css('color', 'white');
			jQuery('.droneFollowingDistanceSettingIncreaseButton p').css('color', 'white');
			jQuery('.droneFollowingDistanceSettingDecreaseButton p').css('color', 'white');
    	}, 100);
	}

	altitudeSettingIncreaseButton.on('click', function()
	{
		settingButtonPress('altitudeIncrease');
	});

	altitudeSettingDecreaseButton.on('click', function()
	{
		settingButtonPress('altitudeDecrease');
	});

	followingDistanceSettingIncreaseButton.on('click', function()
	{
		settingButtonPress('followingDistanceIncrease');
	});

	followingDistanceSettingDecreaseButton.on('click', function()
	{
		settingButtonPress('followingDistanceDecrease');
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

	socket.on('DroneAltitudeSettingsUpdate', function(newAltitudeSettings)
	{
		console.log('DroneAltitudeSettingsUpdate: lowerBound: ' + newAltitudeSettings['lowerBound'] + ', upperBound: ' + newAltitudeSettings['upperBound']);

		jQuery('.droneAltitudeSettingStatus').html("<p>ALTITUDE SETTING: " + ((newAltitudeSettings['lowerBound'] + newAltitudeSettings['upperBound']) / 2) + " m</p>");
	});

	socket.on('DroneFollowingDistanceSettingsUpdate', function(newFollowingDistanceSettings)
	{
		console.log('DroneFollowingDistanceSettingsUpdate: innerBound: ' + newFollowingDistanceSettings['innerBound'] + ', outerBound: ' + newFollowingDistanceSettings['outerBound']);

		jQuery('.droneFollowingDistanceSettingStatus').html("<p>FOLLOWING DISTANCE SETTING: " + ((newFollowingDistanceSettings['innerBound'] + newFollowingDistanceSettings['outerBound']) / 2) + " m</p>");
	});

	socket.on('MCTabToggle', function(newSelectedTab)
	{
		console.log('MCTabToggle: ' + newSelectedTab);

		if (videoChatWindow != undefined && videoChatWindow.phoneVideoContainerBorder != undefined)
		{
			videoChatWindow.phoneVideoContainerBorder.css('opacity', 0.0);
		}
		jQuery('.droneVideoFrameContainer-border').css('opacity', 0.0);

		if (newSelectedTab == 'VideoChatView')
		{
			if (videoChatWindow != undefined && videoChatWindow.phoneVideoContainerBorder != undefined)
			{
				videoChatWindow.phoneVideoContainerBorder.css('opacity', 0.75);
			}
		}
		else if (newSelectedTab == 'DroneVideoView')
		{
			jQuery('.droneVideoFrameContainer-border').css('opacity', 0.75);
		}
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

	// Compatibility shim
    navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia;

    var peer;
    var videoChatWindow;

    // PeerJS object
    //var peer = new Peer('0', { key: 's51s84ud22jwz5mi', debug: 3 });
    peer = new Peer(
    	{ host: window.location.hostname, port: 8055, path: '/dvc', secure: false, debug: 3 },
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
	    	}
	    });

	    videoChatWindow.existingCall = call;
    }


    /**
     * WINDOW CLOSING
     */

    videoChatWindow.onbeforeunload = function (e)
	{
	    videoChatWindow.existingCall.close();
	};

    window.onbeforeunload = function (e)
    {
	    if (videoChatWindow)
    	{
    		videoChatWindow.close();
    	}
	};
});
