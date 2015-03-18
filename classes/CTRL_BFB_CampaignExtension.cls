public class CTRL_BFB_CampaignExtension {

    private final Campaign camp;
    public String campaignName {get; set;}
    private List<CampaignMember> cms;
    private List<CampaignMemberStatus> cmstatuses;
 
    public String sortMethod {get; set;}

    // The extension constructor initializes the private member
    public CTRL_BFB_CampaignExtension(ApexPages.StandardController stdController) {
        this.camp = (Campaign)stdController.getRecord();
        cms = new List<CampaignMember>();
        campaignName = [SELECT Name FROM Campaign WHERE id =: camp.Id LIMIT 1].Name;
        cmstatuses = [SELECT Label, Id FROM CampaignMemberStatus WHERE CampaignId =: camp.Id];
        sortMethod = 'Contact.Household_Informal_Name__c';
    }

    public void updateCampaignMembers() {
      update cms;
    }

   public List<Schema.FieldSetMember> getFields() {
        return SObjectType.CampaignMember.FieldSets.BetterCampaignMemberManagementFields.getFields();
    }

   public List<CampaignMember> getCampaignMembers() {
        String query = 'SELECT ';
        for(Schema.FieldSetMember f : this.getFields()) {
            query += f.getFieldPath() + ', ';
        }
        Id campid = camp.id;
        query += 'Id, Contact.LastName, Status FROM CampaignMember WHERE CampaignId =: campid ORDER BY ' + sortMethod + ' LIMIT 500';
        cms = (List<CampaignMember>)Database.query(query);
        return cms;
    }

    public List<SelectOption> getCMStatuses() {
	List<SelectOption> options = new List<SelectOption>();
	for(CampaignMemberStatus status: cmstatuses) {
	   options.add(new SelectOption(status.Label, status.Label));
        }
	return options;
    }

    public List<SelectOption> getSortOptions() {
	List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Contact.Household_Informal_Name__c','Household Informal Name'));
        options.add(new SelectOption('Contact.LastName','Last Name'));
        options.add(new SelectOption('Status', 'Status'));
	return options;
    }

    static testMethod void testStatuses() {
      Campaign c = new Campaign(Name='Test');
      insert c;
      CampaignMemberStatus s = new CampaignMemberStatus(Label='Testing',CampaignId = c.Id, SortOrder=3);
      insert s;

      ApexPages.standardController sc = new ApexPages.standardController(c);
      CTRL_BFB_CampaignExtension pageController = new CTRL_BFB_CampaignExtension(sc);

      List<SelectOption> options = pageController.getCMStatuses();
      System.Assert(options.size() > 0);
    }
}