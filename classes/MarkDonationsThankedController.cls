public with sharing class MarkDonationsThankedController {
	public List<TableRow> tableRows { get; set; }
	public List<Contact> allStewardedContacts { get; set; } 
	public List<Account> allStewardedAccounts { get; set; } 
	public List<OrgTableRow> orgTableRows { get; set; }

    public Boolean loadedDonations { get; set; }
    public Boolean filterBlankPhone { get; set; }


    public string donationAmount { get; set; }
	public String donorSteward;
	public String donorClassification { get; set; }
    public String recordTypeName { get; set; }
        

	public String errorMessage { get; set; }
	

	public class TableRow implements Comparable {
		public Contact theContact { get; set; }
		public Opportunity theDonation { get; set; }	
	
		public TableRow(Opportunity o, Contact c) {
			theDonation = o;
			theContact = c;
		}
		 
		public void updateThis() {
			//update theContact;
			update theDonation; 
		}
	
	    public Integer compareTo(Object compareTo) {
	      TableRow compareToRow = (TableRow)compareTo;
	      return theContact.LastName.compareTo(compareToRow.theContact.LastName);
	      //return 0;
	    }
	}

	public class OrgTableRow implements Comparable {
		public Account theAccount { get; set; }
		public Opportunity theDonation { get; set; }	
	
		public OrgTableRow(Opportunity o, Account a) {
			theDonation = o;
			theAccount = a;
		}
		 
		public void updateThis() {
			update theDonation; 
		}

        public Integer compareTo(Object compareTo) {
            OrgTableRow compareToRow = (OrgTableRow)compareTo;
            return theAccount.Name.compareTo(compareToRow.theAccount.Name);
        }
	}
	 

    public MarkDonationsThankedController() {
        loadedDonations = False;
        filterBlankPhone = True;
        donationAmount = '0';
        donorSteward = '';
        donorClassification = 'All';
        errorMessage = '';
        recordTypeName = 'Donation';
    }

	public String getDonorSteward() {
		return donorSteward;  
	}
	
	public void setDonorSteward(String donorSteward) {
		this.donorSteward = donorSteward;
	}
	
	public String getInfo(){
		return 'this is REALLY the controller text';
	}
	
	public PageReference invokeService() { 
        System.debug('***************** Calling Invoke Service');

        // Handle all the contact donations
		Opportunity[] donations;
 		// opp ID and corresponding contact ID
		Map<Id, Id> donorContactIDMap = new Map<Id, Id>();
		// contact ID and corresponding contact
		Map<Id, Contact> contactMap = new Map<Id, Contact>();
                if(donorClassification == null) donorClassification = '';
		//String donorSteward = System.currentPageReference().getParameters().get('donorsteward');

                Id recordTypeId = getRecordTypeId(recordTypeName, 'Opportunity');

                String queryString = '';

                queryString = 'select o.AccountId, a.Name, o.Name, o.Id, o.CloseDate, o.Amount, o.StageName, o.Donor_Called__c, o.No_Call_Needed__c, o.Called_Left_Message__c, o.Program__c, ';
                queryString += '(select OpportunityId, IsPrimary from OpportunityContactRoles where IsPrimary = True) from Opportunity o, o.Account a ';
                queryString += 'where Opportunity.Donor_Called__c != True and Opportunity.No_Call_Needed__c != True and Opportunity.Called_Left_Message__c != True and Opportunity.RecordTypeID =: recordTypeId and (a.Name = \'Individual\' or o.AccountId = null) ';
                queryString += 'and o.Amount >= '+donationAmount +' and o.StageName = \'Closed Won\' and id in ';
                queryString += '(Select OpportunityId from OpportunityContactRole where ContactId != \'\' and ';

                if(filterBlankPhone) queryString += 'Contact.Phone != \'\' and ';

                queryString += 'Contact.Contact_Preference__c != \'No Contact\' and Contact.Contact_Preference__c != \'No Calls\' and Contact.Deceased__c != true and ';
                System.debug(' ********* Donor Classification Multi-Select results: '+donorClassification);

                Integer i = 0;
                donorClassification = donorClassification.replace('[','');
                donorClassification = donorClassification.replace(']','');
                if(!donorClassification.equals('All') && !donorClassification.equals('')) {
                  queryString += '(';
                  String[] donorClassifications = donorClassification.split(', ',0);
                  for(String donorClass: donorClassifications) {
                    i++;
                    queryString += 'Contact.Donor_Classification__c like \'%'+donorClass+'%\' ';
                    if(i < donorClassifications.size()) queryString += 'or ';
                    else queryString += ') and ';
                  }
                }

                queryString += 'Contact.Donor_Steward__c =: donorSteward) LIMIT 30';

                System.debug(' ********* QUERY: '+queryString);

                donations = Database.query(queryString);

		for(Opportunity opp: donations) {
			donorContactIDMap.put(opp.id, null);
		}
		for(OpportunityContactRole ocr: [select ContactID, OpportunityID, IsPrimary from OpportunityContactRole 
		    where IsPrimary = True and OpportunityContactRole.OpportunityId in :donorContactIDMap.keySet()]) {
			donorContactIDMap.put(ocr.OpportunityID, ocr.ContactId);				
		}
			
                for(Contact c: [select c.Name, c.LastName, c.Id, c.email, c.Phone, c.MailingStreet, c.MailingCity, c.MailingState, c.MailingPostalCode, c.Donor_Classification__c, c.npo02__Household__c, c.Most_Recent_Recognition_Call_Date__c, h.Name
		    from Contact c, c.npo02__Household__r h where id in :donorContactIdMap.values() ORDER BY c.LastName LIMIT 200]) {
			contactMap.put(c.id, c);
		}
		
		//if(!donorSteward.equals('')) {
		if(donorSteward != null) {
			allStewardedContacts = [select c.Name, c.Id, c.email, c.Phone, c.MailingStreet, c.MailingCity, c.MailingState, c.MailingPostalCode, c.Donor_Classification__c, c.npo02__Household__c, c.Most_Recent_Recognition_Call_Date__c, h.Name, c.npo02__LastCloseDate__c, c.npo02__LastOppAmount__c
				from Contact c, c.npo02__Household__r h where Donor_Steward__c =: donorSteward ORDER BY c.LastName LIMIT 200];
		} else {
			allStewardedContacts = null;
		}
		List<TableRow> rows = new List<TableRow>();
		for(Opportunity o: donations) {
			rows.add(new TableRow(o, contactMap.get(donorContactIDMap.get(o.id))));
		}
                rows.sort();
		tableRows = rows;
		


		// account ID and corresponding account
                Map<Id,Account> accounts = new Map<Id,Account>();
                if(filterBlankPhone) {
                  accounts = new Map<Id,Account>([select Id, Name, Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode, Most_Recent_Recognition_Call_Date__c, 
                  								Informal_Contact_Name__c, Donor_Classification__c 
                    from Account where Name != 'Individual' and Phone != '' and Donor_Steward__c =: donorSteward ORDER BY Name LIMIT 100]);
                } else {
                  accounts = new Map<Id,Account>([select Id, Name, Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode, Most_Recent_Recognition_Call_Date__c, 
                  								Informal_Contact_Name__c, Donor_Classification__c 
                    from Account where Name != 'Individual' and Donor_Steward__c =: donorSteward ORDER BY Name LIMIT 100]);
                }
                Set<Id> keys = accounts.keySet();

                // opp ID and the corresponding opp 
                String orgQueryString = 'select Id, AccountId, Name, CloseDate, Amount, StageName, Donor_Called__c, ';
                	   orgQueryString +='No_Call_Needed__c, Called_Left_Message__c from Opportunity ';
                	   orgQueryString += 'where Donor_Called__c != True and RecordTypeId =: recordTypeId and No_Call_Needed__c != True';
                	   orgQueryString += ' and Called_Left_Message__c != True and StageName = \'Closed Won\' and AccountId =: keys ';
                	   orgQueryString += 'and Amount >= '+donationAmount;
                
                i = 0;               
                if(!donorClassification.equals('All') && !donorClassification.equals('')) {
                  orgQueryString += ' and (';
                  String[] donorClassifications = donorClassification.split(', ',0);
                  for(String donorClass: donorClassifications) {
                    i++;
                    orgQueryString += 'Account.Donor_Classification_Formula__c like \'%'+donorClass+'%\' ';
                    if(i < donorClassifications.size()) orgQueryString += 'or ';
                    else orgQueryString += ') ';
                  }
                }
                
                orgQueryString += 'ORDER BY Name LIMIT 100';
                //System.debug('DEBUG >>> sql for account is '+orgQueryString);

                Map<Id,Opportunity> orgDonations = new Map<Id,Opportunity>((List<Opportunity>)Database.query(orgQueryString));

                // build up the map connecting things
                List<OrgTableRow> orows = new List<OrgTableRow>();
                for(Id oid: orgDonations.keySet()) {
                    orows.add(new OrgTableRow(orgDonations.get(oid), accounts.get((orgDonations.get(oid)).AccountId)));
                }
                orows.sort();
                orgTableRows = orows;

                allStewardedAccounts = new List<Account>();
                if(donorSteward != null) {
                    for(Id aid: accounts.keySet()) {
                        allStewardedAccounts.add(accounts.get(aid));
                    }
                }

                if(tableRows.size() > 0 || orgTableRows.size() > 0) loadedDonations = True;
                else loadedDonations = False;

		return null; 
	}
	
	public PageReference markThanked() { 
          try {
            List<Opportunity> opps = new List<Opportunity>();
	    for(TableRow row: tableRows) {
              opps.add(row.theDonation);
            }
            update opps;
            
            opps = new List<Opportunity>();
	    for(OrgTableRow row: orgTableRows) {
              opps.add(row.theDonation);
            }
            update opps;
            
	    return invokeService();
          } catch (Exception e) {
            //errorMessage = e.getMessage();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
          }
	}
		
        public Id getRecordTypeId(String RecordTypeName, String CurrentObjectName) {
          RecordType[] thisRecordType = [Select Id from RecordType where Name=:RecordTypeName and IsActive=true and SobjectType=:CurrentObjectName];
          if (thisRecordType.size()>0) {
            return thisRecordType[0].Id;
          } else {
            return null;
          }
        }

        public Set<String> getRecordTypeNames(String CurrentObjectName) {
          RecordType[] recordTypes = [Select Id, Name from RecordType where IsActive=true and SobjectType=:CurrentObjectName];
          Set<String> names = new Set<String>();
          for(RecordType rt: recordTypes) {
            names.add(rt.Name);
          }
          return names;
        }
        
        public List<SelectOption> getRecordTypeOptions() {
	  List<SelectOption> options = new List<SelectOption>();
          Set<String> rtNames = getRecordTypeNames('Opportunity');
          for(String name: rtNames) {
            options.add(new SelectOption(name, name));
          }
          return options;
        }

	public List<SelectOption> getDonationAmounts() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('0','-'));
		options.add(new SelectOption('50','$50'));
		options.add(new SelectOption('100','$100'));
		options.add(new SelectOption('250','$250'));
		options.add(new SelectOption('500','$500'));
		options.add(new SelectOption('1000','$1000'));
		return options;
	}

	public List<SelectOption> getDonorStewards() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('None','Select your name'));
		options.add(new SelectOption('','No Specified Donor Steward'));
		Schema.DescribeFieldResult fieldResult = Contact.Donor_Steward__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for(Schema.PicklistEntry p : ple)
			options.add(new SelectOption(p.getValue(),p.getValue()));
		return options;
	}

	public List<SelectOption> getDonorClassifications() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('All','All donor classifications'));
		//options.add(new SelectOption('','None'));
		Schema.DescribeFieldResult fieldResult = npo02__Household__c.Donor_Classification__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for(Schema.PicklistEntry p : ple)
			options.add(new SelectOption(p.getValue(),p.getValue()));
		return options;
                //return new List<SelectOption>();
	}
	
	static testMethod void testController() {
            Test.startTest();

            Contact c1 = new Contact(FirstName='Patrick', LastName='Tewson', Donor_Steward__c = 'Bob');
            Contact c2 = new Contact(FirstName='Joseph', LastName='Stalin', Donor_Steward__c = 'Bob');

            insert c1;
            insert c2;

            Opportunity opp1 = new Opportunity(Name='opp', npe01__Contact_Id_for_Role__c=c1.id, StageName='Closed Won', CloseDate=Date.Today());
            Opportunity opp2 = new Opportunity(Name='opp', npe01__Contact_Id_for_Role__c=c2.id, StageName='Closed Won', CloseDate=Date.Today());
            
            insert opp1;
            insert opp2;
            
            Account o1 = new Account(Name='Test Org 1', Donor_Steward__c='Bob');
            insert o1;
            Account o2 = new Account(Name='Test Org 2', Donor_Steward__c='Bob');
            insert o2;
            
            Opportunity opp3 = new Opportunity(Name='opp3', AccountId=o1.id, StageName='Closed Won', CloseDate=Date.Today(), Amount=1000);
            insert opp3;
            
            Opportunity opp4 = new Opportunity(Name='opp4', AccountId=o2.id, StageName='Closed Won', CloseDate=Date.Today(), Amount=5000);
            insert opp4;

            MarkDonationsThankedController mdtc = new MarkDonationsThankedController();
            //mdtc.getDonations();
            //mdtc.getDonorStewards();

            mdtc.setDonorSteward('bob');
                        
            List<SelectOption> options = mdtc.getDonorStewards();
            
            mdtc.invokeService();
            System.assertEquals('bob',mdtc.getDonorSteward());
            
            mdtc.donorClassification = 'All';
            mdtc.invokeService();
            
            mdtc.donorClassification = 'First Time Donor';
            mdtc.invokeService();
            
            mdtc.markThanked();            
            Test.stopTest();	                                    
            
            List<SelectOption> dclassif = mdtc.getDonorClassifications();            
            System.assertEquals('All donor classifications', dclassif.get(0).getLabel());   
            
            List<SelectOption> donationAmounts = mdtc.getDonationAmounts();
            System.assertEquals(6, donationAmounts.size());
                
            TableRow arow = new TableRow(opp1, c1);
            TableRow brow = new TableRow(opp2, c2);                        
            System.assertEquals(arow.compareTo(brow), 1);
            
            OrgTableRow orgARow = new OrgTableRow(opp3, o1);
			OrgTableRow orgBRow = new OrgTableRow(opp4, o2);
			System.assertEquals(1, orgBRow.compareTo(orgARow));
	}
}