// this's a global format function

String.prototype.format = function () {
    "use strict";
    var str = this.toString();
    if (arguments.length) {
        var t = typeof arguments[0];
        var key;
        var args = ("string" === t || "number" === t) ?
            Array.prototype.slice.call(arguments) :
            arguments[0];

        for (key in args) {
            str = str.replace(new RegExp("\\{" + key + "\\}", "gi"), args[key]);
        }
    }

    return str;
};

String.prototype.contains = function (segment, ignoreCase) {

    if (ignoreCase) {
        return this.toLowerCase().indexOf(segment.toLowerCase()) !== -1; 
    }
    return this.indexOf(segment) !== -1; 
};

Array.prototype.inList=function(value,ignoreCase){
    
    for (var i = 0; i < this.length; i++) {
        if (value.contains(this[i],ignoreCase)) {
            return true;
        }
    }       
    return false;
}

importScripts(
    'hooks/const.js',
    'hooks/ntdll.js', 
    'hooks/kernelbase.js',
    'hooks/kernel32.js', 
    'hooks/kernel32_self.js',
    'hooks/kernel32_files.js',
    'hooks/kernel32_desktop.js',
    'hooks/kernel32_threads.js',
    'hooks/kernek32_strings.js',
    'hooks/kernel32_processes.js',
    'hooks/user32.js',
    'hooks/advapi32.js',
    'hooks/shell32.js',
    'hooks/shlwapi.js',
    'hooks/urlmon.js',
    'hooks/ws2_32.js',
    'hooks/winhttp.js',
    'hooks/msvcrt.js',
    'hooks/c_runtime.js',
    'hooks/wtsapi32.js',
    'hooks/uxtheme.js',
    'hooks/ole32.js',
    'hooks/lpk.js',
    'hooks/crtdll.js',
    'hooks/powrprof.js',
    'hooks/gdi32.js',
    'hooks/wininet.js'
);

// put custom scripts here :D
importScripts('hooks/address.js');


