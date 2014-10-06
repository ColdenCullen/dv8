module v8.v8;

import core.stdc.stdint;

enum TYPE_CHECK( T, S ) = __traits( compiles, { *(cast(T**)null) = cast(S*)null; } );

extern(C++, v8) // namespace v8
{
    final abstract class V8
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
         * Mangling Problems:
         * ---
         * Windows:
         * From D:
         * ?ConfigureDefaults@ResourceConstraints@v8@@QEAAX_K_KI@Z
         * public: void __cdecl v8::ResourceConstraints::ConfigureDefaults(unsigned __int64,unsigned __int64,unsigned int)
         *
         * From C++:
         * ?ConfigureDefaults@ResourceConstraints@v8@@QEAAX_K0I@Z
         * public: void __cdecl v8::ResourceConstraints::ConfigureDefaults(unsigned __int64,unsigned __int64,unsigned int) __ptr64
         * ---
         */
        /*
        void ConfigureDefaults(uint64_t physical_memory,
                               uint64_t virtual_memory_limit,
                               uint32_t number_of_processors);
        //*/

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
            // [TODO] - Implement Isolate.CreateParams.entry_hook (requires: FunctionEntryHook)
            //FunctionEntryHook entry_hook;
            size_t entry_hook;

            /**
             * Allows the host application to provide the address of a function that is
             * notified each time code is added, moved or removed.
             */
            // [TODO] - Implement Isolate.CreateParams.code_event_handler (requires: JitCodeEventHandler)
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
        static struct Scope
        {
        public:
            this( Isolate isolate )
            {
                isolate_ = isolate;
                isolate_.Enter();
            }
            ~this()
            {
                isolate_.Exit();
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
        final void Enter();

        /**
         * Exits this isolate by restoring the previously entered one in the
         * current thread.  The isolate may still stay the same, if it was
         * entered more than once.
         *
         * Requires: this == Isolate::GetCurrent().
         */
        final void Exit();

        /**
         * Disposes the isolate.  The isolate must not be entered by any
         * thread to be disposable.
         */
        final void Dispose();
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
        // [TODO] - Investigate Linker Errors
        /*
         * Mangling Problems:
         * ---
         * Windows:
         * From D:
         * ?__ctor@HandleScope@v8@@QEAA@PEAVIsolate@2@@Z
         * public: __cdecl v8::HandleScope::__ctor(class v8::Isolate *)
         *
         * From C++:
         * ??0HandleScope@v8@@QEAA@PEAVIsolate@1@@Z
         * public: __cdecl v8::HandleScope::HandleScope(class v8::Isolate * __ptr64) __ptr64
         * ---
         */
        pragma( mangle, "??0HandleScope@v8@@QEAA@PEAVIsolate@1@@Z" )
        this( Isolate isolate );

        /**
         * Counts the number of allocated handles.
         */
        static int NumberOfHandles( Isolate isolate );
        final Isolate GetIsolate() const;
    }

    /**
     * A sandboxed execution context with its own set of built-in objects
     * and functions.
     */
    struct Context
    {
    public:
        /**
         * Returns the global proxy object.
         *
         * Global proxy object is a thin wrapper whose prototype points to actual
         * context's global object with the properties like Object, etc. This is done
         * that way for security reasons (for more details see
         * https://wiki.mozilla.org/Gecko:SplitWindow).
         *
         * Please note that changes to global proxy object prototype most probably
         * would break VM---v8 expects only global object as a prototype of global
         * proxy object.
         */
        // [TODO] - Implement Context.Global (requires: Local!T, Object)
        //final Local!Object Global();

        /**
         * Detaches the global object from its context before
         * the global object can be reused to create a new context.
         */
        final void DetachGlobal();

        /**
         * Creates a new context and returns a handle to the newly allocated
         * context.
         *
         * \param isolate The isolate in which to create the context.
         *
         * \param extensions An optional extension configuration containing
         * the extensions to be installed in the newly created context.
         *
         * \param global_template An optional object template from which the
         * global object for the newly created context will be created.
         *
         * \param global_object An optional global object to be reused for
         * the newly created context. This global object must have been
         * created by a previous call to Context::New with the same global
         * template. The state of the global object will be completely reset
         * and only object identify will remain.
         */
        // [TODO] - Implement Context.New (requires: Local, Extension Configuration, Handle!T, ObjectTemplate, Value)
        /*
        static Local!Context New(
            Isolate* isolate,
            ExtensionConfiguration* extensions = NULL,
            Handle<ObjectTemplate> global_template = Handle<ObjectTemplate>(),
            Handle<Value> global_object = Handle<Value>());
        */

        /**
         * Sets the security token for the context.  To access an object in
         * another context, the security tokens must match.
         */
        // [TODO] - Implement Context.SetSecurityToken (requires: Handle!T, Value)
        /*
        final void SetSecurityToken(Handle!Value token);
        */

        /** Restores the security token to the default value. */
        final void UseDefaultSecurityToken();

        /** Returns the security token of this context.*/
        // [TODO] - Implement Context.GetSecurityToken (requires: Handle!T, Value)
        /*
        final Handle!Value GetSecurityToken();
        */
    }

    class Value
    {

    }

    /**
     * A JavaScript object (ECMA-262, 4.3.3)
     */
    // [TODO] - Rename to Object (somehow?)
    class JSObject : Value
    {
    public:
        // [TODO] - Implement Object.Set (requires: Handle!Value)
        /*
        final bool Set(Handle!Value key, Handle!Value value);
        final bool Set(uint32_t index, Handle<Value> value);
        */

        // Sets an own property on this object bypassing interceptors and
        // overriding accessors or read-only properties.
        //
        // Note that if the object has an interceptor the property will be set
        // locally, but since the interceptor takes precedence the local property
        // will only be returned if the interceptor doesn't return a value.
        //
        // Note also that this only works for named properties.
        // [TODO] - Implement Object.ForceSet (requires: Handle!Value, PropertyAttribs)
        /*
        final bool ForceSet(Handle!Value key,
                      Handle!Value value,
                      PropertyAttribute attribs = None);
        */

        // [TODO] - Implement Object.Get (requires: Local!Value, Handle!Value)
        /*
        final Local!Value Get(Handle!Value key);
        final Local!Value Get(uint32_t index);
        */

        /**
         * Gets the property attributes of a property which can be None or
         * any combination of ReadOnly, DontEnum and DontDelete. Returns
         * None when the property doesn't exist.
         */
        // [TODO] - Implement Object.GetPropertyAttributes (requires: PropertyAttribute, Handle!Value)
        /*
        final PropertyAttribute GetPropertyAttributes(Handle!Value key);
        */

        /**
         * Returns Object.getOwnPropertyDescriptor as per ES5 section 15.2.3.3.
         */
        // [TODO] - Implement Object.GetOwnPropertyDescriptor (requires: Local!Value, Local!String)
        /*
        final Local!Value GetOwnPropertyDescriptor(Local!String key);
        */

        // [TODO] - Implement Object.Has (requires: Handle!Value)
        /*
        final bool Has(Handle!Value key);
        */

        // [TODO] - Implement Object.Delete (requires: Handle!Value)
        /*
        final bool Delete(Handle!Value key);
        */

        // Delete a property on this object bypassing interceptors and
        // ignoring dont-delete attributes.
        // [TODO] - Implement Object.ForceDelete (requires: Handle!Value)
        /*
        final bool ForceDelete(Handle!Value key);
        */

        final bool Has(uint32_t index);

        final bool Delete(uint32_t index);

        // [TODO] - Implement Object.SetAccessor (requires: Handle!String, Accessor*Callback, Handle!Value, AccessControl, PropertyAttribute)
        /*
        final bool SetAccessor(Handle!String name,
                               AccessorGetterCallback getter,
                               AccessorSetterCallback setter = 0,
                               Handle!Value data = Handle!Value(),
                               AccessControl settings = DEFAULT,
                               PropertyAttribute attribute = None);
        final bool SetAccessor(Handle!Name name,
                               AccessorNameGetterCallback getter,
                               AccessorNameSetterCallback setter = 0,
                               Handle!Value data = Handle!Value(),
                               AccessControl settings = DEFAULT,
                               PropertyAttribute attribute = None);
        */

        // This function is not yet stable and should not be used at this time.
        // [TODO] - Implement these (requires: Local!Name, Local!DeclaredAccessorDescriptor, PropertyAttribute, AccessControl)
        /*
        final bool SetDeclaredAccessor(Local!Name name,
                                       Local!DeclaredAccessorDescriptor descriptor,
                                       PropertyAttribute attribute = None,
                                       AccessControl settings = DEFAULT);

        final void SetAccessorProperty(Local!Name name,
                                       Local!Function getter,
                                       Handle!Function setter = Handle!Function(),
                                       PropertyAttribute attribute = None,
                                       AccessControl settings = DEFAULT);
        */

        /**
         * Functionality for private properties.
         * This is an experimental feature, use at your own risk.
         * Note: Private properties are inherited. Do not rely on this, since it may
         * change.
         */
        // [TODO] - Implement Privates (requires: Handle!Private, Handle!Value, Local!Value)
        /*
        final bool HasPrivate(Handle!Private key);
        final bool SetPrivate(Handle!Private key, Handle!Value value);
        final bool DeletePrivate(Handle!Private key);
        final Local!Value GetPrivate(Handle!Private key);
        */

        /**
         * Returns an array containing the names of the enumerable properties
         * of this object, including properties from prototype objects.  The
         * array returned by this method contains the same values as would
         * be enumerated by a for-in statement over this object.
         */
        // [TODO] - Implement Object.GetPropertyNames (requires: Local!Array)
        /*
        final Local!Array GetPropertyNames();
        */

        /**
         * This function has the same functionality as GetPropertyNames but
         * the returned array doesn't contain the names of properties from
         * prototype objects.
         */
        // [TODO] - Implement Object.GetOwnPropertyNames (requires: Local!Array)
        /*
        final Local!Array GetOwnPropertyNames();
        */

        /**
         * Get the prototype object.  This does not skip objects marked to
         * be skipped by __proto__ and it does not consult the security
         * handler.
         */
        // [TODO] - Implement Object.GetPrototype (requires: Local!Value)
        /*
        final Local!Value GetPrototype();
        */

        /**
         * Set the prototype object.  This does not skip objects marked to
         * be skipped by __proto__ and it does not consult the security
         * handler.
         */
        // [TODO] - Implement Object.SetPrototype (requires: Handle!Value)
        /*
        final bool SetPrototype(Handle!Value prototype);
        */

        /**
         * Finds an instance of the given function template in the prototype
         * chain.
         */
        // [TODO] - Implement Object.FindInstanceInPrototypeChain (requires: Local!Object, Handle!FunctionTemplate)
        /*
        Local!Object FindInstanceInPrototypeChain(Handle!FunctionTemplate tmpl);
        */

        /**
         * Call builtin Object.prototype.toString on this object.
         * This is different from Value::ToString() that may call
         * user-defined toString function. This one does not.
         */
        // [TODO] - Implement Object.ObjectProtoToString (requires: Local!String)
        /*
        final Local!String ObjectProtoToString();
        */

        /**
         * Returns the name of the function invoked as a constructor for this object.
         */
        // [TODO] - Implement Object.GetConstructorName (requires: Local!String)
        /*
        final Local!String GetConstructorName();
        */

        /** Gets the number of internal fields for this Object. */
        final int InternalFieldCount();

        /** Same as above, but works for Persistents */
        // [TODO] - Implement Object.InternalFieldCount (requires: PersistantBase!Object)
        /*
        static int InternalFieldCount(const ref PersistentBase!Object object)
        {
          return object.val_->InternalFieldCount();
        }
        */

        /** Gets the value from an internal field. */
        // [TODO] - Implement Object.GetInternalField (requires: Local!Value)
        /*
        final Local!Value GetInternalField(int index);
        */

        /** Sets the value in an internal field. */
        // [TODO] - Implement Object.SetInternalField (requires: Handle!Value)
        /*
        final void SetInternalField(int index, Handle!Value value);
        */

        /**
         * Gets a 2-byte-aligned native pointer from an internal field. This field
         * must have been set by SetAlignedPointerInInternalField, everything else
         * leads to undefined behavior.
         */
        final void* GetAlignedPointerFromInternalField(int index);

        /** Same as above, but works for Persistents */
        // [TODO] - Implement Object.GetAlignedPointerFromInternalField (requires: PersistantBase!Object)
        /*
        static void* GetAlignedPointerFromInternalField(
            const ref PersistentBase!Object object, int index)
        {
            return object.val_->GetAlignedPointerFromInternalField(index);
        }
        */

        /**
         * Sets a 2-byte-aligned native pointer in an internal field. To retrieve such
         * a field, GetAlignedPointerFromInternalField must be used, everything else
         * leads to undefined behavior.
         */
        final void SetAlignedPointerInInternalField(int index, void* value);

        // Testers for local properties.
        // [TODO] - Implement these (requires: Handle!String)
        //final bool HasOwnProperty(Handle!String key);
        //final bool HasRealNamedProperty(Handle!String key);
        final bool HasRealIndexedProperty(uint32_t index);
        //final bool HasRealNamedCallbackProperty(Handle!String key);

        /**
         * If result.IsEmpty() no real property was located in the prototype chain.
         * This means interceptors in the prototype chain are not called.
         */
        // [TODO] - Implement Object.GetRealNamedPropertyInPrototypeChain (requires: Handle!String, Local!Value)
        /*
        final Local!Value GetRealNamedPropertyInPrototypeChain(Handle!String key);
        */

        /**
         * If result.IsEmpty() no real property was located on the object or
         * in the prototype chain.
         * This means interceptors in the prototype chain are not called.
         */
        // [TODO] - Implement Object.GetRealNamedProperty (requires: Handle!String, Local!Value)
        /*
        final Local!Value GetRealNamedProperty(Handle!String key);
        */

        /** Tests for a named lookup interceptor.*/
        final bool HasNamedLookupInterceptor();

        /** Tests for an index lookup interceptor.*/
        final bool HasIndexedLookupInterceptor();

        /**
         * Turns on access check on the object if the object is an instance of
         * a template that has access check callbacks. If an object has no
         * access check info, the object cannot be accessed by anyone.
         */
        final void TurnOnAccessCheck();

        /**
         * Returns the identity hash for this object. The current implementation
         * uses a hidden property on the object to store the identity hash.
         *
         * The return value will never be 0. Also, it is not guaranteed to be
         * unique.
         */
        final int GetIdentityHash();

        /**
         * Access hidden properties on JavaScript objects. These properties are
         * hidden from the executing JavaScript and only accessible through the V8
         * C++ API. Hidden properties introduced by V8 internally (for example the
         * identity hash) are prefixed with "v8::".
         */
        // [TODO] - Implement these (requires: Handle!Value, Handle!String)
        /*
        final bool SetHiddenValue(Handle!String key, Handle!Value value);
        final Local<Value> GetHiddenValue(Handle!String key);
        final bool DeleteHiddenValue(Handle!String key);
        */

        /**
         * Returns true if this is an instance of an api function (one
         * created from a function created from a function template) and has
         * been modified since it was created.  Note that this method is
         * conservative and may return true for objects that haven't actually
         * been modified.
         */
        final bool IsDirty();

        /**
         * Clone this object with a fast but shallow copy.  Values will point
         * to the same values as the original object.
         */
        // [TODO] - Implement Object.Clone (requires: Local!Object)
        /*
        Local!Object Clone();
        */

        /**
         * Returns the context in which the object was created.
         */
        // [TODO] - Implement Object.CreationContext (requires: Local!Context)
        /*
        final Local!Context CreationContext();
        */

        /**
         * Set the backing store of the indexed properties to be managed by the
         * embedding layer. Access to the indexed properties will follow the rules
         * spelled out in CanvasPixelArray.
         * Note: The embedding program still owns the data and needs to ensure that
         *       the backing store is preserved while V8 has a reference.
         */
        final void SetIndexedPropertiesToPixelData(uint8_t* data, int length);
        final bool HasIndexedPropertiesInPixelData();
        final uint8_t* GetIndexedPropertiesPixelData();
        final int GetIndexedPropertiesPixelDataLength();

        /**
         * Set the backing store of the indexed properties to be managed by the
         * embedding layer. Access to the indexed properties will follow the rules
         * spelled out for the CanvasArray subtypes in the WebGL specification.
         * Note: The embedding program still owns the data and needs to ensure that
         *       the backing store is preserved while V8 has a reference.
         */
        // [TODO] - Implement Object.SetIndexedPropertiesToExternalArrayData (requires: ExternalArrayType)
        /*
        final void SetIndexedPropertiesToExternalArrayData(void* data,
                                                     ExternalArrayType array_type,
                                                     int number_of_elements);
        */
        final bool HasIndexedPropertiesInExternalArrayData();
        final void* GetIndexedPropertiesExternalArrayData();
        // [TODO] - Implement Object.GetIndexedPropertiesExternalArrayDataType (requires: ExternalArrayType)
        /*
        final ExternalArrayType GetIndexedPropertiesExternalArrayDataType();
        */
        final int GetIndexedPropertiesExternalArrayDataLength();

        /**
         * Checks whether a callback is set by the
         * ObjectTemplate::SetCallAsFunctionHandler method.
         * When an Object is callable this method returns true.
         */
        final bool IsCallable();

        /**
         * Call an Object as a function if a callback is set by the
         * ObjectTemplate::SetCallAsFunctionHandler method.
         */
        // [TODO] - Implement Object.CallAsFunction (requires: Local!Value, Handle!Value)
        /*
        final Local!Value CallAsFunction(Handle!Value recv,
                                         int argc,
                                         Handle!Value argv);
        */

        /**
         * Call an Object as a constructor if a callback is set by the
         * ObjectTemplate::SetCallAsFunctionHandler method.
         * Note: This method behaves like the Function::NewInstance method.
         */
        // [TODO] - Implement Object.CallAsConstructor (requires: Local!Value, Handle!Value)
        /*
        final Local!Value CallAsConstructor( int argc, Handle!Value argv );
        */

        static Local!Object New( Isolate* isolate );
        static Object Cast( Value obj );
    }

    class Handle( T )
    {
        final void Clear();
    }

    class Local( T ) : Handle!T
    {
    }

    extern( C++, platform )
    {
        // [TODO] - Investigate Linker errors. Problems appear to be with a lack of exporting.
        //Platform CreateDefaultPlatform( int thread_pool_size = 0 );
    }
}
