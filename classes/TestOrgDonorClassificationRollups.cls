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
private class TestOrgDonorClassificationRollups {

    static testMethod void testDonorClassificationRollups() {
       Test.startTest();

	       Account acc = new Account(Name='Test Org', Type='Business');
	       insert acc;
	
		   System.assertEquals(acc.Donor_Classification__c, null);
			
		   Program__c p = new Program__c(Name = 'Test');
		   insert p;
			
		   Campaign camp = new Campaign(Name = 'Test');
		   insert camp;               

		   Opportunity o = new Opportunity(Name = 'Test Donation', 
		   								    Amount = 1.00,
		   								    AccountId = acc.id,
											CloseDate = Date.today(),											
											Program__c = p.Id,
											CampaignId = camp.id,											
											StageName = 'Closed Won',
											Payment_Method__c = 'Cash');
		    insert o;
		    Account a = [select Donor_Classification__c, Previous_Donor_Classification__c,
							Donor_Classification_Transition_Date__c, Always_classify_as_Major_Donor__c 
							from Account where id =:acc.id];
				
		    System.assertEquals('First Time Donor', a.Donor_Classification__c);
		    System.assertEquals(null, a.Previous_Donor_Classification__c);
			System.assert(Date.today().isSameDay(a.Donor_Classification_Transition_Date__c.date()));
			System.assert(!a.Always_classify_as_Major_Donor__c);
    	Test.stopTest();              
	}
	
