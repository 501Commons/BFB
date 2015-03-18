/**
* Author: Nineta Martinov - 501Commons -2014
* Utility class used by DonorClassificationOpportuntyRollup trigger and batch job.
* This attempts to realize the behavior for donor classification described in the BFB Donor
* Stewardship plan, original date July 18, 2012
*/
public without sharing class OrgDonorClassificationRollups {
	
	public static Id oppInKindRecType = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('In-Kind').getRecordTypeId();
	
	public static void rollupAllOrganizations() {
		rollupAllOrganizations(true, false, null);
	}
			
	/*
	* Roll up opp data for all orgs, batch mode. Exclude the individual account.
	*/
	public static void rollupAllOrganizations(boolean currentDonorClass, boolean customDonorClass, Date customDate) {		
		Integer batchSize = 200;
        BATCH_DonorClassRollups batch = new BATCH_DonorClassRollups
        					('select id, Always_classify_as_Major_Donor__c, Donor_Classification__c, Previous_Donor_Classification__c,'+  
        					 'Donor_Classification_Transition_Date__c from Account where name <> \'Individual\'',
        					 currentDonorClass, customDonorClass, customDate);
        id batchProcessId = database.executeBatch(batch, batchSize);  
	}	
	
	/*
	* For a given set of new opportunities roll up the org donor classification, exclude the Individual account
	*/
	/*public static void rollupDonorClass(Set<id> newOppIds) {		
		Map<Id, Account> accounts = new Map<Id, Account>([SELECT id, Donor_Classification__c, Previous_Donor_Classification__c,
															  Donor_Classification_Transition_Date__c, Always_classify_as_Major_Donor__c 
															  from Account where name <> 'Individual' and id in 
															 (select AccountId from Opportunity where id in :newOppIds)]);																		 	     
        rollupDonorClass(accounts);        
	}*/
	
	/*
	* For a given set of new opportunities roll up the org donor classification, exclude the Individual account
	*/
	public static void rollupDonorClass(List<Opportunity> opps) {
		Set<Id> accsToSelect = new Set<Id>();		
		for (Opportunity opp : opps) {
			if (opp.AccountId != null)
				accsToSelect.add(opp.AccountId);
		}		
		if (accsToSelect.size() > 0) {
			Map<Id, Account> accounts = new Map<Id, Account>([SELECT id, Donor_Classification__c, Previous_Donor_Classification__c,
																  Donor_Classification_Transition_Date__c, Always_classify_as_Major_Donor__c 
																  from Account where name <> 'Individual' and id in :accsToSelect]);																		 	     
	        rollupDonorClass(accounts); 
		}       
	}
	
	public static void rollupDonorClass(List<Account> accounts) {
		rollupDonorClass(accounts, true, false, null, null);
	}
			
	public static void rollupDonorClass(List<Account> accounts, boolean currentDonorClass, 
											boolean customDonorClass, Date customDate, Datetime batchJobRun) {
		Map<Id, Account> accountsMap = new Map<Id, Account>(); 
		for (Account a : accounts) {
			accountsMap.put(a.id, a);
		}		
		rollupDonorClass(accountsMap, currentDonorClass, customDonorClass, customDate, batchJobRun);
	}	
	
	public static void rollupDonorClass(Map<Id, Account> accounts) {
		rollupDonorClass(accounts, true, false, null, null);
	}
	
	/*
	* Rolls up donor classification for a list of accounts
	*/
	public static void rollupDonorClass(Map<Id, Account> accounts, boolean currentDonorClass, 
											boolean customDonorClass, Date customDate, Datetime batchJobRun) {                                              
        //get all the opportunities attached to the above accounts
        //create map of <Account, List of Opps>
        Map<Id, List<Opportunity>> acctToOpps = new Map<Id, List<Opportunity>>();
        for (Id accId : accounts.keySet()) {
        	acctToOpps.put(accId, new List<Opportunity>());
        }
        //now put the opportunities with the right account
        for (Opportunity opp : [select Id, AccountID, Name, CloseDate, RecordTypeId, Amount 
            								  from Opportunity
            								  where StageName='Closed Won' and AccountID in :accounts.keySet() and
            								  RecordTypeId != :oppInKindRecType order by CloseDate asc]) {
			if (acctToOpps.get(opp.AccountId)==null){
				acctToOpps.put(opp.AccountId, new List<Opportunity>());
			}                								  	
			acctToOpps.get(opp.AccountId).add(opp);         		    												  	
        }       
        //calculate only current donor classification
        if (currentDonorClass && !customDonorClass){
        	DonorClassificationUtility.rollupDonorClass(accounts, acctToOpps, null, batchJobRun, true);
        //calculate both current and custom donor classification	
        } else if (currentDonorClass && customDonorClass) {
        	DonorClassificationUtility.rollupDonorClass(accounts, acctToOpps, customDate, batchJobRun, true);
        //calculate only custom donor classification		
        } else if (!currentDonorClass && customDonorClass) {
        	DonorClassificationUtility.rollupDonorClass(accounts, acctToOpps, customDate, batchJobRun, false);
        }	
	}
			
}