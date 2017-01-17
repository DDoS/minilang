// Written in the D programming language.
/**
This is a submodule of $(MREF std, algorithm).
It contains generic _searching algorithms.

$(BOOKTABLE Cheat Sheet,
$(TR $(TH Function Name) $(TH Description))
$(T2 all,
        $(D all!"a > 0"([1, 2, 3, 4])) returns $(D true) because all elements
        are positive)
$(T2 any,
        $(D any!"a > 0"([1, 2, -3, -4])) returns $(D true) because at least one
        element is positive)
$(T2 balancedParens,
        $(D balancedParens("((1 + 1) / 2)")) returns $(D true) because the
        string has balanced parentheses.)
$(T2 boyerMooreFinder,
        $(D find("hello world", boyerMooreFinder("or"))) returns $(D "orld")
        using the $(LUCKY Boyer-Moore _algorithm).)
$(T2 canFind,
        $(D canFind("hello world", "or")) returns $(D true).)
$(T2 count,
        Counts elements that are equal to a specified value or satisfy a
        predicate.  $(D count([1, 2, 1], 1)) returns $(D 2) and
        $(D count!"a < 0"([1, -3, 0])) returns $(D 1).)
$(T2 countUntil,
        $(D countUntil(a, b)) returns the number of steps taken in $(D a) to
        reach $(D b); for example, $(D countUntil("hello!", "o")) returns
        $(D 4).)
$(T2 commonPrefix,
        $(D commonPrefix("parakeet", "parachute")) returns $(D "para").)
$(T2 endsWith,
        $(D endsWith("rocks", "ks")) returns $(D true).)
$(T2 find,
        $(D find("hello world", "or")) returns $(D "orld") using linear search.
        (For binary search refer to $(REF sortedRange, std,range).))
$(T2 findAdjacent,
        $(D findAdjacent([1, 2, 3, 3, 4])) returns the subrange starting with
        two equal adjacent elements, i.e. $(D [3, 3, 4]).)
$(T2 findAmong,
        $(D findAmong("abcd", "qcx")) returns $(D "cd") because $(D 'c') is
        among $(D "qcx").)
$(T2 findSkip,
        If $(D a = "abcde"), then $(D findSkip(a, "x")) returns $(D false) and
        leaves $(D a) unchanged, whereas $(D findSkip(a, "c")) advances $(D a)
        to $(D "de") and returns $(D true).)
$(T2 findSplit,
        $(D findSplit("abcdefg", "de")) returns the three ranges $(D "abc"),
        $(D "de"), and $(D "fg").)
$(T2 findSplitAfter,
        $(D findSplitAfter("abcdefg", "de")) returns the two ranges
        $(D "abcde") and $(D "fg").)
$(T2 findSplitBefore,
        $(D findSplitBefore("abcdefg", "de")) returns the two ranges $(D "abc")
        and $(D "defg").)
$(T2 minCount,
        $(D minCount([2, 1, 1, 4, 1])) returns $(D tuple(1, 3)).)
$(T2 maxCount,
        $(D maxCount([2, 4, 1, 4, 1])) returns $(D tuple(4, 2)).)
$(T2 minElement,
        Selects the minimal element of a range.
        `minElement([3, 4, 1, 2])` returns `1`.)
$(T2 maxElement,
        Selects the maximal element of a range.
        `maxElement([3, 4, 1, 2])` returns `4`.)
$(T2 minPos,
        $(D minPos([2, 3, 1, 3, 4, 1])) returns the subrange $(D [1, 3, 4, 1]),
        i.e., positions the range at the first occurrence of its minimal
        element.)
$(T2 maxPos,
        $(D maxPos([2, 3, 1, 3, 4, 1])) returns the subrange $(D [4, 1]),
        i.e., positions the range at the first occurrence of its maximal
        element.)
$(T2 mismatch,
        $(D mismatch("parakeet", "parachute")) returns the two ranges
        $(D "keet") and $(D "chute").)
$(T2 skipOver,
        Assume $(D a = "blah"). Then $(D skipOver(a, "bi")) leaves $(D a)
        unchanged and returns $(D false), whereas $(D skipOver(a, "bl"))
        advances $(D a) to refer to $(D "ah") and returns $(D true).)
$(T2 startsWith,
        $(D startsWith("hello, world", "hello")) returns $(D true).)
$(T2 until,
        Lazily iterates a range until a specific value is found.)
)

Copyright: Andrei Alexandrescu 2008-.

License: $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).

Authors: $(HTTP erdani.com, Andrei Alexandrescu)

Source: $(PHOBOSSRC std/algorithm/_searching.d)

Macros:
T2=$(TR $(TDNW $(LREF $1)) $(TD $+))
 */
module std.algorithm.searching;

// FIXME
import std.functional; // : unaryFun, binaryFun;
import std.range.primitives;
import std.traits;
// FIXME
import std.typecons; // : Tuple, Flag, Yes, No;

/++
Checks if $(I _all) of the elements verify $(D pred).
 +/
template all(alias pred = "a")
{
    /++
    Returns $(D true) if and only if $(I _all) values $(D v) found in the
    input _range $(D range) satisfy the predicate $(D pred).
    Performs (at most) $(BIGOH range.length) evaluations of $(D pred).
     +/
    bool all(Range)(Range range)
    if (isInputRange!Range && is(typeof(unaryFun!pred(range.front))))
    {
        import std.functional : not;

        return find!(not!(unaryFun!pred))(range).empty;
    }
}

///
@safe unittest
{
    assert( all!"a & 1"([1, 3, 5, 7, 9]));
    assert(!all!"a & 1"([1, 2, 3, 5, 7, 9]));
}

/++
$(D all) can also be used without a predicate, if its items can be
evaluated to true or false in a conditional statement. This can be a
convenient way to quickly evaluate that $(I _all) of the elements of a range
are true.
 +/
@safe unittest
{
    int[3] vals = [5, 3, 18];
    assert( all(vals[]));
}

@safe unittest
{
    int x = 1;
    assert(all!(a => a > x)([2, 3]));
}

/++
Checks if $(I _any) of the elements verifies $(D pred).
$(D !any) can be used to verify that $(I none) of the elements verify
$(D pred).
 +/
template any(alias pred = "a")
{
    /++
    Returns $(D true) if and only if $(I _any) value $(D v) found in the
    input _range $(D range) satisfies the predicate $(D pred).
    Performs (at most) $(BIGOH range.length) evaluations of $(D pred).
     +/
    bool any(Range)(Range range)
    if (isInputRange!Range && is(typeof(unaryFun!pred(range.front))))
    {
        return !find!pred(range).empty;
    }
}

///
@safe unittest
{
    import std.ascii : isWhite;
    assert( all!(any!isWhite)(["a a", "b b"]));
    assert(!any!(all!isWhite)(["a a", "b b"]));
}

/++
$(D any) can also be used without a predicate, if its items can be
evaluated to true or false in a conditional statement. $(D !any) can be a
convenient way to quickly test that $(I none) of the elements of a range
evaluate to true.
 +/
@safe unittest
{
    int[3] vals1 = [0, 0, 0];
    assert(!any(vals1[])); //none of vals1 evaluate to true

    int[3] vals2 = [2, 0, 2];
    assert( any(vals2[]));
    assert(!all(vals2[]));

    int[3] vals3 = [3, 3, 3];
    assert( any(vals3[]));
    assert( all(vals3[]));
}

@safe unittest
{
    debug(std_algorithm) scope(success)
        writeln("unittest @", __FILE__, ":", __LINE__, " done.");
    auto a = [ 1, 2, 0, 4 ];
    assert(any!"a == 2"(a));
}

// balancedParens
/**
Checks whether $(D r) has "balanced parentheses", i.e. all instances
of $(D lPar) are closed by corresponding instances of $(D rPar). The
parameter $(D maxNestingLevel) controls the nesting level allowed. The
most common uses are the default or $(D 0). In the latter case, no
nesting is allowed.

Params:
    r = The range to check.
    lPar = The element corresponding with a left (opening) parenthesis.
    rPar = The element corresponding with a right (closing) parenthesis.
    maxNestingLevel = The maximum allowed nesting level.

Returns:
    true if the given range has balanced parenthesis within the given maximum
    nesting level; false otherwise.
*/
bool balancedParens(Range, E)(Range r, E lPar, E rPar,
        size_t maxNestingLevel = size_t.max)
if (isInputRange!(Range) && is(typeof(r.front == lPar)))
{
    size_t count;
    for (; !r.empty; r.popFront())
    {
        if (r.front == lPar)
        {
            if (count > maxNestingLevel) return false;
            ++count;
        }
        else if (r.front == rPar)
        {
            if (!count) return false;
            --count;
        }
    }
    return count == 0;
}

///
@safe unittest
{
    auto s = "1 + (2 * (3 + 1 / 2)";
    assert(!balancedParens(s, '(', ')'));
    s = "1 + (2 * (3 + 1) / 2)";
    assert(balancedParens(s, '(', ')'));
    s = "1 + (2 * (3 + 1) / 2)";
    assert(!balancedParens(s, '(', ')', 0));
    s = "1 + (2 * 3 + 1) / (2 - 5)";
    assert(balancedParens(s, '(', ')', 0));
}

/**
 * Sets up Boyer-Moore matching for use with $(D find) below.
 * By default, elements are compared for equality.
 *
 * $(D BoyerMooreFinder) allocates GC memory.
 *
 * Params:
 * pred = Predicate used to compare elements.
 * needle = A random-access range with length and slicing.
 *
 * Returns:
 * An instance of $(D BoyerMooreFinder) that can be used with $(D find()) to
 * invoke the Boyer-Moore matching algorithm for finding of $(D needle) in a
 * given haystack.
 */
BoyerMooreFinder!(binaryFun!(pred), Range) boyerMooreFinder
(alias pred = "a == b", Range)
(Range needle) if ((isRandomAccessRange!(Range) && hasSlicing!Range) || isSomeString!Range)
{
    return typeof(return)(needle);
}

/// Ditto
struct BoyerMooreFinder(alias pred, Range)
{
private:
    size_t[] skip;                              // GC allocated
    ptrdiff_t[ElementType!(Range)] occ;         // GC allocated
    Range needle;

    ptrdiff_t occurrence(ElementType!(Range) c)
    {
        auto p = c in occ;
        return p ? *p : -1;
    }

/*
This helper function checks whether the last "portion" bytes of
"needle" (which is "nlen" bytes long) exist within the "needle" at
offset "offset" (counted from the end of the string), and whether the
character preceding "offset" is not a match.  Notice that the range
being checked may reach beyond the beginning of the string. Such range
is ignored.
 */
    static bool needlematch(R)(R needle,
                              size_t portion, size_t offset)
    {
        import std.algorithm.comparison : equal;
        ptrdiff_t virtual_begin = needle.length - offset - portion;
        ptrdiff_t ignore = 0;
        if (virtual_begin < 0)
        {
            ignore = -virtual_begin;
            virtual_begin = 0;
        }
        if (virtual_begin > 0
            && needle[virtual_begin - 1] == needle[$ - portion - 1])
            return 0;

        immutable delta = portion - ignore;
        return equal(needle[needle.length - delta .. needle.length],
                needle[virtual_begin .. virtual_begin + delta]);
    }

public:
    ///
    this(Range needle)
    {
        if (!needle.length) return;
        this.needle = needle;
        /* Populate table with the analysis of the needle */
        /* But ignoring the last letter */
        foreach (i, n ; needle[0 .. $ - 1])
        {
            this.occ[n] = i;
        }
        /* Preprocess #2: init skip[] */
        /* Note: This step could be made a lot faster.
         * A simple implementation is shown here. */
        this.skip = new size_t[needle.length];
        foreach (a; 0 .. needle.length)
        {
            size_t value = 0;
            while (value < needle.length
                   && !needlematch(needle, a, value))
            {
                ++value;
            }
            this.skip[needle.length - a - 1] = value;
        }
    }

    ///
    Range beFound(Range haystack)
    {
        import std.algorithm.comparison : max;

        if (!needle.length) return haystack;
        if (needle.length > haystack.length) return haystack[$ .. $];
        /* Search: */
        immutable limit = haystack.length - needle.length;
        for (size_t hpos = 0; hpos <= limit; )
        {
            size_t npos = needle.length - 1;
            while (pred(needle[npos], haystack[npos+hpos]))
            {
                if (npos == 0) return haystack[hpos .. $];
                --npos;
            }
            hpos += max(skip[npos], cast(sizediff_t) npos - occurrence(haystack[npos+hpos]));
        }
        return haystack[$ .. $];
    }

    ///
    @property size_t length()
    {
        return needle.length;
    }

    ///
    alias opDollar = length;
}

/**
Returns the common prefix of two ranges.

Params:
    pred = The predicate to use in comparing elements for commonality. Defaults
        to equality $(D "a == b").

    r1 = A $(REF_ALTTEXT forward range, isForwardRange, std,range,primitives) of
        elements.

    r2 = An $(REF_ALTTEXT input range, isInputRange, std,range,primitives) of
        elements.

Returns:
A slice of $(D r1) which contains the characters that both ranges start with,
if the first argument is a string; otherwise, the same as the result of
$(D takeExactly(r1, n)), where $(D n) is the number of elements in the common
prefix of both ranges.

See_Also:
    $(REF takeExactly, std,range)
 */
auto commonPrefix(alias pred = "a == b", R1, R2)(R1 r1, R2 r2)
if (isForwardRange!R1 && isInputRange!R2 &&
    !isNarrowString!R1 &&
    is(typeof(binaryFun!pred(r1.front, r2.front))))
{
    import std.algorithm.comparison : min;
    static if (isRandomAccessRange!R1 && isRandomAccessRange!R2 &&
               hasLength!R1 && hasLength!R2 &&
               hasSlicing!R1)
    {
        immutable limit = min(r1.length, r2.length);
        foreach (i; 0 .. limit)
        {
            if (!binaryFun!pred(r1[i], r2[i]))
            {
                return r1[0 .. i];
            }
        }
        return r1[0 .. limit];
    }
    else
    {
        import std.range : takeExactly;
        auto result = r1.save;
        size_t i = 0;
        for (;
             !r1.empty && !r2.empty && binaryFun!pred(r1.front, r2.front);
             ++i, r1.popFront(), r2.popFront())
        {}
        return takeExactly(result, i);
    }
}

///
@safe unittest
{
    assert(commonPrefix("hello, world", "hello, there") == "hello, ");
}

/// ditto
auto commonPrefix(alias pred, R1, R2)(R1 r1, R2 r2)
if (isNarrowString!R1 && isInputRange!R2 &&
    is(typeof(binaryFun!pred(r1.front, r2.front))))
{
    import std.utf : decode;

    auto result = r1.save;
    immutable len = r1.length;
    size_t i = 0;

    for (size_t j = 0; i < len && !r2.empty; r2.popFront(), i = j)
    {
        immutable f = decode(r1, j);
        if (!binaryFun!pred(f, r2.front))
            break;
    }

    return result[0 .. i];
}

/// ditto
auto commonPrefix(R1, R2)(R1 r1, R2 r2)
if (isNarrowString!R1 && isInputRange!R2 && !isNarrowString!R2 &&
    is(typeof(r1.front == r2.front)))
{
    return commonPrefix!"a == b"(r1, r2);
}

/// ditto
auto commonPrefix(R1, R2)(R1 r1, R2 r2)
if (isNarrowString!R1 && isNarrowString!R2)
{
    import std.algorithm.comparison : min;

    static if (ElementEncodingType!R1.sizeof == ElementEncodingType!R2.sizeof)
    {
        import std.utf : stride, UTFException;

        immutable limit = min(r1.length, r2.length);
        for (size_t i = 0; i < limit;)
        {
            immutable codeLen = stride(r1, i);
            size_t j = 0;

            for (; j < codeLen && i < limit; ++i, ++j)
            {
                if (r1[i] != r2[i])
                    return r1[0 .. i - j];
            }

            if (i == limit && j < codeLen)
                throw new UTFException("Invalid UTF-8 sequence", i);
        }
        return r1[0 .. limit];
    }
    else
        return commonPrefix!"a == b"(r1, r2);
}

