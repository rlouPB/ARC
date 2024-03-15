@isTest 
public with sharing class BHS_QueuedRequestMock implements HttpCalloutMock {
    protected Integer code;
    protected String status;
    protected String bodyAsString;
    protected Blob bodyAsBlob;
    protected String observationId;
    protected Map<String, String> responseHeaders;
    static List<String> staticResourceQueue = new List<String>();
    public static void setStaticResourceQueue(List<String> resources) {
        staticResourceQueue = resources;
    }
    public BHS_QueuedRequestMock(Integer code, String status, String observationId,
                                         Map<String, String> responseHeaders) {
        this.code = code;
        this.status = status;
        this.observationId = observationId;
        this.responseHeaders = responseHeaders;

       
    }

    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse resp = new HttpResponse();
        resp.setStatusCode(code);
        resp.setStatus(status);
        String resourceName = 'BHS_MockEmptyQueue';
        if(staticResourceQueue.size() > 0 ) {
            resourceName = staticResourceQueue.remove(0);  
        } 
        StaticResource sr= [select id,body from StaticResource Where Name = :resourceName];
        String payload = sr.body.toString();
        payload = payload.replace('{{observationId}}', observationId);
        
        resp.setBody(payload);

        if (responseHeaders != null) {
             for (String key : responseHeaders.keySet()) {
            resp.setHeader(key, responseHeaders.get(key));
             }
        }
        return resp;
    }

}