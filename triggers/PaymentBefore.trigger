/**
* Author: Nineta Martinov - NPower NW - 2012
* Trigger on new payment creation to update with data from opportunity
*/
trigger PaymentBefore on npe01__OppPayment__c (before insert) {
	//When adding new payment
  	if(trigger.isInsert){	
    	PaymentTriggerUtility.updatePayment(trigger.new);
  	}
}