@safe unittest
{
    import std.algorithm.comparison : equal;
    import std.algorithm.iteration : filter;
    import std.conv : to;
    import std.exception : assertThrown;
    import std.meta : AliasSeq;
    import std.range;
    import std.utf : UTFException;

    assert(commonPrefix([1, 2, 3], [1, 2, 3, 4, 5]) == [1, 2, 3]);
    assert(commonPrefix([1, 2, 3, 4, 5], [1, 2, 3]) == [1, 2, 3]);
    assert(commonPrefix([1, 2, 3, 4], [1, 2, 3, 4]) == [1, 2, 3, 4]);
    assert(commonPrefix([1, 2, 3], [7, 2, 3, 4, 5]).empty);
    assert(commonPrefix([7, 2, 3, 4, 5], [1, 2, 3]).empty);
    assert(commonPrefix([1, 2, 3], cast(int[])null).empty);
    assert(commonPrefix(cast(int[])null, [1, 2, 3]).empty);
    assert(commonPrefix(cast(int[])null, cast(int[])null).empty);

    foreach (S; AliasSeq!(char[], const(char)[], string,
                          wchar[], const(wchar)[], wstring,
                          dchar[], const(dchar)[], dstring))
    {
        foreach (T; AliasSeq!(string, wstring, dstring))
        (){ // avoid slow optimizations for large functions @@@BUG@@@ 2396
            assert(commonPrefix(to!S(""), to!T("")).empty);
            assert(commonPrefix(to!S(""), to!T("hello")).empty);
            assert(commonPrefix(to!S("hello"), to!T("")).empty);
            assert(commonPrefix(to!S("hello, world"), to!T("hello, there")) == to!S("hello, "));
            assert(commonPrefix(to!S("hello, there"), to!T("hello, world")) == to!S("hello, "));
            assert(commonPrefix(to!S("hello, "), to!T("hello, world")) == to!S("hello, "));
            assert(commonPrefix(to!S("hello, world"), to!T("hello, ")) == to!S("hello, "));
            assert(commonPrefix(to!S("hello, world"), to!T("hello, world")) == to!S("hello, world"));

            //Bug# 8890
            assert(commonPrefix(to!S("Пиво"), to!T("Пони"))== to!S("П"));
            assert(commonPrefix(to!S("Пони"), to!T("Пиво"))== to!S("П"));
            assert(commonPrefix(to!S("Пиво"), to!T("Пиво"))== to!S("Пиво"));
            assert(commonPrefix(to!S("\U0010FFFF\U0010FFFB\U0010FFFE"),
                                to!T("\U0010FFFF\U0010FFFB\U0010FFFC")) == to!S("\U0010FFFF\U0010FFFB"));
            assert(commonPrefix(to!S("\U0010FFFF\U0010FFFB\U0010FFFC"),
                                to!T("\U0010FFFF\U0010FFFB\U0010FFFE")) == to!S("\U0010FFFF\U0010FFFB"));
            assert(commonPrefix!"a != b"(to!S("Пиво"), to!T("онво")) == to!S("Пи"));
            assert(commonPrefix!"a != b"(to!S("онво"), to!T("Пиво")) == to!S("он"));
        }();

        static assert(is(typeof(commonPrefix(to!S("Пиво"), filter!"true"("Пони"))) == S));
        assert(equal(commonPrefix(to!S("Пиво"), filter!"true"("Пони")), to!S("П")));

        static assert(is(typeof(commonPrefix(filter!"true"("Пиво"), to!S("Пони"))) ==
                      typeof(takeExactly(filter!"true"("П"), 1))));
        assert(equal(commonPrefix(filter!"true"("Пиво"), to!S("Пони")), takeExactly(filter!"true"("П"), 1)));
    }

    assertThrown!UTFException(commonPrefix("\U0010FFFF\U0010FFFB", "\U0010FFFF\U0010FFFB"[0 .. $ - 1]));

    assert(commonPrefix("12345"d, [49, 50, 51, 60, 60]) == "123"d);
    assert(commonPrefix([49, 50, 51, 60, 60], "12345" ) == [49, 50, 51]);
    assert(commonPrefix([49, 50, 51, 60, 60], "12345"d) == [49, 50, 51]);

    assert(commonPrefix!"a == ('0' + b)"("12345" , [1, 2, 3, 9, 9]) == "123");
    assert(commonPrefix!"a == ('0' + b)"("12345"d, [1, 2, 3, 9, 9]) == "123"d);
    assert(commonPrefix!"('0' + a) == b"([1, 2, 3, 9, 9], "12345" ) == [1, 2, 3]);
    assert(commonPrefix!"('0' + a) == b"([1, 2, 3, 9, 9], "12345"d) == [1, 2, 3]);
}

// count
/**
The first version counts the number of elements $(D x) in $(D r) for
which $(D pred(x, value)) is $(D true). $(D pred) defaults to
equality. Performs $(BIGOH haystack.length) evaluations of $(D pred).

The second version returns the number of times $(D needle) occurs in
$(D haystack). Throws an exception if $(D needle.empty), as the _count
of the empty range in any range would be infinite. Overlapped counts
are not considered, for example $(D count("aaa", "aa")) is $(D 1), not
$(D 2).

The third version counts the elements for which $(D pred(x)) is $(D
true). Performs $(BIGOH haystack.length) evaluations of $(D pred).

Note: Regardless of the overload, $(D count) will not accept
infinite ranges for $(D haystack).

Params:
    pred = The predicate to evaluate.
    haystack = The range to _count.
    needle = The element or sub-range to _count in the `haystack`.

Returns:
    The number of positions in the `haystack` for which `pred` returned true.
*/
size_t count(alias pred = "a == b", Range, E)(Range haystack, E needle)
    if (isInputRange!Range && !isInfinite!Range &&
        is(typeof(binaryFun!pred(haystack.front, needle)) : bool))
{
    bool pred2(ElementType!Range a) { return binaryFun!pred(a, needle); }
    return count!pred2(haystack);
}

///
@safe unittest
{
    import std.uni : toLower;

    // count elements in range
    int[] a = [ 1, 2, 4, 3, 2, 5, 3, 2, 4 ];
    assert(count(a, 2) == 3);
    assert(count!("a > b")(a, 2) == 5);
    // count range in range
    assert(count("abcadfabf", "ab") == 2);
    assert(count("ababab", "abab") == 1);
    assert(count("ababab", "abx") == 0);
    // fuzzy count range in range
    assert(count!((a, b) => std.uni.toLower(a) == std.uni.toLower(b))("AbcAdFaBf", "ab") == 2);
    // count predicate in range
    assert(count!("a > 1")(a) == 8);
}

@safe unittest
{
    import std.conv : text;

    debug(std_algorithm) scope(success)
        writeln("unittest @", __FILE__, ":", __LINE__, " done.");

    int[] a = [ 1, 2, 4, 3, 2, 5, 3, 2, 4 ];
    assert(count(a, 2) == 3, text(count(a, 2)));
    assert(count!("a > b")(a, 2) == 5, text(count!("a > b")(a, 2)));

    // check strings
    assert(count("日本語")  == 3);
    assert(count("日本語"w) == 3);
    assert(count("日本語"d) == 3);

    assert(count!("a == '日'")("日本語")  == 1);
    assert(count!("a == '本'")("日本語"w) == 1);
    assert(count!("a == '語'")("日本語"d) == 1);
}

@safe unittest
{
    debug(std_algorithm) printf("algorithm.count.unittest\n");
    string s = "This is a fofofof list";
    string sub = "fof";
    assert(count(s, sub) == 2);
}

/// Ditto
size_t count(alias pred = "a == b", R1, R2)(R1 haystack, R2 needle)
    if (isForwardRange!R1 && !isInfinite!R1 &&
        isForwardRange!R2 &&
        is(typeof(binaryFun!pred(haystack.front, needle.front)) : bool))
{
    assert(!needle.empty, "Cannot count occurrences of an empty range");

    static if (isInfinite!R2)
    {
        //Note: This is the special case of looking for an infinite inside a finite...
        //"How many instances of the Fibonacci sequence can you count in [1, 2, 3]?" - "None."
        return 0;
    }
    else
    {
        size_t result;
        //Note: haystack is not saved, because findskip is designed to modify it
        for ( ; findSkip!pred(haystack, needle.save) ; ++result)
        {}
        return result;
    }
}

/// Ditto
size_t count(alias pred = "true", R)(R haystack)
    if (isInputRange!R && !isInfinite!R &&
        is(typeof(unaryFun!pred(haystack.front)) : bool))
{
    size_t result;
    alias T = ElementType!R; //For narrow strings forces dchar iteration
    foreach (T elem; haystack)
        if (unaryFun!pred(elem)) ++result;
    return result;
}

@safe unittest
{
    debug(std_algorithm) scope(success)
        writeln("unittest @", __FILE__, ":", __LINE__, " done.");
    int[] a = [ 1, 2, 4, 3, 2, 5, 3, 2, 4 ];
    assert(count!("a == 3")(a) == 2);
    assert(count("日本語") == 3);
}

// Issue 11253
@safe nothrow unittest
{
    assert([1, 2, 3].count([2, 3]) == 1);
}

/++
    Counts elements in the given
    $(REF_ALTTEXT forward range, isForwardRange, std,range,primitives)
    until the given predicate is true for one of the given $(D needles).

    Params:
        pred = The predicate for determining when to stop counting.
        haystack = The
            $(REF_ALTTEXT input range, isInputRange, std,range,primitives) to be
            counted.
        needles = Either a single element, or a
            $(REF_ALTTEXT forward range, isForwardRange, std,range,primitives)
            of elements, to be evaluated in turn against each
            element in $(D haystack) under the given predicate.

    Returns: The number of elements which must be popped from the front of
    $(D haystack) before reaching an element for which
    $(D startsWith!pred(haystack, needles)) is $(D true). If
    $(D startsWith!pred(haystack, needles)) is not $(D true) for any element in
    $(D haystack), then $(D -1) is returned.
  +/
ptrdiff_t countUntil(alias pred = "a == b", R, Rs...)(R haystack, Rs needles)
    if (isForwardRange!R
        && Rs.length > 0
        && isForwardRange!(Rs[0]) == isInputRange!(Rs[0])
        && is(typeof(startsWith!pred(haystack, needles[0])))
        && (Rs.length == 1
            || is(typeof(countUntil!pred(haystack, needles[1 .. $])))))
{
    typeof(return) result;

    static if (needles.length == 1)
    {
        static if (hasLength!R) //Note: Narrow strings don't have length.
        {
            //We delegate to find because find is very efficient.
            //We store the length of the haystack so we don't have to save it.
            auto len = haystack.length;
            auto r2 = find!pred(haystack, needles[0]);
            if (!r2.empty)
              return cast(typeof(return)) (len - r2.length);
        }
        else
        {
            import std.range : dropOne;

            if (needles[0].empty)
              return 0;

            //Default case, slower route doing startsWith iteration
            for ( ; !haystack.empty ; ++result )
            {
                //We compare the first elements of the ranges here before
                //forwarding to startsWith. This avoids making useless saves to
                //haystack/needle if they aren't even going to be mutated anyways.
                //It also cuts down on the amount of pops on haystack.
                if (binaryFun!pred(haystack.front, needles[0].front))
                {
                    //Here, we need to save the needle before popping it.
                    //haystack we pop in all paths, so we do that, and then save.
                    haystack.popFront();
                    if (startsWith!pred(haystack.save, needles[0].save.dropOne()))
                      return result;
                }
                else
                  haystack.popFront();
            }
        }
    }
    else
    {
        foreach (i, Ri; Rs)
        {
            static if (isForwardRange!Ri)
            {
                if (needles[i].empty)
                  return 0;
            }
        }
        Tuple!Rs t;
        foreach (i, Ri; Rs)
        {
            static if (!isForwardRange!Ri)
            {
                t[i] = needles[i];
            }
        }
        for (; !haystack.empty ; ++result, haystack.popFront())
        {
            foreach (i, Ri; Rs)
            {
                static if (isForwardRange!Ri)
                {
                    t[i] = needles[i].save;
                }
            }
            if (startsWith!pred(haystack.save, t.expand))
            {
                return result;
            }
        }
    }

    //Because of @@@8804@@@: Avoids both "unreachable code" or "no return statement"
    static if (isInfinite!R) assert(0);
    else return -1;
}

/// ditto
ptrdiff_t countUntil(alias pred = "a == b", R, N)(R haystack, N needle)
    if (isInputRange!R &&
        is(typeof(binaryFun!pred(haystack.front, needle)) : bool))
{
    bool pred2(ElementType!R a) { return binaryFun!pred(a, needle); }
    return countUntil!pred2(haystack);
}

///
@safe unittest
{
    assert(countUntil("hello world", "world") == 6);
    assert(countUntil("hello world", 'r') == 8);
    assert(countUntil("hello world", "programming") == -1);
    assert(countUntil("日本語", "本語") == 1);
    assert(countUntil("日本語", '語')   == 2);
    assert(countUntil("日本語", "五") == -1);
    assert(countUntil("日本語", '五') == -1);
    assert(countUntil([0, 7, 12, 22, 9], [12, 22]) == 2);
    assert(countUntil([0, 7, 12, 22, 9], 9) == 4);
    assert(countUntil!"a > b"([0, 7, 12, 22, 9], 20) == 3);
}

@safe unittest
{
    import std.algorithm.iteration : filter;
    import std.internal.test.dummyrange;

    assert(countUntil("日本語", "") == 0);
    assert(countUntil("日本語"d, "") == 0);

    assert(countUntil("", "") == 0);
    assert(countUntil("".filter!"true"(), "") == 0);

    auto rf = [0, 20, 12, 22, 9].filter!"true"();
    assert(rf.countUntil!"a > b"((int[]).init) == 0);
    assert(rf.countUntil!"a > b"(20) == 3);
    assert(rf.countUntil!"a > b"([20, 8]) == 3);
    assert(rf.countUntil!"a > b"([20, 10]) == -1);
    assert(rf.countUntil!"a > b"([20, 8, 0]) == -1);

    auto r = new ReferenceForwardRange!int([0, 1, 2, 3, 4, 5, 6]);
    auto r2 = new ReferenceForwardRange!int([3, 4]);
    auto r3 = new ReferenceForwardRange!int([3, 5]);
    assert(r.save.countUntil(3)  == 3);
    assert(r.save.countUntil(r2) == 3);
    assert(r.save.countUntil(7)  == -1);
    assert(r.save.countUntil(r3) == -1);
}

@safe unittest
{
    assert(countUntil("hello world", "world", "asd") == 6);
    assert(countUntil("hello world", "world", "ello") == 1);
    assert(countUntil("hello world", "world", "") == 0);
    assert(countUntil("hello world", "world", 'l') == 2);
}

/++
    Similar to the previous overload of $(D countUntil), except that this one
    evaluates only the predicate $(D pred).

    Params:
        pred = Predicate to when to stop counting.
        haystack = An
          $(REF_ALTTEXT input range, isInputRange, std,range,primitives) of
          elements to be counted.
    Returns: The number of elements which must be popped from $(D haystack)
    before $(D pred(haystack.front)) is $(D true).
  +/
ptrdiff_t countUntil(alias pred, R)(R haystack)
    if (isInputRange!R &&
        is(typeof(unaryFun!pred(haystack.front)) : bool))
{
    typeof(return) i;
    static if (isRandomAccessRange!R)
    {
        //Optimized RA implementation. Since we want to count *and* iterate at
        //the same time, it is more efficient this way.
        static if (hasLength!R)
        {
            immutable len = cast(typeof(return)) haystack.length;
            for ( ; i < len ; ++i )
                if (unaryFun!pred(haystack[i])) return i;
        }
        else //if (isInfinite!R)
        {
            for ( ;  ; ++i )
                if (unaryFun!pred(haystack[i])) return i;
        }
    }
    else static if (hasLength!R)
    {
        //For those odd ranges that have a length, but aren't RA.
        //It is faster to quick find, and then compare the lengths
        auto r2 = find!pred(haystack.save);
        if (!r2.empty) return cast(typeof(return)) (haystack.length - r2.length);
    }
    else //Everything else
    {
        alias T = ElementType!R; //For narrow strings forces dchar iteration
        foreach (T elem; haystack)
        {
            if (unaryFun!pred(elem)) return i;
            ++i;
        }
    }

    //Because of @@@8804@@@: Avoids both "unreachable code" or "no return statement"
    static if (isInfinite!R) assert(0);
    else return -1;
}

///
@safe unittest
{
    import std.ascii : isDigit;
    import std.uni : isWhite;

    assert(countUntil!(std.uni.isWhite)("hello world") == 5);
    assert(countUntil!(std.ascii.isDigit)("hello world") == -1);
    assert(countUntil!"a > 20"([0, 7, 12, 22, 9]) == 3);
}

@safe unittest
{
    import std.internal.test.dummyrange;

    // References
    {
        // input
        ReferenceInputRange!int r;
        r = new ReferenceInputRange!int([0, 1, 2, 3, 4, 5, 6]);
        assert(r.countUntil(3) == 3);
        r = new ReferenceInputRange!int([0, 1, 2, 3, 4, 5, 6]);
        assert(r.countUntil(7) == -1);
    }
    {
        // forward
        auto r = new ReferenceForwardRange!int([0, 1, 2, 3, 4, 5, 6]);
        assert(r.save.countUntil([3, 4]) == 3);
        assert(r.save.countUntil(3) == 3);
        assert(r.save.countUntil([3, 7]) == -1);
        assert(r.save.countUntil(7) == -1);
    }
    {
        // infinite forward
        auto r = new ReferenceInfiniteForwardRange!int(0);
        assert(r.save.countUntil([3, 4]) == 3);
        assert(r.save.countUntil(3) == 3);
    }
}

