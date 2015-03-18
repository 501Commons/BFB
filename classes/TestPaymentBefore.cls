/**
* Author: Nineta Martinov - NPower NW - 2012
* Test class for PaymentBefore trigger.
*/
@isTest
private class TestPaymentBefore {

    static testMethod void testInsertPayment() {
        Contact c = new Contact();
        c.LastName = 'Test';
        insert c;
        
        Id acc = [select id, accountId from contact].accountId;
        
        Campaign camp = new Campaign();
        camp.name = 'Campaign Name';
        insert camp;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Opp Name';
        opp.AccountId = acc;
        opp.Amount = 100.0;
        opp.CloseDate = Date.today();
        opp.CampaignId = camp.id;
        opp.StageName = 'Closed Won';
        opp.Type = 'Individual';
        opp.Payment_Method__c = 'Cash';
        opp.Check_Reference_Number__c = '123456';
        
        insert opp;
        //check that the payment has the payment method and check ref number from opp
        npe01__OppPayment__c payment = [select npe01__Payment_Method__c, npe01__Check_Reference_Number__c 
        									from npe01__OppPayment__c];
        System.assertEquals('Cash', payment.npe01__Payment_Method__c);
        System.assertEquals('123456', payment.npe01__Check_Reference_Number__c);									
    }
}