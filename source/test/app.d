module test.app;

import v8.v8;
import std.stdio;

unittest
{
	Handle!Value handle;
	handle.Clear();
}

version( unittest ) {}
else void main()
{
	writeln( "Edit source/app.d to start your project." );
}
