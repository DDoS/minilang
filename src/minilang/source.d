module minilang.source;

import std.conv : to;
import std.string : stripRight;
import std.algorithm.comparison : min;

import minilang.chars;

public class SourceReader {
    private enum size_t DEFAULT_COLLECT_SIZE = 16;
    private string source;
    private size_t index = 0;
    private char[] collected;
    private size_t collectedCount = 0;

    public this(string source) {
        this.source = source;
        collected.length = DEFAULT_COLLECT_SIZE;
    }

    public bool has() {
        return index < source.length;
    }

    public char head() {
        if (!has()) {
            return '\u0004';
        }
        return source[index];
    }

    @property public size_t count() {
        return index;
    }

    public void advance() {
        index++;
    }

    public void collect() {
        collected[collectedCount++] = head();
        if (collectedCount >= collected.length) {
            collected.length += DEFAULT_COLLECT_SIZE;
        }
        advance();
    }

    public string peekCollected() {
        return collected[0 .. collectedCount].idup;
    }

    public string popCollected() {
        auto cs = peekCollected();
        collected.length = DEFAULT_COLLECT_SIZE;
        collectedCount = 0;
        return cs;
    }
}

unittest {
    auto reader = new SourceReader("this is a test to see hoho l");
    while (reader.head() != ' ') {
        reader.advance();
    }
    while (reader.head() != 'h') {
        reader.collect();
    }
    assert(reader.popCollected() == " is a test to see ");
    while (reader.has()) {
        reader.collect();
    }
    assert(reader.popCollected() == "hoho l");
}

public mixin template sourceIndexFields() {
    private size_t _start;
    private size_t _end;

    @property public size_t start() {
        return _start;
    }

    @property public size_t end() {
        return _end;
    }

    @property public void start(size_t start) {
        _start = start;
    }

    @property public void end(size_t end) {
        _end = end;
    }
}

public class SourceException : Exception {
    // This is a duck typing trick: "is(type)" only returns true if the type is valid.
    // The type can be that of a lambda, so we declare one and get the type using typeof(lambda).
    // Since typeof doesn't actually evaluate the expression, all that matters is that it compiles.
    // This is where duck typing comes in, the lambda body defines the operations we want on S
    // and only compiles if the operations are valid
    private enum bool isSourceIndexed(S) = is(typeof(
        (inout int = 0) {
            S s = S.init;
            size_t start = s.start;
            size_t end = s.end;
        }
    ));

    private string offender = null;
    private size_t _start;
    private size_t _end;

    public this(string message, size_t index) {
        this(message, null, index);
    }

    public this(string message, char offender, size_t index) {
        this(message, offender.escapeChar(), index);
    }

    public this(string message, string offender, size_t index) {
        super(message);
        this.offender = offender;
        _start = index;
        _end = index;
    }

    public this(SourceIndexed)(string message, SourceIndexed problem) if (isSourceIndexed!SourceIndexed) {
        this(message, problem.start, problem.end);
    }

    public this(SourceIndexed)(string message, string offender, SourceIndexed problem) if (isSourceIndexed!SourceIndexed) {
        this(message, offender, problem.start, problem.end);
    }

    public this(string message, size_t start, size_t end) {
        this(message, null, start, end);
    }

    public this(string message, string offender, size_t start, size_t end) {
        super(message);
        assert(start <= end);
        _start = start;
        _end = end;
    }

    @property public size_t start() {
        return _start;
    }

    @property public size_t end() {
        return _start;
    }

    public immutable(ErrorInformation)* getErrorInformation(string source) {
        if (source.length == 0) {
            return new immutable ErrorInformation(this.msg, offender, "", 0, 0, 0);
        }
        // Special case, both start and end are max values when the source is unknown
        if (_start == size_t.max && _end == size_t.max) {
            return new immutable ErrorInformation(this.msg, offender);
        }
        // find the line number the error occurred on
        size_t lineNumber = findLine(source, min(_start, source.length - 1));
        // find start and end of the line containing the error
        size_t lineStart = _start, lineEnd = _start;
        while (lineStart > 0 && !source[lineStart - 1].isNewLine()) {
            lineStart--;
        }
        while (lineEnd < source.length && !source[lineEnd].isNewLine()) {
            lineEnd++;
        }
        string line = source[lineStart .. lineEnd].stripRight();
        return new immutable ErrorInformation(this.msg, offender, line, lineNumber, _start - lineStart, _end - lineStart);
    }

    private static size_t findLine(string source, size_t index) {
        size_t line = 0;
        for (size_t i = 0; i < index; i++) {
            if (source[i].isNewLine()) {
                consumeNewLine(source, i);
                if (i < index) {
                    line++;
                }
            }
        }
        return line;
    }

    private static void consumeNewLine(string source, ref size_t i) {
        if (source[i] == '\n') {
            // LF
            i++;
        } else if (source[i] == '\r') {
            // CR
            i++;
            if (i < source.length && source[i] == '\n') {
                // CR LF
                i++;
            }
        }
    }

    public immutable struct ErrorInformation {
        public string message;
        public string offender;
        public bool knownSource;
        public string line;
        public size_t lineNumber;
        public size_t startIndex;
        public size_t endIndex;

        public this(string message, string offender) {
            this.message = message;
            this.offender = offender;
            knownSource = false;
        }

        public this(string message, string offender, string line, size_t lineNumber, size_t startIndex, size_t endIndex) {
            this.message = message;
            this.offender = offender;
            knownSource = true;
            this.line = line;
            this.lineNumber = lineNumber;
            this.startIndex = startIndex;
            this.endIndex = endIndex;
        }

        public string toString() {
            // Create a mutable string
            char[] buffer = [];
            buffer.reserve(256);
            // Begin with the error message
            buffer ~= "Error: \"" ~ message ~ '"';
            // Add the offender if known
            if (offender != null) {
                buffer ~= " caused by '" ~ offender ~ '\'';
            }
            // If the source is unknown mention it and stop here
            if (!knownSource) {
                buffer ~= " of unknown source";
                return buffer.idup;
            }
            // Othwerise add the line number and index in that line
            buffer ~= " at line: " ~ lineNumber.to!string ~ ", index: " ~ startIndex.to!string;
            // Also add the end index if more than one character is involved
            if (startIndex != endIndex) {
                buffer ~= " to " ~ endIndex.to!string;
            }
            // Now append the actual line source
            buffer ~= " in \n" ~ line ~ '\n';
            // We'll underline the problem area, so first pad to the start index
            foreach (i; 0 .. startIndex) {
                char pad;
                if (i < line.length) {
                    // Use a tab if the source does so to ensure correct alignment
                    pad = line[i] == '\t' ? '\t' : ' ';
                } else {
                    pad = ' ';
                }
                buffer ~= pad;
            }
            // Now underline, using a circumflex for a single character or tildes for many
            if (startIndex == endIndex) {
                buffer ~= '^';
            } else {
                for (size_t i = startIndex; i <= endIndex; i++) {
                    buffer ~= '~';
                }
            }
            // Finally return an immutable duplicate of the buffer (a proper string)
            return buffer.idup;
        }
    }
}
