@isTest
public with sharing class BHS_SingleRequestMock implements HttpCalloutMock {
    protected Integer code;
    protected String status;
    protected String bodyAsString;
    protected Blob bodyAsBlob;
    protected Map<String, String> responseHeaders;
    Protected String staticResourceName;
    public void setStaticResourceName(String name) {
        staticResourceName = name;
    }
    
    public BHS_SingleRequestMock(Integer code, String status, String staticResourceName,
                                         Map<String, String> responseHeaders) {
        this.code = code;
        this.status = status;
        this.responseHeaders = responseHeaders;
        this.staticResourceName = staticResourceName;
    }

    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse resp = new HttpResponse();
        resp.setStatusCode(code);
        resp.setStatus(status);
        StaticResource sr= [select id,body from StaticResource Where Name = :staticResourceName];
        resp.setBody(sr.body.toString());

        if (responseHeaders != null) {
             for (String key : responseHeaders.keySet()) {
            resp.setHeader(key, responseHeaders.get(key));
             }
        }
        return resp;
    }

}