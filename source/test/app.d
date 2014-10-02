module test.app;
import std.stdio;

version( unittest ) {}
else void main()
{
	writeln( "Edit source/app.d to start your project." );
}