/**
Checks if the given range ends with (one of) the given needle(s).
The reciprocal of $(D startsWith).

Params:
    pred = The predicate to use for comparing elements between the range and
        the needle(s).

    doesThisEnd = The
        $(REF_ALTTEXT bidirectional range, isBidirectionalRange, std,range,primitives)
        to check.

    withOneOfThese = The needles to check against, which may be single
        elements, or bidirectional ranges of elements.

    withThis = The single element to check.

Returns:
0 if the needle(s) do not occur at the end of the given range;
otherwise the position of the matching needle, that is, 1 if the range ends
with $(D withOneOfThese[0]), 2 if it ends with $(D withOneOfThese[1]), and so
on.

In the case when no needle parameters are given, return $(D true) iff back of
$(D doesThisStart) fulfils predicate $(D pred).
*/
uint endsWith(alias pred = "a == b", Range, Needles...)(Range doesThisEnd, Needles withOneOfThese)
if (isBidirectionalRange!Range && Needles.length > 1 &&
    is(typeof(.endsWith!pred(doesThisEnd, withOneOfThese[0])) : bool) &&
    is(typeof(.endsWith!pred(doesThisEnd, withOneOfThese[1 .. $])) : uint))
{
    alias haystack = doesThisEnd;
    alias needles  = withOneOfThese;

    // Make one pass looking for empty ranges in needles
    foreach (i, Unused; Needles)
    {
        // Empty range matches everything
        static if (!is(typeof(binaryFun!pred(haystack.back, needles[i])) : bool))
        {
            if (needles[i].empty) return i + 1;
        }
    }

    for (; !haystack.empty; haystack.popBack())
    {
        foreach (i, Unused; Needles)
        {
            static if (is(typeof(binaryFun!pred(haystack.back, needles[i])) : bool))
            {
                // Single-element
                if (binaryFun!pred(haystack.back, needles[i]))
                {
                    // found, but continue to account for one-element
                    // range matches (consider endsWith("ab", "b",
                    // 'b') should return 1, not 2).
                    continue;
                }
            }
            else
            {
                if (binaryFun!pred(haystack.back, needles[i].back))
                    continue;
            }

            // This code executed on failure to match
            // Out with this guy, check for the others
            uint result = endsWith!pred(haystack, needles[0 .. i], needles[i + 1 .. $]);
            if (result > i) ++result;
            return result;
        }

        // If execution reaches this point, then the back matches for all
        // needles ranges. What we need to do now is to lop off the back of
        // all ranges involved and recurse.
        foreach (i, Unused; Needles)
        {
            static if (is(typeof(binaryFun!pred(haystack.back, needles[i])) : bool))
            {
                // Test has passed in the previous loop
                return i + 1;
            }
            else
            {
                needles[i].popBack();
                if (needles[i].empty) return i + 1;
            }
        }
    }
    return 0;
}

/// Ditto
bool endsWith(alias pred = "a == b", R1, R2)(R1 doesThisEnd, R2 withThis)
if (isBidirectionalRange!R1 &&
    isBidirectionalRange!R2 &&
    is(typeof(binaryFun!pred(doesThisEnd.back, withThis.back)) : bool))
{
    alias haystack = doesThisEnd;
    alias needle   = withThis;

    static if (is(typeof(pred) : string))
        enum isDefaultPred = pred == "a == b";
    else
        enum isDefaultPred = false;

    static if (isDefaultPred && isArray!R1 && isArray!R2 &&
               is(Unqual!(ElementEncodingType!R1) == Unqual!(ElementEncodingType!R2)))
    {
        if (haystack.length < needle.length) return false;

        return haystack[$ - needle.length .. $] == needle;
    }
    else
    {
        import std.range : retro;
        return startsWith!pred(retro(doesThisEnd), retro(withThis));
    }
}

/// Ditto
bool endsWith(alias pred = "a == b", R, E)(R doesThisEnd, E withThis)
if (isBidirectionalRange!R &&
    is(typeof(binaryFun!pred(doesThisEnd.back, withThis)) : bool))
{
    return doesThisEnd.empty
        ? false
        : binaryFun!pred(doesThisEnd.back, withThis);
}

/// Ditto
bool endsWith(alias pred, R)(R doesThisEnd)
    if (isInputRange!R &&
        ifTestable!(typeof(doesThisEnd.front), unaryFun!pred))
{
    return !doesThisEnd.empty && unaryFun!pred(doesThisEnd.back);
}

///
@safe unittest
{
    import std.ascii : isAlpha;
    assert("abc".endsWith!(a => a.isAlpha));
    assert("abc".endsWith!isAlpha);

    assert(!"ab1".endsWith!(a => a.isAlpha));

    assert(!"ab1".endsWith!isAlpha);
    assert(!"".endsWith!(a => a.isAlpha));

    import std.algorithm.comparison : among;
    assert("abc".endsWith!(a => a.among('c', 'd') != 0));
    assert(!"abc".endsWith!(a => a.among('a', 'b') != 0));

    assert(endsWith("abc", ""));
    assert(!endsWith("abc", "b"));
    assert(endsWith("abc", "a", 'c') == 2);
    assert(endsWith("abc", "c", "a") == 1);
    assert(endsWith("abc", "c", "c") == 1);
    assert(endsWith("abc", "bc", "c") == 2);
    assert(endsWith("abc", "x", "c", "b") == 2);
    assert(endsWith("abc", "x", "aa", "bc") == 3);
    assert(endsWith("abc", "x", "aaa", "sab") == 0);
    assert(endsWith("abc", "x", "aaa", 'c', "sab") == 3);
}

@safe unittest
{
    import std.algorithm.iteration : filterBidirectional;
    import std.meta : AliasSeq;
    import std.conv : to;

    debug(std_algorithm) scope(success)
        writeln("unittest @", __FILE__, ":", __LINE__, " done.");

    foreach (S; AliasSeq!(char[], wchar[], dchar[], string, wstring, dstring))
    {
        assert(!endsWith(to!S("abc"), 'a'));
        assert(endsWith(to!S("abc"), 'a', 'c') == 2);
        assert(!endsWith(to!S("abc"), 'x', 'n', 'b'));
        assert(endsWith(to!S("abc"), 'x', 'n', 'c') == 3);
        assert(endsWith(to!S("abc\uFF28"), 'a', '\uFF28', 'c') == 2);

        foreach (T; AliasSeq!(char[], wchar[], dchar[], string, wstring, dstring))
        (){ // avoid slow optimizations for large functions @@@BUG@@@ 2396
            //Lots of strings
            assert(endsWith(to!S("abc"), to!T("")));
            assert(!endsWith(to!S("abc"), to!T("a")));
            assert(!endsWith(to!S("abc"), to!T("b")));
            assert(endsWith(to!S("abc"), to!T("bc"), 'c') == 2);
            assert(endsWith(to!S("abc"), to!T("a"), "c") == 2);
            assert(endsWith(to!S("abc"), to!T("c"), "a") == 1);
            assert(endsWith(to!S("abc"), to!T("c"), "c") == 1);
            assert(endsWith(to!S("abc"), to!T("x"), 'c', "b") == 2);
            assert(endsWith(to!S("abc"), 'x', to!T("aa"), "bc") == 3);
            assert(endsWith(to!S("abc"), to!T("x"), "aaa", "sab") == 0);
            assert(endsWith(to!S("abc"), to!T("x"), "aaa", "c", "sab") == 3);
            assert(endsWith(to!S("\uFF28el\uFF4co"), to!T("l\uFF4co")));
            assert(endsWith(to!S("\uFF28el\uFF4co"), to!T("lo"), to!T("l\uFF4co")) == 2);

            //Unicode
            assert(endsWith(to!S("\uFF28el\uFF4co"), to!T("l\uFF4co")));
            assert(endsWith(to!S("\uFF28el\uFF4co"), to!T("lo"), to!T("l\uFF4co")) == 2);
            assert(endsWith(to!S("日本語"), to!T("本語")));
            assert(endsWith(to!S("日本語"), to!T("日本語")));
            assert(!endsWith(to!S("本語"), to!T("日本語")));

            //Empty
            assert(endsWith(to!S(""),  T.init));
            assert(!endsWith(to!S(""), 'a'));
            assert(endsWith(to!S("a"), T.init));
            assert(endsWith(to!S("a"), T.init, "") == 1);
            assert(endsWith(to!S("a"), T.init, 'a') == 1);
            assert(endsWith(to!S("a"), 'a', T.init) == 2);
        }();
    }

    foreach (T; AliasSeq!(int, short))
    {
        immutable arr = cast(T[])[0, 1, 2, 3, 4, 5];

        //RA range
        assert(endsWith(arr, cast(int[])null));
        assert(!endsWith(arr, 0));
        assert(!endsWith(arr, 4));
        assert(endsWith(arr, 5));
        assert(endsWith(arr, 0, 4, 5) == 3);
        assert(endsWith(arr, [5]));
        assert(endsWith(arr, [4, 5]));
        assert(endsWith(arr, [4, 5], 7) == 1);
        assert(!endsWith(arr, [2, 4, 5]));
        assert(endsWith(arr, [2, 4, 5], [3, 4, 5]) == 2);

        //Normal input range
        assert(!endsWith(filterBidirectional!"true"(arr), 4));
        assert(endsWith(filterBidirectional!"true"(arr), 5));
        assert(endsWith(filterBidirectional!"true"(arr), [5]));
        assert(endsWith(filterBidirectional!"true"(arr), [4, 5]));
        assert(endsWith(filterBidirectional!"true"(arr), [4, 5], 7) == 1);
        assert(!endsWith(filterBidirectional!"true"(arr), [2, 4, 5]));
        assert(endsWith(filterBidirectional!"true"(arr), [2, 4, 5], [3, 4, 5]) == 2);
        assert(endsWith(arr, filterBidirectional!"true"([4, 5])));
        assert(endsWith(arr, filterBidirectional!"true"([4, 5]), 7) == 1);
        assert(!endsWith(arr, filterBidirectional!"true"([2, 4, 5])));
        assert(endsWith(arr, [2, 4, 5], filterBidirectional!"true"([3, 4, 5])) == 2);

        //Non-default pred
        assert(endsWith!("a%10 == b%10")(arr, [14, 15]));
        assert(!endsWith!("a%10 == b%10")(arr, [15, 14]));
    }
}

/**
Iterates the passed range and selects the extreme element with `less`.
If the extreme element occurs multiple time, the first occurrence will be
returned.

Params:
    map = custom accessor for the comparison key
    selector = custom mapping for the extrema selection
    seed = custom seed to use as initial element
    r = Range from which the extreme value will be selected

Returns:
    The extreme value according to `map` and `selector` of the passed-in values.
*/
private auto extremum(alias map = "a", alias selector = "a < b", Range)(Range r)
    if (isInputRange!Range && !isInfinite!Range)
in
{
    assert(!r.empty, "r is an empty range");
}
body
{
    alias mapFun = unaryFun!map;
    alias Element = ElementType!Range;
    Unqual!Element seed = r.front;
    r.popFront();
    return extremum!(map, selector)(r, seed);
}

private auto extremum(alias map = "a", alias selector = "a < b", Range,
                      RangeElementType = ElementType!Range)
                     (Range r, RangeElementType seedElement)
    if (isInputRange!Range && !isInfinite!Range &&
        !is(CommonType!(ElementType!Range, RangeElementType) == void))
{
    alias mapFun = unaryFun!map;
    alias selectorFun = binaryFun!selector;

    alias Element = ElementType!Range;
    alias CommonElement = CommonType!(Element, RangeElementType);
    alias MapType = Unqual!(typeof(mapFun(CommonElement.init)));

    Unqual!CommonElement extremeElement = seedElement;
    MapType extremeElementMapped = mapFun(extremeElement);

    static if (isRandomAccessRange!Range && hasLength!Range)
    {
        foreach (const i; 0 .. r.length)
        {
            MapType mapElement = mapFun(r[i]);
            if (selectorFun(mapElement, extremeElementMapped))
            {
                extremeElement = r[i];
                extremeElementMapped = mapElement;
            }
        }
    }
    else
    {
        while (!r.empty)
        {
            MapType mapElement = mapFun(r.front);
            if (selectorFun(mapElement, extremeElementMapped))
            {
                extremeElement = r.front;
                extremeElementMapped = mapElement;
            }
            r.popFront();
        }
    }
    return extremeElement;
}

@safe pure nothrow unittest
{
    // allows a custom map to select the extremum
    assert([[0, 4], [1, 2]].extremum!"a[0]" == [0, 4]);
    assert([[0, 4], [1, 2]].extremum!"a[1]" == [1, 2]);

    // allows a custom selector for comparison
    assert([[0, 4], [1, 2]].extremum!("a[0]", "a > b") == [1, 2]);
    assert([[0, 4], [1, 2]].extremum!("a[1]", "a > b") == [0, 4]);
}

@safe pure nothrow unittest
{
    // allow seeds
    int[] arr;
    assert(arr.extremum(1) == 1);

    int[][] arr2d;
    assert(arr2d.extremum([1]) == [1]);

    // allow seeds of different types (implicit casting)
    assert(extremum([2, 3, 4], 1.5) == 1.5);
}

// find
/**
Finds an individual element in an input range. Elements of $(D
haystack) are compared with $(D needle) by using predicate $(D
pred). Performs $(BIGOH walkLength(haystack)) evaluations of $(D
pred).

To _find the last occurrence of $(D needle) in $(D haystack), call $(D
find(retro(haystack), needle)). See $(REF retro, std,range).

Params:

pred = The predicate for comparing each element with the needle, defaulting to
$(D "a == b").
The negated predicate $(D "a != b") can be used to search instead for the first
element $(I not) matching the needle.

haystack = The $(REF_ALTTEXT input range, isInputRange, std,range,primitives)
searched in.

needle = The element searched for.

Constraints:

$(D isInputRange!InputRange && is(typeof(binaryFun!pred(haystack.front, needle)
: bool)))

Returns:

$(D haystack) advanced such that the front element is the one searched for;
that is, until $(D binaryFun!pred(haystack.front, needle)) is $(D true). If no
such position exists, returns an empty $(D haystack).

See_Also:
     $(HTTP sgi.com/tech/stl/_find.html, STL's _find)
 */
InputRange find(alias pred = "a == b", InputRange, Element)(InputRange haystack, scope Element needle)
if (isInputRange!InputRange &&
    is (typeof(binaryFun!pred(haystack.front, needle)) : bool))
{
    alias R = InputRange;
    alias E = Element;
    alias predFun = binaryFun!pred;
    static if (is(typeof(pred == "a == b")))
        enum isDefaultPred = pred == "a == b";
    else
        enum isDefaultPred = false;
    enum  isIntegralNeedle = isSomeChar!E || isIntegral!E || isBoolean!E;

    alias EType  = ElementType!R;

    static if (isNarrowString!R)
    {
        alias EEType = ElementEncodingType!R;
        alias UEEType = Unqual!EEType;

        //These are two special cases which can search without decoding the UTF stream.
        static if (isDefaultPred && isIntegralNeedle)
        {
            import std.utf : canSearchInCodeUnits;

            //This special case deals with UTF8 search, when the needle
            //is represented by a single code point.
            //Note: "needle <= 0x7F" properly handles sign via unsigned promotion
            static if (is(UEEType == char))
            {
                if (!__ctfe && canSearchInCodeUnits!char(needle))
                {
                    static R trustedMemchr(ref R haystack, ref E needle) @trusted nothrow pure
                    {
                        import core.stdc.string : memchr;
                        auto ptr = memchr(haystack.ptr, needle, haystack.length);
                        return ptr ?
                             haystack[ptr - haystack.ptr .. $] :
                             haystack[$ .. $];
                    }
                    return trustedMemchr(haystack, needle);
                }
            }

            //Ditto, but for UTF16
            static if (is(UEEType == wchar))
            {
                if (canSearchInCodeUnits!wchar(needle))
                {
                    foreach (i, ref EEType e; haystack)
                    {
                        if (e == needle)
                            return haystack[i .. $];
                    }
                    return haystack[$ .. $];
                }
            }
        }

        //Previous conditonal optimizations did not succeed. Fallback to
        //unconditional implementations
        static if (isDefaultPred)
        {
            import std.utf : encode;

            //In case of default pred, it is faster to do string/string search.
            UEEType[is(UEEType == char) ? 4 : 2] buf;

            size_t len = encode(buf, needle);
            return find(haystack, buf[0 .. len]);
        }
        else
        {
            import std.utf : decode;

            //Explicit pred: we must test each character by the book.
            //We choose a manual decoding approach, because it is faster than
            //the built-in foreach, or doing a front/popFront for-loop.
            immutable len = haystack.length;
            size_t i = 0, next = 0;
            while (next < len)
            {
                if (predFun(decode(haystack, next), needle))
                    return haystack[i .. $];
                i = next;
            }
            return haystack[$ .. $];
        }
    }
    else static if (isArray!R)
    {
        //10403 optimization
        static if (isDefaultPred && isIntegral!EType && EType.sizeof == 1 && isIntegralNeedle)
        {
            import std.algorithm.comparison : max, min;

            R findHelper(ref R haystack, ref E needle) @trusted nothrow pure
            {
                import core.stdc.string : memchr;

                EType* ptr = null;
                //Note: we use "min/max" to handle sign mismatch.
                if (min(EType.min, needle) == EType.min &&
                    max(EType.max, needle) == EType.max)
                {
                    ptr = cast(EType*) memchr(haystack.ptr, needle,
                        haystack.length);
                }

                return ptr ?
                    haystack[ptr - haystack.ptr .. $] :
                    haystack[$ .. $];
            }

            if (!__ctfe)
                return findHelper(haystack, needle);
        }

        //Default implementation.
        foreach (i, ref e; haystack)
            if (predFun(e, needle))
                return haystack[i .. $];
        return haystack[$ .. $];
    }
    else
    {
        //Everything else. Walk.
        for ( ; !haystack.empty; haystack.popFront() )
        {
            if (predFun(haystack.front, needle))
                break;
        }
        return haystack;
    }
}

