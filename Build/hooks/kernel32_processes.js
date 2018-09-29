'use strict';

// init fake Process list ¯\_(ツ)_/¯

var processes = {0: "System Idle Process", 4: "System"};

function GetRandPID () {

	var PID = Math.floor((1 + Math.random()) * 0x1000);
	while (PID == 0 || PID == 4) {
	 	PID = Math.floor((1 + Math.random()) * 0x1000);
	} 
	return PID;
}

var list = ["GoogleUpdate.exe","iexplorer.exe","smss.exe","csrss.exe","winlogon.exe",
			"services.exe","lsass.exe","svchost.exe","explorer.exe","firefox.exe"];

var PIDS = [];

for (var i = 0; i < list.length; i++) {
    var id = GetRandPID();

    if (PIDS.indexOf(id) == -1) {
        PIDS.push(id);
    }else 
      i--;
}

for (var i = 0; i < list.length; i++) {
	processes[PIDS[i]] = list[i];
}

// for (var PID in processes) {info("PID : " + PID + " 	- " + processes[PID]);}

/*
###################################################################################################
###################################################################################################
*/



