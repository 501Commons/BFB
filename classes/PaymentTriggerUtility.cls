/**
* Author: Nineta Martinov - NPower NW - 2012
* Utility class used by PaymentBefore trigger.
*/
public with sharing class PaymentTriggerUtility {
	public static void updatePayment(List<npe01__OppPayment__c> payments) {
		//get the opportunity ids
		List<Id> oppsIds = new List<Id>();
		for (npe01__OppPayment__c p : payments){
			oppsIds.add(p.npe01__Opportunity__c);
		}
		//get opportunities
		List<Opportunity> opps = [select id, Payment_Method__c, Check_Reference_Number__c 
									from Opportunity where id in :oppsIds];
		
		//match opps with payments							
		Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
		for (Opportunity opp : opps) {
			oppMap.put(opp.id, opp);
		}							
		
		//update payment
		for (npe01__OppPayment__c p : payments){
			p.npe01__Payment_Method__c = oppMap.get(p.npe01__Opportunity__c).Payment_Method__c;
			p.npe01__Check_Reference_Number__c = oppMap.get(p.npe01__Opportunity__c).Check_Reference_Number__c;
		}								
	}
}