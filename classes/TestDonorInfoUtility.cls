@isTest
private class TestDonorInfoUtility {
	
	@isTest
	static void testSetPrimaryDonor() {			  
		   Contact c = new Contact(FirstName = 'Test', LastName = 'Testerson', Donor_Steward__c='Donor Steward');
		   insert c;
		   
		   Contact ds = new Contact(FirstName = 'Donor', LastName = 'Steward', Email='test@donor.org', 	ConstituentType__c='Board Member');
		   insert ds;		   
			
		   Program__c p = new Program__c(Name = 'Test');
		   insert p;
			
		   Campaign camp = new Campaign(Name = 'Test');
		   insert camp;   

           // Test First Year Donor
           Date today = Date.today();
           List<Opportunity> opps = new List<Opportunity>();          
           
           Opportunity opp1 = new Opportunity(Name = 'Test Donation', 
               	  									Amount = 1.00,                            	  									
													CloseDate = today.addYears(-1),													  
													Program__c = p.Id,
													CampaignId = camp.id,													  
													StageName = 'Pending',
													Payment_Method__c = 'Cash');																									  
			opps.add(opp1);			
           
           	insert(opps); 
           	//create contact roles
           	OpportunityContactRole cr1 = new OpportunityContactRole(ContactId = c.id,
           														   OpportunityId = opps.get(0).id,
																   IsPrimary = true);
		   	insert cr1;
		   	
		   	//make sure the primary donor is not set on donation
		   	List<Opportunity> opp = [select Primary_Donor__c, Donor_Steward_Email__c from Opportunity];
		   	System.assertEquals(null, opp[0].Primary_Donor__c);
		   	System.assertEquals(null, opp[0].Donor_Steward_Email__c);	
		   	DonorInfoUtility.setPrimaryDonor(opp1.Id);		
		   	opp = [select Primary_Donor__c, Donor_Steward_Email__c from Opportunity];
		   	System.assertEquals(c.Id, opp[0].Primary_Donor__c);
		   	System.assertEquals('test@donor.org', opp[0].Donor_Steward_Email__c);	
	}
	
	@isTest
	static void testSetPrimaryDonorsBatch() {		
	       npo02__Household__c hh = new npo02__Household__c(Name='Testerson Household');
           insert hh;

		   Contact c = new Contact(FirstName = 'Test', LastName = 'Testerson', npo02__Household__c=hh.id, Donor_Steward__c='Donor Steward');
		   insert c;
		   
		   Contact ds = new Contact(FirstName = 'Donor', LastName = 'Steward', Email='test@donor.org', 	ConstituentType__c='Board Member');
		   insert ds;		   
			
		   Program__c p = new Program__c(Name = 'Test');
		   insert p;
			
		   Campaign camp = new Campaign(Name = 'Test');
		   insert camp;   

           // Test First Year Donor
           Date today = Date.today();
           List<Opportunity> opps = new List<Opportunity>();          
           
           Opportunity opp1 = new Opportunity(Name = 'Test Donation', 
               	  									Amount = 1.00,                            	  									
													CloseDate = today.addYears(-1),													  
													Program__c = p.Id,
													CampaignId = camp.id,													  
													StageName = 'Pending',
													Payment_Method__c = 'Cash');
			Opportunity opp2 = new Opportunity(Name = 'Test Donation', 
               	  									Amount = 1.00,                            	  									
													CloseDate = today.addYears(-1),													  
													Program__c = p.Id,
													CampaignId = camp.id,													  
													StageName = 'Pending',
													Payment_Method__c = 'Cash');																							  
			opps.add(opp1);
			opps.add(opp2);
           
           	insert(opps); 
           	//create contact roles
           	OpportunityContactRole cr1 = new OpportunityContactRole(ContactId = c.id,
           														   OpportunityId = opps.get(0).id,
																   IsPrimary = true);
		   	insert cr1;
		   	OpportunityContactRole cr2 = new OpportunityContactRole(ContactId = c.id,
           														   OpportunityId = opps.get(1).id,
																   IsPrimary = true);
		   	insert cr2;
		   	//make sure the primary donor is not set on donation
		   	List<Opportunity> opp = [select Primary_Donor__c, Donor_Steward_Email__c from Opportunity];
		   	System.assertEquals(null, opp[0].Primary_Donor__c);
		   	System.assertEquals(null, opp[0].Donor_Steward_Email__c);
		   	System.assertEquals(null, opp[1].Primary_Donor__c);
		   	System.assertEquals(null, opp[1].Donor_Steward_Email__c);		
		   	//now call the batch job
		   	Test.startTest();
		   	DonorInfoUtility.setPrimaryDonors();		   	
		   	Test.stopTest();
		   	opp = [select Primary_Donor__c, Donor_Steward_Email__c from Opportunity];
		   	System.assertEquals(c.Id, opp[0].Primary_Donor__c);
		   	System.assertEquals('test@donor.org', opp[0].Donor_Steward_Email__c);		   	
		   	
	}
}