// D import file generated from 'src/core/sync/config.d'
module core.sync.config;
version (Posix)
{
	private import core.sys.posix.time;
	private import core.sys.posix.sys.time;
	private import core.time;
	nothrow void mktspec(ref timespec t);
	nothrow void mktspec(ref timespec t, Duration delta);
	nothrow void mvtspec(ref timespec t, Duration delta);
}
