trigger DonorClassificationOpportunityRollup on Opportunity (after delete, after insert, after update, before delete) {
		
	if(trigger.isInsert){
		// prevent troubles with bulk adds
		if(trigger.newMap.keySet().size() <= 10) {					
			//for npsp3 upgrade no longer using households
			//HHDonorClassificationRollups.rollupDonorClass(trigger.newMap.keySet()); 
			OrgDonorClassificationRollups.rollupDonorClass(trigger.newMap.values());
		} 
	} else if (trigger.isUpdate) {
		// prevent troubles with bulk adds
		if(trigger.newMap.keySet().size() <= 10) {		
			//check if relevant fields have changed (amount, close date, stage name)
			List<Opportunity> processOpps = new List<Opportunity>();
			//Set<Id> oppIds = new Set<Id>();
			for (Opportunity newopp : trigger.newMap.values()) {
				Opportunity oldOpp = trigger.oldMap.get(newopp.id);
				if (oldOpp.CloseDate <> newopp.CloseDate || oldOpp.Amount <> newopp.Amount ||
						oldOpp.StageName <> newopp.StageName) {
					processOpps.add(newOpp);
					//oppIds.add(newOpp.Id);
				}
			}	
			if (processOpps.size() >0) {
				//for npsp3 upgrade no longer using households		
				//HHDonorClassificationRollups.rollupDonorClass(oppIds);
				OrgDonorClassificationRollups.rollupDonorClass(processOpps);
			}
		} 
	} else if(trigger.isDelete) {
		// prevent troubles with bulk deletes
	    if(trigger.oldMap.keySet().size() <= 10) {			
			/********* for npsp3 upgrade no longer using households	*****************
			if (trigger.isBefore) {
				HHDonorClassificationRollups.rollupDonorClass(trigger.oldMap.keySet());
			}*/ 			
			if (trigger.isAfter) {		      		      	
		      	OrgDonorClassificationRollups.rollupDonorClass(trigger.oldMap.values());		      
			}
	    }
	}
}