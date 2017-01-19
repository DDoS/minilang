module minilang.util;

public K[V] inverse(K, V)(V[K] array) {
    K[V] inv;
    foreach (k, v; array) {
        inv[v] = k;
    }
    return inv;
}