///
@safe unittest
{
    import std.algorithm.comparison : equal;
    import std.container : SList;
    import std.range.primitives : empty;

    assert(find("hello, world", ',') == ", world");
    assert(find([1, 2, 3, 5], 4) == []);
    assert(equal(find(SList!int(1, 2, 3, 4, 5)[], 4), SList!int(4, 5)[]));
    assert(find!"a > b"([1, 2, 3, 5], 2) == [3, 5]);

    auto a = [ 1, 2, 3 ];
    assert(find(a, 5).empty);       // not found
    assert(!find(a, 2).empty);      // found

    // Case-insensitive find of a string
    string[] s = [ "Hello", "world", "!" ];
    assert(!find!("toLower(a) == b")(s, "hello").empty);
}

@safe unittest
{
    import std.algorithm.comparison : equal;
    import std.container : SList;

    debug(std_algorithm) scope(success)
        writeln("unittest @", __FILE__, ":", __LINE__, " done.");
    auto lst = SList!int(1, 2, 5, 7, 3);
    assert(lst.front == 1);
    auto r = find(lst[], 5);
    assert(equal(r, SList!int(5, 7, 3)[]));
    assert(find([1, 2, 3, 5], 4).empty);
    assert(equal(find!"a > b"("hello", 'k'), "llo"));
}

@safe pure nothrow unittest
{
    int[] a1 = [1, 2, 3];
    assert(!find              ([1, 2, 3], 2).empty);
    assert(!find!((a,b)=>a==b)([1, 2, 3], 2).empty);
    ubyte[] a2 = [1, 2, 3];
    ubyte   b2 = 2;
    assert(!find              ([1, 2, 3], 2).empty);
    assert(!find!((a,b)=>a==b)([1, 2, 3], 2).empty);
}

@safe pure unittest
{
    import std.meta : AliasSeq;
    foreach (R; AliasSeq!(string, wstring, dstring))
    {
        foreach (E; AliasSeq!(char, wchar, dchar))
        {
            R r1 = "hello world";
            E e1 = 'w';
            assert(find              ("hello world", 'w') == "world");
            assert(find!((a,b)=>a==b)("hello world", 'w') == "world");
            R r2 = "日c語";
            E e2 = 'c';
            assert(find              ("日c語", 'c') == "c語");
            assert(find!((a,b)=>a==b)("日c語", 'c') == "c語");
            static if (E.sizeof >= 2)
            {
                R r3 = "hello world";
                E e3 = 'w';
                assert(find              ("日本語", '本') == "本語");
                assert(find!((a,b)=>a==b)("日本語", '本') == "本語");
            }
        }
    }
}

@safe unittest
{
    //CTFE
    static assert (find("abc", 'b') == "bc");
    static assert (find("日b語", 'b') == "b語");
    static assert (find("日本語", '本') == "本語");
    static assert (find([1, 2, 3], 2)  == [2, 3]);

    int[] a1 = [1, 2, 3];
    static assert(find              ([1, 2, 3], 2));
    static assert(find!((a,b)=>a==b)([1, 2, 3], 2));
    ubyte[] a2 = [1, 2, 3];
    ubyte   b2 = 2;
    static assert(find              ([1, 2, 3], 2));
    static assert(find!((a,b)=>a==b)([1, 2, 3], 2));
}

@safe unittest
{
    import std.exception : assertCTFEable;
    import std.meta : AliasSeq;

    void dg() @safe pure nothrow
    {
        byte[]  sarr = [1, 2, 3, 4];
        ubyte[] uarr = [1, 2, 3, 4];
        foreach (arr; AliasSeq!(sarr, uarr))
        {
            foreach (T; AliasSeq!(byte, ubyte, int, uint))
            {
                assert(find(arr, cast(T) 3) == arr[2 .. $]);
                assert(find(arr, cast(T) 9) == arr[$ .. $]);
            }
            assert(find(arr, 256) == arr[$ .. $]);
        }
    }
    dg();
    assertCTFEable!dg;
}

@safe unittest
{
    // Bugzilla 11603
    enum Foo : ubyte { A }
    assert([Foo.A].find(Foo.A).empty == false);

    ubyte x = 0;
    assert([x].find(x).empty == false);
}

/**
Advances the input range $(D haystack) by calling $(D haystack.popFront)
until either $(D pred(haystack.front)), or $(D
haystack.empty). Performs $(BIGOH haystack.length) evaluations of $(D
pred).

To _find the last element of a bidirectional $(D haystack) satisfying
$(D pred), call $(D find!(pred)(retro(haystack))). See $(REF retro, std,range).

Params:

pred = The predicate for determining if a given element is the one being
searched for.

haystack = The $(REF_ALTTEXT input range, isInputRange, std,range,primitives) to
search in.

Returns:

$(D haystack) advanced such that the front element is the one searched for;
that is, until $(D binaryFun!pred(haystack.front, needle)) is $(D true). If no
such position exists, returns an empty $(D haystack).

See_Also:
     $(HTTP sgi.com/tech/stl/find_if.html, STL's find_if)
*/
InputRange find(alias pred, InputRange)(InputRange haystack)
if (isInputRange!InputRange)
{
    alias R = InputRange;
    alias predFun = unaryFun!pred;
    static if (isNarrowString!R)
    {
        import std.utf : decode;

        immutable len = haystack.length;
        size_t i = 0, next = 0;
        while (next < len)
        {
            if (predFun(decode(haystack, next)))
                return haystack[i .. $];
            i = next;
        }
        return haystack[$ .. $];
    }
    else
    {
        //standard range
        for ( ; !haystack.empty; haystack.popFront() )
        {
            if (predFun(haystack.front))
                break;
        }
        return haystack;
    }
}

///
@safe unittest
{
    auto arr = [ 1, 2, 3, 4, 1 ];
    assert(find!("a > 2")(arr) == [ 3, 4, 1 ]);

    // with predicate alias
    bool pred(int x) { return x + 1 > 1.5; }
    assert(find!(pred)(arr) == arr);
}

@safe pure unittest
{
    //scope(success) writeln("unittest @", __FILE__, ":", __LINE__, " done.");
    int[] r = [ 1, 2, 3 ];
    assert(find!(a=>a > 2)(r) == [3]);
    bool pred(int x) { return x + 1 > 1.5; }
    assert(find!(pred)(r) == r);

    assert(find!(a=>a > 'v')("hello world") == "world");
    assert(find!(a=>a%4 == 0)("日本語") == "本語");
}

/**
Finds the first occurrence of a forward range in another forward range.

Performs $(BIGOH walkLength(haystack) * walkLength(needle)) comparisons in the
worst case.  There are specializations that improve performance by taking
advantage of bidirectional or random access in the given ranges (where
possible), depending on the statistics of the two ranges' content.

Params:

pred = The predicate to use for comparing respective elements from the haystack
and the needle. Defaults to simple equality $(D "a == b").

haystack = The $(REF_ALTTEXT forward range, isForwardRange, std,range,primitives)
searched in.

needle = The $(REF_ALTTEXT forward range, isForwardRange, std,range,primitives)
searched for.

Returns:

$(D haystack) advanced such that $(D needle) is a prefix of it (if no
such position exists, returns $(D haystack) advanced to termination).
 */
R1 find(alias pred = "a == b", R1, R2)(R1 haystack, scope R2 needle)
if (isForwardRange!R1 && isForwardRange!R2
        && is(typeof(binaryFun!pred(haystack.front, needle.front)) : bool)
        && !isRandomAccessRange!R1)
{
    static if (is(typeof(pred == "a == b")) && pred == "a == b" && isSomeString!R1 && isSomeString!R2
            && haystack[0].sizeof == needle[0].sizeof)
    {
        //return cast(R1) find(representation(haystack), representation(needle));
        // Specialization for simple string search
        alias Representation =
            Select!(haystack[0].sizeof == 1, ubyte[],
                Select!(haystack[0].sizeof == 2, ushort[], uint[]));
        // Will use the array specialization
        static TO force(TO, T)(T r) @trusted { return cast(TO)r; }
        return force!R1(.find!(pred, Representation, Representation)
            (force!Representation(haystack), force!Representation(needle)));
    }
    else
    {
        return simpleMindedFind!pred(haystack, needle);
    }
}

///
@safe unittest
{
    import std.container : SList;
    import std.range.primitives : empty;
    import std.typecons : Tuple;

    assert(find("hello, world", "World").empty);
    assert(find("hello, world", "wo") == "world");
    assert([1, 2, 3, 4].find(SList!int(2, 3)[]) == [2, 3, 4]);
    alias C = Tuple!(int, "x", int, "y");
    auto a = [C(1,0), C(2,0), C(3,1), C(4,0)];
    assert(a.find!"a.x == b"([2, 3]) == [C(2,0), C(3,1), C(4,0)]);
    assert(a[1 .. $].find!"a.x == b"([2, 3]) == [C(2,0), C(3,1), C(4,0)]);
}

@safe unittest
{
    import std.container : SList;
    alias C = Tuple!(int, "x", int, "y");
    assert([C(1,0), C(2,0), C(3,1), C(4,0)].find!"a.x == b"(SList!int(2, 3)[]) == [C(2,0), C(3,1), C(4,0)]);
}

@safe unittest
{
    import std.algorithm.comparison : equal;
    import std.container : SList;

    debug(std_algorithm) scope(success)
        writeln("unittest @", __FILE__, ":", __LINE__, " done.");
    auto lst = SList!int(1, 2, 5, 7, 3);
    static assert(isForwardRange!(int[]));
    static assert(isForwardRange!(typeof(lst[])));
    auto r = find(lst[], [2, 5]);
    assert(equal(r, SList!int(2, 5, 7, 3)[]));
}

/// ditto
R1 find(alias pred = "a == b", R1, R2)(R1 haystack, scope R2 needle)
if (isRandomAccessRange!R1 && hasLength!R1 && hasSlicing!R1 && isBidirectionalRange!R2
        && is(typeof(binaryFun!pred(haystack.front, needle.front)) : bool))
{
    if (needle.empty) return haystack;
    static if (hasLength!R2)
    {
        immutable needleLength = needle.length;
    }
    else
    {
        immutable needleLength = walkLength(needle.save);
    }
    if (needleLength > haystack.length)
    {
        return haystack[haystack.length .. haystack.length];
    }
    static if (isRandomAccessRange!R2)
    {
        immutable lastIndex = needleLength - 1;
        auto last = needle[lastIndex];
        size_t j = lastIndex, skip = 0;
        for (; j < haystack.length;)
        {
            if (!binaryFun!pred(haystack[j], last))
            {
                ++j;
                continue;
            }
            immutable k = j - lastIndex;
            // last elements match
            for (size_t i = 0;; ++i)
            {
                if (i == lastIndex)
                    return haystack[k .. haystack.length];
                if (!binaryFun!pred(haystack[k + i], needle[i]))
                    break;
            }
            if (skip == 0)
            {
                skip = 1;
                while (skip < needleLength && needle[needleLength - 1 - skip] != needle[needleLength - 1])
                {
                    ++skip;
                }
            }
            j += skip;
        }
    }
    else
    {
        // @@@BUG@@@
        // auto needleBack = moveBack(needle);
        // Stage 1: find the step
        size_t step = 1;
        auto needleBack = needle.back;
        needle.popBack();
        for (auto i = needle.save; !i.empty && i.back != needleBack;
                i.popBack(), ++step)
        {
        }
        // Stage 2: linear find
        size_t scout = needleLength - 1;
        for (;;)
        {
            if (scout >= haystack.length)
                break;
            if (!binaryFun!pred(haystack[scout], needleBack))
            {
                ++scout;
                continue;
            }
            // Found a match with the last element in the needle
            auto cand = haystack[scout + 1 - needleLength .. haystack.length];
            if (startsWith!pred(cand, needle))
            {
                // found
                return cand;
            }
            scout += step;
        }
    }
    return haystack[haystack.length .. haystack.length];
}

@safe unittest
{
    //scope(success) writeln("unittest @", __FILE__, ":", __LINE__, " done.");
    // @@@BUG@@@ removing static below makes unittest fail
    static struct BiRange
    {
        int[] payload;
        @property bool empty() { return payload.empty; }
        @property BiRange save() { return this; }
        @property ref int front() { return payload[0]; }
        @property ref int back() { return payload[$ - 1]; }
        void popFront() { return payload.popFront(); }
        void popBack() { return payload.popBack(); }
    }
    //static assert(isBidirectionalRange!BiRange);
    auto r = BiRange([1, 2, 3, 10, 11, 4]);
    //assert(equal(find(r, [3, 10]), BiRange([3, 10, 11, 4])));
    //assert(find("abc", "bc").length == 2);
    debug(std_algorithm) scope(success)
        writeln("unittest @", __FILE__, ":", __LINE__, " done.");
    //assert(find!"a == b"("abc", "bc").length == 2);
}

/// ditto
R1 find(alias pred = "a == b", R1, R2)(R1 haystack, scope R2 needle)
if (isRandomAccessRange!R1 && isForwardRange!R2 && !isBidirectionalRange!R2 &&
    is(typeof(binaryFun!pred(haystack.front, needle.front)) : bool))
{
    static if (!is(ElementType!R1 == ElementType!R2))
    {
        return simpleMindedFind!pred(haystack, needle);
    }
    else
    {
        // Prepare the search with needle's first element
        if (needle.empty)
            return haystack;

        haystack = .find!pred(haystack, needle.front);

        static if (hasLength!R1 && hasLength!R2 && is(typeof(takeNone(haystack)) == R1))
        {
            if (needle.length > haystack.length)
                return takeNone(haystack);
        }
        else
        {
            if (haystack.empty)
                return haystack;
        }

        needle.popFront();
        size_t matchLen = 1;

        // Loop invariant: haystack[0 .. matchLen] matches everything in
        // the initial needle that was popped out of needle.
        for (;;)
        {
            // Extend matchLength as much as possible
            for (;;)
            {
                import std.range : takeNone;

                if (needle.empty || haystack.empty)
                    return haystack;

                static if (hasLength!R1 && is(typeof(takeNone(haystack)) == R1))
                {
                    if (matchLen == haystack.length)
                        return takeNone(haystack);
                }

                if (!binaryFun!pred(haystack[matchLen], needle.front))
                    break;

                ++matchLen;
                needle.popFront();
            }

            auto bestMatch = haystack[0 .. matchLen];
            haystack.popFront();
            haystack = .find!pred(haystack, bestMatch);
        }
    }
}

@safe unittest
{
    import std.container : SList;

    assert(find([ 1, 2, 3 ], SList!int(2, 3)[]) == [ 2, 3 ]);
    assert(find([ 1, 2, 1, 2, 3, 3 ], SList!int(2, 3)[]) == [ 2, 3, 3 ]);
}

//Bug# 8334
@safe unittest
{
    import std.algorithm.iteration : filter;
    import std.range;

    auto haystack = [1, 2, 3, 4, 1, 9, 12, 42];
    auto needle = [12, 42, 27];

    //different overload of find, but it's the base case.
    assert(find(haystack, needle).empty);

    assert(find(haystack, takeExactly(filter!"true"(needle), 3)).empty);
    assert(find(haystack, filter!"true"(needle)).empty);
}

// Internally used by some find() overloads above
private R1 simpleMindedFind(alias pred, R1, R2)(R1 haystack, scope R2 needle)
{
    enum estimateNeedleLength = hasLength!R1 && !hasLength!R2;

    static if (hasLength!R1)
    {
        static if (!hasLength!R2)
            size_t estimatedNeedleLength = 0;
        else
            immutable size_t estimatedNeedleLength = needle.length;
    }

    bool haystackTooShort()
    {
        static if (estimateNeedleLength)
        {
            return haystack.length < estimatedNeedleLength;
        }
        else
        {
            return haystack.empty;
        }
    }

  searching:
    for (;; haystack.popFront())
    {
        if (haystackTooShort())
        {
            // Failed search
            static if (hasLength!R1)
            {
                static if (is(typeof(haystack[haystack.length ..
                                                haystack.length]) : R1))
                    return haystack[haystack.length .. haystack.length];
                else
                    return R1.init;
            }
            else
            {
                assert(haystack.empty);
                return haystack;
            }
        }
        static if (estimateNeedleLength)
            size_t matchLength = 0;
        for (auto h = haystack.save, n = needle.save;
             !n.empty;
             h.popFront(), n.popFront())
        {
            if (h.empty || !binaryFun!pred(h.front, n.front))
            {
                // Failed searching n in h
                static if (estimateNeedleLength)
                {
                    if (estimatedNeedleLength < matchLength)
                        estimatedNeedleLength = matchLength;
                }
                continue searching;
            }
            static if (estimateNeedleLength)
                ++matchLength;
        }
        break;
    }
    return haystack;
}

