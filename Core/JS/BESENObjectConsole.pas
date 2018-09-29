(*******************************************************************************
                                 L I C E N S E
********************************************************************************

BESEN - A ECMAScript Fifth Edition Object Pascal Implementation
Copyright (C) 2009-2016, Benjamin 'BeRo' Rosseaux

The source code of the BESEN ecmascript engine library and helper tools are
distributed under the Library GNU Lesser General Public License Version 2.1
(see the file copying.txt) with the following modification:

As a special exception, the copyright holders of this library give you
permission to link this library with independent modules to produce an
executable, regardless of the license terms of these independent modules,
and to copy and distribute the resulting executable under terms of your choice,
provided that you also meet, for each linked independent module, the terms
and conditions of the license of that module. An independent module is a module
which is not derived from or based on this library. If you modify this
library, you may extend this exception to your version of the library, but you
are not obligated to do so. If you do not wish to do so, delete this exception
statement from your version.

If you didn't receive a copy of the license, see <http://www.gnu.org/licenses/>
or contact:
      Free Software Foundation
      675 Mass Ave
      Cambridge, MA  02139
      USA

*******************************************************************************)
unit BESENObjectConsole;
{$i BESEN.inc}

interface

const BESENObjectConsoleSource:{$ifdef BESENSingleStringType}TBESENSTRING{$else}widestring{$endif}=
'/**'+#13#10+
' * Console object for BESEN'+#13#10+
' * @author Dmitry A. Soshnikov <dmitry.soshnikov@gmail.com>'+#13#10+
' */'+#13#10+
'(function initConsole(global) {'+#13#10+
''+#13#10+
'  // helpers'+#13#10+
'  var timeMap = {};'+#13#10+
''+#13#10+
'  function repeatSring(string, times) {'+#13#10+
'    return Array(times + 1).join(string);'+#13#10+
'  }'+#13#10+
''+#13#10+
'  function dir(o, recurse, compress, level)'+#13#10+
'  {'+#13#10+
'  var s = "";'+#13#10+
'  var pfx = "";'+#13#10+
''+#13#10+
'  if (typeof recurse == "undefined")'+#13#10+
'      recurse = 0;'+#13#10+
'  if (typeof level == "undefined")'+#13#10+
'      level = 0;'+#13#10+
'  if (typeof compress == "undefined")'+#13#10+
'      compress = true;'+#13#10+
''+#13#10+
'  for (var i = 0; i < level; i++)'+#13#10+
'      pfx += (compress) ? "| " : "|  ";'+#13#10+
''+#13#10+
'  var tee = (compress) ? "+ " : "+- ";'+#13#10+
''+#13#10+
''+#13#10+
'  Object.getOwnPropertyNames(o).forEach(function (i) {'+#13#10+
'      var t, ex;'+#13#10+
'      try'+#13#10+
'      {'+#13#10+
'          t = typeof o[i];'+#13#10+
'      }'+#13#10+
'      catch (ex)'+#13#10+
'      {'+#13#10+
'          t = "ERROR";'+#13#10+
'      }'+#13#10+
''+#13#10+
'      switch (t)'+#13#10+
'      {'+#13#10+
'          case "function":'+#13#10+
'              var sfunc = String(o[i]).split("\n");'+#13#10+
'              if (sfunc[1].indexOf(''native'') !== -1)'+#13#10+
'                  sfunc = "[native code]";'+#13#10+
'              else'+#13#10+
'                  if (sfunc.length == 1)'+#13#10+
'                      sfunc = String(sfunc);'+#13#10+
'                  else'+#13#10+
'                      sfunc = sfunc.length + " lines";'+#13#10+
'              s += pfx + tee + i + " (function) " + sfunc + "\n";'+#13#10+
''+#13#10+
'              if ((i != "parent") && (recurse))'+#13#10+
'                  s += dir(o[i], recurse - 1,'+#13#10+
'                                       compress, level + 1);'+#13#10+
''+#13#10+
'              break;'+#13#10+
''+#13#10+
'          case "object":'+#13#10+
'              s += pfx + tee + i + " (object)";'+#13#10+
'              if (o[i] == null)'+#13#10+
'              {'+#13#10+
'                  s += " null\n";'+#13#10+
'                  break;'+#13#10+
'              }'+#13#10+
''+#13#10+
'              s += "\n";'+#13#10+
''+#13#10+
'              if (!compress)'+#13#10+
'                  s += pfx + "|\n";'+#13#10+
'              if ((i != "parent") && (recurse))'+#13#10+
'                  s += dir(o[i], recurse - 1,'+#13#10+
'                                       compress, level + 1);'+#13#10+
'              break;'+#13#10+
''+#13#10+
'          case "string":'+#13#10+
'              if (o[i].length > 200)'+#13#10+
'                  s += pfx + tee + i + " (" + t + ") " +'+#13#10+
'                      o[i].length + " chars\n";'+#13#10+
'              else'+#13#10+
'                  s += pfx + tee + i + " (" + t + ") ''" + o[i] + "''\n";'+#13#10+
'              break;'+#13#10+
''+#13#10+
'          case "ERROR":'+#13#10+
'              s += pfx + tee + i + " (" + t + ") ?\n";'+#13#10+
'              break;'+#13#10+
''+#13#10+
'          default:'+#13#10+
'              s += pfx + tee + i + " (" + t + ") " + o[i] + "\n";'+#13#10+
''+#13#10+
'      }'+#13#10+
''+#13#10+
'      if (!compress)'+#13#10+
'          s += pfx + "|\n";'+#13#10+
''+#13#10+
'  });'+#13#10+
''+#13#10+
'  s += pfx + "*\n";'+#13#10+
''+#13#10+
'  return s;'+#13#10+
'  }'+#13#10+
''+#13#10+
'  /**'+#13#10+
'   * console object;'+#13#10+
'   * implements: log, dir, time, timeEnd'+#13#10+
'   */'+#13#10+
'  global.console = {'+#13#10+
''+#13#10+
'    /**'+#13#10+
'     * simple log using toString'+#13#10+
'     */'+#13#10+
'    log: function(){'+#13#10+
'      var s = "", a = arguments, j = +a.length;'+#13#10+
'      for(var i=0;i<j;i++) s += a[i] + " ";'+#13#10+
'      print(s);'+#13#10+
'    },'+#13#10+
''+#13#10+
''+#13#10+
'    dir: function (object, recurse, compress, level) {'+#13#10+
'      // if called for a primitive'+#13#10+
'      if (Object(object) !== object) {'+#13#10+
'        return console.log(object);'+#13#10+
'      }'+#13#10+
'      // else for an object'+#13#10+
'      return print(dir(object, recurse, compress ,level));'+#13#10+
'    },'+#13#10+
''+#13#10+
'    // time functions borrowed from Firebug'+#13#10+
''+#13#10+
'    /**'+#13#10+
'     * time start'+#13#10+
'     */'+#13#10+
'    time: function(name) {'+#13#10+
'      timeMap[name] = Date.now();'+#13#10+
'    },'+#13#10+
''+#13#10+
'    /**'+#13#10+
'     * time end'+#13#10+
'     */'+#13#10+
'    timeEnd: function(name) {'+#13#10+
'      if (name in timeMap) {'+#13#10+
'        var delta = Date.now() - timeMap[name];'+#13#10+
'        print(name + ": ", delta + "ms");'+#13#10+
'        delete timeMap[name];'+#13#10+
'      }'+#13#10+
'    }'+#13#10+
'  };'+#13#10+
'})(this);'+#13#10;

implementation

end.
