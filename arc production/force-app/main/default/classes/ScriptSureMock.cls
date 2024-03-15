global class ScriptSureMock implements System.HttpCalloutMock {
    global ScriptSureMock() {

    }
    global System.HttpResponse respond(System.HttpRequest req) {
        HttpResponse resp = new HttpResponse();
        resp.setBody('{"Status":"OK", "StatusCode":"200"}');
        return resp;
    }
}