@safe unittest
{
    // Test simpleMindedFind for the case where both haystack and needle have
    // length.
    debug(std_algorithm) scope(success)
        writeln("unittest @", __FILE__, ":", __LINE__, " done.");

    struct CustomString
    {
    @safe:
        string _impl;

        // This is what triggers issue 7992.
        @property size_t length() const { return _impl.length; }
        @property void length(size_t len) { _impl.length = len; }

        // This is for conformance to the forward range API (we deliberately
        // make it non-random access so that we will end up in
        // simpleMindedFind).
        @property bool empty() const { return _impl.empty; }
        @property dchar front() const { return _impl.front; }
        void popFront() { _impl.popFront(); }
        @property CustomString save() { return this; }
    }

    // If issue 7992 occurs, this will throw an exception from calling
    // popFront() on an empty range.
    auto r = find(CustomString("a"), CustomString("b"));
}

/**
Finds two or more $(D needles) into a $(D haystack). The predicate $(D
pred) is used throughout to compare elements. By default, elements are
compared for equality.

Params:

pred = The predicate to use for comparing elements.

haystack = The target of the search. Must be an input range.
If any of $(D needles) is a range with elements comparable to
elements in $(D haystack), then $(D haystack) must be a forward range
such that the search can backtrack.

needles = One or more items to search for. Each of $(D needles) must
be either comparable to one element in $(D haystack), or be itself a
forward range with elements comparable with elements in
$(D haystack).

Returns:

A tuple containing $(D haystack) positioned to match one of the
needles and also the 1-based index of the matching element in $(D
needles) (0 if none of $(D needles) matched, 1 if $(D needles[0])
matched, 2 if $(D needles[1]) matched...). The first needle to be found
will be the one that matches. If multiple needles are found at the
same spot in the range, then the shortest one is the one which matches
(if multiple needles of the same length are found at the same spot (e.g
$(D "a") and $(D 'a')), then the left-most of them in the argument list
matches).

The relationship between $(D haystack) and $(D needles) simply means
that one can e.g. search for individual $(D int)s or arrays of $(D
int)s in an array of $(D int)s. In addition, if elements are
individually comparable, searches of heterogeneous types are allowed
as well: a $(D double[]) can be searched for an $(D int) or a $(D
short[]), and conversely a $(D long) can be searched for a $(D float)
or a $(D double[]). This makes for efficient searches without the need
to coerce one side of the comparison into the other's side type.

The complexity of the search is $(BIGOH haystack.length *
max(needles.length)). (For needles that are individual items, length
is considered to be 1.) The strategy used in searching several
subranges at once maximizes cache usage by moving in $(D haystack) as
few times as possible.
 */
Tuple!(Range, size_t) find(alias pred = "a == b", Range, Ranges...)
(Range haystack, Ranges needles)
if (Ranges.length > 1 && is(typeof(startsWith!pred(haystack, needles))))
{
    for (;; haystack.popFront())
    {
        size_t r = startsWith!pred(haystack, needles);
        if (r || haystack.empty)
        {
            return tuple(haystack, r);
        }
    }
}

///
@safe unittest
{
    import std.typecons : tuple;
    int[] a = [ 1, 4, 2, 3 ];
    assert(find(a, 4) == [ 4, 2, 3 ]);
    assert(find(a, [ 1, 4 ]) == [ 1, 4, 2, 3 ]);
    assert(find(a, [ 1, 3 ], 4) == tuple([ 4, 2, 3 ], 2));
    // Mixed types allowed if comparable
    assert(find(a, 5, [ 1.2, 3.5 ], 2.0) == tuple([ 2, 3 ], 3));
}

@safe unittest
{
    debug(std_algorithm) scope(success)
        writeln("unittest @", __FILE__, ":", __LINE__, " done.");
    auto s1 = "Mary has a little lamb";
    //writeln(find(s1, "has a", "has an"));
    assert(find(s1, "has a", "has an") == tuple("has a little lamb", 1));
    assert(find(s1, 't', "has a", "has an") == tuple("has a little lamb", 2));
    assert(find(s1, 't', "has a", 'y', "has an") == tuple("y has a little lamb", 3));
    assert(find("abc", "bc").length == 2);
}

@safe unittest
{
    import std.algorithm.internal : rndstuff;
    import std.meta : AliasSeq;
    import std.uni : toUpper;

    debug(std_algorithm) scope(success)
        writeln("unittest @", __FILE__, ":", __LINE__, " done.");

    int[] a = [ 1, 2, 3 ];
    assert(find(a, 5).empty);
    assert(find(a, 2) == [2, 3]);

    foreach (T; AliasSeq!(int, double))
    {
        auto b = rndstuff!(T)();
        if (!b.length) continue;
        b[$ / 2] = 200;
        b[$ / 4] = 200;
        assert(find(b, 200).length == b.length - b.length / 4);
    }

    // Case-insensitive find of a string
    string[] s = [ "Hello", "world", "!" ];
    //writeln(find!("toUpper(a) == toUpper(b)")(s, "hello"));
    assert(find!("toUpper(a) == toUpper(b)")(s, "hello").length == 3);

    static bool f(string a, string b) { return toUpper(a) == toUpper(b); }
    assert(find!(f)(s, "hello").length == 3);
}

@safe unittest
{
    import std.algorithm.internal : rndstuff;
    import std.algorithm.comparison : equal;
    import std.meta : AliasSeq;
    import std.range : retro;

    debug(std_algorithm) scope(success)
        writeln("unittest @", __FILE__, ":", __LINE__, " done.");

    int[] a = [ 1, 2, 3, 2, 6 ];
    assert(find(retro(a), 5).empty);
    assert(equal(find(retro(a), 2), [ 2, 3, 2, 1 ][]));

    foreach (T; AliasSeq!(int, double))
    {
        auto b = rndstuff!(T)();
        if (!b.length) continue;
        b[$ / 2] = 200;
        b[$ / 4] = 200;
        assert(find(retro(b), 200).length ==
                b.length - (b.length - 1) / 2);
    }
}

@safe unittest
{
    import std.algorithm.comparison : equal;
    import std.internal.test.dummyrange;

    debug(std_algorithm) scope(success)
        writeln("unittest @", __FILE__, ":", __LINE__, " done.");
    int[] a = [ -1, 0, 1, 2, 3, 4, 5 ];
    int[] b = [ 1, 2, 3 ];
    assert(find(a, b) == [ 1, 2, 3, 4, 5 ]);
    assert(find(b, a).empty);

    foreach (DummyType; AllDummyRanges)
    {
        DummyType d;
        auto findRes = find(d, 5);
        assert(equal(findRes, [5,6,7,8,9,10]));
    }
}

/**
 * Finds $(D needle) in $(D haystack) efficiently using the
 * $(LUCKY Boyer-Moore) method.
 *
 * Params:
 * haystack = A random-access range with length and slicing.
 * needle = A $(LREF BoyerMooreFinder).
 *
 * Returns:
 * $(D haystack) advanced such that $(D needle) is a prefix of it (if no
 * such position exists, returns $(D haystack) advanced to termination).
 */
Range1 find(Range1, alias pred, Range2)(
    Range1 haystack, scope BoyerMooreFinder!(pred, Range2) needle)
{
    return needle.beFound(haystack);
}

@safe unittest
{
    debug(std_algorithm) scope(success)
        writeln("unittest @", __FILE__, ":", __LINE__, " done.");
    string h = "/homes/aalexand/d/dmd/bin/../lib/libphobos.a(dmain2.o)"~
        "(.gnu.linkonce.tmain+0x74): In function `main' undefined reference"~
        " to `_Dmain':";
    string[] ns = ["libphobos", "function", " undefined", "`", ":"];
    foreach (n ; ns)
    {
        auto p = find(h, boyerMooreFinder(n));
        assert(!p.empty);
    }
}

///
@safe unittest
{
    import std.range.primitives : empty;
    int[] a = [ -1, 0, 1, 2, 3, 4, 5 ];
    int[] b = [ 1, 2, 3 ];

    assert(find(a, boyerMooreFinder(b)) == [ 1, 2, 3, 4, 5 ]);
    assert(find(b, boyerMooreFinder(a)).empty);
}

@safe unittest
{
    auto bm = boyerMooreFinder("for");
    auto match = find("Moor", bm);
    assert(match.empty);
}

// canFind
/++
Convenience function. Like find, but only returns whether or not the search
was successful.

See_Also:
$(LREF among) for checking a value against multiple possibilities.
 +/
template canFind(alias pred="a == b")
{
    import std.meta : allSatisfy;

    /++
    Returns $(D true) if and only if any value $(D v) found in the
    input range $(D range) satisfies the predicate $(D pred).
    Performs (at most) $(BIGOH haystack.length) evaluations of $(D pred).
     +/
    bool canFind(Range)(Range haystack)
    if (is(typeof(find!pred(haystack))))
    {
        return any!pred(haystack);
    }

    /++
    Returns $(D true) if and only if $(D needle) can be found in $(D
    range). Performs $(BIGOH haystack.length) evaluations of $(D pred).
     +/
    bool canFind(Range, Element)(Range haystack, scope Element needle)
    if (is(typeof(find!pred(haystack, needle))))
    {
        return !find!pred(haystack, needle).empty;
    }

    /++
    Returns the 1-based index of the first needle found in $(D haystack). If no
    needle is found, then $(D 0) is returned.

    So, if used directly in the condition of an if statement or loop, the result
    will be $(D true) if one of the needles is found and $(D false) if none are
    found, whereas if the result is used elsewhere, it can either be cast to
    $(D bool) for the same effect or used to get which needle was found first
    without having to deal with the tuple that $(D LREF find) returns for the
    same operation.
     +/
    size_t canFind(Range, Ranges...)(Range haystack, scope Ranges needles)
    if (Ranges.length > 1 &&
        allSatisfy!(isForwardRange, Ranges) &&
        is(typeof(find!pred(haystack, needles))))
    {
        return find!pred(haystack, needles)[1];
    }
}

///
@safe unittest
{
    assert(canFind([0, 1, 2, 3], 2) == true);
    assert(canFind([0, 1, 2, 3], [1, 2], [2, 3]));
    assert(canFind([0, 1, 2, 3], [1, 2], [2, 3]) == 1);
    assert(canFind([0, 1, 2, 3], [1, 7], [2, 3]));
    assert(canFind([0, 1, 2, 3], [1, 7], [2, 3]) == 2);

    assert(canFind([0, 1, 2, 3], 4) == false);
    assert(!canFind([0, 1, 2, 3], [1, 3], [2, 4]));
    assert(canFind([0, 1, 2, 3], [1, 3], [2, 4]) == 0);
}

/**
 * Example using a custom predicate.
 * Note that the needle appears as the second argument of the predicate.
 */
@safe unittest
{
    auto words = [
        "apple",
        "beeswax",
        "cardboard"
    ];
    assert(!canFind(words, "bees"));
    assert( canFind!((string a, string b) => a.startsWith(b))(words, "bees"));
}

@safe unittest
{
    import std.algorithm.internal : rndstuff;
    debug(std_algorithm) scope(success)
        writeln("unittest @", __FILE__, ":", __LINE__, " done.");
    auto a = rndstuff!(int)();
    if (a.length)
    {
        auto b = a[a.length / 2];
        assert(canFind(a, b));
    }
}

@safe unittest
{
    import std.algorithm.comparison : equal;
    assert(equal!(canFind!"a < b")([[1, 2, 3], [7, 8, 9]], [2, 8]));
}

// findAdjacent
/**
Advances $(D r) until it finds the first two adjacent elements $(D a),
$(D b) that satisfy $(D pred(a, b)). Performs $(BIGOH r.length)
evaluations of $(D pred).

Params:
    pred = The predicate to satisfy.
    r = A $(REF_ALTTEXT forward range, isForwardRange, std,range,primitives) to
        search in.

Returns:
$(D r) advanced to the first occurrence of two adjacent elements that satisfy
the given predicate. If there are no such two elements, returns $(D r) advanced
until empty.

See_Also:
     $(HTTP sgi.com/tech/stl/adjacent_find.html, STL's adjacent_find)
*/
Range findAdjacent(alias pred = "a == b", Range)(Range r)
    if (isForwardRange!(Range))
{
    auto ahead = r.save;
    if (!ahead.empty)
    {
        for (ahead.popFront(); !ahead.empty; r.popFront(), ahead.popFront())
        {
            if (binaryFun!(pred)(r.front, ahead.front)) return r;
        }
    }
    static if (!isInfinite!Range)
        return ahead;
}

///
@safe unittest
{
    int[] a = [ 11, 10, 10, 9, 8, 8, 7, 8, 9 ];
    auto r = findAdjacent(a);
    assert(r == [ 10, 10, 9, 8, 8, 7, 8, 9 ]);
    auto p = findAdjacent!("a < b")(a);
    assert(p == [ 7, 8, 9 ]);

}

@safe unittest
{
    import std.algorithm.comparison : equal;
    import std.internal.test.dummyrange;
    import std.range;

    //scope(success) writeln("unittest @", __FILE__, ":", __LINE__, " done.");
    int[] a = [ 11, 10, 10, 9, 8, 8, 7, 8, 9 ];
    auto p = findAdjacent(a);
    assert(p == [10, 10, 9, 8, 8, 7, 8, 9 ]);
    p = findAdjacent!("a < b")(a);
    assert(p == [7, 8, 9]);
    // empty
    a = [];
    p = findAdjacent(a);
    assert(p.empty);
    // not found
    a = [ 1, 2, 3, 4, 5 ];
    p = findAdjacent(a);
    assert(p.empty);
    p = findAdjacent!"a > b"(a);
    assert(p.empty);
    ReferenceForwardRange!int rfr = new ReferenceForwardRange!int([1, 2, 3, 2, 2, 3]);
    assert(equal(findAdjacent(rfr), [2, 2, 3]));

    // Issue 9350
    assert(!repeat(1).findAdjacent().empty);
}

// findAmong
/**
Searches the given range for an element that matches one of the given choices.

Advances $(D seq) by calling $(D seq.popFront) until either
$(D find!(pred)(choices, seq.front)) is $(D true), or $(D seq) becomes empty.
Performs $(BIGOH seq.length * choices.length) evaluations of $(D pred).

Params:
    pred = The predicate to use for determining a match.
    seq = The $(REF_ALTTEXT input range, isInputRange, std,range,primitives) to
        search.
    choices = A $(REF_ALTTEXT forward range, isForwardRange, std,range,primitives)
        of possible choices.

Returns:
$(D seq) advanced to the first matching element, or until empty if there are no
matching elements.

See_Also:
    $(HTTP sgi.com/tech/stl/find_first_of.html, STL's find_first_of)
*/
Range1 findAmong(alias pred = "a == b", Range1, Range2)(
    Range1 seq, Range2 choices)
    if (isInputRange!Range1 && isForwardRange!Range2)
{
    for (; !seq.empty && find!pred(choices, seq.front).empty; seq.popFront())
    {
    }
    return seq;
}

///
@safe unittest
{
    int[] a = [ -1, 0, 1, 2, 3, 4, 5 ];
    int[] b = [ 3, 1, 2 ];
    assert(findAmong(a, b) == a[2 .. $]);
}

@safe unittest
{
    //scope(success) writeln("unittest @", __FILE__, ":", __LINE__, " done.");
    int[] a = [ -1, 0, 2, 1, 2, 3, 4, 5 ];
    int[] b = [ 1, 2, 3 ];
    assert(findAmong(a, b) == [2, 1, 2, 3, 4, 5 ]);
    assert(findAmong(b, [ 4, 6, 7 ][]).empty);
    assert(findAmong!("a == b")(a, b).length == a.length - 2);
    assert(findAmong!("a == b")(b, [ 4, 6, 7 ][]).empty);
}

// findSkip
/**
 * Finds $(D needle) in $(D haystack) and positions $(D haystack)
 * right after the first occurrence of $(D needle).
 *
 * Params:
 *  haystack = The
 *   $(REF_ALTTEXT forward range, isForwardRange, std,range,primitives) to search
 *   in.
 *  needle = The
 *   $(REF_ALTTEXT forward range, isForwardRange, std,range,primitives) to search
 *   for.
 *
 * Returns: $(D true) if the needle was found, in which case $(D haystack) is
 * positioned after the end of the first occurrence of $(D needle); otherwise
 * $(D false), leaving $(D haystack) untouched.
 */
bool findSkip(alias pred = "a == b", R1, R2)(ref R1 haystack, R2 needle)
if (isForwardRange!R1 && isForwardRange!R2
        && is(typeof(binaryFun!pred(haystack.front, needle.front))))
{
    auto parts = findSplit!pred(haystack, needle);
    if (parts[1].empty) return false;
    // found
    haystack = parts[2];
    return true;
}

///
@safe unittest
{
    import std.range.primitives : empty;
    // Needle is found; s is replaced by the substring following the first
    // occurrence of the needle.
    string s = "abcdef";
    assert(findSkip(s, "cd") && s == "ef");

    // Needle is not found; s is left untouched.
    s = "abcdef";
    assert(!findSkip(s, "cxd") && s == "abcdef");

    // If the needle occurs at the end of the range, the range is left empty.
    s = "abcdef";
    assert(findSkip(s, "def") && s.empty);
}

