module test.app;

import v8.v8;
import std.stdio, std.typecons;

// Creates a new execution environment containing the built-in
// functions.
/*
Handle!Context CreateShellContext(Isolate isolate)
{
    // Create a template for the global object.
    Handle!ObjectTemplate global = ObjectTemplate.New( isolate );
    // Bind the global 'print' function to the C++ Print callback.
    global->Set(v8::String::NewFromUtf8(isolate, "print"),
                v8::FunctionTemplate::New(isolate, Print));
                // Bind the global 'read' function to the C++ Read callback.
    global->Set(v8::String::NewFromUtf8(isolate, "read"),
                v8::FunctionTemplate::New(isolate, Read));
                // Bind the global 'load' function to the C++ Load callback.
    global->Set(v8::String::NewFromUtf8(isolate, "load"),
                v8::FunctionTemplate::New(isolate, Load));
                // Bind the 'quit' function
    global->Set(v8::String::NewFromUtf8(isolate, "quit"),
                v8::FunctionTemplate::New(isolate, Quit));
                // Bind the 'version' function
    global->Set(v8::String::NewFromUtf8(isolate, "version"),
                v8::FunctionTemplate::New(isolate, Version));
    return Context.New(isolate, null, global);
}
*/

unittest
{
    write( "Starting... Press enter to continue..." );
    readln();

    V8.InitializeICU();
    V8.Initialize();

    writeln( "Initialized!" );

    Isolate.CreateParams params;
    //params.constraints.ConfigureDefaults( 0, 0, 0 );
    Isolate isolate = Isolate.New( params );
    {
        auto isolate_scope = Isolate.Scope( isolate );
        auto handle_scope = new HandleScope( isolate );//scoped!( HandleScope )( isolate );

        /*
        Handle!Context context = CreateShellContext(isolate);
        if (context.IsEmpty()) {
            fprintf(stderr, "Error creating context\n");
            return 1;
        }
        auto context_scope = scoped!( Context.Scope )( context );
        */

        writeln( "Scoped!" );
    }
    isolate.Dispose();
    V8.Dispose();

    writeln( "Shutdown!" );
}

version( unittest ) {}
else void main()
{
    writeln( "Edit source/app.d to start your project." );
}
