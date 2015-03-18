/**
* Author: Patrick Tewson - NPower NW - 2012
* Utility class used by Donor Classification rollups and HHDonorClassificationRollups trigger.
* This attempts to realize the behavior for donor classification described in the BFB Donor
* The general contract I'm attempting to adhere to is that the new donor
* class depends only on the donation history of the contact, NOT the previous 
* donor state. This will make the whole system more reliable and mean that calling
* this class on all the contacts can set the correct donor class independent of 
* initial conditions.
* Stewardship plan, original date July 18, 2012
*/

public without sharing class HHDonorClassificationRollups {          
	
	public static void rollupAllContacts() {
		rollupAllContacts (true, false, null);
	}  
		
	public static void rollupAllContacts(boolean currentDonorClass, boolean customDonorClass, Date customDate) {		
		Integer batchSize = 200;
        BATCH_DonorClassRollups batch = new BATCH_DonorClassRollups
	     		('select id, Always_classify_as_Major_Donor__c, Donor_Classification__c from npo02__Household__c',
	     			currentDonorClass, customDonorClass, customDate);

        id batchProcessId = database.executeBatch(batch, batchSize);  
	}
	
	public static void rollupDonorClass(Set<id> newOppIds) {				
    	List<Contact> contacts = [SELECT id, npo02__household__r.id from Contact where id in 
									(select ContactId from OpportunityContactRole where OpportunityId =: newOppIds 
									 and IsPrimary = True)];        
        List<Id> hhids = new List<Id>();
        for(Contact c: contacts) hhids.add(c.npo02__household__r.id);
        List<npo02__Household__c> households = [SELECT id, Always_classify_as_Major_Donor__c, Donor_Classification__c 
        											from npo02__Household__c where id =: hhids];                
        rollupDonorClass(households);        
	}			
			
	public static void rollupDonorClass(List<npo02__Household__c> households) {
       rollupDonorClass(households, true, false, null, null);
	}
	
	/*
	* rolls up donor classification with users selected parameters.
	*/
	public static void rollupDonorClass(List<npo02__Household__c> households, boolean currentDonorClass, 
											boolean customDonorClass, Date customDate, Datetime batchJobRun) {
		
		Map<Id, npo02__Household__c> hhMap = new Map<Id,npo02__Household__c>();
        for(npo02__Household__c hh: households) {
           hhMap.put(hh.id, hh);
        }

        // get all the contacts attached to any of the households
        Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT id, npo02__Household__c from Contact where npo02__Household__c =: hhMap.keySet()]);            

        // get all the opportunitycontactroles related to these contacts
        List<OpportunityContactRole> ocrs = 
            [SELECT OpportunityId, ContactId from OpportunityContactRole where ContactId =: contactMap.keySet() and IsPrimary = True];            

        List<Id> oids = new List<Id>();
        for(OpportunityContactRole ocr: ocrs) {
            oids.add(ocr.OpportunityId);               
        }

        // get all the opportunities attached to the above OCRS
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([SELECT o.id, o.AccountID, a.Name, o.CloseDate, 
            													o.RecordTypeId, o.Amount from Opportunity o, o.Account a 
            													where StageName =: 'Closed Won' and id =: oids order by o.CloseDate asc]);            

        // now we must attach donations to household
        Map<id,List<Opportunity>> householdsAndDonations = new Map<Id,List<Opportunity>>();
        for (npo02__Household__c hh : households) {
        	householdsAndDonations.put(hh.Id, new List<Opportunity>());
        }
        //now put the opportunities with the right household
        for(OpportunityContactRole ocr: ocrs) {
            Id hhid = contactMap.get(ocr.ContactId).npo02__Household__c;
            if(!householdsAndDonations.containsKey(hhid)) {
                householdsAndDonations.put(hhid, new List<Opportunity>());
            }
            Opportunity opp = oppMap.get( ocr.OpportunityId );
            if(opp != null) householdsAndDonations.get(hhid).add( opp );
        }
        
        //calculate only current donor classification
        if (currentDonorClass && !customDonorClass) {
        	DonorClassificationUtility.rollupDonorClass(hhMap, householdsAndDonations, null, batchJobRun, true);
        //calculate both current and custom donor classification	
        } else if (currentDonorClass && customDonorClass) {
        	DonorClassificationUtility.rollupDonorClass(hhMap, householdsAndDonations, customDate, batchJobRun, true);	
        //calculate only custom donor classification	
        } else if (!currentDonorClass && customDonorClass) {
        	DonorClassificationUtility.rollupDonorClass(hhMap, householdsAndDonations, customDate, batchJobRun, false);
        }	
		
	}	
					
}