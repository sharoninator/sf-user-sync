
// Test HTTP callout
HttpRequest req = new HttpRequest();
req.setEndpoint('http://localhost:3000/health');
req.setMethod('GET');
req.setTimeout(10000);

try {
    Http http = new Http();
    HttpResponse res = http.send(req);
    System.debug('Status Code: ' + res.getStatusCode());
    System.debug('Response: ' + res.getBody());
} catch (Exception e) {
    System.debug('Error: ' + e.getMessage());
}

