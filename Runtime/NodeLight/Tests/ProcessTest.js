(function() {
    try {
        if (!(typeof process.nextTick === "function"))
            throw new Error("process.nextTick not an function: " + typeof process.nextTick);
        if (!(typeof process.cwd === "function"))
            throw new Error("process.cwd not an function: " + typeof process.cwd);
        if (!(typeof process.cwd() === "string"))
            throw new Error("process.cwd() not a string: " + typeof process.cwd());
        if (!(typeof process.exit === "function"))
            throw new Error("process.exit not an function: " + typeof process.exit);
    }
    catch (e) {
        return e;
    }
})();
