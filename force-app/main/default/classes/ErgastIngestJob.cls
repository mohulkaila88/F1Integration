public class ErgastIngestJob implements Queueable, Database.AllowsCallouts {
    private Integer season;
    private Integer startOffset;
    private Integer pageSize;

    public ErgastIngestJob(Integer season, Integer startOffset, Integer pageSize) {
        this.season = season;
        this.startOffset = startOffset;
        this.pageSize = pageSize == null ? 100 : Math.min(100, pageSize);
    }
    public ErgastIngestJob(Integer season) {
        this(season, 0, 100);
    }

    public void execute(QueueableContext qc) {
        Integer offset = startOffset;
        Integer total = 0;
        Integer processed = 0;

        do {
            HttpRequest req = new HttpRequest();
            // Named Credential base: https://api.jolpi.ca/ergast/f1
            req.setEndpoint('callout:Ergast/' + season + '/results.json?limit=' + pageSize + '&offset=' + offset);
            req.setMethod('GET');

            Http http = new Http();
            HttpResponse res = http.send(req);
            if (res.getStatusCode() != 200) {
                System.debug('Ergast call failed: ' + res.getStatus() + ' body=' + res.getBody());
                break;
            }

            System.Debug('+++Ergast call succeeded: ' + res.getBody());

            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, Object> mr = (Map<String, Object>) root.get('MRData');
            total = Integer.valueOf((String) mr.get('total'));
            Map<String, Object> raceTable = (Map<String, Object>) mr.get('RaceTable');
            List<Object> races = (List<Object>) raceTable.get('Races');

            // Staging lists
            List<Circuit__c> circuitsToUpsert = new List<Circuit__c>();
            List<Driver__c> driversToUpsert   = new List<Driver__c>();
            List<Team__c> teamsToUpsert       = new List<Team__c>();
            List<Race__c> racesToUpsert       = new List<Race__c>();
            List<Race_Result__c> resultsToUpsert = new List<Race_Result__c>();

            for (Object rObj : races) {
                Map<String, Object> r = (Map<String, Object>) rObj;

                // --- Circuit
                Map<String, Object> circuit = (Map<String, Object>) r.get('Circuit');
                Map<String, Object> loc = (Map<String, Object>) circuit.get('Location');
                String circuitId = (String) circuit.get('circuitId');

                /*circuitsToUpsert.add(new Circuit__c(
                    External_Circuit_Id__c = circuitId,
                    Circuit_Name__c        = (String) circuit.get('circuitName'),
                    Country__c             = (String) (loc != null ? loc.get('country') : null),
                    Locality__c            = (String) (loc != null ? loc.get('locality') : null),
                    Latitude__c            = toDecimal(loc, 'lat'),
                    Longitude__c           = toDecimal(loc, 'long'),
                    Url__c                 = (String) circuit.get('url')
                ));*/

                // --- Race
                String roundStr = (String) r.get('round');
                Integer roundNum = roundStr == null ? null : Integer.valueOf(roundStr);
                String raceKey = season + '-' + roundStr; // External_Race_Key__c

                /*racesToUpsert.add(new Race__c(
                    External_Race_Key__c = raceKey,
                    Season__c            = season,
                    Round__c             = roundNum,
                    Grand_Prix_Name__c   = (String) r.get('raceName'),
                    Date__c              = toDate(r, 'date'),
                    Time_UTC__c          = (String) r.get('time'),
                    Url__c               = (String) r.get('url'),
                    Circuit__r           = new Circuit__c(External_Circuit_Id__c = circuitId)
                ));*/

                // --- Results per race
                List<Object> results = (List<Object>) r.get('Results');
                if (results != null) {
                    for (Object rrObj : results) {
                        Map<String, Object> rr = (Map<String, Object>) rrObj;

                        // Driver
                        Map<String, Object> driver = (Map<String, Object>) rr.get('Driver');
                        String driverId = (String) driver.get('driverId');
                        /*driversToUpsert.add(new Driver__c(
                            External_Driver_Id__c = driverId,
                            First_Name__c         = (String) driver.get('givenName'),
                            Last_Name__c          = (String) driver.get('familyName'),
                            Code__c               = (String) driver.get('code'),
                            Permanent_Number__c   = toInteger(driver, 'permanentNumber'),
                            Date_Of_Birth__c      = toDate(driver, 'dateOfBirth'),
                            Nationality__c        = (String) driver.get('nationality'),
                            Url__c                = (String) driver.get('url')
                        ));*/

                        // Team (Constructor)
                        Map<String, Object> cons = (Map<String, Object>) rr.get('Constructor');
                        String consId = (String) cons.get('constructorId');
                       /* teamsToUpsert.add(new Team__c(
                            External_Team_Id__c = consId,
                            Team_Name__c        = (String) cons.get('name'),
                            Nationality__c      = (String) cons.get('nationality'),
                            Url__c              = (String) cons.get('url')
                        ));*/

                        // Times / Fastest Lap (optional)
                        Map<String, Object> t = (Map<String, Object>) rr.get('Time');
                        Map<String, Object> fl = (Map<String, Object>) rr.get('FastestLap');
                        Map<String, Object> flTime = fl == null ? null : (Map<String, Object>) fl.get('Time');
                        Map<String, Object> flSpeed = fl == null ? null : (Map<String, Object>) fl.get('AverageSpeed');

                        String resultKey = season + '-' + roundStr + '-' + driverId;

                        /*Race_Result__c resRec = new Race_Result__c(
                            External_Result_Key__c = resultKey,
                            Race__r    = new Race__c(External_Race_Key__c = raceKey),
                            Driver__r  = new Driver__c(External_Driver_Id__c = driverId),
                            Team__r    = new Team__c(External_Team_Id__c = consId),
                            Grid_Position__c       = toInteger(rr, 'grid'),
                            Finish_Position__c     = toInteger(rr, 'position'),
                            Position_Text__c       = (String) rr.get('positionText'),
                            Points__c              = toDecimal(rr, 'points'),
                            Laps__c                = toInteger(rr, 'laps'),
                            Status__c              = (String) rr.get('status'),
                            Finish_Time_Text__c    = t == null ? null : (String) t.get('time'),
                            Finish_Time_Millis__c  = t == null ? null : toInteger(t, 'millis'),
                            Fastest_Lap_Number__c  = fl == null ? null : toInteger(fl, 'lap'),
                            Fastest_Lap_Rank__c    = fl == null ? null : toInteger(fl, 'rank'),
                            Fastest_Lap_Time__c    = flTime == null ? null : (String) flTime.get('time'),
                            Avg_Speed__c           = flSpeed == null ? null : toDecimal(flSpeed, 'speed'),
                            Avg_Speed_Units__c     = flSpeed == null ? null : (String) flSpeed.get('units')
                        );
                        resultsToUpsert.add(resRec);*/
                    }
                }
            }

            // DML in batches (External ID upsert; lookups by external id via relationship SObjects)
            /*if (!circuitsToUpsert.isEmpty()) upsert circuitsToUpsert Circuit__c.External_Circuit_Id__c;
            if (!driversToUpsert.isEmpty())  upsert driversToUpsert  Driver__c.External_Driver_Id__c;
            if (!teamsToUpsert.isEmpty())    upsert teamsToUpsert    Team__c.External_Team_Id__c;
            if (!racesToUpsert.isEmpty())    upsert racesToUpsert    Race__c.External_Race_Key__c;
            if (!resultsToUpsert.isEmpty())  upsert resultsToUpsert  Race_Result__c.External_Result_Key__c;*/

            Integer pageCount = races == null ? 0 : races.size();
            processed += pageCount;
            offset += pageSize;

            // Stop if we've loaded all races (results come nested under each race)
        } while (processed < total && processed > 0);

        // If you ever need to chain (e.g., to split huge seasons), you could:
        // System.enqueueJob(new ErgastIngestJob(season, offset, pageSize));
    }

    // ---- helpers
    private static Integer toInteger(Map<String, Object> m, String key) {
        Object v = m == null ? null : m.get(key);
        if (v == null) return null;
        String s = String.valueOf(v);
        return s == null || s.trim() == '' ? null : Integer.valueOf(s);
    }
    private static Decimal toDecimal(Map<String, Object> m, String key) {
        Object v = m == null ? null : m.get(key);
        if (v == null) return null;
        String s = String.valueOf(v);
        return s == null || s.trim() == '' ? null : Decimal.valueOf(s);
    }
    private static Date toDate(Map<String, Object> m, String key) {
        Object v = m == null ? null : m.get(key);
        if (v == null) return null;
        String s = String.valueOf(v);
        return Date.valueOf(s); // expects YYYY-MM-DD (Ergast format)
    }
}
