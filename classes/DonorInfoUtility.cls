/**
* Author: Nineta Martinov - 501Commons -2014
* Utility class used to set primary donor, batchable and schedulable
*/
global class DonorInfoUtility implements Database.Batchable<sObject>, Schedulable {
	private static String query = 'select id, Primary_Donor__c, Donor_Steward_Email__c from Opportunity';
	
	public static void setPrimaryDonor(Map<Id, Opportunity> newOpps) {
		List<Id> contactIds = new List<Id>();	
		List<OpportunityContactRole> contacts = [select ContactId, OpportunityId 
													from OpportunityContactRole 
													where OpportunityId in :newOpps.keySet() and IsPrimary = True];																	 
		for (OpportunityContactRole ocr : contacts) {
			contactIds.add(ocr.ContactId);			
		}	
		
		Map<Id, String> boardMemberNames = new Map<Id, String>();
		for (Contact donor : [select id, Donor_Steward__c from Contact where id in:contactIds]){
			boardMemberNames.put(donor.Id, donor.Donor_Steward__c);
		}
		System.debug('DEBUG >>> board members names '+boardMemberNames);
		List<Contact> boardmembers = [select id, email, name from Contact 
										where name in :boardMemberNames.values() and 
											ConstituentType__c includes ('Board Member')];
		Map<String, String> bmEmailMap = new Map<String,String>();
		for (Contact c : boardmembers) {
			bmEmailMap.put(c.name, c.email);
		}
		System.debug('DEBUG >>> board emails '+bmEmailMap);
		List<Opportunity> oppsToUpdate = new List<Opportunity>();
		for (OpportunityContactRole ocr : contacts) {			
			Opportunity o = newOpps.get(ocr.OpportunityId);
			String boardName = boardMemberNames.get(ocr.ContactId);
			if (o.Donor_Steward_Email__c <>  bmEmailMap.get(boardName) || o.Primary_Donor__c <> ocr.ContactId) {
				o.Donor_Steward_Email__c = bmEmailMap.get(boardName); //get the email				
				o.Primary_Donor__c = ocr.ContactId;			
				oppsToUpdate.add(o);
			}	
		}
		update oppsToUpdate;									   
	}
	
	webservice static void setPrimaryDonor(Id oppId) {
		Map<Id,Opportunity> opp = new Map<Id,Opportunity>([select id, Primary_Donor__c, Donor_Steward_Email__c 
										from Opportunity where id=:oppId]);
		setPrimaryDonor(opp);
	}
	
	webservice static void setPrimaryDonors() {
		DonorInfoUtility b = new DonorInfoUtility();
		Database.executeBatch(b);
	}
	
	global void execute(SchedulableContext sc){
    	DonorInfoUtility batch = new DonorInfoUtility();
      	Database.executeBatch(batch);
  	}
  	
  	global database.Querylocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query);		 
	}
	
	global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
		Map<Id, Opportunity> newOpps = new Map<Id, Opportunity>();			
 		for (Opportunity o : scope) {
 			newOpps.put(o.Id, o);
 		} 	 
 		setPrimaryDonor(newOpps);					
	}

	global void finish(Database.BatchableContext bc) {
	}
}