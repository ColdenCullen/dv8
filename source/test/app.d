module test.app;

import v8.v8;
import std.stdio, std.typecons;

unittest
{
    V8.Initialize();
    V8.Dispose();

    V8.InitializeICU();
    Platform platform = CreateDefaultPlatform();
    V8.InitializePlatform( platform );
    V8.Initialize();

    writeln( "Initialized!" );

    auto desc = Isolate.CreateParams();
    Isolate isolate = Isolate.New( desc );
    {
        auto isolate_scope = scoped!( Isolate.Scope )( isolate );

        writeln( "Scoped!" );
    }

    //V8.SetFlagsFromCommandLine(&argc, argv, true);
    //ShellArrayBufferAllocator array_buffer_allocator;
    //V8.SetArrayBufferAllocator(&array_buffer_allocator);
    /*Isolate* isolate = Isolate.New();
    run_shell = (argc == 1);
    int result;
    {
        v8::Isolate::Scope isolate_scope(isolate);
        v8::HandleScope handle_scope(isolate);
        v8::Handle<v8::Context> context = CreateShellContext(isolate);
        if (context.IsEmpty()) {
          fprintf(stderr, "Error creating context\n");
          return 1;
        }
        v8::Context::Scope context_scope(context);
        result = RunMain(isolate, argc, argv);
        if (run_shell) RunShell(context);
    }*/
    V8.Dispose();
    V8.ShutdownPlatform();
    //delete platform;
    //return result;

    writeln( "Shutdown!" );
}

version( unittest ) {}
else void main()
{
    writeln( "Edit source/app.d to start your project." );
}
