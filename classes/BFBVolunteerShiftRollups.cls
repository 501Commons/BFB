// Written by Patrick Tewson at 501 Commons
//
// This just takes the contacts that have signalled their interest in sharing info for carpooling and munges their names into a field on the shift;
// that field can be used by the email templates to notify those signing up of the participants who wish to be involved in carpooling,
// and how to get ahold of those people.

public with sharing class BFBVolunteerShiftRollups {

  public static Boolean alreadyInThisMethod = False;

  public static void rollupCarpoolContact(list<GW_Volunteers__Volunteer_Hours__c> listHoursOld, list<GW_Volunteers__Volunteer_Hours__c> listHoursNew) {
   if(alreadyInThisMethod) return;
   else alreadyinThisMethod = True;

   if((listHoursNew != null && listHoursNew.size() <= 10) || (listHoursOld != null && listHoursOld.size() <= 10 )) {

      List<Id> contactIds = new List<Id>();
      List<Id> shiftIds = new List<Id>();
      Set<Id> hoursBeingRemoved = new Set<Id>();

      //List<Contact> carpoolInterest = new List<Contact>();

      Map<Id,Contact> contactIdMap = new Map<Id,Contact>();
      List<GW_Volunteers__Volunteer_Shift__c> shifts = new List<GW_Volunteers__Volunteer_Shift__c>();

      // key is shift ID, value is list of all the contacts connected to the shift by their hours
      Map<Id, List<Contact>> shiftIdContactMap = new Map<Id, List<Contact>>();

      Map<Id, List<Id>> shiftIdContactIdsMap = new Map<Id,List<Id>>();
      Map<Id, List<GW_Volunteers__Volunteer_Hours__c>> shiftIdHoursMap = new Map<Id,List<GW_Volunteers__Volunteer_Hours__c>>();

      if(listHoursNew != null) {
        for(GW_Volunteers__Volunteer_Hours__c hr: listHoursNew) {
          shiftIds.add(hr.GW_Volunteers__Volunteer_Shift__c);
        }
      }

      if(listHoursOld != null) {
        for(GW_Volunteers__Volunteer_Hours__c hr: listHoursOld) {
          shiftIds.add(hr.GW_Volunteers__Volunteer_Shift__c);
          hoursBeingRemoved.add(hr.Id);
        }
      }


      List<GW_Volunteers__Volunteer_Hours__c> allTheHours = [SELECT GW_Volunteers__Contact__c, GW_Volunteers__Status__c, GW_Volunteers__Volunteer_Shift__c FROM GW_Volunteers__Volunteer_Hours__c 
                                                             WHERE GW_Volunteers__Volunteer_Shift__c =: shiftIds LIMIT 400];

      for(GW_Volunteers__Volunteer_Hours__c hr: allTheHours) {
         if(hr.GW_Volunteers__Status__c != 'No-Show' && hr.GW_Volunteers__Status__c != 'Canceled' && !hoursBeingRemoved.contains(hr.Id) ) {
           contactIds.add(hr.GW_Volunteers__Contact__c);

           if(!shiftIdContactIdsMap.containsKey( hr.GW_Volunteers__Volunteer_Shift__c )) {
             shiftIdContactIdsMap.put( hr.GW_Volunteers__Volunteer_Shift__c, new List<Id>() );
           } // else {
           shiftIdContactIdsMap.get( hr.GW_Volunteers__Volunteer_Shift__c ).add( hr.GW_Volunteers__Contact__c );
             //           }
         }
         if(!shiftIdHoursMap.containsKey( hr.GW_Volunteers__Volunteer_Shift__c ) ) {
           shiftIdHoursMap.put( hr.GW_Volunteers__Volunteer_Shift__c, new List<GW_Volunteers__Volunteer_Hours__c>() );
         } 
         shiftIdHoursMap.get( hr.GW_Volunteers__Volunteer_Shift__c ).add( hr );
      }     

      System.debug('******** Identified '+allTheHours.size()+' related hours entries');
      System.debug('******** Identified '+shiftIds.size()+' related shifts');
      System.debug('******** Identified '+contactIds.size()+' related contacts');


      contactIdMap = new Map<Id,Contact>([SELECT Id, Name, Email, Phone, Volunteer_Share_Information_for_Carpool__c FROM Contact 
                                          WHERE Volunteer_Share_Information_for_Carpool__c = True AND Id = :contactIds LIMIT 400]);

      shifts = [SELECT Id, Carpool_Contact_Info__c FROM GW_Volunteers__Volunteer_Shift__c where Id = :shiftIds LIMIT 100];

      System.debug('********* Displaying shifts, of which there are '+shifts.size());
      for(GW_Volunteers__Volunteer_Shift__c shift: shifts) {
        System.debug('******** shift '+shift);
      }      

      List<GW_Volunteers__Volunteer_Shift__c> updatedShifts = new List<GW_Volunteers__Volunteer_Shift__c>();
      List<GW_Volunteers__Volunteer_Hours__c> updatedHours = new List<GW_Volunteers__Volunteer_Hours__c>();

      for(GW_Volunteers__Volunteer_Shift__c shift: shifts) {
         System.debug('**** Inside shift loop');
         String carpoolContactInfo = '';
         if(shiftIdContactIdsMap.containsKey(shift.Id)) {
            for(Id cid: shiftIdContactIdsMap.get(shift.Id)) {
               System.debug('     **** Inside contact loop');
	       if(contactIdMap.containsKey( cid ) ) {
                  System.debug('     **** Contact Name: '+contactIdMap.get( cid ).Name);
	          carpoolContactInfo = buildCarpoolInfo(carpoolContactInfo,contactIdMap.get( cid ));
	       }
	    }
	 }	 
	 shift.Carpool_Contact_Info__c = carpoolContactInfo.removeEnd('; ');
         // Carpool really belongs on shift, but the shift fields don't come into the email template. We could pull it onto hours with a formula, but 
         // formula fields can't use Long Text. So, we hack it in the trigger. Old Skool.
         if(shiftIdHoursMap.containsKey(shift.Id)) {
           for(GW_Volunteers__Volunteer_Hours__c hr: shiftIdHoursMap.get( shift.Id )) {
             hr.Carpool_Contact_Info__c = carpoolContactInfo.removeEnd('; ');
             updatedHours.add(hr);
           }
         }
	 updatedShifts.add( shift );
      }     
      try {
         update updatedShifts;
         update updatedHours;
      } catch (Exception e) {
         System.debug(e);
      }
   }
   alreadyinThisMethod = False;
  }

  public static String buildCarpoolInfo(String cpInfo, Contact c) {
    String phoneString = '';
    String emailString = '';
    String conjunction = '';

    if(c.Phone != null) phoneString = c.Phone;
    if(c.Email != null) emailSTring = c.Email;
    if(c.Phone != null && c.Email != null) conjunction = ', ';
    cpInfo += c.Name +' ['+phoneString+conjunction+emailString+']; ';
    return cpInfo;
    
  }

  static testMethod void testCarpoolRollup() {
        // set up intial test data
        Account acc = new Account(name='Test Individual Bucket Account');
        insert acc;

        Contact con = new Contact(Lastname='Testy', Firstname='Test', Email='test@testy.com', AccountId=acc.Id, Volunteer_Share_Information_for_Carpool__c=True);
        insert con;
        Contact con2 = new Contact(Lastname='NoShare', Firstname='Test', Email='test@testy.com', AccountId=acc.Id, Volunteer_Share_Information_for_Carpool__c=False);
        insert con2;

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
        
        GW_Volunteers__Volunteer_Hours__c hrs1 = new GW_Volunteers__Volunteer_Hours__c(GW_Volunteers__Contact__c=con.Id, GW_Volunteers__Volunteer_Job__c=job.Id, GW_Volunteers__Volunteer_Shift__c=shift.Id,
                                        GW_Volunteers__Number_of_Volunteers__c=1,GW_Volunteers__Start_Date__c=Date.Today(), GW_Volunteers__Status__c='Confirmed');
        GW_Volunteers__Volunteer_Hours__c hrs2 = new GW_Volunteers__Volunteer_Hours__c(GW_Volunteers__Contact__c=con2.Id, GW_Volunteers__Volunteer_Job__c=job.Id, GW_Volunteers__Volunteer_Shift__c=shift.Id,
                                        GW_Volunteers__Number_of_Volunteers__c=1,GW_Volunteers__Start_Date__c=Date.Today(), GW_Volunteers__Status__c='Confirmed');


        shift = [SELECT Id, Carpool_Contact_Info__c from GW_Volunteers__Volunteer_Shift__c where Id =: shift.Id];
        System.AssertEquals( shift.Carpool_Contact_Info__c, null );
        insert hrs2;
        shift = [SELECT Id, Carpool_Contact_Info__c from GW_Volunteers__Volunteer_Shift__c where Id =: shift.Id];
        System.AssertEquals( shift.Carpool_Contact_Info__c, null );
        insert hrs1;
        shift = [SELECT Id, Carpool_Contact_Info__c from GW_Volunteers__Volunteer_Shift__c where Id =: shift.Id];
        System.Assert( shift.Carpool_Contact_Info__c.contains('Testy') );


  }


}