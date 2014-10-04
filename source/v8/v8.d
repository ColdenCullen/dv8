module v8.v8;

extern(C++, v8) // namespace v8
{
    class V8
    {
    static:
        /**
         * Initializes V8. This function needs to be called before the first Isolate
         * is created. It always returns true.
         */
        bool Initialize();

        /**
         * Initialize the ICU library bundled with V8. The embedder should only
         * invoke this method when using the bundled ICU. Returns true on success.
         *
         * If V8 was compiled with the ICU data in an external file, the location
         * of the data file has to be provided.
         */
        bool InitializeICU(const(char)* icu_data_file = null);

        /**
         * Sets the v8::Platform to use. This should be invoked before V8 is
         * initialized.
         */
        void InitializePlatform(Platform platform);

        /**
         * Clears all references to the v8::Platform. This should be invoked after
         * V8 was disposed.
         */
        void ShutdownPlatform();

        /**
         * Releases any resources used by v8 and stops any utility threads
         * that may be running.  Note that disposing v8 is permanent, it
         * cannot be reinitialized.
         *
         * It should generally not be necessary to dispose v8 before exiting
         * a process, this should happen automatically.  It is only necessary
         * to use if the process needs the resources taken up by v8.
         */
        bool Dispose();
    }

    class Isolate
    {
        /**
         * Initial configuration parameters for a new Isolate.
         */
        struct CreateParams
        {
            /**
            * The optional entry_hook allows the host application to provide the
            * address of a function that's invoked on entry to every V8-generated
            * function.  Note that entry_hook is invoked at the very start of each
            * generated function. Furthermore, if an  entry_hook is given, V8 will
            * always run without a context snapshot.
            */
            //TODO
            //FunctionEntryHook entry_hook;

            /**
            * Allows the host application to provide the address of a function that is
            * notified each time code is added, moved or removed.
            */
            //TODO
            //JitCodeEventHandler code_event_handler;

            /**
            * ResourceConstraints to use for the new Isolate.
            */
            //TODO
            //ResourceConstraints constraints;

            /**
            * This flag currently renders the Isolate unusable.
            */
            bool enable_serializer;
        }

        /**
         * Stack-allocated class which sets the isolate for all operations
         * executed within a local scope.
         */
        class Scope
        {
        public:
            this( Isolate isolate )
            {
                isolate_ = isolate;
                //TODO
                //isolate_.Enter();
            }
            ~this()
            {
                //TODO
                //isolate_.Exit();
            }

        private:
            Isolate isolate_;
        };

        /**
         * Creates a new isolate.  Does not change the currently entered
         * isolate.
         *
         * When an isolate is no longer used its resources should be freed
         * by calling Dispose().  Using the delete operator is not allowed.
         *
         * V8::Initialize() must have run prior to this.
         */
        static Isolate New( const ref CreateParams params );

        /**
         * Returns the entered isolate for the current thread or NULL in
         * case there is no current isolate.
         */
        static Isolate GetCurrent();

        /**
         * Sets this isolate as the entered one for the current thread.
         * Saves the previously entered one (if any), so that it can be
         * restored when exiting.  Re-entering an isolate is allowed.
         */
        //TODO
        //void Enter();

        /**
         * Exits this isolate by restoring the previously entered one in the
         * current thread.  The isolate may still stay the same, if it was
         * entered more than once.
         *
         * Requires: this == Isolate::GetCurrent().
         */
        //TODO
        //void Exit();

        /**
         * Disposes the isolate.  The isolate must not be entered by any
         * thread to be disposable.
         */
        //TODO
        //void Dispose();
    }

    class Platform
    {

    }

    class Value
    {

    }

    class Local( Value )
    {
        void Clear();
    }

    extern( C++, platform )
    {
        Platform CreateDefaultPlatform( int thread_pool_size = 0 );
    }
}
