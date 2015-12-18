(function() {
    try {
        var fs = require("fs");
        
        if (!(typeof fs.existsSync === "function"))
            throw new Error("fs.existsSync not an function: " + typeof fs.existsSync);
            
        if (fs.existsSync("doesnt exists"))
            throw new Error("fs.existsSync() is true");
            
        var ar = fs.readdirSync(".");
        if (!(ar instanceof Array))
            throw new Error("fs.readdirSync should return an array");
    }
    catch (e) {
        return e;
    }
})();
