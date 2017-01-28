module minilang.transform;

import std.meta : AliasSeq, DerivedToFront, NoDuplicates;
import std.traits : BaseClassesTuple, ReturnType;
import std.format : format;

import minilang.ast;
import minilang.util;

public alias transform = AutoDispatch!(
    NameExpr,
    StringExpr, IntExpr, FloatExpr,
    NegateExpr,
    AddExpr, SubtractExpr, MultiplyExpr, DivideExpr,
    Declaration,
    ReadStmt, PrintStmt,
    Assignment,
    IfStmt, WhileStmt,
    Program
);

// This code is modified from: https://wiki.dlang.org/Dispatching_an_object_based_on_its_dynamic_type
private template AutoDispatch(Leaves...) {
    public R AutoDispatch(alias func, R = ReturnType!func, Args...)(Args args)
            if (Args.length >= 1 && is(Args[0] == class)) {
        auto objInfo = typeid(args[0]);
        foreach (Base; ClassTree!Leaves) {
            if (objInfo == Base.classinfo) {
                // Avoid CT errors due to unrolled static foreach
                static if (__traits(compiles, {return func(cast(Base) cast(void*) args[0], args[1..$]);}())) {
                    return func(cast(Base) cast(void*) args[0], args[1..$]);
                }
            }
        }
        string[] arguments;
        arguments ~= objInfo.toString();
        foreach (arg; args[1..$]) {
            arguments ~= typeof(arg).stringof;
        }
        throw new Error(
            format("function '%s' is not callable with types '(%s)'", __traits(identifier, func), arguments.join!", "())
        );
    }
}

private template ClassTreeImpl(Leaves...) {
    static if (Leaves.length > 1) {
        private alias ClassTreeImpl = AliasSeq!(Leaves[0], BaseClassesTuple!(Leaves[0]), ClassTreeImpl!(Leaves[1..$]));
    } else static if (Leaves.length == 1) {
        private alias ClassTreeImpl = AliasSeq!(Leaves[0], BaseClassesTuple!(Leaves[0]));
    } else {
        private alias ClassTreeImpl = AliasSeq!();
    }
}

private template ClassTree(Leaves...) {
    private alias ClassTree = DerivedToFront!(NoDuplicates!(ClassTreeImpl!(Leaves)));
}
