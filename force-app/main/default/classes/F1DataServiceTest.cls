@IsTest
private class F1DataServiceTest {
    @IsTest
    static void testFetchDrivers() {
        Test.setMock(HttpCalloutMock.class, new MockF1DriverResponse());

        Test.startTest();
        F1DataService.fetchDrivers('2023');
        Test.stopTest();

        // Assert that at least one driver got inserted
        List<Driver__c> drivers = [SELECT Id, FirstName__c, LastName__c FROM Driver__c];
        System.assert(!drivers.isEmpty(), 'Drivers should be inserted');
    }

    private class MockF1DriverResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"MRData":{"DriverTable":{"Drivers":[{"driverId":"hamilton","givenName":"Lewis","familyName":"Hamilton","dateOfBirth":"1985-01-07","nationality":"British"}]}}}');
            return res;
        }
    }
}
