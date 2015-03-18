public with sharing class CNTL_CampaignInvitation {
	public List<Contact> filteredContacts { get; set; } 

        public Boolean loadedContacts { get; set; }
        public Boolean loadedCampaignMembers { get; set; }
        public Boolean hasExcludedCampaigns { get; set; }

        public Integer givingLevel { get; set; }
	public String donorClassification { get; set; }

        public CampaignMember targetCampaignMember { get; set; }
        public String targetCampaignName { get; set; }
        public String campaignMemberStatus { get; set; } 

        public CampaignMember excludeCampaign { get; set; }
        public Map<Id,Campaign> excludeMembersOfTheseCampaigns { get; set; }

        public List<CMTableRow> campaignMemberRows { get; set; }
        public List<ContactRow> potentialInvitees { get; set; }
        public List<CMSRow>     excludedCMS { get; set; }

	public String errorMessage { get; set; }

        // have to store dates in an SObject? Tres annoying
        public Contact lastGiftDate { get; set; }

        public class CMSRow implements Comparable {

          public String status { get; set; }
          public Boolean selected { get; set; }

          public CMSRow(String s) {
            selected = false;
            status = s;
          }

          public Integer compareTo(Object compareTo) {
            return status.compareTo(((CMSRow)compareTo).status);
          }
        }

        public class ContactRow implements Comparable {
                public Contact theContact { get; set; }
                public Boolean selected { get; set; }

                public ContactRow(Contact c) {
                  theContact = c;
                  selected = false;
                }
                public Integer compareTo(Object compareTo) {
                  ContactRow compareToRow = (ContactRow)compareTo;
                  return theContact.LastName.compareTo(compareToRow.theContact.LastName);
                }
        }

        public class CMTableRow implements Comparable {
                public Contact theContact { get; set; }
                public CampaignMember theCampaignMember { get; set; }

                public CMTableRow(CampaignMember cm, Contact c) {
                        theCampaignMember = cm;
                        theContact = c;
                }

                public Integer compareTo(Object compareTo) {
                  CMTableRow compareToRow = (CMTableRow)compareTo;
                  return theContact.LastName.compareTo(compareToRow.theContact.LastName);
                }
        }


        public CNTL_CampaignInvitation() {
            lastGiftDate = new Contact(Birthdate = Date.newInstance(1900,1,1));
            loadedContacts = False;
            givingLevel = 250;
            donorClassification = 'All';

            errorMessage = '';

            targetCampaignMember = new CampaignMember();
            campaignMemberRows = new List<CMTableRow>();
            excludedCMS = new List<CMSRow>();
            hasExcludedCampaigns = false;

            excludeCampaign = new CampaignMember();
            excludeMembersOfTheseCampaigns = new Map<Id,Campaign>();
        }

        public PageReference addToExcludeList() {
          Campaign newExclude = [SELECT Name, Id from Campaign WHERE Id =: excludeCampaign.CampaignId];
          excludeMembersOfTheseCampaigns.put(excludeCampaign.CampaignId, newExclude);
          for(Id cid: excludeMembersOfTheseCampaigns.keySet()) {
            System.debug(' ***** Adding to excludedCampaigns: Id='+cid+', Name='+excludeMembersOfTheseCampaigns.get(cid));
          }

          // add new options for campign member statuses for options to exclude
          List<CampaignMemberStatus> cmss = [SELECT Id, label FROM CampaignMemberStatus WHERE CampaignId =: excludeCampaign.CampaignId];
          for(CampaignMemberStatus cms: cmss) {
            Boolean alreadyInList = false;
            for(CMSRow row: excludedCMS) {
              if(row.status == cms.label) {
                alreadyInList = true;
                break;
              }
            }
            if(!alreadyInList) {
              excludedCMS.add( new CMSRow(cms.label) );
            }
          }
          return invokeService();
        }

	public PageReference invokeService() { 
                System.debug('***************** Calling Invoke Service ' + targetCampaignMember.CampaignId);
                potentialInvitees = new List<ContactRow>();

                Campaign target = [select Name from Campaign where Id =: targetCampaignMember.CampaignId LIMIT 1];
                targetCampaignName = target.Name;
                System.debug('********** Target Campaign Name: '+targetCampaignName);

                if(donorClassification == null) donorClassification = '';

                List<CampaignMember> currentCampaignMembers = [select Id, Status, ContactId, CampaignId from CampaignMember where CampaignId =: targetCampaignMember.CampaignId LIMIT 500];
                List<Id> cids = new List<Id>();
                for(CampaignMember cm: currentCampaignMembers) {
                  cids.add(cm.ContactId);
                }
                Map<Id,Contact> currentContactsInCampaign = new Map<Id,Contact>([select Id, FirstName, LastName from Contact where Id =: cids]);


                campaignMemberRows = new List<CMTableRow>();
                for(CampaignMember cm: currentCampaignMembers) {
                  campaignMemberRows.add( new CMTableRow( cm, currentContactsInCampaign.get(cm.ContactId) ) );
                }

                List<String> excludedCMStatuses = new List<String>();
                for(CMSRow row: excludedCMS) {
                  if(row.selected) excludedCMStatuses.add(row.status);
                }

                Set<Id> excludedCampaignIds = excludeMembersOfTheseCampaigns.keySet();
                String cmQuery = 'SELECT ContactId, Status FROM CampaignMember WHERE CampaignId = :excludedCampaignIds';

                if(excludedCMStatuses.size() > 0) cmQuery += ' AND Status = :excludedCMStatuses';

                System.debug(' ***** Query for excluded Campaign Members: '+cmQuery);
                CampaignMember[] excludeCMs = Database.query(cmQuery);
                for(CampaignMember cm: excludeCMS) {
                  cids.add(cm.ContactId);
                }

                String queryString = '';
                queryString += 'select c.Name, c.LastName, c.Id, c.email, c.Phone, c.MailingStreet, c.MailingCity, c.MailingState, c.MailingPostalCode, ';
                queryString += 'c.Donor_Classification__c, c.npo02__Total_Household_Gifts__c, c.npo02__Household__c, c.Most_Recent_Recognition_Call_Date__c, h.Name ';
                queryString += 'from Contact c, c.npo02__Household__r h ';

                Integer i = 0;
                donorClassification = donorClassification.replace('[','');
                donorClassification = donorClassification.replace(']','');
                if(!donorClassification.equals('All') && !donorClassification.equals('')) {
                  String[] donorClassifications = donorClassification.split(', ',0);
                  queryString += 'where ';
                  if(donorClassifications.size() > 1) queryString += '(';
                  for(String donorClass: donorClassifications) {
                    i++;
                    queryString += 'c.Donor_Classification__c like \'%'+donorClass+'%\' ';
                    if(i < donorClassifications.size()) queryString += 'or ';
                    else if(donorClassifications.size() == 1) {
                      queryString += ' and ';
                    } else {
                      queryString += ') and ';
                    }
                  }
                } else {
                  queryString += 'where ';
                }

                Date filterLastGift = lastGiftDate.BirthDate;
                if(lastGiftDate.BirthDate.Year() > 1900) {
                  queryString += 'c.npo02__LastCloseDateHH__c >= :filterLastGift AND ';
                }
                queryString += 'c.npo02__Total_Household_Gifts__c >=: givingLevel AND c.Id NOT IN :cids ORDER BY c.LastName LIMIT 500';

                System.debug(' ********* QUERY: '+queryString);
                filteredContacts = Database.query(queryString);
                for(Contact c: filteredContacts) {
                  potentialInvitees.add(new ContactRow(c));
                }


                if(potentialInvitees.size() > 0) {
                  loadedContacts = true;
                } else {
                  loadedContacts = false;
                }

                if(campaignMemberRows.size() > 0) {
                  loadedCampaignMembers = true;
                } else {
                  loadedCampaignMembers = false;
                }

                if(excludeMembersOfTheseCampaigns.keySet().size() > 0) {
                  hasExcludedCampaigns = True;
                } else {
                  hasExcludedCampaigns = False;
                }

		return null; 
	}
	
	public PageReference addToCampaign() { 

          try {
            List<CampaignMember> cms = new List<CampaignMember>();
            for(ContactRow row: potentialInvitees) {
              if(row.selected) {
                CampaignMember cm = new CampaignMember(ContactId = row.theContact.Id, CampaignId = targetCampaignMember.CampaignId, Status = campaignMemberStatus);
                System.debug(' ***** CM STATUS: '+cm+', '+campaignMemberStatus);
                cms.add(cm);
              }
            }
            insert cms;
	    return invokeService();
          } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
          }

          return invokeService();
	}

        public List<Campaign> getExcludedCampaigns() {
          return excludeMembersOfTheseCampaigns.values();
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

 	public List<SelectOption> getCMStatuses() {
                List<CampaignMemberStatus> cms = [SELECT id, label FROM CampaignMemberStatus where CampaignId =: targetCampaignMember.campaignID LIMIT 20];
		List<SelectOption> options = new List<SelectOption>();
		for(CampaignMemberStatus cm: cms)
			options.add(new SelectOption(cm.Label,cm.Label));
		return options;
	}

        public Integer getNumberOfPotentialInvitees() {
          return potentialInvitees.size();
        }

        public Integer getNumberOfCurrentInvitees() {
          return campaignMemberRows.size();
        }

        public String getExcludedStatusesAsString() {
          String response = '';
          List<String> selected = new List<String>();
          for(CMSRow row: excludedCMS) {
            if(row.selected) selected.add(row.status);
          }
          
          Integer index = 0;
          for(String status: selected) {
            response+= status;
            if(index < selected.size()-1) response+=', ';
            index++;
          }
          return response;
        }

	static testMethod void testController() {
            Test.startTest();

            Campaign newCampaign = new Campaign(Name='New Test Campaign', IsActive=true);
            Campaign oldCampaign = new Campaign(Name='Old Test Campaign', IsActive=true);
            insert newCampaign;
            insert oldCampaign;

            CampaignMemberStatus s1 = new CampaignMemberStatus(Label='Invited',CampaignId=oldCampaign.Id, SortOrder=0);
            CampaignMemberStatus s2 = new CampaignMemberStatus(Label='Attending',CampaignId=oldCampaign.Id, SortOrder=1);
            insert s1;
            //insert s2;

            Account individual = new Account(Name = 'Individual');
            insert individual;
            
            npo02__Household__c hh = new npo02__Household__c(Name='Testerson Household');
            insert hh;

            Contact alice = new Contact(FirstName='Alice', LastName='Andrews', npo02__Household__c = hh.id);
            Contact bob = new Contact(FirstName='Bob', LastName='Barker', npo02__Household__c = hh.id);
            Contact charlie = new Contact(FirstName='Charlie', LastName='Carver', npo02__Household__c = hh.id);
            List<Contact> contacts = new List<Contact>();
            contacts.add(alice);
            contacts.add(bob);
            contacts.add(charlie);
            insert contacts;

	    Program__c p = new Program__c(Name = 'Test');
	    insert p;
	    
	    Campaign camp = new Campaign(Name = 'Test');
	    insert camp; 

            for(Contact c: contacts) {
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
            }


            Test.stopTest();

            CNTL_CampaignInvitation pageController = new CNTL_CampaignInvitation();
            pageController.givingLevel = 0;
            pageController.targetCampaignMember.CampaignId = newCampaign.Id;
            pageController.invokeService();

            List<Contact> cs = [select Id,FirstName,LastName,npo02__LastCloseDateHH__c,npo02__Household__c from Contact];
            for(Contact c: cs) {
              System.debug(' ******* Last gift date: '+c.npo02__Household__c +' '+c.npo02__LastCloseDateHH__c);
            }

            System.assertEquals(pageController.potentialInvitees.size(),3);
            System.assertEquals(pageController.getCMStatuses().size(), 0);

            pageController.potentialInvitees.get(0).selected = true;
            pageController.addToCampaign();
            System.assertEquals(pageController.potentialInvitees.size(),2);

            CampaignMember cm2 = new CampaignMember(ContactId=bob.Id, CampaignId=oldCampaign.Id);
            insert cm2;
            pageController.excludeCampaign.CampaignId = oldCampaign.Id;
            pageController.addToExcludeList();

            System.assertEquals(pageController.potentialInvitees.size(),1);

            String excludedStatuses = pageController.getExcludedStatusesAsString();
            System.assertEquals('',excludedStatuses);
            
            System.assertEquals(1,pageController.getExcludedCampaigns().size());

            System.assertEquals(pageController.getNumberOfPotentialInvitees(), 1);
            System.assertEquals(pageController.getNumberOfCurrentInvitees(), 1);

	}
}