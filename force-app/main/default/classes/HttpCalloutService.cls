public with sharing class HttpCalloutService {
    
    // Production: Will be updated with Railway URL after deployment
    private static final String MIDDLEWARE_BASE_URL = 'https://YOUR-RAILWAY-APP.up.railway.app';
    private static final Integer TIMEOUT_SECONDS = 30;
    
    public static void sendUsersToExternalSystem(List<ExternalUserService.ExternalUserData> userData) {
        if (userData == null || userData.isEmpty()) {
            return;
        }
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint(MIDDLEWARE_BASE_URL + '/users/from-salesforce');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(TIMEOUT_SECONDS * 1000);
        
        // Convert userData to JSON payload
        String jsonPayload = JSON.serialize(userData);
        request.setBody(jsonPayload);
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        // POC: Simple logging instead of throwing errors
        System.debug('Sent ' + userData.size() + ' users to MySQL. Status: ' + response.getStatusCode());
    }
    
    public static List<ExternalUserService.ExternalUserData> fetchUsersFromExternalSystem(String cursor) {
        HttpRequest request = new HttpRequest();
        String endpoint = MIDDLEWARE_BASE_URL + '/users/changes-since';
        if (String.isNotBlank(cursor)) {
            endpoint += '?cursor=' + EncodingUtil.urlEncode(cursor, 'UTF-8');
        }
        
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('Accept', 'application/json');
        request.setTimeout(TIMEOUT_SECONDS * 1000);
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        // POC: Return empty list if middleware not running
        if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
            List<ExternalUserService.ExternalUserData> userData = 
                (List<ExternalUserService.ExternalUserData>) JSON.deserialize(
                    response.getBody(), 
                    List<ExternalUserService.ExternalUserData>.class
                );
            return userData;
        } else {
            System.debug('Middleware not available. Status: ' + response.getStatusCode());
            return new List<ExternalUserService.ExternalUserData>();
        }
    }
}