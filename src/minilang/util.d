module minilang.util;

import std.range.primitives : isInputRange;
import std.algorithm.iteration : map, reduce;

public T castOrFail(T, S)(S s) {
    T t = cast(T) s;
    if (t is null) {
        throw new Error("Cannot cast " ~ __traits(identifier, S) ~ " to " ~ __traits(identifier, T));
    }
    return t;
}

public K[V] inverse(K, V)(V[K] array) {
    K[V] inv;
    foreach (k, v; array) {
        inv[v] = k;
    }
    return inv;
}

public string join(string joiner, string stringer = "a.to!string()", Range)(Range things) if (isInputRange!Range) {
    if (things.length <= 0) {
        return "";
    }
    return things.map!stringer().reduce!("a ~ \"" ~ joiner ~ "\" ~ b")();
}
