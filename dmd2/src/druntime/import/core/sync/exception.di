// D import file generated from 'src/core/sync/exception.d'
module core.sync.exception;
class SyncError : Error
{
	pure nothrow @safe this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null);
	pure nothrow @safe this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__);
}