/**
These functions find the first occurrence of `needle` in `haystack` and then
split `haystack` as follows.

`findSplit` returns a tuple `result` containing $(I three) ranges. `result[0]`
is the portion of `haystack` before `needle`, `result[1]` is the portion of
`haystack` that matches `needle`, and `result[2]` is the portion of `haystack`
after the match. If `needle` was not found, `result[0]` comprehends `haystack`
entirely and `result[1]` and `result[2]` are empty.

`findSplitBefore` returns a tuple `result` containing two ranges. `result[0]` is
the portion of `haystack` before `needle`, and `result[1]` is the balance of
`haystack` starting with the match. If `needle` was not found, `result[0]`
comprehends `haystack` entirely and `result[1]` is empty.

`findSplitAfter` returns a tuple `result` containing two ranges.
`result[0]` is the portion of `haystack` up to and including the
match, and `result[1]` is the balance of `haystack` starting
after the match. If `needle` was not found, `result[0]` is empty
and `result[1]` is `haystack`.

In all cases, the concatenation of the returned ranges spans the
entire `haystack`.

If `haystack` is a random-access range, all three components of the tuple have
the same type as `haystack`. Otherwise, `haystack` must be a forward range and
the type of `result[0]` and `result[1]` is the same as $(REF takeExactly,
std,range).

Params:
    pred = Predicate to use for comparing needle against haystack.
    haystack = The range to search.
    needle = What to look for.

Returns:

A sub-type of `Tuple!()` of the split portions of `haystack` (see above for
details).  This sub-type of `Tuple!()` has `opCast` defined for `bool`.  This
`opCast` returns `true` when the separating `needle` was found
(`!result[1].empty`) and `false` otherwise.  This enables the convenient idiom
shown in the following example.

Example:
---
if (const split = haystack.findSplit(needle))
{
     doSomethingWithSplit(split);
}
---
 */
auto findSplit(alias pred = "a == b", R1, R2)(R1 haystack, R2 needle)
if (isForwardRange!R1 && isForwardRange!R2)
{
    static struct Result(S1, S2) if (isForwardRange!S1 &&
                                     isForwardRange!S2)
    {
        this(S1 pre, S1 separator, S2 post)
        {
            asTuple = typeof(asTuple)(pre, separator, post);
        }
        void opAssign(typeof(asTuple) rhs)
        {
            asTuple = rhs;
        }
        Tuple!(S1, S1, S2) asTuple;
        bool opCast(T : bool)()
        {
            return !asTuple[1].empty;
        }
        alias asTuple this;
    }

    static if (isSomeString!R1 && isSomeString!R2
            || (isRandomAccessRange!R1 && hasSlicing!R1 && hasLength!R1 && hasLength!R2))
    {
        auto balance = find!pred(haystack, needle);
        immutable pos1 = haystack.length - balance.length;
        immutable pos2 = balance.empty ? pos1 : pos1 + needle.length;
        return Result!(typeof(haystack[0 .. pos1]),
                       typeof(haystack[pos2 .. haystack.length]))(haystack[0 .. pos1],
                                                                  haystack[pos1 .. pos2],
                                                                  haystack[pos2 .. haystack.length]);
    }
    else
    {
        import std.range : takeExactly;
        auto original = haystack.save;
        auto h = haystack.save;
        auto n = needle.save;
        size_t pos1, pos2;
        while (!n.empty && !h.empty)
        {
            if (binaryFun!pred(h.front, n.front))
            {
                h.popFront();
                n.popFront();
                ++pos2;
            }
            else
            {
                haystack.popFront();
                n = needle.save;
                h = haystack.save;
                pos2 = ++pos1;
            }
        }
        return Result!(typeof(takeExactly(original, pos1)),
                       typeof(h))(takeExactly(original, pos1),
                                  takeExactly(haystack, pos2 - pos1),
                                  h);
    }
}

/// Ditto
auto findSplitBefore(alias pred = "a == b", R1, R2)(R1 haystack, R2 needle)
if (isForwardRange!R1 && isForwardRange!R2)
{
    static struct Result(S1, S2) if (isForwardRange!S1 &&
                                     isForwardRange!S2)
    {
        this(S1 pre, S2 post)
        {
            asTuple = typeof(asTuple)(pre, post);
        }
        void opAssign(typeof(asTuple) rhs)
        {
            asTuple = rhs;
        }
        Tuple!(S1, S2) asTuple;
        bool opCast(T : bool)()
        {
            return !asTuple[0].empty;
        }
        alias asTuple this;
    }

    static if (isSomeString!R1 && isSomeString!R2
            || (isRandomAccessRange!R1 && hasLength!R1 && hasSlicing!R1 && hasLength!R2))
    {
        auto balance = find!pred(haystack, needle);
        immutable pos = haystack.length - balance.length;
        return Result!(typeof(haystack[0 .. pos]),
                       typeof(haystack[pos .. haystack.length]))(haystack[0 .. pos],
                                                                 haystack[pos .. haystack.length]);
    }
    else
    {
        import std.range : takeExactly;
        auto original = haystack.save;
        auto h = haystack.save;
        auto n = needle.save;
        size_t pos;
        while (!n.empty && !h.empty)
        {
            if (binaryFun!pred(h.front, n.front))
            {
                h.popFront();
                n.popFront();
            }
            else
            {
                haystack.popFront();
                n = needle.save;
                h = haystack.save;
                ++pos;
            }
        }
        return Result!(typeof(takeExactly(original, pos)),
                       typeof(haystack))(takeExactly(original, pos),
                                         haystack);
    }
}

/// Ditto
auto findSplitAfter(alias pred = "a == b", R1, R2)(R1 haystack, R2 needle)
if (isForwardRange!R1 && isForwardRange!R2)
{
    static struct Result(S1, S2) if (isForwardRange!S1 &&
                                     isForwardRange!S2)
    {
        this(S1 pre, S2 post)
        {
            asTuple = typeof(asTuple)(pre, post);
        }
        void opAssign(typeof(asTuple) rhs)
        {
            asTuple = rhs;
        }
        Tuple!(S1, S2) asTuple;
        bool opCast(T : bool)()
        {
            return !asTuple[1].empty;
        }
        alias asTuple this;
    }

    static if (isSomeString!R1 && isSomeString!R2
            || isRandomAccessRange!R1 && hasLength!R1 && hasSlicing!R1 && hasLength!R2)
    {
        auto balance = find!pred(haystack, needle);
        immutable pos = balance.empty ? 0 : haystack.length - balance.length + needle.length;
        return Result!(typeof(haystack[0 .. pos]),
                       typeof(haystack[pos .. haystack.length]))(haystack[0 .. pos],
                                                                 haystack[pos .. haystack.length]);
    }
    else
    {
        import std.range : takeExactly;
        auto original = haystack.save;
        auto h = haystack.save;
        auto n = needle.save;
        size_t pos1, pos2;
        while (!n.empty)
        {
            if (h.empty)
            {
                // Failed search
                return Result!(typeof(takeExactly(original, 0)),
                               typeof(original))(takeExactly(original, 0),
                                                 original);
            }
            if (binaryFun!pred(h.front, n.front))
            {
                h.popFront();
                n.popFront();
                ++pos2;
            }
            else
            {
                haystack.popFront();
                n = needle.save;
                h = haystack.save;
                pos2 = ++pos1;
            }
        }
        return Result!(typeof(takeExactly(original, pos2)),
                       typeof(h))(takeExactly(original, pos2),
                                  h);
    }
}

///
@safe pure nothrow unittest
{
    import std.range.primitives : empty;

    auto a = "Carl Sagan Memorial Station";
    auto r = findSplit(a, "Velikovsky");
    import std.typecons : isTuple;
    static assert(isTuple!(typeof(r.asTuple)));
    static assert(isTuple!(typeof(r)));
    assert(!r);
    assert(r[0] == a);
    assert(r[1].empty);
    assert(r[2].empty);
    r = findSplit(a, " ");
    assert(r[0] == "Carl");
    assert(r[1] == " ");
    assert(r[2] == "Sagan Memorial Station");
    auto r1 = findSplitBefore(a, "Sagan");
    assert(r1);
    assert(r1[0] == "Carl ", r1[0]);
    assert(r1[1] == "Sagan Memorial Station");
    auto r2 = findSplitAfter(a, "Sagan");
    assert(r2);
    assert(r2[0] == "Carl Sagan");
    assert(r2[1] == " Memorial Station");
}

@safe pure nothrow unittest
{
    import std.range.primitives : empty;

    auto a = [ 1, 2, 3, 4, 5, 6, 7, 8 ];
    auto r = findSplit(a, [9, 1]);
    assert(!r);
    assert(r[0] == a);
    assert(r[1].empty);
    assert(r[2].empty);
    r = findSplit(a, [3]);
    assert(r);
    assert(r[0] == a[0 .. 2]);
    assert(r[1] == a[2 .. 3]);
    assert(r[2] == a[3 .. $]);

    auto r1 = findSplitBefore(a, [9, 1]);
    assert(r1);
    assert(r1[0] == a);
    assert(r1[1].empty);
    r1 = findSplitBefore(a, [3, 4]);
    assert(r1);
    assert(r1[0] == a[0 .. 2]);
    assert(r1[1] == a[2 .. $]);

    auto r2 = findSplitAfter(a, [9, 1]);
    assert(r2);
    assert(r2[0].empty);
    assert(r2[1] == a);
    r2 = findSplitAfter(a, [3, 4]);
    assert(r2);
    assert(r2[0] == a[0 .. 4]);
    assert(r2[1] == a[4 .. $]);
}

@safe pure nothrow unittest
{
    import std.algorithm.comparison : equal;
    import std.algorithm.iteration : filter;

    auto a = [ 1, 2, 3, 4, 5, 6, 7, 8 ];
    auto fwd = filter!"a > 0"(a);
    auto r = findSplit(fwd, [9, 1]);
    assert(!r);
    assert(equal(r[0], a));
    assert(r[1].empty);
    assert(r[2].empty);
    r = findSplit(fwd, [3]);
    assert(r);
    assert(equal(r[0],  a[0 .. 2]));
    assert(equal(r[1], a[2 .. 3]));
    assert(equal(r[2], a[3 .. $]));

    auto r1 = findSplitBefore(fwd, [9, 1]);
    assert(r1);
    assert(equal(r1[0], a));
    assert(r1[1].empty);
    r1 = findSplitBefore(fwd, [3, 4]);
    assert(r1);
    assert(equal(r1[0], a[0 .. 2]));
    assert(equal(r1[1], a[2 .. $]));

    auto r2 = findSplitAfter(fwd, [9, 1]);
    assert(r2);
    assert(r2[0].empty);
    assert(equal(r2[1], a));
    r2 = findSplitAfter(fwd, [3, 4]);
    assert(r2);
    assert(equal(r2[0], a[0 .. 4]));
    assert(equal(r2[1], a[4 .. $]));
}

@safe pure nothrow @nogc unittest
{
    auto str = "sep,one,sep,two";

    auto split = str.findSplitAfter(",");
    assert(split[0] == "sep,");

    split = split[1].findSplitAfter(",");
    assert(split[0] == "one,");

    split = split[1].findSplitBefore(",");
    assert(split[0] == "sep");
}

@safe pure nothrow @nogc unittest
{
    auto str = "sep,one,sep,two";

    auto split = str.findSplitBefore(",two");
    assert(split[0] == "sep,one,sep");
    assert(split[1] == ",two");

    split = split[0].findSplitBefore(",sep");
    assert(split[0] == "sep,one");
    assert(split[1] == ",sep");

    split = split[0].findSplitAfter(",");
    assert(split[0] == "sep,");
    assert(split[1] == "one");
}

// minCount
/**

Computes the minimum (respectively maximum) of `range` along with its number of
occurrences. Formally, the minimum is a value `x` in `range` such that $(D
pred(a, x)) is `false` for all values `a` in `range`. Conversely, the maximum is
a value `x` in `range` such that $(D pred(x, a)) is `false` for all values `a`
in `range` (note the swapped arguments to `pred`).

These functions may be used for computing arbitrary extrema by choosing `pred`
appropriately. For corrrect functioning, `pred` must be a strict partial order,
i.e. transitive (if $(D pred(a, b) && pred(b, c)) then $(D pred(a, c))) and
irreflexive ($(D pred(a, a)) is `false`). The $(LUCKY trichotomy property of
inequality) is not required: these algoritms consider elements `a` and `b` equal
(for the purpose of counting) if `pred` puts them in the same equivalence class,
i.e. $(D !pred(a, b) && !pred(b, a)).

Params:
    pred = The ordering predicate to use to determine the extremum (minimum
        or maximum).
    range = The input range to count.

Returns: The minimum, respectively maximum element of a range together with the
number it occurs in the range.

Throws: `Exception` if `range.empty`.
 */
Tuple!(ElementType!Range, size_t)
minCount(alias pred = "a < b", Range)(Range range)
if (isInputRange!Range && !isInfinite!Range &&
    is(typeof(binaryFun!pred(range.front, range.front))))
{
    import std.algorithm.internal : algoFormat;
    import std.exception : enforce;

    alias T  = ElementType!Range;
    alias UT = Unqual!T;
    alias RetType = Tuple!(T, size_t);

    static assert (is(typeof(RetType(range.front, 1))),
        algoFormat("Error: Cannot call minCount on a %s, because it is not possible "~
               "to copy the result value (a %s) into a Tuple.", Range.stringof, T.stringof));

    enforce(!range.empty, "Can't count elements from an empty range");
    size_t occurrences = 1;

    static if (isForwardRange!Range)
    {
        Range least = range.save;
        for (range.popFront(); !range.empty; range.popFront())
        {
            if (binaryFun!pred(least.front, range.front))
            {
                assert(!binaryFun!pred(range.front, least.front),
                    "min/maxPos: predicate must be a strict partial order.");
                continue;
            }
            if (binaryFun!pred(range.front, least.front))
            {
                // change the min
                least = range.save;
                occurrences = 1;
            }
            else
                ++occurrences;
        }
        return RetType(least.front, occurrences);
    }
    else static if (isAssignable!(UT, T) || (!hasElaborateAssign!UT && isAssignable!UT))
    {
        UT v = UT.init;
        static if (isAssignable!(UT, T)) v = range.front;
        else                             v = cast(UT)range.front;

        for (range.popFront(); !range.empty; range.popFront())
        {
            if (binaryFun!pred(*cast(T*)&v, range.front)) continue;
            if (binaryFun!pred(range.front, *cast(T*)&v))
            {
                // change the min
                static if (isAssignable!(UT, T)) v = range.front;
                else                             v = cast(UT)range.front; //Safe because !hasElaborateAssign!UT
                occurrences = 1;
            }
            else
                ++occurrences;
        }
        return RetType(*cast(T*)&v, occurrences);
    }
    else static if (hasLvalueElements!Range)
    {
        import std.algorithm.internal : addressOf;
        T* p = addressOf(range.front);
        for (range.popFront(); !range.empty; range.popFront())
        {
            if (binaryFun!pred(*p, range.front)) continue;
            if (binaryFun!pred(range.front, *p))
            {
                // change the min
                p = addressOf(range.front);
                occurrences = 1;
            }
            else
                ++occurrences;
        }
        return RetType(*p, occurrences);
    }
    else
        static assert(false,
            algoFormat("Sorry, can't find the minCount of a %s: Don't know how "~
                   "to keep track of the smallest %s element.", Range.stringof, T.stringof));
}

/// Ditto
Tuple!(ElementType!Range, size_t)
maxCount(alias pred = "a < b", Range)(Range range)
if (isInputRange!Range && !isInfinite!Range &&
    is(typeof(binaryFun!pred(range.front, range.front))))
{
    return range.minCount!((a, b) => binaryFun!pred(b, a));
}

///
unittest
{
    import std.conv : text;
    import std.typecons : tuple;

    debug(std_algorithm) scope(success)
        writeln("unittest @", __FILE__, ":", __LINE__, " done.");

    int[] a = [ 2, 3, 4, 1, 2, 4, 1, 1, 2 ];
    // Minimum is 1 and occurs 3 times
    assert(a.minCount == tuple(1, 3));
    // Maximum is 4 and occurs 2 times
    assert(a.maxCount == tuple(4, 2));
}

unittest
{
    import std.conv : text;
    import std.exception : assertThrown;
    import std.internal.test.dummyrange;

    debug(std_algorithm) scope(success)
        writeln("unittest @", __FILE__, ":", __LINE__, " done.");

    int[][] b = [ [4], [2, 4], [4], [4] ];
    auto c = minCount!("a[0] < b[0]")(b);
    assert(c == tuple([2, 4], 1), text(c[0]));

    //Test empty range
    assertThrown(minCount(b[$..$]));

    //test with reference ranges. Test both input and forward.
    assert(minCount(new ReferenceInputRange!int([1, 2, 1, 0, 2, 0])) == tuple(0, 2));
    assert(minCount(new ReferenceForwardRange!int([1, 2, 1, 0, 2, 0])) == tuple(0, 2));
}

