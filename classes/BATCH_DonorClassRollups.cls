global class BATCH_DonorClassRollups implements Database.Batchable<SObject> {
// batch apex class to rollup opportunities
	
	public String query { get; set; }
	private Boolean currentDonorClass, customDonorClass;
	private Date customDate;
	
	// constructor
	public BATCH_DonorClassRollups(String q, Boolean curDonCls, Boolean custDonCls, Date custDate) {   
		query = q; 
		currentDonorClass = curDonCls;
		customDonorClass = custDonCls;
		customDate = custDate;
	}
	
	global database.Querylocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query);		 
	}
	
	global void execute(Database.BatchableContext bc, Sobject[] result) {
		Datetime batchJobRunTimestamp = Datetime.now();
		/**** For npsp3 upgrade no longer using households ************************************************ 		
 		if (result[0].getSObjectType() == npo02__Household__c.sObjectType) {  			
			HHDonorClassificationRollups.rollupDonorClass((List<npo02__Household__c>)result, currentDonorClass, 
																customDonorClass, customDate, batchJobRunTimestamp);
 		}*/  	
 		if (result[0].getSObjectType() == Account.sObjectType) { 
			OrgDonorClassificationRollups.rollupDonorClass((List<Account>)result, currentDonorClass, 
																customDonorClass, customDate, batchJobRunTimestamp);
 		}  			
	}

	global void finish(Database.BatchableContext bc) {
	}

}