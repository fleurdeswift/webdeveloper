(function() {
    try {
        var buffer = require("buffer");
        
        if (!(typeof buffer.INSPECT_MAX_BYTES === "number"))
            throw new Error("buffer.INSPECT_MAX_BYTES not a number: " + (typeof buffer.INSPECT_MAX_BYTES));
        if (!(typeof buffer.kMaxLength === "number"))
            throw new Error("buffer.kMaxLength not a number: " + (typeof buffer.kMaxLength));
        if (!(typeof buffer.Buffer === "object"))
            throw new Error("buffer.Buffer not an object: " + typeof buffer.Buffer);
        if (!(typeof buffer.SlowBuffer === "object"))
            throw new Error("buffer.SlowBuffer not an object: " + typeof buffer.SlowBuffer);
        if (!expectException(function() { new buffer.Buffer(); }))
            throw new Error("Expected an exception to be thrown by passing no arguments to Buffer()");
 
        var b = new buffer.Buffer("testé", "utf8");
        if (b.length != 6)
            throw new Error("Expected 6 bytes buffer");
    }
    catch (e) {
        return e;
    }
})();