unittest
{
    import std.conv : text;
    import std.meta : AliasSeq;

    debug(std_algorithm) scope(success)
        writeln("unittest @", __FILE__, ":", __LINE__, " done.");

    static struct R(T) //input range
    {
        T[] arr;
        alias arr this;
    }

    immutable         a = [ 2, 3, 4, 1, 2, 4, 1, 1, 2 ];
    R!(immutable int) b = R!(immutable int)(a);

    assert(minCount(a) == tuple(1, 3));
    assert(minCount(b) == tuple(1, 3));
    assert(minCount!((ref immutable int a, ref immutable int b) => (a > b))(a) == tuple(4, 2));
    assert(minCount!((ref immutable int a, ref immutable int b) => (a > b))(b) == tuple(4, 2));

    immutable(int[])[] c = [ [4], [2, 4], [4], [4] ];
    assert(minCount!("a[0] < b[0]")(c) == tuple([2, 4], 1), text(c[0]));

    static struct S1
    {
        int i;
    }
    alias IS1 = immutable(S1);
    static assert( isAssignable!S1);
    static assert( isAssignable!(S1, IS1));

    static struct S2
    {
        int* p;
        this(ref immutable int i) immutable {p = &i;}
        this(ref int i) {p = &i;}
        @property ref inout(int) i() inout {return *p;}
        bool opEquals(const S2 other) const {return i == other.i;}
    }
    alias IS2 = immutable(S2);
    static assert( isAssignable!S2);
    static assert(!isAssignable!(S2, IS2));
    static assert(!hasElaborateAssign!S2);

    static struct S3
    {
        int i;
        void opAssign(ref S3 other) @disable;
    }
    static assert(!isAssignable!S3);

    foreach (Type; AliasSeq!(S1, IS1, S2, IS2, S3))
    {
        static if (is(Type == immutable)) alias V = immutable int;
        else                              alias V = int;
        V one = 1, two = 2;
        auto r1 = [Type(two), Type(one), Type(one)];
        auto r2 = R!Type(r1);
        assert(minCount!"a.i < b.i"(r1) == tuple(Type(one), 2));
        assert(minCount!"a.i < b.i"(r2) == tuple(Type(one), 2));
        assert(one == 1 && two == 2);
    }
}

/**
Iterates the passed range and returns the minimal element.
A custom mapping function can be passed to `map`.

Complexity: O(n)
    Exactly `n - 1` comparisons are needed.

Params:
    map = custom accessor for the comparison key
    r = range from which the minimal element will be selected
    seed = custom seed to use as initial element

Returns: The minimal element of the passed-in range.

See_Also:
    $(REF min, std,algorithm,comparison)
*/
auto minElement(alias map = "a", Range)(Range r)
    if (isInputRange!Range && !isInfinite!Range)
{
    return extremum!map(r);
}

/// ditto
auto minElement(alias map = "a", Range, RangeElementType = ElementType!Range)
               (Range r, RangeElementType seed)
    if (isInputRange!Range && !isInfinite!Range &&
        !is(CommonType!(ElementType!Range, RangeElementType) == void))
{
    return extremum!map(r, seed);
}

///
@safe pure unittest
{
    import std.range : enumerate;
    import std.typecons : tuple;

    assert([2, 1, 4, 3].minElement == 1);

    // allows to get the index of an element too
    assert([5, 3, 7, 9].enumerate.minElement!"a.value" == tuple(1, 3));

    // any custom accessor can be passed
    assert([[0, 4], [1, 2]].minElement!"a[1]" == [1, 2]);

    // can be seeded
    int[] arr;
    assert(arr.minElement(1) == 1);
}

@safe pure unittest
{
    import std.range : enumerate, iota;
    // supports mapping
    assert([3, 4, 5, 1, 2].enumerate.minElement!"a.value" == tuple(3, 1));
    assert([5, 2, 4].enumerate.minElement!"a.value" == tuple(1, 2));

    // forward ranges
    assert(iota(1, 5).minElement() == 1);
    assert(iota(2, 5).enumerate.minElement!"a.value" == tuple(0, 2));

    // should work with const
    const(int)[] immArr = [2, 1, 3];
    assert(immArr.minElement == 1);

    // should work with immutable
    immutable(int)[] immArr2 = [2, 1, 3];
    assert(immArr2.minElement == 1);

    // with strings
    assert(["b", "a", "c"].minElement == "a");

    // with all dummy ranges
    import std.internal.test.dummyrange;
    foreach (DummyType; AllDummyRanges)
    {
        DummyType d;
        assert(d.minElement == 1);
    }
}

@nogc @safe nothrow pure unittest
{
    static immutable arr = [7, 3, 4, 2, 1, 8];
    assert(arr.minElement == 1);

    static immutable arr2d = [[1, 9], [3, 1], [4, 2]];
    assert(arr2d.minElement!"a[1]" == arr2d[1]);
}

/**
Iterates the passed range and returns the maximal element.
A custom mapping function can be passed to `map`.

Complexity:
    Exactly `n - 1` comparisons are needed.

Params:
    map = custom accessor for the comparison key
    r = range from which the maximum will be selected
    seed = custom seed to use as initial element

Returns: The maximal element of the passed-in range.

See_Also:
    $(REF max, std,algorithm,comparison)
*/
auto maxElement(alias map = "a", Range)(Range r)
    if (isInputRange!Range && !isInfinite!Range &&
        !is(CommonType!(ElementType!Range, RangeElementType) == void))
{
    return extremum!(map, "a > b")(r);
}

/// ditto
auto maxElement(alias map = "a", Range, RangeElementType = ElementType!Range)
               (Range r, RangeElementType seed)
    if (isInputRange!Range && !isInfinite!Range)
{
    return extremum!(map, "a > b")(r, seed);
}

///
@safe pure unittest
{
    import std.range : enumerate;
    import std.typecons : tuple;
    assert([2, 1, 4, 3].maxElement == 4);

    // allows to get the index of an element too
    assert([2, 1, 4, 3].enumerate.maxElement!"a.value" == tuple(2, 4));

    // any custom accessor can be passed
    assert([[0, 4], [1, 2]].maxElement!"a[1]" == [0, 4]);

    // can be seeded
    int[] arr;
    assert(arr.minElement(1) == 1);
}

@safe pure unittest
{
    import std.range : enumerate, iota;

    // supports mapping
    assert([3, 4, 5, 1, 2].enumerate.maxElement!"a.value" == tuple(2, 5));
    assert([5, 2, 4].enumerate.maxElement!"a.value" == tuple(0, 5));

    // forward ranges
    assert(iota(1, 5).maxElement() == 4);
    assert(iota(2, 5).enumerate.maxElement!"a.value" == tuple(2, 4));
    assert(iota(4, 14).enumerate.maxElement!"a.value" == tuple(9, 13));

    // should work with const
    const(int)[] immArr = [2, 3, 1];
    assert(immArr.maxElement == 3);

    // should work with immutable
    immutable(int)[] immArr2 = [2, 3, 1];
    assert(immArr2.maxElement == 3);

    // with strings
    assert(["a", "c", "b"].maxElement == "c");

    // with all dummy ranges
    import std.internal.test.dummyrange;
    foreach (DummyType; AllDummyRanges)
    {
        DummyType d;
        assert(d.maxElement == 10);
    }
}

@nogc @safe nothrow pure unittest
{
    static immutable arr = [7, 3, 8, 2, 1, 4];
    assert(arr.maxElement == 8);

    static immutable arr2d = [[1, 3], [3, 9], [4, 2]];
    assert(arr2d.maxElement!"a[1]" == arr2d[1]);
}


// minPos
/**
Computes a subrange of `range` starting at the first occurrence of `range`'s
minimum (respectively maximum) and with the same ending as `range`, or the
empty range if `range` itself is empty.

Formally, the minimum is a value `x` in `range` such that $(D pred(a, x)) is
`false` for all values `a` in `range`. Conversely, the maximum is a value `x` in
`range` such that $(D pred(x, a)) is `false` for all values `a` in `range` (note
the swapped arguments to `pred`).

These functions may be used for computing arbitrary extrema by choosing `pred`
appropriately. For corrrect functioning, `pred` must be a strict partial order,
i.e. transitive (if $(D pred(a, b) && pred(b, c)) then $(D pred(a, c))) and
irreflexive ($(D pred(a, a)) is `false`).

Params:
    pred = The ordering predicate to use to determine the extremum (minimum or
        maximum) element.
    range = The input range to search.

Returns: The position of the minimum (respectively maximum) element of forward
range `range`, i.e. a subrange of `range` starting at the position of  its
smallest (respectively largest) element and with the same ending as `range`.

*/
Range minPos(alias pred = "a < b", Range)(Range range)
    if (isForwardRange!Range && !isInfinite!Range &&
        is(typeof(binaryFun!pred(range.front, range.front))))
{
    static if (hasSlicing!Range && isRandomAccessRange!Range && hasLength!Range)
    {
        // Prefer index-based access
        size_t pos = 0;
        foreach (i; 1 .. range.length)
        {
            if (binaryFun!pred(range[i], range[pos]))
            {
                pos = i;
            }
        }
        return range[pos .. range.length];
    }
    else
    {
        auto result = range.save;
        if (range.empty) return result;
        for (range.popFront(); !range.empty; range.popFront())
        {
            // Note: Unlike minCount, we do not care to find equivalence, so a
            // single pred call is enough.
            if (binaryFun!pred(range.front, result.front))
            {
                // change the min
                result = range.save;
            }
        }
        return result;
    }
}

/// Ditto
Range maxPos(alias pred = "a < b", Range)(Range range)
if (isForwardRange!Range && !isInfinite!Range &&
    is(typeof(binaryFun!pred(range.front, range.front))))
{
    return range.minPos!((a, b) => binaryFun!pred(b, a));
}

///
@safe unittest
{
    int[] a = [ 2, 3, 4, 1, 2, 4, 1, 1, 2 ];
    // Minimum is 1 and first occurs in position 3
    assert(a.minPos == [ 1, 2, 4, 1, 1, 2 ]);
    // Maximum is 4 and first occurs in position 2
    assert(a.maxPos == [ 4, 1, 2, 4, 1, 1, 2 ]);
}

@safe unittest
{
    import std.algorithm.comparison : equal;
    import std.internal.test.dummyrange;

    debug(std_algorithm) scope(success)
        writeln("unittest @", __FILE__, ":", __LINE__, " done.");
    int[] a = [ 2, 3, 4, 1, 2, 4, 1, 1, 2 ];
    //Test that an empty range works
    int[] b = a[$..$];
    assert(equal(minPos(b), b));

    //test with reference range.
    assert( equal( minPos(new ReferenceForwardRange!int([1, 2, 1, 0, 2, 0])), [0, 2, 0] ) );
}

unittest
{
    //Rvalue range
    import std.algorithm.comparison : equal;
    import std.container : Array;

    debug(std_algorithm) scope(success)
        writeln("unittest @", __FILE__, ":", __LINE__, " done.");

    assert(Array!int(2, 3, 4, 1, 2, 4, 1, 1, 2)
               []
               .minPos()
               .equal([ 1, 2, 4, 1, 1, 2 ]));
}

@safe unittest
{
    //BUG 9299
    debug(std_algorithm) scope(success)
        writeln("unittest @", __FILE__, ":", __LINE__, " done.");
    immutable a = [ 2, 3, 4, 1, 2, 4, 1, 1, 2 ];
    // Minimum is 1 and first occurs in position 3
    assert(minPos(a) == [ 1, 2, 4, 1, 1, 2 ]);
    // Maximum is 4 and first occurs in position 5
    assert(minPos!("a > b")(a) == [ 4, 1, 2, 4, 1, 1, 2 ]);

    immutable(int[])[] b = [ [4], [2, 4], [4], [4] ];
    assert(minPos!("a[0] < b[0]")(b) == [ [2, 4], [4], [4] ]);
}

/**
Skip over the initial portion of the first given range that matches the second
range, or do nothing if there is no match.

Params:
    pred = The predicate that determines whether elements from each respective
        range match. Defaults to equality $(D "a == b").
    r1 = The $(REF_ALTTEXT forward range, isForwardRange, std,range,primitives) to
        move forward.
    r2 = The $(REF_ALTTEXT input range, isInputRange, std,range,primitives)
        representing the initial segment of $(D r1) to skip over.

Returns:
true if the initial segment of $(D r1) matches $(D r2), and $(D r1) has been
advanced to the point past this segment; otherwise false, and $(D r1) is left
in its original position.
 */
bool skipOver(R1, R2)(ref R1 r1, R2 r2)
    if (isForwardRange!R1 && isInputRange!R2
        && is(typeof(r1.front == r2.front)))
{
    static if (is(typeof(r1[0 .. $] == r2) : bool)
        && is(typeof(r2.length > r1.length) : bool)
        && is(typeof(r1 = r1[r2.length .. $])))
    {
        if (r2.length > r1.length || r1[0 .. r2.length] != r2)
        {
            return false;
        }
        r1 = r1[r2.length .. $];
        return true;
    }
    else
    {
        return skipOver!((a, b) => a == b)(r1, r2);
    }
}

/// Ditto
bool skipOver(alias pred, R1, R2)(ref R1 r1, R2 r2)
    if (is(typeof(binaryFun!pred(r1.front, r2.front))) &&
        isForwardRange!R1 &&
        isInputRange!R2)
{
    static if (hasLength!R1 && hasLength!R2)
    {
        // Shortcut opportunity!
        if (r2.length > r1.length)
            return false;
    }
    auto r = r1.save;
    while (!r2.empty && !r.empty && binaryFun!pred(r.front, r2.front))
    {
        r.popFront();
        r2.popFront();
    }
    if (r2.empty)
        r1 = r;
    return r2.empty;
}

///
@safe unittest
{
    import std.algorithm.comparison : equal;

    auto s1 = "Hello world";
    assert(!skipOver(s1, "Ha"));
    assert(s1 == "Hello world");
    assert(skipOver(s1, "Hell") && s1 == "o world");

    string[]  r1 = ["abc", "def", "hij"];
    dstring[] r2 = ["abc"d];
    assert(!skipOver!((a, b) => a.equal(b))(r1, ["def"d]));
    assert(r1 == ["abc", "def", "hij"]);
    assert(skipOver!((a, b) => a.equal(b))(r1, r2));
    assert(r1 == ["def", "hij"]);
}

/**
Skip over the first element of the given range if it matches the given element,
otherwise do nothing.

Params:
    pred = The predicate that determines whether an element from the range
        matches the given element.

    r = The $(REF_ALTTEXT input range, isInputRange, std,range,primitives) to skip
        over.

    e = The element to match.

Returns:
true if the first element matches the given element according to the given
predicate, and the range has been advanced by one element; otherwise false, and
the range is left untouched.
 */
bool skipOver(R, E)(ref R r, E e)
    if (isInputRange!R && is(typeof(r.front == e) : bool))
{
    return skipOver!((a, b) => a == b)(r, e);
}

/// Ditto
bool skipOver(alias pred, R, E)(ref R r, E e)
    if (is(typeof(binaryFun!pred(r.front, e))) && isInputRange!R)
{
    if (r.empty || !binaryFun!pred(r.front, e))
        return false;
    r.popFront();
    return true;
}

///
@safe unittest
{
    import std.algorithm.comparison : equal;

    auto s1 = "Hello world";
    assert(!skipOver(s1, 'a'));
    assert(s1 == "Hello world");
    assert(skipOver(s1, 'H') && s1 == "ello world");

    string[] r = ["abc", "def", "hij"];
    dstring e = "abc"d;
    assert(!skipOver!((a, b) => a.equal(b))(r, "def"d));
    assert(r == ["abc", "def", "hij"]);
    assert(skipOver!((a, b) => a.equal(b))(r, e));
    assert(r == ["def", "hij"]);

    auto s2 = "";
    assert(!s2.skipOver('a'));
}

/**
Checks whether the given
$(REF_ALTTEXT input range, isInputRange, std,range,primitives) starts with (one
of) the given needle(s) or, if no needles are given,
if its front element fulfils predicate $(D pred).

Params:

    pred = Predicate to use in comparing the elements of the haystack and the
        needle(s). Mandatory if no needles are given.

    doesThisStart = The input range to check.

    withOneOfThese = The needles against which the range is to be checked,
        which may be individual elements or input ranges of elements.

    withThis = The single needle to check, which may be either a single element
        or an input range of elements.

Returns:

0 if the needle(s) do not occur at the beginning of the given range;
otherwise the position of the matching needle, that is, 1 if the range starts
with $(D withOneOfThese[0]), 2 if it starts with $(D withOneOfThese[1]), and so
on.

In the case where $(D doesThisStart) starts with multiple of the ranges or
elements in $(D withOneOfThese), then the shortest one matches (if there are
two which match which are of the same length (e.g. $(D "a") and $(D 'a')), then
the left-most of them in the argument
list matches).

In the case when no needle parameters are given, return $(D true) iff front of
$(D doesThisStart) fulfils predicate $(D pred).
 */
