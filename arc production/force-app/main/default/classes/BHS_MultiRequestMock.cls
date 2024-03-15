@isTest public with sharing class BHS_MultiRequestMock implements HttpCalloutMock {
    Map<String, HttpCalloutMock> requests;

    public BHS_MultiRequestMock(Map<String, HttpCalloutMock> requests) {
        this.requests = requests;
    }

    public HTTPResponse respond(HTTPRequest req) {
        HttpCalloutMock mock = requests.get(req.getEndpoint());
        if (mock != null) {
            return mock.respond(req);
        } else {
            throw new BHS_CustomException('HTTP callout not supported for test methods');
        }
    }

    public void addRequestMock(String url, HttpCalloutMock mock) {
        requests.put(url, mock);
    }

    public class BHS_CustomException extends Exception {

    }
}