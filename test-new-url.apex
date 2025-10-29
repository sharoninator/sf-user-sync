
// Test the NEW public URL from Salesforce
HttpRequest req = new HttpRequest();
req.setEndpoint('https://bumpy-feet-greet.loca.lt/health');
req.setMethod('GET');
req.setTimeout(10000);

try {
    Http http = new Http();
    HttpResponse res = http.send(req);
    System.debug('Status Code: ' + res.getStatusCode());
    System.debug('Response: ' + res.getBody());
    
    if (res.getStatusCode() == 200) {
        System.debug('🎉 SUCCESS! SALESFORCE IS NOW CONNECTED TO MYSQL!');
    }
} catch (Exception e) {
    System.debug('Error: ' + e.getMessage());
}

