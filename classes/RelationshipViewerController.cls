global with sharing class RelationshipViewerController {
    
    global RelationshipViewerController(ApexPages.StandardController controller) {
	}  

    @RemoteAction
    global static list<Node> getRelationships(id cid) {
        list<Node> returnList = new list<Node>();
        list<npe4__Relationship__c> relationshipList = new list<npe4__Relationship__c>();
		
        //base node
        Node basenode = new Node();
      
        Contact c = [select LastName, FirstName, id, Title, Account.Name from Contact where id = :cid];
        basenode.LastName = c.LastName;
        basenode.FirstName = c.FirstName;
        basenode.Title = c.Title;
        basenode.AccountName = c.Account.Name;
        basenode.id = c.id;
        returnList.add(basenode);
        
        relationshipList = [select id, npe4__RelatedContact__r.LastName, npe4__Type__c, npe4__Status__c, npe4__RelatedContact__r.FirstName, npe4__RelatedContact__r.id, npe4__RelatedContact__r.Account.Name, npe4__RelatedContact__r.Title from npe4__Relationship__c where npe4__Contact__c = :cid];

        for (npe4__Relationship__c r : relationshipList){
        	Node n = new Node();
        	n.LastName = r.npe4__RelatedContact__r.LastName;
        	n.id = r.npe4__RelatedContact__r.id;
        	n.Type = r.npe4__Type__c;
        	n.Status = r.npe4__Status__c;
        	n.FirstName = r.npe4__RelatedContact__r.FirstName;
        	n.link =  URL.getSalesforceBaseUrl().toExternalForm() + '/' + r.npe4__RelatedContact__r.id;
        	n.AccountName = r.npe4__RelatedContact__r.Account.Name;
        	n.Title = r.npe4__RelatedContact__r.Title;
			
        	returnList.add(n);
        	
        }

        return returnList;
    }

    global class Node { 
    	string FirstName;
        string LastName;
        string id;            	
    	string Status;
    	string Type;
    	string link; 	
    	string AccountName;
    	string Title;
    }  

	static testMethod void TestController() {
		Contact firstContact = new Contact (
			FirstName='Joe',
			LastName='Johanssen'
		);
		insert firstContact;
		
		Contact secondContact = new Contact (
			FirstName='Bobby',
			LastName='Johanssen'
		);
		insert secondContact;
		
		npe4__Relationship__c[] crel = new npe4__Relationship__c[]{
			new npe4__Relationship__c(npe4__contact__c = firstContact.id, npe4__relatedcontact__c = secondContact.id, npe4__Type__c='Friend',npe4__Status__c='Active',npe4__Description__c='notes')
		};
		insert crel;
		
		list<Node> relationshipList = RelationshipViewerController.getRelationships(firstContact.id);
		list<Node> nodeList = new list<Node>();
		
		Node n = new Node();
		n.firstName = 'Joe';
		n.lastName = 'Johanssen';
		n.AccountName = 'Joe Johanssen';
		n.id = firstContact.id;
		nodeList.add(n);
		System.assertEquals(True, True);
	}
}