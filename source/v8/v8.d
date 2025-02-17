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
        // [TODO] - Implement properly once D's C++ ABI supports ctors
        //this( Isolate isolate );

        /**
         * Counts the number of allocated handles.
         */
        static int NumberOfHandles( Isolate isolate );
        final Isolate GetIsolate() const;
    }

    /**
     * A container for extension names.
     */
    class ExtensionConfiguration
    {
    public:
        this() { name_count_ = 0; names_ = null; }
        this(int name_count, const char** names) { name_count_ = name_count; names_ = names; }

        const(char**) begin() const { return &names_[0]; }
        const(char**) end()  const { return &names_[name_count_]; }

    private:
        const int name_count_;
        const char** names_;
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
            Isolate isolate,
            ExtensionConfiguration extensions = null,
            Handle!ObjectTemplate global_template = null,
            Handle!Value global_object = null);
        //*/

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

        /**
         * Enter this context.  After entering a context, all code compiled
         * and run is compiled and run in this context.  If another context
         * is already entered, this old context is saved so it can be
         * restored when the new context is exited.
         */
        final void Enter();

        /**
         * Exit this context.  Exiting the current context restores the
         * context that was in place when entering the current context.
         */
        final void Exit();

        /** Returns an isolate associated with a current context. */
        final Isolate GetIsolate();

        /**
         * Stack-allocated class which sets the execution context for all
         * operations executed within a local scope.
         */
        static struct Scope
        {
        public:
            this(Handle!Context context)
            {
                context_ = context;
                context_.Enter();
            }
            ~this() { context_.Exit(); }

        private:
            Handle!Context context_;
        }
    }

    class Value
    {
    public:
        /**
         * Returns true if this value is the undefined value.  See ECMA-262
         * 4.3.10.
         */
        final bool IsUndefined() const;

        /**
         * Returns true if this value is the null value.  See ECMA-262
         * 4.3.11.
         */
        final bool IsNull() const;

        /**
         * Returns true if this value is true.
         */
        final bool IsTrue() const;

        /**
         * Returns true if this value is false.
         */
        final bool IsFalse() const;

        /**
         * Returns true if this value is a symbol or a string.
         * This is an experimental feature.
         */
        final bool IsName() const;

        /**
         * Returns true if this value is an instance of the String type.
         * See ECMA-262 8.4.
         */
        final bool IsString() const;

        /**
         * Returns true if this value is a symbol.
         * This is an experimental feature.
         */
        final bool IsSymbol() const;

        /**
         * Returns true if this value is a function.
         */
        final bool IsFunction() const;

        /**
         * Returns true if this value is an array.
         */
        final bool IsArray() const;

        /**
         * Returns true if this value is an object.
         */
        final bool IsObject() const;

        /**
         * Returns true if this value is boolean.
         */
        final bool IsBoolean() const;

        /**
         * Returns true if this value is a number.
         */
        final bool IsNumber() const;

        /**
         * Returns true if this value is external.
         */
        final bool IsExternal() const;

        /**
         * Returns true if this value is a 32-bit signed integer.
         */
        final bool IsInt32() const;

        /**
         * Returns true if this value is a 32-bit unsigned integer.
         */
        final bool IsUint32() const;

        /**
         * Returns true if this value is a Date.
         */
        final bool IsDate() const;

        /**
         * Returns true if this value is an Arguments object.
         */
        final bool IsArgumentsObject() const;

        /**
         * Returns true if this value is a Boolean object.
         */
        final bool IsBooleanObject() const;

        /**
         * Returns true if this value is a Number object.
         */
        final bool IsNumberObject() const;

        /**
         * Returns true if this value is a String object.
         */
        final bool IsStringObject() const;

        /**
         * Returns true if this value is a Symbol object.
         * This is an experimental feature.
         */
        final bool IsSymbolObject() const;

        /**
         * Returns true if this value is a NativeError.
         */
        final bool IsNativeError() const;

        /**
         * Returns true if this value is a RegExp.
         */
        final bool IsRegExp() const;

        /**
         * Returns true if this value is a Generator function.
         * This is an experimental feature.
         */
        final bool IsGeneratorFunction() const;

        /**
         * Returns true if this value is a Generator object (iterator).
         * This is an experimental feature.
         */
        final bool IsGeneratorObject() const;

        /**
         * Returns true if this value is a Promise.
         * This is an experimental feature.
         */
        final bool IsPromise() const;

        /**
         * Returns true if this value is a Map.
         * This is an experimental feature.
         */
        final bool IsMap() const;

        /**
         * Returns true if this value is a Set.
         * This is an experimental feature.
         */
        final bool IsSet() const;

        /**
         * Returns true if this value is a WeakMap.
         * This is an experimental feature.
         */
        final bool IsWeakMap() const;

        /**
         * Returns true if this value is a WeakSet.
         * This is an experimental feature.
         */
        final bool IsWeakSet() const;

        /**
         * Returns true if this value is an ArrayBuffer.
         * This is an experimental feature.
         */
        final bool IsArrayBuffer() const;

        /**
         * Returns true if this value is an ArrayBufferView.
         * This is an experimental feature.
         */
        final bool IsArrayBufferView() const;

        /**
         * Returns true if this value is one of TypedArrays.
         * This is an experimental feature.
         */
        final bool IsTypedArray() const;

        /**
         * Returns true if this value is an Uint8Array.
         * This is an experimental feature.
         */
        final bool IsUint8Array() const;

        /**
         * Returns true if this value is an Uint8ClampedArray.
         * This is an experimental feature.
         */
        final bool IsUint8ClampedArray() const;

        /**
         * Returns true if this value is an Int8Array.
         * This is an experimental feature.
         */
        final bool IsInt8Array() const;

        /**
         * Returns true if this value is an Uint16Array.
         * This is an experimental feature.
         */
        final bool IsUint16Array() const;

        /**
         * Returns true if this value is an Int16Array.
         * This is an experimental feature.
         */
        final bool IsInt16Array() const;

        /**
         * Returns true if this value is an Uint32Array.
         * This is an experimental feature.
         */
        final bool IsUint32Array() const;

        /**
         * Returns true if this value is an Int32Array.
         * This is an experimental feature.
         */
        final bool IsInt32Array() const;

        /**
         * Returns true if this value is a Float32Array.
         * This is an experimental feature.
         */
        final bool IsFloat32Array() const;

        /**
         * Returns true if this value is a Float64Array.
         * This is an experimental feature.
         */
        final bool IsFloat64Array() const;

        /**
         * Returns true if this value is a DataView.
         * This is an experimental feature.
         */
        final bool IsDataView() const;

        // [TODO] - Implement these (requires: Local!*)
        /*
        final Local!Boolean ToBoolean() const;
        final Local!Number ToNumber() const;
        final Local!String ToString() const;
        final Local!String ToDetailString() const;
        final Local!Object ToObject() const;
        final Local!Integer ToInteger() const;
        final Local!Uint32 ToUint32() const;
        final Local!Int32 ToInt32() const;
        */

        /**
         * Attempts to convert a string to an array index.
         * Returns an empty handle if the conversion fails.
         */
        // [TODO] - Implement Value.ToArrayIndex (requires: Local!Uint32)
        /*
        final Local!Uint32 ToArrayIndex() const;
        */

        final bool BooleanValue() const;
        final double NumberValue() const;
        final int64_t IntegerValue() const;
        final uint32_t Uint32Value() const;
        final int32_t Int32Value() const;

        /** JS == */
        // [TODO] Implement these (requires: Handle!Value)
        /*
        final bool Equals(Handle!Value that) const;
        final bool StrictEquals(Handle!Value that) const;
        final bool SameValue(Handle!Value that) const;
        */

        static Value* Cast(T)(T* value);

    private:
        final bool QuickIsUndefined() const;
        final bool QuickIsNull() const;
        final bool QuickIsString() const;
        final bool FullIsUndefined() const;
        final bool FullIsNull() const;
        final bool FullIsString() const;
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

    private:
        static void CheckCast(Value obj);
        // [TODO] - Implement Object.SlowGetInternalField (requires: Local!Value)
        /*
        final Local!Value SlowGetInternalField(int index);
        */
        final void* SlowGetAlignedPointerFromInternalField(int index);
    }

    /**
     * An object reference managed by the v8 garbage collector.
     *
     * All objects returned from v8 have to be tracked by the garbage
     * collector so that it knows that the objects are still alive.  Also,
     * because the garbage collector may move objects, it is unsafe to
     * point directly to an object.  Instead, all objects are stored in
     * handles which are known by the garbage collector and updated
     * whenever an object moves.  Handles should always be passed by value
     * (except in cases like out-parameters) and they should never be
     * allocated on the heap.
     *
     * There are two types of handles: local and persistent handles.
     * Local handles are light-weight and transient and typically used in
     * local operations.  They are managed by HandleScopes.  Persistent
     * handles can be used when storing objects across several independent
     * operations and have to be explicitly deallocated when they're no
     * longer used.
     *
     * It is safe to extract the object stored in the handle by
     * dereferencing the handle (for instance, to extract the Object* from
     * a Handle<Object>); the value will still be governed by a handle
     * behind the scenes and the same rules apply to these values as to
     * their handles.
     */
    class Handle(T)
    {
    private:
        static if(is(T == class))
            alias StorageT = T;
        else
            alias StorageT = T*;

        StorageT val_;

    public:
        /**
         * Creates an empty handle.
         */
        this() { val_ = null; }

        /**
         * Creates a handle for the contents of the specified handle.  This
         * constructor allows you to pass handles as arguments by value and
         * to assign between handles.  However, if you try to assign between
         * incompatible handles, for instance from a Handle<String> to a
         * Handle<Number> it will cause a compile-time error.  Assigning
         * between compatible handles, for instance assigning a
         * Handle<String> to a variable declared as Handle<Value>, is legal
         * because String is a subclass of Value.
         */
        this(S)(Handle!S that) if (TYPE_CHECK!(T, S))
        {
            val_ = cast(StorageT)that.val_;
        }

        /**
         * Returns true if the handle is empty.
         */
        bool IsEmpty() const { return val_ is null; }

        /**
         * Sets the handle to be empty. IsEmpty() will then return true.
         */
        final void Clear() { val_ = null; }

        static Handle!T Cast(S)(Handle!S that)
        {
            version(V8_ENABLE_CHECKS)
            {
                if (that.IsEmpty()) return new Handle!T();
            }

            return Handle!T(T.Cast(val_));
        }

        // [TODO] - Tons of missing functions here

        StorageT get() { return val_; }
        alias get this;

    private:
        /**
         * Creates a new handle for the specified value.
         */
        this(StorageT val) { val_ = val; }

        static Handle!T New(Isolate isolate, StorageT that);
    }

    /**
     * A light-weight stack-allocated object handle.  All operations
     * that return objects from within v8 return them in local handles.  They
     * are created within HandleScopes, and all local handles allocated within a
     * handle scope are destroyed when the handle scope is destroyed.  Hence it
     * is not necessary to explicitly deallocate local handles.
     */
    class Local(T) : Handle!T
    {
    public:
        this(S)(Local!S that)
        {
            super(cast(StorageT)that.val_);

            /**
             * This check fails when trying to convert between incompatible
             * handles. For example, converting from a Handle<String> to a
             * Handle<Number>.
             */
            TYPE_CHECK!(T, S);
        }

        static Local!T Cast(S)(Local!S that)
        {
            version(V8_ENABLE_CHECKS)
            {
                if (that.IsEmpty()) return new Local!T();
            }

            return Local!T(T.Cast(val_));
        }

    private:
        static if(is(T == class))
            alias StorageT = T;
        else
            alias StorageT = T*;

        StorageT val_;
    }

    extern( C++, platform )
    {
        // [TODO] - Investigate Linker errors. Problems appear to be with a lack of exporting.
        //Platform CreateDefaultPlatform( int thread_pool_size = 0 );
    }
}