uint startsWith(alias pred = "a == b", Range, Needles...)(Range doesThisStart, Needles withOneOfThese)
if (isInputRange!Range && Needles.length > 1 &&
    is(typeof(.startsWith!pred(doesThisStart, withOneOfThese[0])) : bool ) &&
    is(typeof(.startsWith!pred(doesThisStart, withOneOfThese[1 .. $])) : uint))
{
    alias haystack = doesThisStart;
    alias needles  = withOneOfThese;

    // Make one pass looking for empty ranges in needles
    foreach (i, Unused; Needles)
    {
        // Empty range matches everything
        static if (!is(typeof(binaryFun!pred(haystack.front, needles[i])) : bool))
        {
            if (needles[i].empty) return i + 1;
        }
    }

    for (; !haystack.empty; haystack.popFront())
    {
        foreach (i, Unused; Needles)
        {
            static if (is(typeof(binaryFun!pred(haystack.front, needles[i])) : bool))
            {
                // Single-element
                if (binaryFun!pred(haystack.front, needles[i]))
                {
                    // found, but instead of returning, we just stop searching.
                    // This is to account for one-element
                    // range matches (consider startsWith("ab", "a",
                    // 'a') should return 1, not 2).
                    break;
                }
            }
            else
            {
                if (binaryFun!pred(haystack.front, needles[i].front))
                {
                    continue;
                }
            }

            // This code executed on failure to match
            // Out with this guy, check for the others
            uint result = startsWith!pred(haystack, needles[0 .. i], needles[i + 1 .. $]);
            if (result > i) ++result;
            return result;
        }

        // If execution reaches this point, then the front matches for all
        // needle ranges, or a needle element has been matched.
        // What we need to do now is iterate, lopping off the front of
        // the range and checking if the result is empty, or finding an
        // element needle and returning.
        // If neither happens, we drop to the end and loop.
        foreach (i, Unused; Needles)
        {
            static if (is(typeof(binaryFun!pred(haystack.front, needles[i])) : bool))
            {
                // Test has passed in the previous loop
                return i + 1;
            }
            else
            {
                needles[i].popFront();
                if (needles[i].empty) return i + 1;
            }
        }
    }
    return 0;
}

/// Ditto
bool startsWith(alias pred = "a == b", R1, R2)(R1 doesThisStart, R2 withThis)
if (isInputRange!R1 &&
    isInputRange!R2 &&
    is(typeof(binaryFun!pred(doesThisStart.front, withThis.front)) : bool))
{
    alias haystack = doesThisStart;
    alias needle   = withThis;

    static if (is(typeof(pred) : string))
        enum isDefaultPred = pred == "a == b";
    else
        enum isDefaultPred = false;

    //Note: While narrow strings don't have a "true" length, for a narrow string to start with another
    //narrow string *of the same type*, it must have *at least* as many code units.
    static if ((hasLength!R1 && hasLength!R2) ||
        (isNarrowString!R1 && isNarrowString!R2 && ElementEncodingType!R1.sizeof == ElementEncodingType!R2.sizeof))
    {
        if (haystack.length < needle.length)
            return false;
    }

    static if (isDefaultPred && isArray!R1 && isArray!R2 &&
               is(Unqual!(ElementEncodingType!R1) == Unqual!(ElementEncodingType!R2)))
    {
        //Array slice comparison mode
        return haystack[0 .. needle.length] == needle;
    }
    else static if (isRandomAccessRange!R1 && isRandomAccessRange!R2 && hasLength!R2)
    {
        //RA dual indexing mode
        foreach (j; 0 .. needle.length)
        {
            if (!binaryFun!pred(haystack[j], needle[j]))
                // not found
                return false;
        }
        // found!
        return true;
    }
    else
    {
        //Standard input range mode
        if (needle.empty) return true;
        static if (hasLength!R1 && hasLength!R2)
        {
            //We have previously checked that haystack.length > needle.length,
            //So no need to check haystack.empty during iteration
            for ( ; ; haystack.popFront() )
            {
                if (!binaryFun!pred(haystack.front, needle.front)) break;
                needle.popFront();
                if (needle.empty) return true;
            }
        }
        else
        {
            for ( ; !haystack.empty ; haystack.popFront() )
            {
                if (!binaryFun!pred(haystack.front, needle.front)) break;
                needle.popFront();
                if (needle.empty) return true;
            }
        }
        return false;
    }
}

/// Ditto
bool startsWith(alias pred = "a == b", R, E)(R doesThisStart, E withThis)
    if (isInputRange!R &&
        is(typeof(binaryFun!pred(doesThisStart.front, withThis)) : bool))
{
    return doesThisStart.empty
        ? false
        : binaryFun!pred(doesThisStart.front, withThis);
}

/// Ditto
bool startsWith(alias pred, R)(R doesThisStart)
    if (isInputRange!R &&
        ifTestable!(typeof(doesThisStart.front), unaryFun!pred))
{
    return !doesThisStart.empty && unaryFun!pred(doesThisStart.front);
}

///
@safe unittest
{
    import std.ascii : isAlpha;

    assert("abc".startsWith!(a => a.isAlpha));
    assert("abc".startsWith!isAlpha);
    assert(!"1ab".startsWith!(a => a.isAlpha));
    assert(!"".startsWith!(a => a.isAlpha));

    import std.algorithm.comparison : among;
    assert("abc".startsWith!(a => a.among('a', 'b') != 0));
    assert(!"abc".startsWith!(a => a.among('b', 'c') != 0));

    assert(startsWith("abc", ""));
    assert(startsWith("abc", "a"));
    assert(!startsWith("abc", "b"));
    assert(startsWith("abc", 'a', "b") == 1);
    assert(startsWith("abc", "b", "a") == 2);
    assert(startsWith("abc", "a", "a") == 1);
    assert(startsWith("abc", "ab", "a") == 2);
    assert(startsWith("abc", "x", "a", "b") == 2);
    assert(startsWith("abc", "x", "aa", "ab") == 3);
    assert(startsWith("abc", "x", "aaa", "sab") == 0);
    assert(startsWith("abc", "x", "aaa", "a", "sab") == 3);

    import std.typecons : Tuple;
    alias C = Tuple!(int, "x", int, "y");
    assert(startsWith!"a.x == b"([ C(1,1), C(1,2), C(2,2) ], [1, 1]));
    assert(startsWith!"a.x == b"([ C(1,1), C(2,1), C(2,2) ], [1, 1], [1, 2], [1, 3]) == 2);
}

@safe unittest
{
    import std.algorithm.iteration : filter;
    import std.conv : to;
    import std.meta : AliasSeq;
    import std.range;

    debug(std_algorithm) scope(success)
        writeln("unittest @", __FILE__, ":", __LINE__, " done.");

    foreach (S; AliasSeq!(char[], wchar[], dchar[], string, wstring, dstring))
    {
        assert(!startsWith(to!S("abc"), 'c'));
        assert(startsWith(to!S("abc"), 'a', 'c') == 1);
        assert(!startsWith(to!S("abc"), 'x', 'n', 'b'));
        assert(startsWith(to!S("abc"), 'x', 'n', 'a') == 3);
        assert(startsWith(to!S("\uFF28abc"), 'a', '\uFF28', 'c') == 2);

        foreach (T; AliasSeq!(char[], wchar[], dchar[], string, wstring, dstring))
        (){ // avoid slow optimizations for large functions @@@BUG@@@ 2396
            //Lots of strings
            assert(startsWith(to!S("abc"), to!T("")));
            assert(startsWith(to!S("ab"), to!T("a")));
            assert(startsWith(to!S("abc"), to!T("a")));
            assert(!startsWith(to!S("abc"), to!T("b")));
            assert(!startsWith(to!S("abc"), to!T("b"), "bc", "abcd", "xyz"));
            assert(startsWith(to!S("abc"), to!T("ab"), 'a') == 2);
            assert(startsWith(to!S("abc"), to!T("a"), "b") == 1);
            assert(startsWith(to!S("abc"), to!T("b"), "a") == 2);
            assert(startsWith(to!S("abc"), to!T("a"), 'a') == 1);
            assert(startsWith(to!S("abc"), 'a', to!T("a")) == 1);
            assert(startsWith(to!S("abc"), to!T("x"), "a", "b") == 2);
            assert(startsWith(to!S("abc"), to!T("x"), "aa", "ab") == 3);
            assert(startsWith(to!S("abc"), to!T("x"), "aaa", "sab") == 0);
            assert(startsWith(to!S("abc"), 'a'));
            assert(!startsWith(to!S("abc"), to!T("sab")));
            assert(startsWith(to!S("abc"), 'x', to!T("aaa"), 'a', "sab") == 3);

            //Unicode
            assert(startsWith(to!S("\uFF28el\uFF4co"), to!T("\uFF28el")));
            assert(startsWith(to!S("\uFF28el\uFF4co"), to!T("Hel"), to!T("\uFF28el")) == 2);
            assert(startsWith(to!S("日本語"), to!T("日本")));
            assert(startsWith(to!S("日本語"), to!T("日本語")));
            assert(!startsWith(to!S("日本"), to!T("日本語")));

            //Empty
            assert(startsWith(to!S(""),  T.init));
            assert(!startsWith(to!S(""), 'a'));
            assert(startsWith(to!S("a"), T.init));
            assert(startsWith(to!S("a"), T.init, "") == 1);
            assert(startsWith(to!S("a"), T.init, 'a') == 1);
            assert(startsWith(to!S("a"), 'a', T.init) == 2);
        }();
    }

    //Length but no RA
    assert(!startsWith("abc".takeExactly(3), "abcd".takeExactly(4)));
    assert(startsWith("abc".takeExactly(3), "abcd".takeExactly(3)));
    assert(startsWith("abc".takeExactly(3), "abcd".takeExactly(1)));

    foreach (T; AliasSeq!(int, short))
    {
        immutable arr = cast(T[])[0, 1, 2, 3, 4, 5];

        //RA range
        assert(startsWith(arr, cast(int[])null));
        assert(!startsWith(arr, 5));
        assert(!startsWith(arr, 1));
        assert(startsWith(arr, 0));
        assert(startsWith(arr, 5, 0, 1) == 2);
        assert(startsWith(arr, [0]));
        assert(startsWith(arr, [0, 1]));
        assert(startsWith(arr, [0, 1], 7) == 1);
        assert(!startsWith(arr, [0, 1, 7]));
        assert(startsWith(arr, [0, 1, 7], [0, 1, 2]) == 2);

        //Normal input range
        assert(!startsWith(filter!"true"(arr), 1));
        assert(startsWith(filter!"true"(arr), 0));
        assert(startsWith(filter!"true"(arr), [0]));
        assert(startsWith(filter!"true"(arr), [0, 1]));
        assert(startsWith(filter!"true"(arr), [0, 1], 7) == 1);
        assert(!startsWith(filter!"true"(arr), [0, 1, 7]));
        assert(startsWith(filter!"true"(arr), [0, 1, 7], [0, 1, 2]) == 2);
        assert(startsWith(arr, filter!"true"([0, 1])));
        assert(startsWith(arr, filter!"true"([0, 1]), 7) == 1);
        assert(!startsWith(arr, filter!"true"([0, 1, 7])));
        assert(startsWith(arr, [0, 1, 7], filter!"true"([0, 1, 2])) == 2);

        //Non-default pred
        assert(startsWith!("a%10 == b%10")(arr, [10, 11]));
        assert(!startsWith!("a%10 == b%10")(arr, [10, 12]));
    }
}

/* (Not yet documented.)
Consume all elements from $(D r) that are equal to one of the elements
$(D es).
 */
private void skipAll(alias pred = "a == b", R, Es...)(ref R r, Es es)
//if (is(typeof(binaryFun!pred(r1.front, es[0]))))
{
  loop:
    for (; !r.empty; r.popFront())
    {
        foreach (i, E; Es)
        {
            if (binaryFun!pred(r.front, es[i]))
            {
                continue loop;
            }
        }
        break;
    }
}

@safe unittest
{
    //scope(success) writeln("unittest @", __FILE__, ":", __LINE__, " done.");
    auto s1 = "Hello world";
    skipAll(s1, 'H', 'e');
    assert(s1 == "llo world");
}

/**
Interval option specifier for $(D until) (below) and others.

If set to $(D OpenRight.yes), then the interval is open to the right
(last element is not included).

Otherwise if set to $(D OpenRight.no), then the interval is closed to the right
(last element included).
 */
alias OpenRight = Flag!"openRight";

/**
Lazily iterates $(D range) _until the element $(D e) for which
$(D pred(e, sentinel)) is true.

Params:
    pred = Predicate to determine when to stop.
    range = The $(REF_ALTTEXT input _range, isInputRange, std,_range,primitives)
    to iterate over.
    sentinel = The element to stop at.
    openRight = Determines whether the element for which the given predicate is
        true should be included in the resulting range ($(D No.openRight)), or
        not ($(D Yes.openRight)).

Returns:
    An $(REF_ALTTEXT input _range, isInputRange, std,_range,primitives) that
    iterates over the original range's elements, but ends when the specified
    predicate becomes true. If the original range is a
    $(REF_ALTTEXT forward _range, isForwardRange, std,_range,primitives) or
    higher, this range will be a forward range.
 */
Until!(pred, Range, Sentinel)
until(alias pred = "a == b", Range, Sentinel)
(Range range, Sentinel sentinel, OpenRight openRight = Yes.openRight)
if (!is(Sentinel == OpenRight))
{
    return typeof(return)(range, sentinel, openRight);
}

/// Ditto
Until!(pred, Range, void)
until(alias pred, Range)
(Range range, OpenRight openRight = Yes.openRight)
{
    return typeof(return)(range, openRight);
}

/// ditto
struct Until(alias pred, Range, Sentinel) if (isInputRange!Range)
{
    private Range _input;
    static if (!is(Sentinel == void))
        private Sentinel _sentinel;
    // mixin(bitfields!(
    //             OpenRight, "_openRight", 1,
    //             bool,  "_done", 1,
    //             uint, "", 6));
    //             OpenRight, "_openRight", 1,
    //             bool,  "_done", 1,
    private OpenRight _openRight;
    private bool _done;

    static if (!is(Sentinel == void))
        ///
        this(Range input, Sentinel sentinel,
                OpenRight openRight = Yes.openRight)
        {
            _input = input;
            _sentinel = sentinel;
            _openRight = openRight;
            _done = _input.empty || openRight && predSatisfied();
        }
    else
        ///
        this(Range input, OpenRight openRight = Yes.openRight)
        {
            _input = input;
            _openRight = openRight;
            _done = _input.empty || openRight && predSatisfied();
        }

    ///
    @property bool empty()
    {
        return _done;
    }

    ///
    @property auto ref front()
    {
        assert(!empty);
        return _input.front;
    }

    private bool predSatisfied()
    {
        static if (is(Sentinel == void))
            return cast(bool) unaryFun!pred(_input.front);
        else
            return cast(bool) startsWith!pred(_input, _sentinel);
    }

    ///
    void popFront()
    {
        assert(!empty);
        if (!_openRight)
        {
            _done = predSatisfied();
            _input.popFront();
            _done = _done || _input.empty;
        }
        else
        {
            _input.popFront();
            _done = _input.empty || predSatisfied();
        }
    }

    static if (isForwardRange!Range)
    {
        static if (!is(Sentinel == void))
            ///
            @property Until save()
            {
                Until result = this;
                result._input     = _input.save;
                result._sentinel  = _sentinel;
                result._openRight = _openRight;
                result._done      = _done;
                return result;
            }
        else
            ///
            @property Until save()
            {
                Until result = this;
                result._input     = _input.save;
                result._openRight = _openRight;
                result._done      = _done;
                return result;
            }
    }
}

///
@safe unittest
{
    import std.algorithm.comparison : equal;
    int[] a = [ 1, 2, 4, 7, 7, 2, 4, 7, 3, 5];
    assert(equal(a.until(7), [1, 2, 4][]));
    assert(equal(a.until(7, No.openRight), [1, 2, 4, 7][]));
}

@safe unittest
{
    import std.algorithm.comparison : equal;
    //scope(success) writeln("unittest @", __FILE__, ":", __LINE__, " done.");
    int[] a = [ 1, 2, 4, 7, 7, 2, 4, 7, 3, 5];

    static assert(isForwardRange!(typeof(a.until(7))));
    static assert(isForwardRange!(typeof(until!"a == 2"(a, No.openRight))));

    assert(equal(a.until(7), [1, 2, 4][]));
    assert(equal(a.until([7, 2]), [1, 2, 4, 7][]));
    assert(equal(a.until(7, No.openRight), [1, 2, 4, 7][]));
    assert(equal(until!"a == 2"(a, No.openRight), [1, 2][]));
}

unittest // bugzilla 13171
{
    import std.algorithm.comparison : equal;
    import std.range;
    auto a = [1, 2, 3, 4];
    assert(equal(refRange(&a).until(3, No.openRight), [1, 2, 3]));
    assert(a == [4]);
}

@safe unittest // Issue 10460
{
    import std.algorithm.comparison : equal;
    auto a = [1, 2, 3, 4];
    foreach (ref e; a.until(3))
        e = 0;
    assert(equal(a, [0, 0, 3, 4]));
}

unittest // Issue 13124
{
    import std.algorithm.comparison : among;
    auto s = "hello how\nare you";
    s.until!(c => c.among!('\n', '\r'));
}