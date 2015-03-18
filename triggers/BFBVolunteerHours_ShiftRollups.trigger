// Written by Patrick Tewson at 501 Commons

trigger BFBVolunteerHours_ShiftRollups on GW_Volunteers__Volunteer_Hours__c (before delete, after insert, after undelete, after update) {
   if(Trigger.isDelete) {
      BFBVolunteerShiftRollups.rollupCarpoolContact(trigger.old, trigger.new);
   } else {
      BFBVolunteerShiftRollups.rollupCarpoolContact(null, trigger.new);
   }
}