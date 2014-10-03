module v8.v8;

extern( C++, v8 ) // namespace v8
{
    struct Value
    {

    }

    class Handle( Value )
    {
        void Clear();
    }
}
