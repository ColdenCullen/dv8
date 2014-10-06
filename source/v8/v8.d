module v8.v8;

import core.stdc.stdint;

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

    //pragma( mangle, class )
    struct ResourceConstraints
    {
    public:
        //TODO
        //this();

        /**
         * Configures the constraints with reasonable default values based on the
         * capabilities of the current device the VM is running on.
         *
         * \param physical_memory The total amount of physical memory on the current
         *   device, in bytes.
         * \param virtual_memory_limit The amount of virtual memory on the current
         *   device, in bytes, or zero, if there is no limit.
         * \param number_of_processors The number of CPUs available on the current
         *   device.
         */
        //TODO
        /*
        void ConfigureDefaults(uint64_t physical_memory,
                               uint64_t virtual_memory_limit,
                               uint32_t number_of_processors);
        */

        int max_semi_space_size() @property const { return max_semi_space_size_; }
        void max_semi_space_size(int value) @property { max_semi_space_size_ = value; }
        int max_old_space_size() @property const { return max_old_space_size_; }
        void max_old_space_size(int value) @property { max_old_space_size_ = value; }
        int max_executable_size() @property const { return max_executable_size_; }
        void max_executable_size(int value) @property { max_executable_size_ = value; }
        uint32_t* stack_limit() @property /*const*/ { return stack_limit_; }
        // Sets an address beyond which the VM's stack may not grow.
        void stack_limit(uint32_t* value) @property { stack_limit_ = value; }
        int available_threads() @property const { return max_available_threads_; }
        // Set the number of threads available to V8, assuming at least 1.
        void max_available_threads(int value) @property {
            max_available_threads_ = value;
        }
        size_t code_range_size() @property const { return code_range_size_; }
        void code_range_size(size_t value) @property {
            code_range_size_ = value;
        }

    private:
        int max_semi_space_size_;
        int max_old_space_size_;
        int max_executable_size_;
        uint32_t* stack_limit_;
        int max_available_threads_;
        size_t code_range_size_;
    }

    class Isolate
    {
        /**
         * Initial configuration parameters for a new Isolate.
         */
        static struct CreateParams
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
            size_t entry_hook;

            /**
             * Allows the host application to provide the address of a function that is
             * notified each time code is added, moved or removed.
             */
            //TODO
            //JitCodeEventHandler code_event_handler;
            size_t code_event_handler;

            /**
             * ResourceConstraints to use for the new Isolate.
             */
            ResourceConstraints constraints;

            /**
             * This flag currently renders the Isolate unusable.
             */
            bool enable_serializer;
        }

        /**
         * Stack-allocated class which sets the isolate for all operations
         * executed within a local scope.
         */
        static class Scope
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
        static Isolate New()
        {
            CreateParams params;
            return New( params );
        }
        /// ditto
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

    /**
     * A stack-allocated class that governs a number of local handles.
     * After a handle scope has been created, all local handles will be
     * allocated within that handle scope until either the handle scope is
     * deleted or another handle scope is created.  If there is already a
     * handle scope and a new one is created, all allocations will take
     * place in the new handle scope until it is deleted.  After that,
     * new handles will again be allocated in the original handle scope.
     *
     * After the handle scope of a local handle has been deleted the
     * garbage collector will no longer track the object stored in the
     * handle and may deallocate it.  The behavior of accessing a handle
     * for which the handle scope has been deleted is undefined.
     */
    class HandleScope
    {
    public:
        this( Isolate isolate );

        static int NumberOfHandles( Isolate isolate );
        //TODO
        //Isolate GetIsolate() const;
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
        //TODO
        //Platform CreateDefaultPlatform( int thread_pool_size = 0 );
    }
}
