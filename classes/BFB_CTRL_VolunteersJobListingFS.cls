// Written by David Habib, copyright (c) 2010-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/
//
// Minor modifications by Patrick Tewson for 501 Commons

global virtual with sharing class BFB_CTRL_VolunteersJobListingFS {

    // page parameters that can get passed into the page to control its behavior.
    global ID campaignIdFilter { get; set; }
    global ID jobIdFilter { get; set; }
    global boolean fCalendar { get; set; }
    //global boolean fPortal { get; set; }
    global boolean ShowJobName { get; set; }
    global boolean ShowDescription { get; set; }
    global boolean ShowLocationAddress { get; set; }
    global boolean ShowLocationInfo { get; set; }
    global boolean ShowSkills { get; set; }
    global boolean ShowShifts { get; set; }
    global string strLanguage { get; set; }
    global string strDateFormat { get; set; }
    global string strTimeFormat { get; set; }
    global list<string> listStrFields { get; set; } 
    global string strSaveResult { get; set; }
    global string strFileUploadLabel { get; set; }
    global Attachment attachment { get; set; }   
    global string strParams { get; set; }
    global integer nMonthsToShow { get; set; }
    global date dtMonthFilter { get; set; }
    

    global list<GW_Volunteers__Volunteer_Job__c> listVolunteerJobs { get; set; }

    public class ShiftPlus {
      public GW_Volunteers__Volunteer_Shift__c theShift { get; set; }
      public String attendees { get; set; }

      public ShiftPlus(GW_Volunteers__Volunteer_Shift__c aShift, String someFolks) {
        theShift = aShift;
        attendees = someFolks;
      }
    }

    public class JobRow implements Comparable {
      public GW_Volunteers__Volunteer_Job__c theJob { get; set; }
      public List<ShiftPlus> theShifts { get; set; }

      public JobRow(GW_Volunteers__Volunteer_Job__c aJob) {
        theJob = aJob;
        theShifts = new List<ShiftPlus>();
      }
      
      public Integer compareTo(Object compareTo) {
        JobRow compareToRow = (JobRow)compareTo;
        //return theJob.Id.compareTo(compareToRow.theJob.Id);
        return 0;
      }
    }
    
    // contact record to bind the Contact SignUp form to.
    global Contact contact { 
        get {
            if (contact == null) {
           		contact = new Contact();
           		
		        // when used within the Portal, we should use the logged in Contact
		        //Cookie cId = ApexPages.currentPage().getCookies().get('contactIdPortal');
		        //if (cId != null) contactIdSignUp = cId.getValue();
				if (contactIdSignUp != null && contactIdSignUp != '') {
            		BFBVOL_SharedCode.LoadAndCopyObject(contactIdSignUp, contact);            		
            	}
            }
            return contact;
        }
        set; 
    }
      
    // volunteer hours record, to bind the field set to.
    global GW_Volunteers__Volunteer_Hours__c vhours {
        get {
            if (vhours == null) vhours = new GW_Volunteers__Volunteer_Hours__c(GW_Volunteers__Number_of_Volunteers__c = 1);
            return vhours;      
        }
        set;
    }
    
    // parameters set by the client before calling VolunteerShiftSignUp()   
    global ID jobIdSignUp { get; set; }
    global string shiftIdSignUp { get; set; }
    global string strJobDisplayName { get; set; }
    global string strShiftDisplayName { get; set; }
    
    // return parameters set by VolunteerShiftSignUp()
    // NOTE: while these are actually ID's, we need to make the type string so the client can clear them with null!
    global string contactIdSignUp { get; set; }
    global string volunteerHoursIdSignUp { get; set; }
    
    // the instance specific url to the css that can be modified by the user.
    global string strURLtoCSSFile { 
        get { 
            if (strURLtoCSSFile == null) {
                list<Document> listDocs = [SELECT Name, Id From Document WHERE Name = 'VolunteersJobListingCSS.css' LIMIT 1 ];
                if (listDocs.size() > 0) {
                    Document doc = listDocs[0];
                    string imageid = doc.id;
                    imageid = imageid.substring(0,15);
                    strURLToCSSFile = '/servlet/servlet.FileDownload?file=' + imageid;
                }
            }
            return strURLtoCSSFile;
        }       
        set;
    }  
    
    // constructor
    global BFB_CTRL_VolunteersJobListingFS() {
                
        // set default's for page parameters
        campaignIdFilter = null;
        jobIdFilter = null;
        fCalendar = false;
        ShowJobName = true;
        ShowDescription = true;
        ShowLocationAddress = true;
        ShowLocationInfo = true;
        ShowSkills = false;
        ShowShifts = true;
    	strLanguage = 'en-us'; 
    	strDateFormat = 'EEEE M/d/yyyy';
    	strTimeFormat = 'h:mm tt';
    	nMonthsToShow = 3;	
    	dtMonthFilter = system.today(); // default to current month.
    	        
        // handle optional parameters (must use string, not ID, to handle null)
        map<string, string> params = ApexPages.currentPage().getParameters();
        string p = params.get('campaignId');
        if (p != null && p != '') campaignIdFilter = p;
        p = params.get('jobId');
        if (p != null && p != '') jobIdFilter = p;
        p = params.get('Calendar');
        if (p == '1') fCalendar = true;
        p = params.get('ShowJobName');
        if (p == '0') ShowJobName = false;
        p = params.get('ShowDescription');
        if (p == '0') ShowDescription = false;
        p = params.get('ShowLocationAddress');
        if (p == '0') ShowLocationAddress = false;
        p = params.get('ShowLocationInfo');
        if (p == '0') ShowLocationInfo = false;
        p = params.get('ShowSkills');
        if (p == '1') ShowSkills = true;
        p = params.get('ShowShifts');
        if ( p == '0') ShowShifts = false;
        p = params.get('Language');
        if (p != null && p != '') strLanguage = p;
        p = params.get('DateFormat');
        if (p != null && p != '') strDateFormat = p;
        p = params.get('TimeFormat');
        if (p != null && p != '') strTimeFormat = p;
        p = params.get('nMonthsToShow');
        if (p != null && p != '') nMonthsToShow = integer.valueOf(p);
        p = params.get('dtMonthFilter');
        if (p != null && p != '') dtMonthFilter = date.valueOf(p);
        p = params.get('FileUploadLabel');
        if (p != null && p != '') {
        	strFileUploadLabel = p;
        	attachment = new Attachment();
        }

    	// we can derive whether we are within the Portal or not, so no need for parameter.
    	//fPortal = ApexPages.currentPage().getUrl().contains('VolunteersPortal');
        
		// finally, keep all parameters for passing back to JobCalendar
		strParams = ApexPages.currentPage().getUrl();
		integer iparams = strParams.indexOf('?');
		if (iparams >= 0){
			strParams = strParams.substring(iparams+1);
		} else {
			strParams = '';
		}		
                
		// initialize the list of all fields on Contact.
		// ideally, we'd only include the fields in the Field Set,
		// but Apex currently has no way to see what those are.
		// so for now, we just include all fields on Contact.
		Map<String, Schema.SObjectField> mapS = Schema.SObjectType.Contact.fields.getMap();
		listStrFields = new list<string>();
		listStrFields.addAll(mapS.keySet());    		
        
        contactIdSignUp = null;
        volunteerHoursIdSignUp = null;        
    }

    public List<JobRow> getEnhancedJobs() {
      List<GW_Volunteers__Volunteer_Job__c> jobs = getListOfJobs();
      List<JobRow> enhancedJobs = new List<JobRow>();

      List<Id> jobIds = new List<Id>();
      for(GW_Volunteers__Volunteer_Job__c job: jobs) {
        jobIds.add(job.Id);
      }

      List<GW_Volunteers__Volunteer_Hours__c> hours = [select Id, GW_Volunteers__Volunteer_Job__c, GW_Volunteers__Contact__r.FirstName, GW_Volunteers__Contact__r.LastName, GW_Volunteers__Full_Name__c, GW_Volunteers__Volunteer_Shift__c from GW_Volunteers__Volunteer_Hours__c where GW_Volunteers__Volunteer_Job__c = :jobIds];

      // shift ID and names
      Map<Id, String> signedUp = new Map<Id, String>();
      for(GW_Volunteers__Volunteer_Hours__c hour: hours) {
        String name = hour.GW_Volunteers__Contact__r.FirstName+'-'+hour.GW_Volunteers__Contact__r.LastName+' ';
        if(!signedup.containsKey(hour.GW_Volunteers__Volunteer_Shift__c)) {
          signedUp.put(hour.GW_Volunteers__Volunteer_Shift__c, name);
        } else {
          String names = signedUp.get(hour.GW_Volunteers__Volunteer_Shift__c);
          names = signedUp.get(hour.GW_Volunteers__Volunteer_Shift__c) + name;
          signedUp.put(hour.GW_Volunteers__Volunteer_Shift__c, names);
        }
      }

      for(GW_Volunteers__Volunteer_Job__c job: jobs) {
        JobRow enhancedJob = new JobRow(job);
        for(GW_Volunteers__Volunteer_Shift__c shift: job.GW_Volunteers__Volunteer_Job_Slots__r) {
          String shiftNames = 'Be the first to sign up!';
          if(signedUp.containsKey(shift.Id)) {
            shiftNames = ' Already signed up: ' + (signedUp.get(shift.Id)).trim().replace(' ',', ').replace('-',' ');
          }
          enhancedJob.theShifts.add(new ShiftPlus(shift, shiftNames));
        }
        enhancedJobs.add( enhancedJob );
      }
      return enhancedJobs;
    }

    public list<GW_Volunteers__Volunteer_Job__c> getListOfJobs() {
      if (listVolunteerJobs == null) {
        
        listVolunteerJobs = new list<GW_Volunteers__Volunteer_Job__c>();
        //DateTime dtNow = system.Now().addHours(-1);
        DateTime dtNow = dtMonthFilter.toStartOfMonth();
        DateTime dtLast = dtNow.date().addMonths(nMonthsToShow + 1).toStartOfMonth();
        
        if (jobIdFilter != null) {
          listVolunteerJobs = [select Id, Name, GW_Volunteers__Campaign__c, GW_Volunteers__Campaign__r.IsActive, GW_Volunteers__Campaign__r.Name, GW_Volunteers__Campaign__r.StartDate, GW_Volunteers__Campaign__r.GW_Volunteers__Volunteer_Website_Time_Zone__c,
          GW_Volunteers__Description__c, GW_Volunteers__Location_Information__c, GW_Volunteers__Number_of_Shifts__c, GW_Volunteers__Skills_Needed__c, GW_Volunteers__Volunteer_Website_Time_Zone__c,
          GW_Volunteers__Location_Street__c, GW_Volunteers__Location_City__c, GW_Volunteers__Location__c, GW_Volunteers__Location_Zip_Postal_Code__c,
          (Select Id, GW_Volunteers__Start_Date_Time__c, GW_Volunteers__Duration__c, GW_Volunteers__Number_of_Volunteers_Still_Needed__c,
          GW_Volunteers__Description__c, GW_Volunteers__System_Note__c From GW_Volunteers__Volunteer_Job_Slots__r 
          where GW_Volunteers__Start_Date_Time__c >= :dtNow and GW_Volunteers__Start_Date_Time__c < :dtLast
          order by GW_Volunteers__Start_Date_Time__c) 
          from GW_Volunteers__Volunteer_Job__c where Id = :jobIdFilter  
          order by GW_Volunteers__First_Shift__c, GW_Volunteers__Campaign__r.StartDate, GW_Volunteers__Campaign__r.Name, Name];
        } else if (campaignIdFilter != null) {
          listVolunteerJobs = [select Id, Name, GW_Volunteers__Campaign__c, GW_Volunteers__Campaign__r.IsActive, GW_Volunteers__Campaign__r.Name, GW_Volunteers__Campaign__r.StartDate, GW_Volunteers__Campaign__r.GW_Volunteers__Volunteer_Website_Time_Zone__c, 
          GW_Volunteers__Description__c, GW_Volunteers__Location_Information__c, GW_Volunteers__Number_of_Shifts__c, GW_Volunteers__Skills_Needed__c, GW_Volunteers__Volunteer_Website_Time_Zone__c,
          GW_Volunteers__Location_Street__c, GW_Volunteers__Location_City__c, GW_Volunteers__Location__c, GW_Volunteers__Location_Zip_Postal_Code__c,
          (Select Id, GW_Volunteers__Start_Date_Time__c, GW_Volunteers__Duration__c, GW_Volunteers__Number_of_Volunteers_Still_Needed__c,
          GW_Volunteers__Description__c, GW_Volunteers__System_Note__c From GW_Volunteers__Volunteer_Job_Slots__r 
          where GW_Volunteers__Start_Date_Time__c >= :dtNow and GW_Volunteers__Start_Date_Time__c < :dtLast
          order by GW_Volunteers__Start_Date_Time__c) 
          from GW_Volunteers__Volunteer_Job__c where GW_Volunteers__Campaign__c = :campaignIdFilter and GW_Volunteers__Display_on_Website__c = true 
          order by GW_Volunteers__First_Shift__c, GW_Volunteers__Campaign__r.StartDate, GW_Volunteers__Campaign__r.Name, Name];
        } else {
          listVolunteerJobs = [select Id, Name, GW_Volunteers__Campaign__c, GW_Volunteers__Campaign__r.IsActive, GW_Volunteers__Campaign__r.Name, GW_Volunteers__Campaign__r.StartDate, GW_Volunteers__Campaign__r.GW_Volunteers__Volunteer_Website_Time_Zone__c,
          GW_Volunteers__Description__c, GW_Volunteers__Location_Information__c, GW_Volunteers__Number_of_Shifts__c, GW_Volunteers__Skills_Needed__c, GW_Volunteers__Volunteer_Website_Time_Zone__c,
          GW_Volunteers__Location_Street__c, GW_Volunteers__Location_City__c, GW_Volunteers__Location__c, GW_Volunteers__Location_Zip_Postal_Code__c,
          (Select Id, GW_Volunteers__Start_Date_Time__c, GW_Volunteers__Duration__c, GW_Volunteers__Number_of_Volunteers_Still_Needed__c,
          GW_Volunteers__Description__c, GW_Volunteers__System_Note__c From GW_Volunteers__Volunteer_Job_Slots__r 
          where GW_Volunteers__Start_Date_Time__c >= :dtNow and GW_Volunteers__Start_Date_Time__c < :dtLast
          order by GW_Volunteers__Start_Date_Time__c LIMIT 100) 
          from GW_Volunteers__Volunteer_Job__c where GW_Volunteers__Campaign__r.IsActive = true and GW_Volunteers__Display_on_Website__c = true 
          order by GW_Volunteers__First_Shift__c, GW_Volunteers__Campaign__r.StartDate, GW_Volunteers__Campaign__r.Name, Name LIMIT 999];
        }
        
        // now remove any jobs whose shifts are all past date.
        for (integer i = listVolunteerJobs.size() - 1; i >= 0; i--) {
          GW_Volunteers__Volunteer_Job__c job = listVolunteerJobs[i];
          if (job.GW_Volunteers__Number_of_Shifts__c > 0 && job.GW_Volunteers__Volunteer_Job_Slots__r.size() == 0) {
            listVolunteerJobs.remove(i);            		
          }
        }
      }
      dateTimeFixup(listVolunteerJobs);
      return sortVolunteerJobs(listVolunteerJobs);
    }
      
    // routine to go through all the shifts, and create the display string
    // for the shifts start date & time - end date & time, using the appropriate
    // time zone that might be specified on the Job, Campaign, or Site Guest User.
    // Note that it stores this string in the Shift's System_Note__c field (in memory only).
    private void dateTimeFixup(list<GW_Volunteers__Volunteer_Job__c> listJob) {
    	
    	// get default time zone for site guest user
    	User u = [Select TimeZoneSidKey From User where id =: Userinfo.getUserId()];
    	
    	// javascript formatting used 'tt' for am/pm, whereas apex formatting uses 'a'.
    	string strFormat = strDateFormat + ' ' + strTimeFormat.replace('tt','a');
    	string strFormatEndTime = strTimeFormat.replace('tt','a');
    	
    	for (GW_Volunteers__Volunteer_Job__c job : listJob) {
			string strTimeZone = job.GW_Volunteers__Volunteer_Website_Time_Zone__c;
			if (strTimeZone == null) strTimeZone = job.GW_Volunteers__Campaign__r.GW_Volunteers__Volunteer_Website_Time_Zone__c;
			if (strTimeZone == null) strTimeZone = u.TimeZoneSidKey;

    		for (GW_Volunteers__Volunteer_Shift__c shift : job.GW_Volunteers__Volunteer_Job_Slots__r) {
    			
    			DateTime dtEnd = shift.GW_Volunteers__Start_Date_Time__c.addMinutes(integer.valueOf(shift.GW_Volunteers__Duration__c * 60));
    			string strStart = shift.GW_Volunteers__Start_Date_Time__c.format(strFormat, strTimeZone);
    			
    			// see if start and end are on the same day
    			if (shift.GW_Volunteers__Start_Date_Time__c.format('d', strTimeZone) == dtEnd.format('d', strTimeZone)) {
    				shift.GW_Volunteers__System_Note__c =  strStart + ' - ' + dtEnd.format(strFormatEndTime, strTimeZone);	
    			} else {
    				shift.GW_Volunteers__System_Note__c =  strStart + ' - ' + dtEnd.format(strFormat, strTimeZone);	    				
    			}    			
    		}
    	}
    }
    
    global virtual list<GW_Volunteers__Volunteer_Job__c> sortVolunteerJobs (list<GW_Volunteers__Volunteer_Job__c> jobsList) {
    	list<GW_Volunteers__Volunteer_Job__c> resultList = new list<GW_Volunteers__Volunteer_Job__c>();
    	DateTime faroutFuture = System.Now().addYears(100);
    	
    	//create a map of earliest shift datetime to job list
    	map<DateTime, list<GW_Volunteers__Volunteer_Job__c>> jobMap = new map<DateTime, list<GW_Volunteers__Volunteer_Job__c>>();
    	
    	for (GW_Volunteers__Volunteer_Job__c vj : jobsList) {
    		DateTime nextShift = faroutFuture;
    		
    		//if the job has no shifts, set it in the past so it appears first on the page, otherwise get the first shift
    		if (vj.GW_Volunteers__Volunteer_Job_Slots__r.size() == 0) {
    			nextShift = faroutFuture.addYears(-200);
    		} else if (vj.GW_Volunteers__Volunteer_Job_Slots__r.size() > 0) {
    			for (GW_Volunteers__Volunteer_Shift__c vs : vj.GW_Volunteers__Volunteer_Job_Slots__r) {
    				if (vs.GW_Volunteers__Start_Date_Time__c < nextshift) {
    					nextShift = vs.GW_Volunteers__Start_Date_Time__c;
    				}
    			}
    		}
    		
    		//if our map doesn't contain this shift, create a new list, otherwise add to the list
    		if (jobMap.get(nextShift) == null) {
    			jobMap.put(nextShift, new List<GW_Volunteers__Volunteer_Job__c>());
    		}
    		jobMap.get(nextShift).add(vj);
    	}
    	
    	//use SF's standard sort method on the datetimes
    	list<DateTime> keys = new list<DateTime>(jobMap.keySet());
    	keys.sort();
    	
    	//rebuild list in order
    	for (DateTime key:keys) {
    		resultList.addAll(jobMap.get(key));
    	}
    	return resultlist;
    }
    
    global virtual boolean getVolunteersHasJobs() {
        return (listVolunteerJobs.size() > 0);
    }
    
    // action method to allow the javascript to clear this variable.
    // used when the confirmation dialog is closed.
    global virtual PageReference ClearVolunteerHoursIdSignUp() {
        volunteerHoursIdSignUp = null;
        return null;
    }
    
    // action method to cancel the signup dialog,
    // clearing any cached state.
    global virtual PageReference CancelSignUp() {
        volunteerHoursIdSignUp = null;
        strSaveResult = null;
        return null;
    }
    // just before we insert the new Volunteer Hours record,
    // give clients a chance to set any additional information they want.
    global virtual void VolunteerHoursBeforeInsert(GW_Volunteers__Volunteer_Hours__c vh) {
        
    }   
    
    private class MyException extends Exception {}
    
    global virtual PageReference VolunteerShiftSignUp() {
		try { 			   	
	        // clear return variables in case we fail.
	        contactIdSignUp = null;
	        volunteerHoursIdSignUp = null;
	        strSaveResult = null;
	        Date dtStart = system.today();

	        // do any validation we weren't able to do directly on the client.
	        // also find the shift's start date.
	        if (shiftIdSignUp != null && shiftIdSignUp != '') {
	        	// make sure we don't go over the number of volunteers still needed on the shift.
	        	list<GW_Volunteers__Volunteer_Shift__c> listShift = [select GW_Volunteers__Number_of_Volunteers_Still_Needed__c, GW_Volunteers__Start_Date_Time__c from GW_Volunteers__Volunteer_Shift__c where Id = :shiftIdSignUp];
	        	if (listShift != null) {
	        		if (vhours.GW_Volunteers__Number_of_Volunteers__c > listShift[0].GW_Volunteers__Number_of_Volunteers_Still_Needed__c) {
	        			string strError = String.Format(system.label.labelVolunteersJobListingErrorTooManyVols, 
	        				new string[] { string.valueOf(listShift[0].GW_Volunteers__Number_of_Volunteers_Still_Needed__c) }); 
						throw (new MyException(strError));    				
	        		}
	        		dtStart = listShift[0].GW_Volunteers__Start_Date_Time__c.date();
	        	}
	        }

	        // when used within the Portal, we should use the logged in Contact
	        //Cookie cId = ApexPages.currentPage().getCookies().get('contactIdPortal');
	        ID contactIdPortal = null;
	        //if (cId != null) contactIdPortal = cId.getValue();

    		// save or update the contact              
	        contactIdSignUp = BFBVOL_SharedCode.CreateOrUpdateContactFS(contactIdPortal, contact, contact.GW_Volunteers__Volunteer_Organization__c, listStrFields);

			// upload any attachment
			if (contactIdSignUp != null && attachment != null && attachment.body != null) {
				attachment.ParentId = contactIdSignUp;
				attachment.Description = strFileUploadLabel + ' ' + system.label.labelFileUploadDescription;
				insert attachment;
				attachment = new Attachment();
			}

	        // then create hours if it was successful.
	        if (contactIdSignUp != null) {
	            vhours.GW_Volunteers__Contact__c = contactIdSignUp;
	            vhours.GW_Volunteers__Volunteer_Job__c = jobIdSignUp;
	            if (shiftIdSignUp != null && shiftIdSignUp != '') { vhours.GW_Volunteers__Volunteer_Shift__c = shiftIdSignUp; }
	            vhours.GW_Volunteers__Status__c = 'Web Sign Up';
	            vhours.GW_Volunteers__Start_Date__c = dtStart;
	            VolunteerHoursBeforeInsert(vhours);
	            insert vhours;
	            volunteerHoursIdSignUp = vhours.Id;

	            // force recreate new hours record to use for next submit.
	            vhours = null;
	        }
    	} catch (exception ex) {
    		StrSaveResult = ex.getMessage(); 
    		//StrSaveResult += ' stack: ' + ex.getStackTraceString();
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage())); 		
    	}
        return null; 
    }

    //==================== TEST METHOD(s) ======================================
    global static testmethod void UnitTest1() {


        // set up intial test data
        Account acc = new Account(name='Test Individual Bucket Account');
        insert acc;
        Contact con = new Contact(Lastname='Testy', Firstname='Test', Email='test@testy.com', AccountId=acc.Id);
        insert con;
        Campaign cmp = new Campaign(recordtypeid=BFBVOL_SharedCode.recordtypeIdVolunteersCampaign, name='Test Job Campaign', IsActive=true);
        insert cmp;
        GW_Volunteers__Volunteer_Job__c job = new GW_Volunteers__Volunteer_Job__c(name='Job1', GW_Volunteers__campaign__c=cmp.Id, GW_Volunteers__Display_on_Website__c=true);
        insert job;
        GW_Volunteers__Volunteer_Shift__c shift = new GW_Volunteers__Volunteer_Shift__c(GW_Volunteers__Volunteer_Job__c=job.Id, GW_Volunteers__Duration__c=1, GW_Volunteers__Start_Date_Time__c=System.now());
        insert shift;        
        
        // specify our settings        
        System.Assert(BFBVOL_SharedCode.VolunteersSettings != null);
        GW_Volunteers__Volunteers_Settings__c settings = new GW_Volunteers__Volunteers_Settings__c();
        settings.GW_Volunteers__Signup_Creates_Contacts_If_No_Match__c = false; // this shouldn't affect this page!
        settings.GW_Volunteers__Signup_Matches_Existing_Contacts__c = false;   // this shouldn't affect this page!
        settings.GW_Volunteers__Signup_Bucket_Account_On_Create__c = 'Test Individual Bucket Account';
        BFBVOL_SharedCode.getVolunteersSettingsForTests(settings);
        
        PageReference pageRef = Page.BFBVolunteersJobListingFS;
        pageRef.getParameters().put('ShowJobName', '1');
        pageRef.getParameters().put('ShowDescription', '1');
        pageRef.getParameters().put('ShowLocationAddress', '1');
        pageRef.getParameters().put('ShowLocationInfo', '1');
        pageRef.getParameters().put('ShowShifts', '1');
        pageRef.getParameters().put('ShowSkills', '1');
        Test.setCurrentPage(pageRef); 

        //instantiate the controller 
        BFB_CTRL_VolunteersJobListingFS ctrl = new BFB_CTRL_VolunteersJobListingFS();
        System.AssertEquals(null, ctrl.campaignIdFilter);
        System.AssertEquals(null, ctrl.jobIdFilter);
        System.AssertEquals(true, ctrl.ShowJobName);
        System.AssertEquals(true, ctrl.ShowDescription);
        System.AssertEquals(true, ctrl.ShowLocationAddress);
        System.AssertEquals(true, ctrl.ShowLocationInfo);
        System.AssertEquals(true, ctrl.ShowShifts);
        System.AssertEquals(true, ctrl.ShowSkills);
        System.AssertEquals(null, ctrl.contact.Id);
        System.AssertEquals(null, ctrl.jobIdSignUp);
        System.AssertEquals(null, ctrl.shiftIdSignUp);
        System.AssertEquals(1, ctrl.vhours.GW_Volunteers__Number_of_Volunteers__c);
        System.AssertEquals(null, ctrl.strJobDisplayName);
        System.AssertEquals(null, ctrl.strShiftDisplayName);
        System.AssertEquals(null, ctrl.contactIdSignUp);
        System.AssertEquals(null, ctrl.volunteerHoursIdSignUp);
        System.Assert(ctrl.strURLtoCSSFile == ctrl.strURLtoCSSFile);

        List<JobRow> jRows = ctrl.getEnhancedJobs();

        System.Assert(ctrl.listVolunteerJobs.size() > 0);
        System.Assert(jRows.size() > 0);
        for(JobRow row: jRows) {
          for(ShiftPlus aShift: row.theShifts) {
            System.AssertEquals('Be the first to sign up!',aShift.attendees);
          }
        }
        
        integer cJobs = ctrl.listVolunteerJobs.size();
        GW_Volunteers__Volunteer_Job__c job2 = new GW_Volunteers__Volunteer_Job__c(name='Job2', GW_Volunteers__campaign__c=cmp.Id, GW_Volunteers__Display_on_Website__c=true);
        insert job2;
        ctrl.listVolunteerJobs = null;
        jRows = ctrl.getEnhancedJobs();
        System.AssertEquals(cJobs + 1, ctrl.listVolunteerJobs.size());
        System.AssertEquals(cJobs + 1, jRows.size());

        // new by P. Tewson
        ctrl.jobIdFilter = job2.Id;
        ctrl.listVolunteerJobs = null;
        jRows = ctrl.getEnhancedJobs();
        System.AssertEquals(cJobs, ctrl.listVolunteerJobs.size());
        System.AssertEquals(cJobs, jRows.size());

        ctrl.jobIdFilter = job2.Id;
        ctrl.listVolunteerJobs = null;
        jRows = ctrl.getEnhancedJobs();
        System.AssertEquals(cJobs, ctrl.listVolunteerJobs.size());
        System.AssertEquals(cJobs, jRows.size());

        ctrl.campaignIdFilter = cmp.Id;
        ctrl.listVolunteerJobs = null;
        jRows = ctrl.getEnhancedJobs();
        System.AssertEquals(cJobs, ctrl.listVolunteerJobs.size());
        System.AssertEquals(cJobs, jRows.size());

        ctrl.ClearVolunteerHoursIdSignUp();
        
        // sign someone up
        System.AssertEquals(null, ctrl.contact.Id);
        System.AssertEquals(null, ctrl.volunteerHoursIdSignUp);
        ctrl.contact.FirstName = 'Test';
        ctrl.contact.LastName = 'Testy';
        ctrl.contact.Email = 'test@testy.com';
        ctrl.jobIdSignUp = job.id;
        ctrl.shiftIdSignUp = shift.id;     
        ctrl.VolunteerShiftSignUp();
        System.AssertEquals(con.Id, ctrl.contactIdSignUp);
        System.Assert(ctrl.volunteerHoursIdSignUp != null);
        
        // pass cmp.Id as filter, verify only 2 jobs.
        // pass Show params with 0, verify values.
        pageRef = Page.BFBVolunteersJobListingFS;
        pageRef.getParameters().put('ShowJobName', '0');
        pageRef.getParameters().put('ShowDescription', '0');
        pageRef.getParameters().put('ShowLocationAddress', '0');
        pageRef.getParameters().put('ShowLocationInfo', '0');
        pageRef.getParameters().put('ShowShifts', '0');
        pageRef.getParameters().put('ShowSkills', '0');
        pageRef.getParameters().put('campaignId', cmp.Id);
        Test.setCurrentPage(pageRef); 

        //instantiate the controller 
        ctrl = new BFB_CTRL_VolunteersJobListingFS();
        ctrl.getEnhancedJobs();
        System.AssertEquals(2, ctrl.listVolunteerJobs.size());
        System.AssertEquals(cmp.Id, ctrl.campaignIdFilter);
        
        // create hours for new person, verify contact created
        ctrl.ClearVolunteerHoursIdSignUp();
        ctrl.contact.FirstName = 'New person';
        ctrl.contact.LastName = 'New person for my test';
        ctrl.contact.Email = 'newperson@volunteersjoblisting.com';
        ctrl.jobIdSignUp = job.id;
        ctrl.VolunteerShiftSignUp();
        System.Assert(ctrl.contactIdSignUp != null);
        System.Assert(ctrl.volunteerHoursIdSignUp != null);
        
    }
    
}