
// Test the new public URL from Salesforce
HttpRequest req = new HttpRequest();
req.setEndpoint('https://common-things-win.loca.lt/health');
req.setMethod('GET');
req.setTimeout(10000);

try {
    Http http = new Http();
    HttpResponse res = http.send(req);
    System.debug('SUCCESS! Status Code: ' + res.getStatusCode());
    System.debug('Response: ' + res.getBody());
    
    if (res.getStatusCode() == 200) {
        System.debug('🎉 SALESFORCE CAN NOW REACH THE MIDDLEWARE!');
    }
} catch (Exception e) {
    System.debug('Error: ' + e.getMessage());
}

