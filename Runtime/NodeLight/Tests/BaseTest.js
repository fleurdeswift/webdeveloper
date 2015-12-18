function expectException(func) {
    try {
        func();
        return false;
    }
    catch (e) {
        return true;
    }
}
