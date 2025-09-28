public with sharing class F1DataService {
    
    // Endpoint: Named Credential called "F1_API" pointing to https://ergast.com/api/f1/
    private static final String NAMED_CREDENTIAL = 'callout:F1_API';

    // Fetch driver list for a season
    @AuraEnabled
    public static void fetchDrivers(String season) {
        String url = NAMED_CREDENTIAL + '/' + season + '/drivers.json';
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        
        try {
            HttpResponse res = http.send(req);
            if (res.getStatusCode() == 200) {
                F1DriverResponse parsed = (F1DriverResponse) JSON.deserialize(res.getBody(), F1DriverResponse.class);
                upsertDrivers(parsed.MRData.DriverTable.Drivers);
            } else {
                //logError('Driver fetch failed: ' + res.getStatusCode() + ' ' + res.getBody());
            }
        } catch (Exception e) {
            //logError('Exception during driver fetch: ' + e.getMessage());
        }
    }

	private static void upsertDrivers(List<Driver> drivers) {
        List<Driver__c> toUpsert = new List<Driver__c>();
		for (Driver d : drivers) {
            Driver__c dr = new Driver__c();
            dr.External_ID__c = d.driverId; // assume you created an ExternalId__c field
            dr.First_Name__c = d.givenName;
            dr.Last_Name__c = d.familyName;
            dr.Date_of_Birth__c = Date.valueOf(d.dateOfBirth);
            dr.Nationality__c = d.nationality;
            toUpsert.add(dr);
        }
        if (!toUpsert.isEmpty()) {
            upsert toUpsert Driver__c.External_ID__c;
        }
    }

    /*private static void logError(String msg) {
        insert new Integration_Log__c(
            Source__c = 'F1DataService',
            Message__c = msg,
            Status__c = 'Error'
        );
    }*/

    // Wrapper for JSON
    public class F1DriverResponse {
        public MRData MRData;
        
    }

    public class MRData {
        public DriverTable DriverTable;
    }

    public class DriverTable {
        public List<Driver> Drivers;
    }

    public class Driver {
        public String driverId;
        public String givenName;
        public String familyName;
        public String dateOfBirth;
        public String nationality;
    }
}
