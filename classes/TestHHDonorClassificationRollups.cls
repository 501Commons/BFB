/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class TestHHDonorClassificationRollups {	
	
	static testMethod void testPreviousYearEndClassificationMajor() {		
       npo02__Household__c hh = new npo02__Household__c(Name='Testerson Household');
       insert hh;
	   Contact c = new Contact(FirstName = 'Test', LastName = 'Testerson', npo02__Household__c=hh.id);
	   insert c;		   			
	   Program__c p = new Program__c(Name = 'Test');
	   insert p;		
	   Campaign camp = new Campaign(Name = 'Test');
	   insert camp;   
       
       Date today = Date.today();
       List<Opportunity> opps = new List<Opportunity>();          
           
       Opportunity opp1 = new Opportunity(Name = 'Test Donation', 
           	  									Amount = 1.00,                            	  									
												CloseDate = today,													  
												Program__c = p.Id,
												CampaignId = camp.id,													  
												StageName = 'Pending',
												Payment_Method__c = 'Cash');
		Opportunity opp2 = new Opportunity(Name = 'Test Donation', 
           	  									Amount = 1000000.00,                            	  									
												CloseDate = date.newInstance(today.year()-2, 12, 31),													  
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

	   	for (Opportunity o : opps) { 
       		o.StageName = 'Closed Won';
	   	}
	   	update opps; 
            
        c = [select Donor_Classification__c, Previous_Donor_Classification__c, Previous_Year_End_Classification__c,
					Donor_Classification_Transition_Date__c, Always_classify_as_Major_Donor__c 
					from Contact where id =:c.id];
        
        Test.startTest();     
		System.assertEquals('Returning Donor', c.Donor_Classification__c);
		System.assertEquals('First Time Donor; Major Donor', c.Previous_Year_End_Classification__c);		
        Test.stopTest(); 
	}
	
	static testMethod void testPreviousYearEndClassification() {		
       npo02__Household__c hh = new npo02__Household__c(Name='Testerson Household');
       insert hh;
	   Contact c = new Contact(FirstName = 'Test', LastName = 'Testerson', npo02__Household__c=hh.id);
	   insert c;		   			
	   Program__c p = new Program__c(Name = 'Test');
	   insert p;		
	   Campaign camp = new Campaign(Name = 'Test');
	   insert camp;   
       
       Date today = Date.today();
       List<Opportunity> opps = new List<Opportunity>();          
           
       Opportunity opp1 = new Opportunity(Name = 'Test Donation', 
           	  									Amount = 1.00,                            	  									
												CloseDate = today,													  
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

	   	for (Opportunity o : opps) { 
       		o.StageName = 'Closed Won';
	   	}
	   	update opps; 
            
        c = [select Donor_Classification__c, Previous_Donor_Classification__c, Previous_Year_End_Classification__c,
					Donor_Classification_Transition_Date__c, Always_classify_as_Major_Donor__c 
					from Contact where id =:c.id];
        
        Test.startTest();     
		System.assertEquals('Renewing Donor', c.Donor_Classification__c);
		System.assertEquals('First Time Donor', c.Previous_Year_End_Classification__c);		
        Test.stopTest(); 
	}

    static testMethod void testDonorClassificationRollups() {
    
        Test.startTest();

        npo02__Household__c hh = new npo02__Household__c(Name='Testerson Household');
        insert hh;

		Contact c = new Contact(FirstName = 'Test', LastName = 'Testerson', npo02__Household__c = hh.id);
		insert c;

		System.assertEquals(hh.Donor_Classification__c, null);
		
		Program__c p = new Program__c(Name = 'Test');
		insert p;
		
		Campaign camp = new Campaign(Name = 'Test');
		insert camp;
		
        Account individual = new Account(Name = 'Individual');
        insert individual;

		Opportunity o = new Opportunity(Name = 'Test Donation');
		o.Amount = 1.00;
        o.Account = individual;
		o.CloseDate = Date.today();
		o.npe01__Contact_Id_for_Role__c = c.Id;
		o.Program__c = p.Id;
		o.CampaignId = camp.id;
		o.Type = 'Individual';
		o.StageName = 'Pending';
		o.Payment_Method__c = 'Cash';
		insert o;
		
		OpportunityContactRole ocr = new OpportunityContactRole();
		ocr.ContactId = c.id;
		ocr.OpportunityId = o.id;
		ocr.IsPrimary = true;
		insert ocr;
		                
		o.StageName = 'Closed Won';
		update o;
		
		OpportunityContactRole[] roles = [select id from OpportunityContactRole where OpportunityID =: o.id];

		System.assert(roles.size() > 0);
		
		Contact[] updated = [select id, npo02__Household__c from Contact where id =: c.id];
        List<Id> hhids = new List<Id>();
        for(contact cont: updated) {
           hhids.add(cont.npo02__Household__c);
           System.debug('*********** Household ID: '+cont.npo02__Household__c);
        }

        System.assertEquals(hhids.size(), 1);
        List<npo02__Household__c> hhs = [SELECT id, Always_Classify_as_Major_Donor__c, Donor_Classification__c from npo02__Household__c where id =: hhids];
        HHDonorClassificationRollups.rollupDonorClass(hhs);

        System.assertEquals(hhs.size(), 1);
		System.assertEquals(hhs.get(0).Donor_Classification__c, 'First Time Donor');
		
        Test.stopTest();        
	}

	static testMethod void testLoyalDonor() {  
        Test.startTest();
        npo02__Household__c hh = new npo02__Household__c(Name='Testerson Household');
        insert hh;

		Contact c = new Contact(FirstName = 'Test', LastName = 'Testerson', npo02__Household__c=hh.id);
		insert c;
		
		System.assertEquals(hh.Donor_Classification__c, null);
		
		Program__c p = new Program__c(Name = 'Test');
		insert p;
		
		Campaign camp = new Campaign(Name = 'Test');
		insert camp;
		
        Account individual = new Account(Name = 'Individual');
        insert individual;

        // Test Loyal Donor
        Date today = Date.today();
        List<Opportunity> opps = new List<Opportunity>();
        List<OpportunityContactRole> ocrs = new List<OpportunityContactRole>();
        for(Integer i=0; i<6; i++) {
       	  Opportunity opp = new Opportunity(Name = 'Test Donation');
		  opp.Amount = 1.00;
          opp.Account = individual;
		  opp.CloseDate = today.addYears(-1 * i);
		  opp.npe01__Contact_Id_for_Role__c = c.Id;
		  opp.Program__c = p.Id;
		  opp.CampaignId = camp.id;
		  opp.Type = 'Individual';
		  opp.StageName = 'Pending';
		  opp.Payment_Method__c = 'Cash';
		  //insert opp;
          opps.add(opp);
        }
        insert(opps);

        for(Opportunity anOpp: opps) {
		  OpportunityContactRole cr = new OpportunityContactRole();
		  cr.ContactId = c.id;
		  cr.OpportunityId = anOpp.id;
		  cr.IsPrimary = true;
		  //insert cr;
          ocrs.add(cr);
        }
        insert(ocrs);

        List<Opportunity> updatedOpps = new List<Opportunity>();
        for(Opportunity anotherOpp: opps) {
          anotherOpp.StageName = 'Closed Won';
          updatedOpps.add(anotherOpp);
        }
        update(updatedOpps);

		Contact[] updated = [select id, npo02__Household__c from Contact where id =: c.id];
        List<Id> hhids = new List<Id>();
        for(contact cont: updated) {
           hhids.add(cont.npo02__Household__c);
           System.debug('*********** TESTLOYAL Household ID: '+cont.npo02__Household__c);
        }

        System.assertEquals(hhids.size(), 1);
        List<npo02__Household__c> hhs = [SELECT id, Always_Classify_as_Major_Donor__c, Donor_Classification__c from npo02__Household__c where id =: hhids];

		System.assert(hhs.get(0).Donor_Classification__c.contains('Loyal Donor'));

        Test.stopTest();               
	}

	static testMethod void testLapsedDonor() {               
        Test.startTest();
        npo02__Household__c hh = new npo02__Household__c(Name='Testerson Household');
        insert hh;

		Contact c = new Contact(FirstName = 'Test', LastName = 'Testerson', npo02__Household__c=hh.id);
		insert c;
		
		System.assertEquals(hh.Donor_Classification__c, null);
		
		Program__c p = new Program__c(Name = 'Test');
		insert p;
		
		Campaign camp = new Campaign(Name = 'Test');
		insert camp;
		
        Account individual = new Account(Name = 'Individual');
        insert individual;

		Opportunity o = new Opportunity(Name = 'Test Donation');
		o.Amount = 1.00;
                o.Account = individual;
		o.CloseDate = Date.today();
		o.npe01__Contact_Id_for_Role__c = c.Id;
		o.Program__c = p.Id;
		o.CampaignId = camp.id;
		o.Type = 'Individual';
		o.StageName = 'Pending';
		o.Payment_Method__c = 'Cash';
		insert o;
		
		OpportunityContactRole ocr = new OpportunityContactRole();
		ocr.ContactId = c.id;
		ocr.OpportunityId = o.id;
		ocr.IsPrimary = true;
		insert ocr;
		
		o.StageName = 'Closed Won';
        // test lapsed donor
        Date today = Date.today();
        o.CloseDate = today.addYears(-5);
        update o;

        Contact[] updated = [select id, npo02__Household__c from Contact where id =: c.id];
        List<Id> hhids = new List<Id>();
        for(contact c2: updated) {
          hhids.add(c2.npo02__Household__c);
        }
        List<npo02__Household__c> hhs = [SELECT id, Always_Classify_as_Major_Donor__c, Donor_Classification__c from npo02__Household__c where id =: hhids];

		System.assert(hhs.get(0).Donor_Classification__c.contains('Lapsed Donor'));
        Test.stopTest();               
	}

	static testMethod void testMonthly() {
        Test.startTest();

        npo02__Household__c hh = new npo02__Household__c(Name='Testerson Household');
        insert hh;

		Contact c = new Contact(FirstName = 'Test', LastName = 'Testerson', npo02__Household__c=hh.id);
		insert c;
		
		System.assertEquals(hh.Donor_Classification__c, null);
		
		Program__c p = new Program__c(Name = 'Test');
		insert p;
		
		Campaign camp = new Campaign(Name = 'Test');
		insert camp;

        Account individual = new Account(Name = 'Individual');
        insert individual;

        // Test Monthly Donor
        Date today = Date.today();
        List<Opportunity> opps = new List<Opportunity>();
        List<OpportunityContactRole> ocrs = new List<OpportunityContactRole>();
        for(Integer i=0; i<6; i++) {
       	  Opportunity opp = new Opportunity(Name = 'Test Donation');
		  opp.Amount = 1.00;
                  opp.Account = individual;
		  opp.CloseDate = today.addMonths(-1 * i);
		  opp.npe01__Contact_Id_for_Role__c = c.Id;
		  opp.Program__c = p.Id;
		  opp.CampaignId = camp.id;
		  opp.Type = 'Individual';
		  opp.StageName = 'Pending';
		  opp.Payment_Method__c = 'Cash';
		  //insert opp;
          opps.add(opp);
        }
        insert(opps);

        for(Opportunity anOpp: opps) {
		  OpportunityContactRole cr = new OpportunityContactRole();
		  cr.ContactId = c.id;
		  cr.OpportunityId = anOpp.id;
		  cr.IsPrimary = true;
		  //insert cr;
          ocrs.add(cr);
        }
        insert(ocrs);

        List<Opportunity> updatedOpps = new List<Opportunity>();
        for(Opportunity anotherOpp: opps) {
          anotherOpp.StageName = 'Closed Won';
          updatedOpps.add(anotherOpp);
        }
        update(updatedOpps);

		Contact[] updated = [select id, npo02__Household__c from Contact where id =: c.id];
        List<Id> hhids = new List<Id>();
        for(contact cont: updated) {
           hhids.add(cont.npo02__Household__c);
           System.debug('*********** TESTMONTHLY Household ID: '+cont.npo02__Household__c);
        }

        System.assertEquals(hhids.size(), 1);
        List<npo02__Household__c> hhs = [SELECT id, Always_Classify_as_Major_Donor__c, Donor_Classification__c from npo02__Household__c where id =: hhids];

		System.assert(hhs.get(0).Donor_Classification__c.contains('Monthly Donor'));

        Test.stopTest();            
	}

	static testMethod void testMajor() {              		
        Test.startTest();

        npo02__Household__c hh = new npo02__Household__c(Name='Testerson Household');
        insert hh;

		Contact c = new Contact(FirstName = 'Test', LastName = 'Testerson', npo02__Household__c=hh.id);
		insert c;

		System.assertEquals(hh.Donor_Classification__c, null);

		Program__c p = new Program__c(Name = 'Test');
		insert p;
		
		Campaign camp = new Campaign(Name = 'Test');
		insert camp;

        Account individual = new Account(Name = 'Individual');
        insert individual;

        // Test Monthly Donor
        Date today = Date.today().addDays(-180);
        List<Opportunity> opps = new List<Opportunity>();
        List<OpportunityContactRole> ocrs = new List<OpportunityContactRole>();
        for(Integer i=0; i<6; i++) {
       	  Opportunity opp = new Opportunity(Name = 'Test Donation');
		  opp.Amount = ((i+1)*100)+400;
                  opp.Account = individual;
		  opp.CloseDate = today;
		  opp.npe01__Contact_Id_for_Role__c = c.Id;
		  opp.Program__c = p.Id;
		  opp.CampaignId = camp.id;
		  opp.Type = 'Individual';
		  opp.StageName = 'Pending';
		  opp.Payment_Method__c = 'Cash';
		  //insert opp;
          opps.add(opp);
        }
        insert(opps);

        for(Opportunity anOpp: opps) {
		  OpportunityContactRole cr = new OpportunityContactRole();
		  cr.ContactId = c.id;
		  cr.OpportunityId = anOpp.id;
		  cr.IsPrimary = true;
		  //insert cr;
          ocrs.add(cr);
        }
        insert(ocrs);

        List<Opportunity> updatedOpps = new List<Opportunity>();
        for(Opportunity anotherOpp: opps) {
          anotherOpp.StageName = 'Closed Won';
          updatedOpps.add(anotherOpp);
        }
        update(updatedOpps);

		Contact[] updated = [select id, npo02__Household__c from Contact where id =: c.id];
        List<Id> hhids = new List<Id>();
        for(contact cont: updated) {
           hhids.add(cont.npo02__Household__c);
           System.debug('*********** TESTMAJOR Household ID: '+cont.npo02__Household__c);
        }

        System.assertEquals(hhids.size(), 1);
        List<npo02__Household__c> hhs = [SELECT id, Always_Classify_as_Major_Donor__c, Donor_Classification__c from npo02__Household__c where id =: hhids];
		System.assert(hhs.get(0).Donor_Classification__c.contains('Major Donor'));

        npo02__Household__c hh2 = new npo02__Household__c(Name='Testerson Household', Always_Classify_As_Major_Donor__c = True);
        insert hh2;

		Contact c2 = new Contact(FirstName = 'Test', LastName = 'Testerson', npo02__Household__c=hh2.id);                
		insert c2;

        // have to insert an opp here to get the trigger to fire
      	Opportunity opp2 = new Opportunity(Name = 'Another Test Donation');
		opp2.Amount = 4;
        opp2.Account = individual;
		opp2.CloseDate = today;
		opp2.npe01__Contact_Id_for_Role__c = c2.Id;
		opp2.Program__c = p.Id;
		opp2.CampaignId = camp.id;
		opp2.Type = 'Individual';
		opp2.StageName = 'Pending';
		opp2.Payment_Method__c = 'Cash';
		insert opp2;

	    OpportunityContactRole cr2 = new OpportunityContactRole();
		cr2.ContactId = c2.id;
		cr2.OpportunityId = opp2.id;
		cr2.IsPrimary = true;
		insert cr2;

		opp2.StageName = 'Closed Won';
        update opp2;

        updated = [select id, npo02__Household__c from Contact where id =: c2.id];

        hhids = new List<Id>();
        for(contact cont: updated) {
           hhids.add(cont.npo02__Household__c);
           System.debug('*********** TESTMAJOR Household ID: '+cont.npo02__Household__c);
        }

        System.assertEquals(hhids.size(), 1);
        hhs = [SELECT id, Always_Classify_as_Major_Donor__c, Donor_Classification__c from npo02__Household__c where id =: hhids];

		System.assertEquals(hhs.get(0).Donor_Classification__c.contains('Major Donor'), True);

        //c2.Always_classify_as_Major_donor__c = False;
        hh2.Always_classify_as_Major_Donor__c = False;
        update hh2;
		opp2.StageName = 'Closed Won';
        // have to update an opp here to get the trigger to fire
        update opp2;
        updated = [select id, npo02__Household__c from Contact where id =: c2.id];
        hhids = new List<Id>();
        for(contact cont: updated) {
           hhids.add(cont.npo02__Household__c);
           System.debug('*********** TESTMAJOR Household ID: '+cont.npo02__Household__c);
        }

        System.assertEquals(hhids.size(), 1);
        hhs = [SELECT id, Always_Classify_as_Major_Donor__c, Donor_Classification__c from npo02__Household__c where id =: hhids];
		
        Test.stopTest();
	}

	static testMethod void testDonorClassEquivalency() {
        String s1 = 'Monthly Donor; Renewing Donor';
        String s2 = 'Renewing Donor; Monthly Donor';
        String s3 = 'Renewing Donor; Monthly Donor; Lapsed Donor';
        String s4 = 'Renewing DOnor; Lapsed Donor';
        
        System.assertEquals(DonorClassificationUtility.donorClassEquivalent(s1,s2), true);
        System.assertEquals(DonorClassificationUtility.donorClassEquivalent(s1,s3), false);
        System.assertEquals(DonorClassificationUtility.donorClassEquivalent(s1,s4), false);         
	}
	
	static testMethod void testRenewingDonor() {
		Test.startTest();
       	npo02__Household__c hh = new npo02__Household__c(Name='Testerson Household');
       	insert hh;

		Contact c = new Contact(FirstName = 'Test', LastName = 'Testerson', npo02__Household__c=hh.id);
		insert c;		   
			
		Program__c p = new Program__c(Name = 'Test');
		insert p;
			
		Campaign camp = new Campaign(Name = 'Test');
		insert camp;   

       	// Test Renewing Donor
       	Date today = Date.today();
       	List<Opportunity> opps = new List<Opportunity>();          
        for(Integer i=1; i<3; i++) {
		   	  Opportunity opp = new Opportunity(Name = 'Test Donation', 
		   	  									Amount = 1.00,                            	  									
												CloseDate = today.addYears(-1 * i),													  
												Program__c = p.Id,
												CampaignId = camp.id,													  
												StageName = 'Pending',
												Payment_Method__c = 'Cash');													  
			  opps.add(opp);
        }
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

		for (Opportunity o : opps) { 
        	o.StageName = 'Closed Won';
		}
		update opps;
		   
       	c = [select Donor_Classification__c, Previous_Donor_Classification__c,
						Donor_Classification_Transition_Date__c, Always_classify_as_Major_Donor__c 
						from Contact where id =:c.id]; 
	   	System.assert(c.Donor_Classification__c.contains('Renewing Donor'));
        Test.stopTest(); 
	}
	
	static testMethod void testReturningDonor() {
		Test.startTest();
	       npo02__Household__c hh = new npo02__Household__c(Name='Testerson Household');
           insert hh;

		   Contact c = new Contact(FirstName = 'Test', LastName = 'Testerson', npo02__Household__c=hh.id);
		   insert c;		   
			
		   Program__c p = new Program__c(Name = 'Test');
		   insert p;
			
		   Campaign camp = new Campaign(Name = 'Test');
		   insert camp;   

           // Test Returning Donor
           Date today = Date.today();
           List<Opportunity> opps = new List<Opportunity>();          
           
           Opportunity opp1 = new Opportunity(Name = 'Test Donation', 
               	  									Amount = 1.00,                            	  									
													CloseDate = today.addYears(-3),													  
													Program__c = p.Id,
													CampaignId = camp.id,													  
													StageName = 'Pending',
													Payment_Method__c = 'Cash');
			Opportunity opp2 = new Opportunity(Name = 'Test Donation', 
               	  									Amount = 1.00,                            	  									
													CloseDate = today,													  
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

		   	for (Opportunity o : opps) { 
           		o.StageName = 'Closed Won';
		   	}
		   	update opps; 
            
            c = [select Donor_Classification__c, Previous_Donor_Classification__c,
							Donor_Classification_Transition_Date__c, Always_classify_as_Major_Donor__c 
							from Contact where id =:c.id];
             
		   	System.assert(c.Donor_Classification__c.contains('Returning Donor'));

        Test.stopTest(); 
	}
	
	static testMethod void testFirstYearDonor() {
		Test.startTest();
	       npo02__Household__c hh = new npo02__Household__c(Name='Testerson Household');
           insert hh;

		   Contact c = new Contact(FirstName = 'Test', LastName = 'Testerson', npo02__Household__c=hh.id);
		   insert c;		   
			
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

		   	for (Opportunity o : opps) { 
           		o.StageName = 'Closed Won';
		   	}
		   	update opps; 
            
            c = [select Donor_Classification__c, Previous_Donor_Classification__c,
							Donor_Classification_Transition_Date__c, Always_classify_as_Major_Donor__c 
							from Contact where id =:c.id];
             
		   	System.assert(c.Donor_Classification__c.contains('First Year Donor'));

        Test.stopTest(); 
	}
	
	static testMethod void testBatchDonations() {
		//create 200 households
		List<npo02__Household__c> households = new List<npo02__Household__c>();
		for (Integer i=0; i<200; i++) {				
			npo02__Household__c hh = new npo02__Household__c(Name='Testerson Household');
			households.add(hh);
		}
        insert households;
        
        List<Contact> contacts = new List<Contact>();
        for (npo02__Household__c hh : households){
			Contact c = new Contact(FirstName = 'Test', LastName = 'Testerson', npo02__Household__c=hh.id);
			contacts.add(c);
        }
		insert contacts;
				   				
		Program__c p = new Program__c(Name = 'Test');
		insert p;				
		Campaign camp = new Campaign(Name = 'Test');
		insert camp;
		   	
		//create 200 opportunities
		List<Opportunity> opps = new List<Opportunity>();
		for (Integer i=0; i<200; i++) {
			Opportunity opp = new Opportunity(Name = 'Test Donation',
		  									Amount = 200,	                  							
		  									CloseDate = date.today(),		  
		  									Program__c = p.Id,
		  									CampaignId = camp.id,		  									
		  									StageName = 'Closed Won',
		  									Payment_Method__c = 'Cash');		  
            opps.add(opp);
		}     
		insert opps;
		//create contact roles
		List<OpportunityContactRole> ocrs = new List<OpportunityContactRole>();
		for (Integer i=0; i<200; i++) {
           	OpportunityContactRole cr = new OpportunityContactRole(ContactId = contacts.get(i).Id,
           														   OpportunityId = opps.get(i).Id,
																   IsPrimary = true);
			ocrs.add(cr);																   
		}
		insert ocrs;				
		
		Test.startTest();
		HHDonorClassificationRollups.rollupAllContacts();
		Test.stopTest();
		
		List<Contact> cons = [select id, Donor_Classification__c from Contact];
		System.assertEquals(200, cons.size());
		for (Contact c: cons) {
			System.assertEquals('First Time Donor', c.Donor_Classification__c);
		}   		
	}
	
	static testMethod void testBatchDonationsBothCurrentAndCustomDate() {
		//create 200 households
		List<npo02__Household__c> households = new List<npo02__Household__c>();
		for (Integer i=0; i<200; i++) {				
			npo02__Household__c hh = new npo02__Household__c(Name='Testerson Household');
			households.add(hh);
		}
        insert households;
        
        List<Contact> contacts = new List<Contact>();
        for (npo02__Household__c hh : households){
			Contact c = new Contact(FirstName = 'Test', LastName = 'Testerson', npo02__Household__c=hh.id);
			contacts.add(c);
        }
		insert contacts;
				   				
		Program__c p = new Program__c(Name = 'Test');
		insert p;				
		Campaign camp = new Campaign(Name = 'Test');
		insert camp;
		   	
		//create 200 opportunities
		List<Opportunity> opps = new List<Opportunity>();
		for (Integer i=0; i<200; i++) {
			Opportunity opp = new Opportunity(Name = 'Test Donation',
		  									Amount = 200,	                  							
		  									CloseDate = date.today().addYears(-2),		  
		  									Program__c = p.Id,
		  									CampaignId = camp.id,		  									
		  									StageName = 'Closed Won',
		  									Payment_Method__c = 'Cash');		  
            opps.add(opp);
		}     
		insert opps;
		//create contact roles
		List<OpportunityContactRole> ocrs = new List<OpportunityContactRole>();
		for (Integer i=0; i<200; i++) {
           	OpportunityContactRole cr = new OpportunityContactRole(ContactId = contacts.get(i).Id,
           														   OpportunityId = opps.get(i).Id,
																   IsPrimary = true);
			ocrs.add(cr);																   
		}
		insert ocrs;				
		
		Test.startTest();
		Date custDate = date.today().addYears(-2);
		Datetime batchTime = datetime.now();
		HHDonorClassificationRollups.rollupDonorClass(households, true, true, custDate, batchTime);
		Test.stopTest();
		
		List<Contact> cons = [select id, Donor_Classification__c, Previous_Year_End_Classification__c, Custom_Date_Donor_Classification__c,
								Custom_Classification_Date__c, Custom_Donor_Classification_Job_Last_Run__c, Donor_Classification_Job_Last_Run__c 
								from Contact];
		System.assertEquals(200, cons.size());
		for (Contact c: cons) {
			System.assertEquals('Lapsed Donor', c.Donor_Classification__c);
			System.assertEquals('First Time Donor', c.Previous_Year_End_Classification__c);
			System.assertEquals('First Time Donor', c.Custom_Date_Donor_Classification__c);
			System.assertEquals(custDate, c.Custom_Classification_Date__c);
			System.assertEquals(batchTime, c.Custom_Donor_Classification_Job_Last_Run__c);
			System.assertEquals(batchTime, c.Donor_Classification_Job_Last_Run__c);
		}   		
	}
	
	static testMethod void testBatchDonationsOnlyCustomDate() {
		//create 200 households
		List<npo02__Household__c> households = new List<npo02__Household__c>();
		for (Integer i=0; i<200; i++) {				
			npo02__Household__c hh = new npo02__Household__c(Name='Testerson Household');
			households.add(hh);
		}
        insert households;
        
        List<Contact> contacts = new List<Contact>();
        for (npo02__Household__c hh : households){
			Contact c = new Contact(FirstName = 'Test', LastName = 'Testerson', npo02__Household__c=hh.id);
			contacts.add(c);
        }
		insert contacts;
				   				
		Program__c p = new Program__c(Name = 'Test');
		insert p;				
		Campaign camp = new Campaign(Name = 'Test');
		insert camp;
		   	
		//create 200 opportunities
		List<Opportunity> opps = new List<Opportunity>();
		for (Integer i=0; i<200; i++) {
			Opportunity opp = new Opportunity(Name = 'Test Donation',
		  									Amount = 200,	                  							
		  									CloseDate = date.today().addYears(-2),		  
		  									Program__c = p.Id,
		  									CampaignId = camp.id,		  									
		  									StageName = 'Closed Won',
		  									Payment_Method__c = 'Cash');		  
            opps.add(opp);
		}     
		insert opps;
		//create contact roles
		List<OpportunityContactRole> ocrs = new List<OpportunityContactRole>();
		for (Integer i=0; i<200; i++) {
           	OpportunityContactRole cr = new OpportunityContactRole(ContactId = contacts.get(i).Id,
           														   OpportunityId = opps.get(i).Id,
																   IsPrimary = true);
			ocrs.add(cr);																   
		}
		insert ocrs;				
		
		Test.startTest();
		Date custDate = date.today().addYears(-2);
		Datetime batchTime = datetime.now();
		HHDonorClassificationRollups.rollupDonorClass(households, false, true, custDate, batchTime);
		Test.stopTest();
		
		List<Contact> cons = [select id, Donor_Classification__c, Previous_Year_End_Classification__c, Custom_Date_Donor_Classification__c,
								Custom_Classification_Date__c, Custom_Donor_Classification_Job_Last_Run__c, Donor_Classification_Job_Last_Run__c 
								from Contact];
		System.assertEquals(200, cons.size());
		for (Contact c: cons) {
			System.assertEquals(null, c.Donor_Classification__c);
			System.assertEquals(null, c.Previous_Year_End_Classification__c);
			System.assertEquals('First Time Donor', c.Custom_Date_Donor_Classification__c);
			System.assertEquals(custDate, c.Custom_Classification_Date__c);
			System.assertEquals(batchTime, c.Custom_Donor_Classification_Job_Last_Run__c);
			System.assertEquals(null, c.Donor_Classification_Job_Last_Run__c);
		}   
	}
}