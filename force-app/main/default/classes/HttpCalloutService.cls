public with sharing class HttpCalloutService {
    
    // Production: Railway deployment URL
    private static final String MIDDLEWARE_BASE_URL = 'https://middleware-production-229f.up.railway.app';
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
        
        // Convert userData to JSON payload wrapped in users object
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('users', userData);
        String jsonPayload = JSON.serialize(payload);
        request.setBody(jsonPayload);
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        // POC: Simple logging instead of throwing errors
        System.debug('Sent ' + userData.size() + ' users to MySQL. Status: ' + response.getStatusCode());
    }
    
    public static List<ExternalUserService.ExternalUserData> fetchUsersFromExternalSystem(String cursor) {
        HttpRequest request = new HttpRequest();
        String endpoint = MIDDLEWARE_BASE_URL + '/users/changes-since/';
        if (String.isNotBlank(cursor)) {
            endpoint += EncodingUtil.urlEncode(cursor, 'UTF-8');
        } else {
            // Default to 1 hour ago if no cursor
            DateTime oneHourAgo = DateTime.now().addHours(-1);
            endpoint += EncodingUtil.urlEncode(oneHourAgo.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''), 'UTF-8');
        }
        
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('Accept', 'application/json');
        request.setTimeout(TIMEOUT_SECONDS * 1000);
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        // POC: Return empty list if middleware not running
        if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
            String responseBody = response.getBody();
            System.debug('Inbound sync response: ' + responseBody);
            
            // Parse the wrapper response object
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            
            if (responseData.containsKey('users')) {
                String usersJson = JSON.serialize(responseData.get('users'));
                List<ExternalUserService.ExternalUserData> userData = 
                    (List<ExternalUserService.ExternalUserData>) JSON.deserialize(
                        usersJson, 
                        List<ExternalUserService.ExternalUserData>.class
                    );
                System.debug('Parsed ' + userData.size() + ' users from middleware');
                return userData;
            } else {
                System.debug('No users key found in response');
                return new List<ExternalUserService.ExternalUserData>();
            }
        } else {
            System.debug('Middleware not available. Status: ' + response.getStatusCode() + ', Body: ' + response.getBody());
            return new List<ExternalUserService.ExternalUserData>();
        }
    }
}