🏎️ **Salesforce F1 Data Integration**

This project demonstrates the Remote Process Invocation (Request/Reply) integration pattern in Salesforce using an Apex callout to the Ergast F1 API.
It fetches Formula 1 drivers and upserts them into custom Salesforce objects.

📌 **Features**

1. Apex service to call an external REST API (via Named Credential).
2. JSON parsing with strongly typed wrapper classes.
3. Upsert into Salesforce custom objects (Driver__c).
4. Unit test with HttpCalloutMock.

🛠️ **Setup Instructions**
1. Create Custom Objects
You should already have these objects:
Driver__c
  External_ID__c (Text, External ID, Unique)
  First_Name__c (Text)
  Last_Name__c (Text)
  DateOfBirth__c (Date)
  Nationality__c (Text)

2. Configure Named Credential
Label: F1 API
Name: F1_API
URL: [https://ergast.com/api/f1](https://api.jolpi.ca/ergast/f1)
Identity Type: Anonymous
Authentication Protocol: No Authentication

3. Deploy Code
F1DataService.cls → Main service class for callout and upsert.
F1DataServiceTest.cls → Unit test with mock response.

4. Run It
From Execute Anonymous in Developer Console:
F1DataService.fetchDrivers('2023');
Query your Driver__c object in Salesforce → you should see new driver records.

✅ **Acceptance Criteria**
Fetching drivers inserts/updates records in Driver__c.
Errors (invalid season, bad response, exceptions) are logged in Integration_Log__c.
Test class covers the callout logic with HttpCalloutMock.

🚀 **Next Steps**
Extend service with fetchCircuits() and fetchRaces().
Add Flow invocable method so admins can run imports without Apex.
Use Continuation for long-running requests.
Publish a Platform Event after sync for downstream subscribers.

📂 **Repo Structure**
/force-app/main/default/classes
  ├── F1DataService.cls
  ├── F1DataService.cls-meta.xml
  ├── F1DataServiceTest.cls
  └── F1DataServiceTest.cls-meta.xml
/README.md


👨‍💻 Author: **Mohul Kaila**
📅 Pattern: Remote Process Invocation — Request/Reply
🔗 API: Ergast F1 Public API
