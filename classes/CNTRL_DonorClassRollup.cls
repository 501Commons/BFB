public class CNTRL_DonorClassRollup {
    // properties for page
    public boolean batching { get; set; }
    public boolean batchRunning { get; set; }
    public String customDate {get;set; }
    public boolean currentDonorClass {get; set;}
    public boolean customDonorClass {get; set;}

    // object id passed in via parameter
    string objectId;
    id oid;

    // constructor
    public CNTRL_DonorClassRollup() {
        batchRunning = false;
        // get parameter if any
        try {
            objectId = ApexPages.currentPage().getParameters().get('id');
            oid = objectId;
        } catch (exception e) {     
        }          
        if (oid != null) {
            batching = false;           
        } else { 
            batching = true;
        }
        currentDonorClass = false;
        customDonorClass = false;
    }

    public PageReference rollup() {       	 
    	if (!currentDonorClass && !customDonorClass) {
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
    		   					'Please select a batch job (or both batch jobs) to run.'));
    	} else if (customDonorClass && (customDate == '' || customDate == null)) {    			
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
    		   					'Please select a custom date to run the custom date donor classification batch job.'));
    	} else {
	        // run batch rollup
	        Date cDate = null;  	        
	        if (customDonorClass && customDate != null && customDate != '') {	        	
	        	cDate = Date.parse(customDate);	
	        } 
	        // for npsp3 upgrade we're not using households anymore      
	        //HHDonorClassificationRollups.rollupAllContacts(currentDonorClass, customDonorClass, cDate);
	        OrgDonorClassificationRollups.rollupAllOrganizations(currentDonorClass, customDonorClass, cDate);               	
	                
	        batchRunning = true;
    	}
        return null;                
    }

    public PageReference cancel() {
        PageReference ref = new PageReference('/home/home.jsp');
        ref.setRedirect(true);
        return ref;
    }

}