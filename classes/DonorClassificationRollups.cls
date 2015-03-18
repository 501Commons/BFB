/**
* Author: Patrick Tewson - NPower NW - 2012
* Utility class used by Donor Classification rollups and DonorClassificationRollups trigger.
* This attempts to realize the behavior for donor classification described in the BFB Donor
* Stewardship plan, original date July 18, 2012
*/

public with sharing class DonorClassificationRollups {

        static Integer numberSOQL = 0;

	/**
	* The general contract I'm attempting to adhere to is that the new donor
	* class depends only on the donation history of the contact, NOT the previous 
	* donor state. This will make the whole system more reliable and mean that calling
	* this class on all the contacts can set the correct donor class independent of 
	* initial conditions.
	**/
        /*
	public static void rollupAllContacts() {
		// nothing yet
		Integer batchSize = 200;

                BATCH_DonorClassRollups batch = new BATCH_DonorClassRollups
        	     ('select id, Always_classify_as_Major_Donor__c, Donor_Classification__c from Contact');

                id batchProcessId = database.executeBatch(batch, batchSize);  
	}	


	public static void rollupDonorClass(List<Contact> contacts) {
                List<Id> cids = new List<Id>();
                for(Contact c: contacts) {
                     cids.add(c.id);
                }

                // get all the opportunitycontactroles related to these contacts
                List<OpportunityContactRole> ocrs = [SELECT OpportunityId, ContactId from OpportunityContactRole where ContactId =: cids and IsPrimary = True];
                numberSOQL++;

                List<Id> oids = new List<Id>();
                for(OpportunityContactRole ocr: ocrs) {
                     oids.add(ocr.OpportunityId);
                }

                // get all the opportunities attached to the above OCRS

                Map<Id,Opportunity> opps = new Map<Id,Opportunity>([SELECT o.AccountID, a.Name, o.id, o.CloseDate, o.RecordTypeId, o.Amount 
                          from Opportunity o, o.Account a where StageName =: 'Closed Won' and id =: oids]);
                numberSOQL++;
                
                // now we have contacts, donations, and opp contact roles but we need to relate the contacts and their opps 
                Map<Contact,List<Opportunity>> contactsAndDonations = new Map<Contact,List<Opportunity>>();
                for(Contact c: contacts) {
                     List<Opportunity> contactOpps = new List<Opportunity>();
                     for(OpportunityContactRole ocr: ocrs) {
                          // find ContactRoles attached to this contact 
                          if(ocr.ContactId == c.Id) {
                               Opportunity o = opps.get(ocr.OpportunityId);
                               if(o != null) {
                                 System.debug('************ '+ o.Account.Name);
                                 contactOpps.add(o);
                               } else {
                                 System.debug('****** Not adding null opp');
                               }
                          }
                     }
                     contactsAndDonations.put(c,contactOpps);
                }

		rollupDonorClass(contactsAndDonations);		
	}


	public static void rollupDonorClass(Set<id> newOppIds) {

		for(id oid: newOppIds) {
			System.debug(' ******** Orig Op ID: '+ oid);
		}

                List<Contact> contacts = [SELECT id, Always_classify_as_Major_Donor__c, Donor_Classification__c from Contact where id in 
			(select ContactId from OpportunityContactRole where OpportunityId =: newOppIds and IsPrimary = True)];
                numberSOQL++;

                rollupDonorClass(contacts);

	}
		
	public static void rollupDonorClass(Map<Contact,List<Opportunity>> contactsAndDonations) {

                List<Contact> contactsToUpdate = new List<Contact>();
			
		// This whole block just debug output

		for(Contact c: contactsAndDonations.keySet()) {
                        String prevDonorClass = c.Donor_Classification__c;
                        if(prevDonorClass == null) prevDonorClass = '';

                        Boolean alwaysMajorDonor = False;
                        if(c.Always_classify_as_Major_Donor__c != null && c.Always_classify_as_Major_Donor__c) alwaysMajorDonor = True;

			// No donations? No classification! Set to blank and move on - unless there's an override
			if(contactsAndDonations.get(c).size() == 0 && !alwaysMajorDonor) {
                                if(!donorClassEquivalent('',prevDonorClass)) {
                                  c.Previous_Donor_Classification__c = prevDonorClass;
                                  c.Donor_Classification_Transition_Date__c = System.now();
                                } 
				c.Donor_Classification__c = '';
                                contactsToUpdate.add(c);
				continue;
			}
			
			Date lastGiftDate = null;
			String currentDonorClass = '';   //c.Donor_Classification__c;
			if(currentDonorClass == null) {
				currentDonorClass = '';
			}
			for(Opportunity o: contactsAndDonations.get(c)) {
				if(lastGiftDate == null) {
					lastGiftDate = o.CloseDate;
				} else if(o.CloseDate > lastGiftDate) {
					lastGiftDate = o.CloseDate;
				}
			}

			Date compareDate = Date.today();
			compareDate = compareDate.addYears(-1);
			
                        if(lastGiftDate != null) {
                          System.debug(' ******* last gift date, compare, diff: '+lastGiftDate + ', '+compareDate +', ' + lastGiftDate.daysBetween(compareDate));
                          if(contactsAndDonations.get(c).size() == 1 && lastGiftDate.daysBetween(compareDate) < 0) {
                            if(!currentDonorClass.contains('First Time Donor')) {
                              currentDonorClass =  'First Time Donor';	
                            }
                          } else if(contactsAndDonations.get(c).size() > 1 && lastGiftDate.daysBetween(compareDate) < 0) {
                            if(!currentDonorClass.contains('Renewing Donor')) {
                              currentDonorClass =  'Renewing Donor';	
                            }
                          } else if(contactsAndDonations.get(c).size() == 1 && lastGiftDate.daysBetween(compareDate) > 0) {
                            if(!currentDonorClass.contains('One Time Donor')) {
                              currentDonorClass = 'One Time Donor';	
                            }
                          } if(contactsAndDonations.get(c).size() > 1) {
                            currentDonorClass = currentDonorClass.replace('First Time Donor','');
                          }

                          // Let's just throw in "Lapsed" as four years w/ no donation for now
                          compareDate = compareDate.addYears(-3);
                          if(lastGiftDate.daysBetween(compareDate) > 0) {
                            if(!currentDonorClass.contains('Lapsed Donor')) {
                              currentDonorClass = 'Lapsed Donor';	
                            }
                          }
                        }

                        Double lastYearGiving = 0;
                        Date todaysDate = Date.today();
		        Date aYearAgo = Date.today().addYears(-1);
                        // override
                        if(!alwaysMajorDonor) {
                          // 'Major Donor' means > 1000 dollars giving in the 12 months preceeding current year
                          //Integer lastYear = todaysDate.year();
                          for(Opportunity opp: contactsAndDonations.get(c)) {
                            //if(opp.closeDate.year() == lastYear) {
                            System.debug(' ********* opp date: '+opp.CloseDate+', a year ago: '+aYearAgo+', today: '+todaysDate);
                            System.debug(' ********* Days between a year ago: '+opp.closeDate.daysBetween(AYearAgo));
                            System.debug(' ********* Days between today: '+opp.closeDate.daysBetween(today));
                            if(opp.closeDate.daysBetween(AYearAgo) < 0 and opp.closeDate.daysBetween(todaysDate) >= 0) {
                              lastYearGiving += opp.Amount;
                              System.debug(' ********* total giving for donor, opp amount: '+lastYearGiving+', '+opp.Amount);
                            }
                          }
                        }
                        if(lastYearGiving > 1000.0 || alwaysMajorDonor) {
  			   if(!currentDonorClass.contains('Major Donor')) {
			     currentDonorClass = currentDonorClass + '; Major Donor';	
			   }
                        } else {
    		           currentDonorClass.replace('Major Donor','');	
                        }
			
			// The "Loyal Donor" class involves donating 5 years in the last 6
			Integer numberYearsDonated = 0;
			// start with last year else things get weird with this incomplete year
			todaysDate = Date.today();
			for(Date aYear = todaysDate.addYears(-1); todaysDate.year() - aYear.year() <= 6; aYear = aYear.addYears(-1)) {
				System.debug(' ******* year, numberYearsDonated: ' + aYear.year()+', '+numberYearsDonated);
				for(Opportunity opp : contactsAndDonations.get(c)) {
					if(opp.CloseDate.year() == aYear.year()) {
						numberYearsDonated++;
						break;
					}
				}
			}
			if(numberYearsDonated >= 5) {
				if(!currentDonorClass.contains('Loyal Donor')) {
					currentDonorClass = currentDonorClass + '; Loyal Donor';
				}
			} else {
				currentDonorClass = currentDonorClass.replace('Loyal Donor','');
			}
			
			// The "Monthly Donor" class involves donating consecutively 3 months w/in the last 6
			todaysDate = Date.today();
			// go back 3 months for the start of reconing
			Boolean isMonthlyDonor = false;
			
			// set up three months of history, we'll be sliding each of these back
			Date oneMonthBack = todaysDate.addMonths(-1);
			Date twoMonthsBack = oneMonthBack.addMonths(-1);
			Date threeMonthsBack = twoMonthsBack.addMonths(-1);
			
			// we are interested in 6 months but the end of our window is only 3 months ago
			while(todaysDate.month() - oneMonthBack.month() <= 3) {
				Boolean hitOneMonthBack = false;
				Boolean hitTwoMonthsBack = false;
				Boolean hitThreeMonthsBack = false;
				
				System.debug(' ******** One month back:    '+oneMonthBack.year()+', '+oneMonthBack.month()+': '+hitOneMonthBack); 
				System.debug(' ******** Two months back:   '+twoMonthsBack.year()+', '+twoMonthsBack.month()+': '+hitTwoMonthsBack);
				System.debug(' ******** Three months back: '+threeMonthsBack.year()+', '+threeMonthsBack.month()+': '+hitThreeMonthsBack);
				// Copy the date, we'll be backing this one up as we identify matches
				for(Opportunity opp : contactsAndDonations.get(c)) {
					// if monnth and year match...
					Integer closeMonth = opp.CloseDate.month();
					Integer closeYear = opp.CloseDate.year();
					System.debug(' ******** Testing opp at: '+closeYear+', '+closeMonth);
					System.debug(' ******** Current donation hits (one,two,three): '+hitOneMonthBack+', '+hitTwoMonthsBack+', '+hitThreeMonthsBack);
					if(closeMonth == oneMonthBack.month() && closeYear == oneMonthBack.year())
						hitOneMonthBack = true;
					if(closeMonth == twoMonthsBack.month() && closeYear == twoMonthsBack.year())
						hitTwoMonthsBack = true;
					if(closeMonth == threeMonthsBack.month() && closeYear == threeMonthsBack.year())
						hitThreeMonthsBack = true; 
					// did we find three consecutive months?
					if(hitOneMonthBack && hitTwoMonthsBack && hitThreeMonthsBack) {
						isMonthlyDonor = true;
						break;
					}
				}
				// if we have already identified donor as monthly, we're done here.
				if(isMonthlyDonor) break;
				
				// if not, slide everything back 1 month and try again
				oneMonthBack = oneMonthBack.addMonths(-1);
				twoMonthsBack = twoMonthsBack.addMonths(-1);
				threeMonthsBack = threeMonthsBack.addMonths(-1);
			}
			if(isMonthlyDonor) {
				if(!currentDonorClass.contains('Monthly Donor')) {
					currentDonorClass = currentDonorClass + '; Monthly Donor';
				}
			} else {
				currentDonorClass = currentDonorClass.replace('Monthly Donor','');
			}
	
			System.debug(' ******* attempting to set donor class: '+currentDonorClass);
			c.Donor_Classification__c = currentDonorClass;

                        System.debug(' ******* Donor class - new, prev ' + currentDonorClass +' '+ prevDonorClass);
                        if(!donorClassEquivalent(currentDonorClass,prevDonorClass)) {
                            c.Previous_Donor_Classification__c = prevDonorClass;
                            c.Donor_Classification_Transition_Date__c = System.now();
                        } 
			//update c;
                        contactsToUpdate.add(c);
		}
                update contactsToUpdate;
                System.debug('********* *I* think I used '+numberSOQL+ ' queries');
	}

        static Boolean donorClassEquivalent(String class1, String class2) {
            Set<String> tokens1 = new Set<String>(); //class1.split(';'));
            Set<String> tokens2 = new Set<String>(class2.split(';'));
            
            for(String token: class1.split(';')) {
              tokens1.add(token.trim());
            }

            if(tokens1.size() != tokens2.size()) return false;

            for(String token: tokens2) {
               if(!tokens1.contains(token.trim())) return false;
            }
            return true;
        }

	static testMethod void testDonorClassificationRollups() {

                Test.startTest();
		Contact c = new Contact(FirstName = 'Test', LastName = 'Testerson');
		insert c;
		
		System.assertEquals(c.Donor_Classification__c, null);
		
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
		
		Contact[] updated = [select id, Always_classify_as_Major_Donor__c, Donor_Classification__c from Contact where id =: c.id];
		System.assertEquals(updated[0].Donor_Classification__c, 'First Time Donor');
		

                // test lapsed donor
                Date today = Date.today();
                o.CloseDate = today.addYears(-5);
                update o;

	        updated = [select id, Always_classify_as_Major_Donor__c, Donor_Classification__c from Contact where id =: c.id];
		System.assertEquals(updated[0].Donor_Classification__c, 'Lapsed Donor');


                // Test Loyal Donor
                today = Date.today();
                List<Opportunity> opps = new List<Opportunity>();
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
		  insert opp;

		  OpportunityContactRole cr = new OpportunityContactRole();
		  cr.ContactId = c.id;
		  cr.OpportunityId = opp.id;
		  cr.IsPrimary = true;
		  insert cr;

		  opp.StageName = 'Closed Won';
		  update opp;
                }
	        updated = [select id, Always_classify_as_Major_Donor__c, Donor_Classification__c from Contact where id =: c.id];
		System.assertEquals(updated[0].Donor_Classification__c.contains('Loyal Donor'), True);


                // test the batch entry point
                List<Contact> contacts = new List<Contact>();
                contacts.add(c);

                rollupDonorClass(contacts);

                Test.stopTest();

                System.debug('********* *I* think I used '+numberSOQL+ ' queries');
	}

	static testMethod void testMonthly() {

                Test.startTest();
		Contact c = new Contact(FirstName = 'Test', LastName = 'Testerson');
		insert c;
		
		System.assertEquals(c.Donor_Classification__c, null);
		
		Program__c p = new Program__c(Name = 'Test');
		insert p;
		
		Campaign camp = new Campaign(Name = 'Test');
		insert camp;

                Account individual = new Account(Name = 'Individual');
                insert individual;

                Date today = Date.today();
                List<Opportunity> opps = new List<Opportunity>();

                // Test Monthly Donor
                today = Date.today();
                opps = new List<Opportunity>();
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
		  insert opp;

		  OpportunityContactRole cr = new OpportunityContactRole();
		  cr.ContactId = c.id;
		  cr.OpportunityId = opp.id;
		  cr.IsPrimary = true;
		  insert cr;

		  opp.StageName = 'Closed Won';
		  update opp;
                }
	        Contact[] updated = [select id, Always_classify_as_Major_Donor__c, Donor_Classification__c from Contact where id =: c.id];
		System.assertEquals(updated[0].Donor_Classification__c.contains('Monthly Donor'), True);


                Test.stopTest();

                System.debug('********* *I* think I used '+numberSOQL+ ' queries');
	}

	static testMethod void testMajor() {

		System.debug(' ******* MAJOR DONOR TEST');

                Test.startTest();
		Contact c = new Contact(FirstName = 'Test', LastName = 'Testerson');
		insert c;
		
		System.assertEquals(c.Donor_Classification__c, null);

		Program__c p = new Program__c(Name = 'Test');
		insert p;
		
		Campaign camp = new Campaign(Name = 'Test');
		insert camp;

                Account individual = new Account(Name = 'Individual');
                insert individual;

                Date today = Date.today();
                List<Opportunity> opps = new List<Opportunity>();

                // Test Monthly Donor
                //today = Date.today().addYears(-1);
                today = Date.today().addDays(-180);
                opps = new List<Opportunity>();
                for(Integer i=0; i<3; i++) {
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
		  insert opp;

                  System.debug(' ******** inserting opp w amount '+opp.Amount);

		  OpportunityContactRole cr = new OpportunityContactRole();
		  cr.ContactId = c.id;
		  cr.OpportunityId = opp.id;
		  cr.IsPrimary = true;
		  insert cr;

		  opp.StageName = 'Closed Won';
		  update opp;
                }
	        Contact[] updated = [select id, Always_classify_as_Major_Donor__c, Donor_Classification__c from Contact where id =: c.id];
		System.assertEquals(updated[0].Donor_Classification__c.contains('Major Donor'), True);

		Contact c2 = new Contact(FirstName = 'Test', LastName = 'Testerson');
                c2.Always_classify_as_Major_donor__c = True;
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

	        updated = [select id, Always_classify_as_Major_Donor__c, Donor_Classification__c from Contact where id =: c2.id];
		System.assertEquals(updated[0].Donor_Classification__c.contains('Major Donor'), True);

                c2.Always_classify_as_Major_donor__c = False;
                update c2;
		opp2.StageName = 'Closed Won';
                // have to update an opp here to get the trigger to fire
                update opp2;
	        updated = [select id, Always_classify_as_Major_Donor__c, Donor_Classification__c from Contact where id =: c2.id];
                if(updated[0].Donor_Classification__c != null) {
                  System.assertEquals(updated[0].Donor_Classification__c.contains('Major Donor'), False);
                }

                Test.stopTest();

                System.debug('********* *I* think I used '+numberSOQL+ ' queries');
	}

	static testMethod void testDonorClassEquivalency() {
            String s1 = 'Monthly Donor; Renewing Donor';
            String s2 = 'Renewing Donor; Monthly Donor';
            String s3 = 'Renewing Donor; Monthly Donor; Lapsed Donor';
            String s4 = 'Renewing DOnor; Lapsed Donor';
            
            System.assertEquals(donorClassEquivalent(s1,s2), true);
            System.assertEquals(donorClassEquivalent(s1,s3), false);
            System.assertEquals(donorClassEquivalent(s1,s4), false);
          
        }
        */
}