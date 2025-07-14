public class LeadConversionController {

    
//Lead response wrapper
public class LeadOutputWrapper {
    @AuraEnabled public Boolean success;
    @AuraEnabled public String message;
    @AuraEnabled public String leadId;
    @AuraEnabled public String opportunityId;
    @AuraEnabled public String emirateCity;
}

//method to check duplicates and create create lead
    @AuraEnabled
    public static LeadOutputWrapper checkDuplicateAndCreateLead(String name, String email, String phone, String emirate) {
       
        LeadOutputWrapper response = new LeadOutputWrapper();
        phone = phone != null ? phone.replaceAll('[^0-9]', '') : '';
        List<Lead> leadList=new List<Lead>();
        List<Contact> existingContacts = [
          
            SELECT Id FROM Contact WHERE Phone = :phone LIMIT 1
        ];
        List<Lead> existingLeads = [
            SELECT Id FROM Lead WHERE Phone = :phone LIMIT 1
        ];
        //check for duplicates
        if (!existingContacts.isEmpty() || !existingLeads.isEmpty()) {
            response.success = false;
            response.message = 'Phone number already registered.';
            return response;
        }
        //lead creation
        try {
            Lead newLead = new Lead(
                LastName = name != null ? name : 'No Name',
                Email = email,
                Phone = phone,
                Company = name + ' Web Signup',
                Emirate__c = emirate,
                Description = 'Signup from portal - Emirate: ' + emirate
            );
            leadList.add(newLead);
            insert leadList;

            response.success = true;
            response.leadId = leadList[0].Id;
            response.message = 'Lead created successfully';
        } catch (Exception e) {
            response.success = false;
            response.message = 'Error creating lead: ' + e.getMessage();
        }

        return response;
    }

//Lead conversion call
    @AuraEnabled
    public static LeadOutputWrapper convertLeadToOpportunity(String leadId, String opptyName) {
        LeadOutputWrapper result = new LeadOutputWrapper();

        try {
            Lead leadRecord = [
                SELECT Id, Email, LastName, Company, Emirate__c
                FROM Lead
                WHERE Id = :leadId
                LIMIT 1
            ];
            
            LeadStatus convertStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
            /* Commented the code as it for checking any contact with email, if exists - oppty will be created and assocaited to respective
            contact and its account*/
           /*
            List<Opportunity> opptyList= new List<Opportunity>();
            if (String.isNotBlank(leadRecord.Email)) {
                List<Contact> existingContacts = [
                    SELECT Id, AccountId FROM Contact WHERE Email = :leadRecord.Email LIMIT 1
                ];
                if (!existingContacts.isEmpty()) {
                    Opportunity oppty = new Opportunity();
                    oppty.Name = leadRecord.LastName + ' from Web Signup';
                    oppty.CloseDate = System.today().addMonths(3);
                    oppty.StageName = 'Qualification';

                    if (existingContacts[0].AccountId != null) {
                        oppty.AccountId = existingContacts[0].AccountId;
                    } else {
                        Account acc = new Account(Name = opptyName);
                        insert acc;
                        oppty.AccountId = acc.Id;
                    }
                    opptyList.add(oppty);

                    insert opptyList;
                    List<OpportunityContactRole> opptyRoles=new List<OpportunityContactRole>();
                    for(Opportunity opp:opptyList ){
                    if (oppty.Id != null) {
                        OpportunityContactRole role = new OpportunityContactRole(
                            OpportunityId = oppty.Id,
                            ContactId = existingContacts[0].Id,
                            Role = 'Decision Maker',
                            IsPrimary = true
                        );
                        opptyRoles.add(role);

                    }
                        insert opptyRoles;

                        leadRecord.Status = convertStatus.MasterLabel;
                        update leadRecord;
                    }

                    result.success = true;
                    result.message = 'Lead converted to Opportunity.';
                    result.opportunityId = oppty.Id;
                    result.emirateCity = leadRecord.Emirate__c;
                    return result;
                }
            }
            
           */
          //Lead conversion using standard lead Conversion
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(leadId);
            lc.setDoNotCreateOpportunity(false);
            lc.setOpportunityName(leadRecord.LastName + ' from Web Signup');
            lc.setConvertedStatus(convertStatus.MasterLabel);

            Database.LeadConvertResult lcr = Database.convertLead(lc);
            if (lcr.isSuccess()) {
                result.success = true;
                result.message = 'Lead converted to Opportunity.';
                result.opportunityId = lcr.getOpportunityId();
                result.emirateCity = leadRecord.Emirate__c;
            } else {
                result.success = false;
                result.message = 'Lead conversion failed.';
            }
        } catch (Exception e) {
            result.success = false;
            result.message = 'Error during conversion: ' + e.getMessage();
        }
        return result;
    }
}