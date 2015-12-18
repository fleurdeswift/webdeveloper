(function(exports) {
    "use strict";

    var process = {
        "platform": "darwin",
        "stdout": null,
        "stderr": null,
        "argv": [],
        "version": "5.2.0",
        "versions": {
            "node": "5.2.0"
        },
        "release": {
            "name": "node",
            "sourceUrl": null,
            "headersUrl": null
        },
        "nextTick": null,
        "cwd": null
    };
 
    var modules = {
        "buffer": {
            "INSPECT_MAX_BYTES": 50,
            "kMaxLength": 2147483647
        },
        "os": {
            "platform": function() { return process.platform; }
        },
        "fs": {
        },
    };

    function require(name) {
        return modules[name];
    }

    function registerModule(name, method) {
        var module = {
            "exports": {}
        };
 
        method(module);
        modules[name] = module.exports;
    }
 
    exports.require = require;
    exports.registerModule = registerModule;
    exports.process = process;
})(this);
