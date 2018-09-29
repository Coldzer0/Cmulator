unit GUI;

{$mode delphi}

interface

uses
  Classes, SysUtils, math, ncurses;

type
  window_t = record
    width : UInt32;
    height : UInt32;
    title : PChar;
    border : PWINDOW;
    content : PWINDOW;
  end;


procedure GuiTest();

implementation

var
  registers, stack, code, console : window_t;
  parent_y, parent_x : LongInt;
  EAX : DWORD = 0;

const
  CONSOLE_HEIGHT = (5 + 2) ;
  REGISTER_WIDTH = (14 + 2);
  STACK_WIDTH    = (21 + 2);

procedure init_window(var w : window_t; y ,x : UInt32;
          height,width : UInt32;
          title : PChar);
begin
  w.width := width - 2;
  w.width := width - 2;
  w.height := height - 2;
  w.title := title;
  w.border := newwin(height, width, y, x);
  w.content := newwin(height - 2, width -2, y + 1, x + 1);
end;

procedure draw_window(var w : window_t);
begin
  wattron(w.border, COLOR_PAIR(1));
  box(w.border, 0, 0);
  wattroff(w.border, COLOR_PAIR(1));
  wattron(w.border, COLOR_PAIR(2));
  mvwprintw(w.border, 0, 2, '[%s]', w.title);
  wattroff(w.border, COLOR_PAIR(2));
  wrefresh(w.border);
  wrefresh(w.content)
end;

procedure render();
begin
  mvwprintw(registers.content, 0, 0, ' EAX: %8.x', EAX);
  draw_window(registers);

  mvwprintw(console.content, 0, 0, '%s ', 'Cmu > ');
  draw_window(console);
end;

procedure GuiTest();
var
  Buff : PChar;
  cmd : string;
  CH : Char;
begin
  initscr;

  cbreak();             // Immediate key input
  nonl();               // Get return key
  timeout(0);           // Non-blocking input
  keypad(stdscr, True);    // Fix keypad .
  nodelay(stdscr, True);
  //noecho();             // No automatic printing
  curs_set(0);          // Hide real cursor
  intrflush(stdscr, False); // Avoid potential graphical issues
  leaveok(stdscr, True);   // Don't care where cursor is left


  getmaxyx(stdscr,parent_y, parent_x);

  init_window(registers, 0, 0, parent_y - CONSOLE_HEIGHT, REGISTER_WIDTH, 'REGISTERS');
  init_window(stack, 0, parent_x - STACK_WIDTH, parent_y - CONSOLE_HEIGHT, STACK_WIDTH, 'STACK');
  init_window(code, 0, REGISTER_WIDTH, parent_y - CONSOLE_HEIGHT, parent_x - REGISTER_WIDTH - STACK_WIDTH, 'CODE');
  init_window(console, parent_y - CONSOLE_HEIGHT, 0, CONSOLE_HEIGHT, parent_x, 'CONSOLE');

  start_color;
  init_pair(1, COLOR_GREEN, COLOR_BLACK);
  init_pair(2, COLOR_BLACK, COLOR_GREEN);
  init_pair(3, COLOR_RED, COLOR_BLACK);
  init_pair(4, COLOR_BLUE, COLOR_BLACK);

  Buff := AllocMem(1024);
  Randomize;
  while True do
  begin
    EAX := RandomRange($10000000,$7FFFFFFF);
    render();

    wgetnstr(console.content,Buff,1024 -1);
    //CH := chr(wgetch(console.content));
    cmd := String(Buff);
    if cmd <> '' then
    begin
      if cmd = 'q' then
        Break
    end;
    napms(1000 div 60);
  end;
  endwin;
end;

end.