	static testMethod void testRenewingDonor() {
		Test.startTest();
	       Account acc = new Account(Name='Test Org', Type='Business');
	       insert acc;
	
		   System.assertEquals(acc.Donor_Classification__c, null);
			
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
               	  									AccountId = acc.id,
													CloseDate = today.addYears(-1 * i),													  
													Program__c = p.Id,
													CampaignId = camp.id,													  
													StageName = 'Closed Won',
													Payment_Method__c = 'Cash');													  
				  opps.add(opp);
           }
           insert(opps);  
           Account a = [select Donor_Classification__c, Previous_Donor_Classification__c,
							Donor_Classification_Transition_Date__c, Always_classify_as_Major_Donor__c 
							from Account where id =:acc.id];    
		   System.assert(a.Donor_Classification__c.contains('Renewing Donor'));

        Test.stopTest(); 
	}
	
	static testMethod void testReturningDonor() {
		Test.startTest();
	       Account acc = new Account(Name='Test Org', Type='Business');
	       insert acc;
	
		   System.assertEquals(acc.Donor_Classification__c, null);
			
		   Program__c p = new Program__c(Name = 'Test');
		   insert p;
			
		   Campaign camp = new Campaign(Name = 'Test');
		   insert camp;   

           // Test Returning Donor
           Date today = Date.today();
           List<Opportunity> opps = new List<Opportunity>();          
           
           Opportunity opp1 = new Opportunity(Name = 'Test Donation', 
               	  									Amount = 1.00,             
               	  									AccountId = acc.id,
													CloseDate = today.addYears(-3),													  
													Program__c = p.Id,
													CampaignId = camp.id,													  
													StageName = 'Closed Won',
													Payment_Method__c = 'Cash');
			Opportunity opp2 = new Opportunity(Name = 'Test Donation', 
               	  									Amount = 1.00,             
               	  									AccountId = acc.id,
													CloseDate = today,													  
													Program__c = p.Id,
													CampaignId = camp.id,													  
													StageName = 'Closed Won',
													Payment_Method__c = 'Cash');																							  
			opps.add(opp1);
			opps.add(opp2);
           
           	insert(opps);  
           	Account a = [select Donor_Classification__c, Previous_Donor_Classification__c,
							Donor_Classification_Transition_Date__c, Always_classify_as_Major_Donor__c 
							from Account where id =:acc.id];    
		   	System.assert(a.Donor_Classification__c.contains('Returning Donor'));

        Test.stopTest(); 
	}

	static testMethod void testLoyalDonor() {               
                
    	Test.startTest();
	       Account acc = new Account(Name='Test Org', Type='Business');
	       insert acc;
	
		   System.assertEquals(acc.Donor_Classification__c, null);
			
		   Program__c p = new Program__c(Name = 'Test');
		   insert p;
			
		   Campaign camp = new Campaign(Name = 'Test');
		   insert camp;   

           // Test Loyal Donor
           Date today = Date.today();
           List<Opportunity> opps = new List<Opportunity>();          
           for(Integer i=0; i<6; i++) {
               	  Opportunity opp = new Opportunity(Name = 'Test Donation', 
               	  									Amount = 1.00,             
               	  									AccountId = acc.id,
													CloseDate = today.addYears(-1 * i),													  
													Program__c = p.Id,
													CampaignId = camp.id,													  
													StageName = 'Closed Won',
													Payment_Method__c = 'Cash');													  
				  opps.add(opp);
           }
           insert(opps);  
           Account a = [select Donor_Classification__c, Previous_Donor_Classification__c,
							Donor_Classification_Transition_Date__c, Always_classify_as_Major_Donor__c 
							from Account where id =:acc.id];    
		   System.assert(a.Donor_Classification__c.contains('Loyal Donor'));

        Test.stopTest();               
	}

	static testMethod void testLapsedDonor() {
		Test.startTest();
        	Account acc = new Account(Name='Test Org', Type='Business');
	       	insert acc;
	
		   	System.assertEquals(acc.Donor_Classification__c, null);
			
		    Program__c p = new Program__c(Name = 'Test');
		    insert p;
			
		    Campaign camp = new Campaign(Name = 'Test');
		    insert camp; 

			Opportunity o = new Opportunity(Name = 'Test Donation',
											Amount = 1.00,
										    AccountId = acc.id,
										    CloseDate = Date.today().addYears(-5),									
											Program__c = p.Id,
											CampaignId = camp.id,											
											StageName = 'Closed Won',
											Payment_Method__c = 'Cash');
			insert o;
			Account a = [select Donor_Classification__c, Previous_Donor_Classification__c,
							Donor_Classification_Transition_Date__c, Always_classify_as_Major_Donor__c 
							from Account where id =:acc.id];		      
			System.assert(a.Donor_Classification__c.contains('Lapsed Donor'));

       Test.stopTest();         
	}

	static testMethod void testMonthly() {
	    Test.startTest();
       	Account acc = new Account(Name='Test Org', Type='Business');
	   	insert acc;
		System.assertEquals(acc.Donor_Classification__c, null);				
		Program__c p = new Program__c(Name = 'Test');
		insert p;		
		Campaign camp = new Campaign(Name = 'Test');
		insert camp;               
        // Test Monthly Donor
        Date today = Date.today();
        List<Opportunity> opps = new List<Opportunity>();        
        for(Integer i=0; i<6; i++) {
       		Opportunity opp = new Opportunity(Name = 'Test Donation',
					  		  				Amount = 1.00,
								         	AccountId = acc.Id,
										  	CloseDate = today.addMonths(-1 * i),							  
										  	Program__c = p.Id,
										  	CampaignId = camp.id,
										  	Type = 'Business',
										  	StageName = 'Closed Won',
										  	Payment_Method__c = 'Cash');		  
           	opps.add(opp);
        }
        insert(opps);
        
		Account a = [select Donor_Classification__c, Previous_Donor_Classification__c,
							Donor_Classification_Transition_Date__c, Always_classify_as_Major_Donor__c 
							from Account where id =:acc.id];		      
		System.assert(a.Donor_Classification__c.contains('Monthly Donor'));			
        Test.stopTest();
              
	}

	static testMethod void testMajor() {               
        Test.startTest();

        Account acc = new Account(Name='Test Org', Type='Business');
	   	insert acc;
		System.assertEquals(acc.Donor_Classification__c, null);	

		Program__c p = new Program__c(Name = 'Test');
		insert p;
		
		Campaign camp = new Campaign(Name = 'Test');
		insert camp;                

        // Test major Donor
        Date today = Date.today().addDays(-180);
        List<Opportunity> opps = new List<Opportunity>();
       
        for(Integer i=0; i<6; i++) {
       	  Opportunity opp = new Opportunity(Name = 'Test Donation',
		  									Amount = ((i+1)*100)+400,
                  							AccountId = acc.Id,
		  									CloseDate = today,		  
		  									Program__c = p.Id,
		  									CampaignId = camp.id,
		  									Type = 'Business',
		  									StageName = 'Closed Won',
		  									Payment_Method__c = 'Cash');
		  
            opps.add(opp);
        }
        insert(opps);
        
        Account a = [select Donor_Classification__c, Previous_Donor_Classification__c,
							Donor_Classification_Transition_Date__c, Always_classify_as_Major_Donor__c 
							from Account where id =:acc.id];	      		
		System.assert(a.Donor_Classification__c.contains('Major Donor'));

        Account acc2 = new Account(Name='Testerson Account', Always_Classify_As_Major_Donor__c = true, Type='Business');
        insert acc2;
		
        // have to insert an opp here to get the trigger to fire
        Opportunity opp2 = new Opportunity(Name = 'Another Test Donation',
											Amount = 4,
									        AccountId = acc2.id,
											CloseDate = today,											
											Program__c = p.Id,
											CampaignId = camp.id,											
											StageName = 'Closed Won',
											Payment_Method__c = 'Cash');
		insert opp2;
        a = [select Donor_Classification__c, Previous_Donor_Classification__c,
							Donor_Classification_Transition_Date__c, Always_classify_as_Major_Donor__c 
							from Account where id =:acc2.id];
               
		System.assert(a.Donor_Classification__c.contains('Major Donor'));
        Test.stopTest();               
	}
	
	static testMethod void testFirstYearDonor() {               
        Test.startTest();

        Account acc = new Account(Name='Test Org', Type='Business');
	   	insert acc;
		System.assertEquals(acc.Donor_Classification__c, null);	

		Program__c p = new Program__c(Name = 'Test');
		insert p;
		
		Campaign camp = new Campaign(Name = 'Test');
		insert camp;                

        // Test major Donor
        Date aYearAgo = Date.today().addDays(-365);                     
        Opportunity opp = new Opportunity(Name = 'Test Donation',
		  									Amount = 200,
                  							AccountId = acc.Id,
		  									CloseDate = aYearAgo,		  
		  									Program__c = p.Id,
		  									CampaignId = camp.id,
		  									Type = 'Business',
		  									StageName = 'Closed Won',
		  									Payment_Method__c = 'Cash');		  
        insert(opp);
        
        Account a = [select Donor_Classification__c, Previous_Donor_Classification__c,
							Donor_Classification_Transition_Date__c, Always_classify_as_Major_Donor__c 
							from Account where id =:acc.id];	      		
		System.assert(a.Donor_Classification__c.contains('First Time Donor'));
        
        opp = new Opportunity(Name = 'Test Donation',
		  									Amount = 200,
                  							AccountId = acc.Id,
		  									CloseDate = aYearAgo,		  
		  									Program__c = p.Id,
		  									CampaignId = camp.id,
		  									Type = 'Business',
		  									StageName = 'Closed Won',
		  									Payment_Method__c = 'Cash');		  
        insert(opp);
        
        a = [select Donor_Classification__c, Previous_Donor_Classification__c,
							Donor_Classification_Transition_Date__c, Always_classify_as_Major_Donor__c 
							from Account where id =:acc.id];	      		
		
		System.assert(a.Donor_Classification__c.contains('First Year Donor'));
		
		//insert an older donation - should change the classification to renewing donor
		opp = new Opportunity(Name = 'Test Donation',
		  									Amount = 200,
                  							AccountId = acc.Id,
		  									CloseDate = aYearAgo.addYears(-1),		  
		  									Program__c = p.Id,
		  									CampaignId = camp.id,
		  									Type = 'Business',
		  									StageName = 'Closed Won',
		  									Payment_Method__c = 'Cash');		  
        insert(opp);
        
        a = [select Donor_Classification__c, Previous_Donor_Classification__c,
							Donor_Classification_Transition_Date__c, Always_classify_as_Major_Donor__c 
							from Account where id =:acc.id];	      		
		System.assertEquals('Renewing Donor', a.Donor_Classification__c);
               
        Test.stopTest();               
	}
	
	static testMethod void testWithInKindDonations() {               
        Test.startTest();
        Account acc = new Account(Name='Test Org', Type='Business');
	   	insert acc;
		System.assertEquals(acc.Donor_Classification__c, null);	
		Program__c p = new Program__c(Name = 'Test');
		insert p;		
		Campaign camp = new Campaign(Name = 'Test');
		insert camp;                        
        Date today = Date.today().addDays(-180);
        List<Opportunity> opps = new List<Opportunity>();
        //create inkind donations
        for(Integer i=0; i<6; i++) {
       	  Opportunity opp = new Opportunity(Name = 'Test Donation',
		  									Amount = ((i+1)*100)+400,
                  							AccountId = acc.Id,
		  									CloseDate = today,		  
		  									Program__c = p.Id,
		  									CampaignId = camp.id,
		  									Type = 'Business',
		  									StageName = 'Closed Won',
		  									Payment_Method__c = 'Cash',
		  									RecordTypeId=OrgDonorClassificationRollups.oppInKindRecType);
		  
            opps.add(opp);
        }
        insert(opps);
        
        Account a = [select Donor_Classification__c, Previous_Donor_Classification__c,
							Donor_Classification_Transition_Date__c, Always_classify_as_Major_Donor__c 
							from Account where id =:acc.id];	  
							    		
		System.assertEquals(null,a.Donor_Classification__c);
		System.assertEquals(null,a.Previous_Donor_Classification__c);
		System.assertEquals(null,a.Donor_Classification_Transition_Date__c);
		System.assert(!a.Always_classify_as_Major_Donor__c);

        Test.stopTest();               
	}
	
	static testMethod void testBatchDonations() {		
		//create 200 accounts
		List<Account> accts = new List<Account>();
		for (Integer i=0; i<200; i++) {
        	Account acc = new Account(Name='Test Org'+i, Type='Business');
        	accts.add(acc);
		}
	   	insert accts;	   		   		   		
		Program__c p = new Program__c(Name = 'Test');
		insert p;		
		Campaign camp = new Campaign(Name = 'Test');
		insert camp; 		
		//each acct wlil get an opp
		List<Opportunity> opps = new List<Opportunity>();
		for (Account a : accts) {
			Opportunity opp = new Opportunity(Name = 'Test Donation',
		  									Amount = 200,
                  							AccountId = a.Id,
		  									CloseDate = date.today(),		  
		  									Program__c = p.Id,
		  									CampaignId = camp.id,
		  									Type = 'Business',
		  									StageName = 'Closed Won',
		  									Payment_Method__c = 'Cash');		  
            opps.add(opp);
		}     
		insert opps;
		Test.startTest();
		OrgDonorClassificationRollups.rollupAllOrganizations();
		Test.stopTest();
		List<Account> accs = [select id, Donor_Classification__c from Account];
		System.assertEquals(200, accs.size());
		for (Account a: accs) {
			System.assertEquals('First Time Donor', a.Donor_Classification__c);
		}   
	}
	
	static testMethod void testBatchDonationsBothCurrentAndCustomDate() {		
		//create 200 accounts
		List<Account> accts = new List<Account>();
		for (Integer i=0; i<200; i++) {
        	Account acc = new Account(Name='Test Org'+i, Type='Business');
        	accts.add(acc);
		}
	   	insert accts;	   		   		   		
		Program__c p = new Program__c(Name = 'Test');
		insert p;		
		Campaign camp = new Campaign(Name = 'Test');
		insert camp; 		
		//each acct wlil get an opp
		List<Opportunity> opps = new List<Opportunity>();
		for (Account a : accts) {
			Opportunity opp = new Opportunity(Name = 'Test Donation',
		  									Amount = 200,
                  							AccountId = a.Id,
		  									CloseDate = date.today().addYears(-2),		  
		  									Program__c = p.Id,
		  									CampaignId = camp.id,
		  									Type = 'Business',
		  									StageName = 'Closed Won',
		  									Payment_Method__c = 'Cash');		  
            opps.add(opp);
		}     
		insert opps;
		Test.startTest();
		Date custDate = date.today().addYears(-2);
		Datetime batchTime = datetime.now();
		OrgDonorClassificationRollups.rollupDonorClass(accts, true, true, custDate, batchTime);
		Test.stopTest();
		List<Account> accs = [select id, Donor_Classification__c, Previous_Year_End_Classification__c, Custom_Date_Donor_Classification__c,
								Custom_Classification_Date__c, Custom_Donor_Classification_Job_Last_Run__c, Donor_Classification_Job_Last_Run__c 
								from Account];
		System.assertEquals(200, accs.size());
		for (Account a: accs) {
			System.assertEquals('Lapsed Donor', a.Donor_Classification__c);
			System.assertEquals('First Time Donor', a.Previous_Year_End_Classification__c);
			System.assertEquals('First Time Donor', a.Custom_Date_Donor_Classification__c);
			System.assertEquals(custDate, a.Custom_Classification_Date__c);
			System.assertEquals(batchTime, a.Custom_Donor_Classification_Job_Last_Run__c);
			System.assertEquals(batchTime, a.Donor_Classification_Job_Last_Run__c);
		}   
	}
	
	static testMethod void testBatchDonationsOnlyCustomDate() {		
		//create 200 accounts
		List<Account> accts = new List<Account>();
		for (Integer i=0; i<200; i++) {
        	Account acc = new Account(Name='Test Org'+i, Type='Business');
        	accts.add(acc);
		}
	   	insert accts;	   		   		   		
		Program__c p = new Program__c(Name = 'Test');
		insert p;		
		Campaign camp = new Campaign(Name = 'Test');
		insert camp; 		
		//each acct wlil get an opp
		List<Opportunity> opps = new List<Opportunity>();
		for (Account a : accts) {
			Opportunity opp = new Opportunity(Name = 'Test Donation',
		  									Amount = 200,
                  							AccountId = a.Id,
		  									CloseDate = date.today().addYears(-2),		  
		  									Program__c = p.Id,
		  									CampaignId = camp.id,
		  									Type = 'Business',
		  									StageName = 'Closed Won',
		  									Payment_Method__c = 'Cash');		  
            opps.add(opp);
		}     
		insert opps;
		Test.startTest();
		Date custDate = date.today().addYears(-2);
		Datetime batchTime = datetime.now();
		OrgDonorClassificationRollups.rollupDonorClass(accts, false, true, custDate, batchTime);
		Test.stopTest();
		List<Account> accs = [select id, Donor_Classification__c, Previous_Year_End_Classification__c, Custom_Date_Donor_Classification__c,
								Custom_Classification_Date__c, Custom_Donor_Classification_Job_Last_Run__c, Donor_Classification_Job_Last_Run__c 
								from Account];
		System.assertEquals(200, accs.size());
		for (Account a: accs) {
			System.assertEquals(null, a.Donor_Classification__c);
			System.assertEquals(null, a.Previous_Year_End_Classification__c);
			System.assertEquals('First Time Donor', a.Custom_Date_Donor_Classification__c);
			System.assertEquals(custDate, a.Custom_Classification_Date__c);
			System.assertEquals(batchTime, a.Custom_Donor_Classification_Job_Last_Run__c);
			System.assertEquals(null, a.Donor_Classification_Job_Last_Run__c);
		}   
	}
	
	static testMethod void testClearOutDonations() {               
        Test.startTest();
        Account acc = new Account(Name='Test Org', Type='Business');
	   	insert acc;
		System.assertEquals(acc.Donor_Classification__c, null);	
		Program__c p = new Program__c(Name = 'Test');
		insert p;		
		Campaign camp = new Campaign(Name = 'Test');
		insert camp;                
        
        Date aYearAgo = Date.today().addDays(-365);                     
        Opportunity opp = new Opportunity(Name = 'Test Donation',
		  									Amount = 200,
                  							AccountId = acc.Id,
		  									CloseDate = aYearAgo,		  
		  									Program__c = p.Id,
		  									CampaignId = camp.id,
		  									Type = 'Business',
		  									StageName = 'Closed Won',
		  									Payment_Method__c = 'Cash');		  
        insert(opp);
        
        Account a = [select Donor_Classification__c, Previous_Donor_Classification__c,
							Donor_Classification_Transition_Date__c, Always_classify_as_Major_Donor__c 
							from Account where id =:acc.id];	      		
		System.assert(a.Donor_Classification__c.contains('First Time Donor'));
        
        opp = new Opportunity(Name = 'Test Donation',
		  									Amount = 200,
                  							AccountId = acc.Id,
		  									CloseDate = aYearAgo,		  
		  									Program__c = p.Id,
		  									CampaignId = camp.id,
		  									Type = 'Business',
		  									StageName = 'Closed Won',
		  									Payment_Method__c = 'Cash');		  
        insert(opp);
        
        a = [select Donor_Classification__c, Previous_Donor_Classification__c,
							Donor_Classification_Transition_Date__c, Always_classify_as_Major_Donor__c 
							from Account where id =:acc.id];	      		
		
		System.assert(a.Donor_Classification__c.contains('First Year Donor'));
		
		//insert an older donation - should change the classification to renewing donor
		opp = new Opportunity(Name = 'Test Donation',
		  									Amount = 200,
                  							AccountId = acc.Id,
		  									CloseDate = aYearAgo.addYears(-1),		  
		  									Program__c = p.Id,
		  									CampaignId = camp.id,
		  									Type = 'Business',
		  									StageName = 'Closed Won',
		  									Payment_Method__c = 'Cash');		  
        insert(opp);
        
        a = [select Donor_Classification__c, Previous_Donor_Classification__c,
							Donor_Classification_Transition_Date__c, Always_classify_as_Major_Donor__c 
							from Account where id =:acc.id];	      		
		System.assertEquals('Renewing Donor', a.Donor_Classification__c);
		
		//delete all donations
		delete [select id from Opportunity];
		a = [select Donor_Classification__c, Previous_Donor_Classification__c,
							Donor_Classification_Transition_Date__c, Always_classify_as_Major_Donor__c 
							from Account where id =:acc.id];	      		
		System.assertEquals(null, a.Donor_Classification__c);
               
        Test.stopTest();               
	}
	
	
}