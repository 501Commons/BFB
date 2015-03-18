/**
* Author: Nineta Martinov - 501Commons -2014
* Utility class used by HHDonorClassificationOpportunity and OrganizationDonorClassification
*/
public without sharing class DonorClassificationUtility {
	  public static Boolean donorClassEquivalent(String class1, String class2) {
        Set<String> tokens1 = new Set<String>(); 
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
    
    /*
	* Rolls up donor classification for a sObjects (Households or Accounts)
	* Arguments are:
	* @arg1 Map of sobjectId and sObject (this could be Household, Account or something else)
	* @arg2 Map of sobjectId to list of Opportunities.
	* 		SOBjects passed into this method must have the donor classification fields on them.
	* @arg3 custom Date to calculate custom classification 
	* @arg4 batchjobTimeStamp When the batch job ran last
	* @arg5 only calculate custom donor classification
	*/
	public static void rollupDonorClass(Map<Id, SObject> rollUpObjs, Map<Id,List<Opportunity>> objOpportunitiesMap, 
											Date customDate, Datetime batchJobTimestamp, boolean includeCurrent) {	
		
		Date currentDate = date.today();	
												  				                                                                              												                                                             			
		for(Id objId : objOpportunitiesMap.keySet()) {
			//get the list of opportunities for this sObject
			List<Opportunity> objOpps = objOpportunitiesMap.get(objId);
			//if there are no opportunities at all		
			if (objOpps == null) objOpps = new List<Opportunity>();	
			
			//this is the donor
			SObject parentObj = rollUpObjs.get(objId);			
			
			String currentDonorClass = '', previousYearEndDateClass = '', customDateClass = '';
			Boolean alwaysMajorDonor = (parentObj.get('Always_classify_as_Major_Donor__c')==null ? 
		      									false : (Boolean)parentObj.get('Always_classify_as_Major_Donor__c'));  
													
			Date previousYearEndDate = date.newInstance(currentDate.year()-1, 12, 31);			
	        List<Opportunity> prevYearEndListOpps = new List<Opportunity>(); //only opps up to previous year end date   
	        List<Opportunity> customDateListOpps = new List<Opportunity>(); //only opps up to custom date         		        
	        for (Opportunity opp : objOpps) {
	          	if (opp.CloseDate <= previousYearEndDate)
	           		prevYearEndListOpps.add(opp);
	           	if (opp.CloseDate <= customDate)
	           		customDateListOpps.add(opp);	
	        }		        		       
				 
			//perform current donor classification if needed
			if (includeCurrent) {								 			
	            String prevDonorClass = (String)parentObj.get('Donor_Classification__c');
	            if (prevDonorClass == null) 
	            	prevDonorClass = '';		            
            
	            //calculate current donor classification based on current date, using all opps                              
				currentDonorClass = getClassification(objOpps, currentDate, alwaysMajorDonor);												                       						
	            
	            //calculate donor classification based on previous year end date, using only opps up 
	            //to the previous end date	           
            	previousYearEndDateClass = getClassification(prevYearEndListOpps, previousYearEndDate, alwaysMajorDonor);            	
            	  	
		        //set fields on parent object	
		        parentObj.put('Donor_Classification__c', currentDonorClass);            
		        if(!DonorClassificationUtility.donorClassEquivalent(currentDonorClass,prevDonorClass)) {
		            parentObj.put('Previous_Donor_Classification__c', prevDonorClass);
		            parentObj.put('Donor_Classification_Transition_Date__c', System.now());
		        } 
		        parentObj.put('Previous_Year_End_Classification__c', previousYearEndDateClass);	
		        if (batchJobTimestamp != null)
		        	parentObj.put('Donor_Classification_Job_Last_Run__c', batchJobTimestamp);
			}
            //if we need to calculate custom donor classification
            if (customDate != null) {
            	customDateClass = getClassification(customDateListOpps, customDate, alwaysMajorDonor);          	            
            	parentObj.put('Custom_Date_Donor_Classification__c', customDateClass);       
            	parentObj.put('Custom_Classification_Date__c', customDate);
            	parentObj.put('Custom_Donor_Classification_Job_Last_Run__c', batchJobTimestamp);
            }			                           		
		}
		update rollUpObjs.values();
	}
	
	/*
	* Given a list of opportunities and an effective date calculate the current donor classification
	*/	
	private static String getClassification(List<Opportunity> objOpps, Date effectiveDate, boolean alwaysMajorDonor) {
		
		Integer currentYear = effectiveDate.year();
        Integer twoYearsAgo = currentYear-2;
        Integer aYearAgo = currentYear-1;       
        Date aYearAgoDate = effectiveDate.addYears(-1);     
		Date lastGiftDate = null;		
		String currentDonorClass = '';		
		Set<String> currentDonorClassSet = new Set<String>();					
		
		for(Opportunity o: objOpps) {
			if (o <> null) {
				if(lastGiftDate == null) {
					lastGiftDate = o.CloseDate;
				} else if(o.CloseDate > lastGiftDate) {
					lastGiftDate = o.CloseDate;
				}
			}
		}			
			
        if(lastGiftDate != null) {               
              //**************************************************************************************
        	  //First time donor - (as per 4/2014 rules) someone who donated ONCE in the last CY or later
        	  //If the date of their gift is 1/1/CY-1 or later 
              if(objOpps.size() == 1) {
            	//Integer currentYear = Date.today().year();
            	if (lastGiftDate.year() == currentYear || lastGiftDate.year() == currentYear-1) {
                	currentDonorClassSet.add('First Time Donor');	                	                                
            	}
              //***************************************************************************************		
              //Renewing Donor - (as per 4/16 rules) is anyone who gives in (CY-2 & CY-1) OR (CY-1 & CY)  
              //Returning Donor - category added 4/16/2014 these are donors who gave once in the past and 
              //then returned in current year (for example they gave in 2011, 2012 and then again in 2014)
              //First year donor - someone who donates more than once in the last year, and is not 
              //a loyal, monthly or other type of donor (added 4/15/2014 as per BFB)
              } else if(objOpps.size() > 1) {	              		
	            	//Integer currentYear = Date.today().year();
	            	boolean gave2CY = false, gave1CY=false, gaveThisCY=false, gaveInPast=false;	
	            	boolean gaveBefore=false; //this flag indicates someone has given at any time before CY-1	
            		Integer gifts1CY = 0, giftsThisCY = 0; // counts gifts given in this CY or previous CY
	            	
	            	for (Opportunity donation : objOpps) {
	            		if (donation.CloseDate.year() == currentYear){
	            			gaveThisCY = true;
	            			giftsThisCY++;
	            		} else if (donation.CloseDate.year() == currentYear-1) {
	            			gave1CY = true;
	            			gifts1CY++;		  
	            		} else if (donation.CloseDate.year() == currentYear-2) {
	            			gave2CY = true;
	            		}
	            		if (donation.CloseDate.year() < currentYear) {
            				gaveInPast = true;
	            		}
	            		if (donation.CloseDate.year() < currentYear-1) {
            				gaveBefore = true;
            			}
	            	}		            	
	            	if ((gaveThisCY && gave1CY) || (gave1CY && gave2CY)) {	                    	
	                    currentDonorClassSet.add('Renewing Donor');                      	                    
	            	} else if (gaveThisCy && gaveInPast){            			
            			currentDonorClassSet.add('Returning Donor');
            		//**********************************************************************************************	                		
            		//First Year Donor added 4/2014	- Someone who has more than 1 donation in this CY or previous CY
            		//but has not given in the past before that
            		} else if (((giftsThisCY > 1) && !gave1CY) || ((gifts1CY > 1) && !gaveThisCY) && 
        					!gaveBefore){            			     
            			currentDonorClassSet.add('First Year Donor');           		
            		}
              }
	
              // Let's just throw in "Lapsed" as four years w/ no donation for now   - OLD DEFINITION
              // NEW RULE: So if I give in any month of 2012 (or earlier), and did not give at all in 2013 
              // (and have not yet given so far in 2014), I am a Lapsed Donor.  The rule needs to look at the 
              // date of the last gift, add one calendar year to the year of that gift, and evaluate if there is a gift.              	            
              //Integer twoYearsAgo = Date.today().year()-2;
              if (lastGiftDate.year() <= twoYearsAgo) {               
              	currentDonorClassSet.add('Lapsed Donor');               
              }
            } //end if lastGiftDate!=null

            Double lastYearGiving = 0;
                  
            // override
            if(!alwaysMajorDonor) {
	            // 'Major Donor' means > 1000 dollars giving in the 12 months preceeding current year	           
	 			for(Opportunity opp : objOpps) {                         
	                if(opp.closeDate.daysBetween(aYearAgoDate) <= 0 && opp.closeDate.daysBetween(effectiveDate) >= 0) {
		                  if(opp.Amount != null) {
		                    lastYearGiving += opp.Amount;	                    
		                  }
	                }
	 			}
            }
	               
	        if (lastYearGiving >= 1000.0 || alwaysMajorDonor) {  			   
			   currentDonorClassSet.add('Major Donor');				   
	        } else {
			   currentDonorClassSet.remove('Major Donor');	
	        }
							
			// The "Loyal Donor" class involves donating 5 years in the last 6
			Integer numberYearsDonated = 0;
			//as per BFB - 4/16/2014 we want to include current year
			// start with last year else things get weird with this incomplete year
			//todaysDate = Date.today();
			//Integer currentYear = Date.today().year();
			for(Integer aYear = currentYear; currentYear-aYear<6; aYear = aYear-1) {								
				for(Opportunity opp : objOpps) {
					if(opp.CloseDate.year() == aYear) {
						numberYearsDonated++;
						break;
					}
				}
			}
			if(numberYearsDonated >= 5) {				
				currentDonorClassSet.add('Loyal Donor');				
			} else {
				currentDonorClassSet.remove('Loyal Donor');
			}
				
			// The "Monthly Donor" class involves donating consecutively 3 months w/in the last 4
			//todaysDate = Date.today();			
			// go back 3 months for the start of reconing
			Boolean isMonthlyDonor = false;
			
			// set up three months of history, we'll be sliding each of these back
			Date currentDate = effectiveDate;							
			Date setDate = effectiveDate;		
			Date oneMonthBack = currentDate.addMonths(-1);			
			Date twoMonthsBack = oneMonthBack.addMonths(-1);			
			Date threeMonthsBack = twoMonthsBack.addMonths(-1);				
				
            // we are interested in 6 months but the end of our window is only 3 months ago			
			while(setDate.monthsBetween(oneMonthBack) >= -3) {	
				Boolean hitThisMonth = false;                	
				Boolean hitOneMonthBack = false;
				Boolean hitTwoMonthsBack = false;
				Boolean hitThreeMonthsBack = false;
					
				// Copy the date, we'll be backing this one up as we identify matches
				for(Opportunity opp : objOpps) {
					// if monnth and year match...
					Integer closeMonth = opp.CloseDate.month();
					Integer closeYear = opp.CloseDate.year();
					if(closeMonth == currentDate.month() && closeYear == currentDate.year())
						hitThisMonth = true;
					if(closeMonth == oneMonthBack.month() && closeYear == oneMonthBack.year())
						hitOneMonthBack = true;
					if(closeMonth == twoMonthsBack.month() && closeYear == twoMonthsBack.year())
						hitTwoMonthsBack = true;
					if(closeMonth == threeMonthsBack.month() && closeYear == threeMonthsBack.year())
						hitThreeMonthsBack = true; 
					// did we find three months? can be any 3 months
					if((hitThisMonth && hitOneMonthBack && hitTwoMonthsBack) || 
							(hitOneMonthBack && hitTwoMonthsBack && hitThreeMonthsBack) ||
							(hitThisMonth && hitTwoMonthsBack && hitThreeMonthsBack) ||
							(hitThisMonth && hitOneMonthBack && hitThreeMonthsBack)) {
						isMonthlyDonor = true;
						break;
					}
				}
					
				// if we have already identified donor as monthly, we're done here.
				if(isMonthlyDonor) break;
					
				// if not, slide everything back 1 month and try again
				currentDate = currentDate.addMonths(-1);
				oneMonthBack = oneMonthBack.addMonths(-1);
				twoMonthsBack = twoMonthsBack.addMonths(-1);
				threeMonthsBack = threeMonthsBack.addMonths(-1);
			} // end while
				
			if(isMonthlyDonor) {				
				currentDonorClassSet.add('Monthly Donor');				
			} else {
				currentDonorClassSet.remove('Monthly Donor');
			}			
			
			List<String> donorClassList = new List<String>();
			donorClassList.addAll(currentDonorClassSet);
			donorClassList.sort();
			currentDonorClass = '';
			for (String s : donorClassList) {
				currentDonorClass = currentDonorClass +'; '+s;
			}
			//trim the current donor class to remove ';' if it's at the front of the string
			if (currentDonorClass.indexOf(';')==0)
				currentDonorClass = currentDonorClass.substring(1).trim();
			return currentDonorClass;			
	}	
}