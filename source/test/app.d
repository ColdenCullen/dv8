module test.app;

import v8.v8;
import std.stdio, std.typecons;

unittest
{
    write( "Starting... Press enter to continue..." );
    readln();

    V8.InitializeICU();
    //Platform platform = CreateDefaultPlatform();
    //V8.InitializePlatform( p );
    V8.Initialize();

    //V8.SetFlagsFromCommandLine(&argc, argv, true);
    //ShellArrayBufferAllocator array_buffer_allocator;
    //V8.SetArrayBufferAllocator(&array_buffer_allocator);

    writeln( "Initialized!" );

    Isolate.CreateParams params;
    //params.constraints.ConfigureDefaults( 0, 0, 0 );
    Isolate isolate = Isolate.New( params );
    {
        auto isolate_scope = Isolate.Scope( isolate );
        auto handle_scope = new HandleScope( isolate );//scoped!( HandleScope )( isolate );

        /*
        Handle<Context> context = CreateShellContext(isolate);
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
    //V8.ShutdownPlatform();

    writeln( "Shutdown!" );
}

version( unittest ) {}
else void main()
{
    writeln( "Edit source/app.d to start your project." );
}
