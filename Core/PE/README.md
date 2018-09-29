# pe-image-for-delphi

This is Delphi library to work with Portable Executable Image files.
The main purpose is to make parsing image structures of 32/64 bit image easy.
Now it can parse most used things, like: sections, imports, exports, resources and tls.

Also it can write image, but that was not primary goal.

ToDo:

- There must be introduced sparsed/paged virtual memory concept (just like Windows does)
  Currently all section data is loaded into memory.
  Some virus samples tested can crash loading because of using too big virtual address range.
  With normal compiler generated images you won't have such problem.


---

### ... and some tweaks for Lazarus.

Lazarus does not support anonymous functions, so I just change it to callbacks.
This code is very dirty and terrible. You should use it at your own risk.

Generic problem was simply solved by "[FreePascal Generics.Collections library](https://github.com/dathox/generics.collections)".
(Thank's for it.)

You also need "TlHelp32.pas" and "PsAPI.pas" units for build it in Lazarus.
Copy them from Delphi's src folder.
