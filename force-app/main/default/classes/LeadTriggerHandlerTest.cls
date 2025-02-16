@IsTest

public with sharing class LeadTriggerHandlerTest {

    @IsTest
    public static void handleTitleNormalization_Test(){
        List<String> titleVariations = new List<String>{
            'vp', 'v.p.', 'Vice President', 'mgr', 'manage', 'head of department', 'exec',
            'chief', 'head', 'assist', 'deputy', 'jr'
        };
        
        List<Lead> leadList = new List<Lead>();
        
        for (String title : titleVariations) {
            leadList.add(new Lead(FirstName = 'Test', LastName = 'User', Title = title, Company = 'Test Company'));
        }
        
        insert leadList;
        
        // Now, query and assert that the normalization worked
        List<Lead> updatedLeads = [SELECT Id, Title FROM Lead WHERE Id IN :leadList];
        
        Map<String, String> expectedTitleMap = new Map<String, String>{
            'vp' => 'Vice President',
            'v.p.' => 'Vice President',
            'vice president' => 'Vice President',

            'mgr' => 'Manager',
            'manage' => 'Manager',
            'head of department' => 'Manager',

            'exec' => 'Executive',
            'chief' => 'Executive',
            'head' => 'Executive',

            'assist' => 'Assistant',
            'deputy' => 'Assistant',
            'jr' => 'Assistant'
        };
        
        for (Lead updatedLead : updatedLeads) {
            if(expectedTitleMap.containsKey(updatedLead.Title)){
            System.assertEquals(expectedTitleMap.get(leadList[updatedLeads.indexOf(updatedLead)].Title), updatedLead.Title, 'Title normalization failed for: ' + updatedLead.Title);
            }
        }  
    }
    @IsTest
    public static void handleAutoLeadScoring_Test(){
        
        List<Lead> leads = new List<Lead>{
        
        new Lead(Company = 'One', LastName = 'Doe1', LeadSource = null, Email = null, Phone = null, Industry = 'Healthcare'),
        new Lead(Company = 'One', LastName = 'Doe2', LeadSource = null, Email = null, Phone = '1234567980', Industry = 'Healthcare'),
        new Lead(Company = 'One', LastName = 'Doe3', LeadSource = null, Email = null, Phone = '1234567980', Industry = 'Technology'),
        new Lead(Company = 'One', LastName = 'Doe4', LeadSource = null, Email = null, Phone = null, Industry = 'Technology'),
        
        new Lead(Company = 'One', LastName = 'Doe5', LeadSource = 'Website', Email = null, Phone = null, Industry = 'Healthcare'),
        new Lead(Company = 'One', LastName = 'Doe6', LeadSource = 'Website', Email = null, Phone = '1234567980', Industry = 'Healthcare'),
        new Lead(Company = 'One', LastName = 'Doe7', LeadSource = 'Website', Email = null, Phone = '1234567980', Industry = 'Technology'),
        new Lead(Company = 'One', LastName = 'Doe8', LeadSource = 'Website', Email = null, Phone = null, Industry = 'Technology'),
        
        new Lead(Company = 'One', LastName = 'Doe9', LeadSource = null, Email = 'test@example.com', Phone = null, Industry = 'Healthcare'),
        new Lead(Company = 'One', LastName = 'Doe10', LeadSource = null, Email = 'test@example.com', Phone = '1234567980', Industry = 'Healthcare'),
        new Lead(Company = 'One', LastName = 'Doe11', LeadSource = null, Email = 'test@example.com', Phone = '1234567980', Industry = 'Technology'),
        new Lead(Company = 'One', LastName = 'Doe12', LeadSource = null, Email = 'test@example.com', Phone = null, Industry = 'Technology'),
        
        new Lead(Company = 'One', LastName = 'Doe13', LeadSource = 'Website', Email = 'test@example.com', Phone = null, Industry = 'Healthcare'),
        new Lead(Company = 'One', LastName = 'Doe14', LeadSource = 'Website', Email = 'test@example.com', Phone = null, Industry = 'Technology'),
        new Lead(Company = 'One', LastName = 'Doe15', LeadSource = 'Website', Email = 'test@example.com', Phone = '1234567980', Industry = 'Healthcare'),
        new Lead(Company = 'One', LastName = 'Doe16', LeadSource = 'Website', Email = 'test@example.com', Phone = '1234567980', Industry = 'Technology')
        };
        
        Test.startTest();
        LeadTriggerHandler.handleAutoLeadScoring(leads);
        Test.stopTest();
        
        // Query updated leads and validate scoring logic
            List<Lead> updatedLeads = [SELECT Id, LeadSource, Email, Phone, Industry, Lead_Score__c FROM Lead WHERE Id IN :leads];        
            // Add validation for expected scores
            for (Lead lead : updatedLeads) {
                Integer expectedScore = calculateExpectedScore(lead.LeadSource, lead.Email, lead.Phone, lead.Industry);
                System.assertEquals(expectedScore, lead.Lead_Score__c, 'Incorrect Lead Score for Lead: ' + lead.LastName);
            }
        }                
        // Helper function to determine the expected Lead Score dynamically
        public static Integer calculateExpectedScore(String leadSource, String email, String phone, String industry) {
            Integer score = 0;
        
            if (leadSource == 'Website' && email != null) {
                score += 3;
            }
            if (phone != null) {
                score += 5;
            }
            if (industry == 'Technology') {
                score += 10;
            }
        
            return Math.min(score, 18);
        }

        @isTest
        static void testLeadAutoConvert_SingleMatch() {
            // Create an Account
            Account acc = new Account(Name = 'Test Account');
            insert acc;
            
            // Create a Contact with an email
            List<Contact> newContacts = new List<Contact>();
            Contact con1 = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test@example.com', AccountId = acc.Id);
            newContacts.add(con1);
            Contact con2 = new Contact(FirstName = 'Jane', LastName = 'Doe', Email = 'him-her@example.com', AccountId = acc.Id);
            newContacts.add(con2);
            Contact con3 = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'him-her@example.com', AccountId = acc.Id);
            newContacts.add(con3);

            insert newContacts;
            // Create a Lead with the same email (should be converted)
            List<Lead> leadsToConvert = new List<Lead>();
            Lead leadConvo = new Lead(FirstName = 'Convert', LastName = 'Lead', Email = 'test@example.com', Company = 'Test Company');
            leadsToConvert.add(leadConvo);
            Lead leadNoConvo = new Lead(FirstName = 'NoConvert1', LastName = 'Lead', Email = 'fandango@example.com', Company = 'Test Company');
            leadsToConvert.add(leadNoConvo);
            Lead leadNoConvo2 = new Lead(FirstName = 'NoConvert', LastName = 'Lead', Email = 'him-her@example.com', Company = 'Test Company');
            leadsToConvert.add(leadNoConvo2);
            
            // Insert, but NOT testing trigger yet!
        
            // Now, **call the method directly** to avoid triggering other methods
            Test.startTest();
            LeadTriggerHandler.handleLeadAutoConvert(leadsToConvert);
            Test.stopTest();
        
            // Query the lead after running the method
            List<Lead> testLeads = [SELECT Id, IsConverted, Email, ConvertedContactId, ConvertedAccountId FROM Lead WHERE Id IN :leadsToConvert];
        
            // Assertions to check conversion success
                for(Lead l :testLeads){
                    if(l.Email == 'test@example.com'){  
                    System.assertEquals(true, l.IsConverted, 'Lead should be converted');
                    System.assertEquals(con1.Id, l.ConvertedContactId, 'Lead should be converted to the existing Contact');
                    System.assertEquals(acc.Id, l.ConvertedAccountId, 'Lead should be linked to the existing Account');                 
                
                } else if(l.Email == 'fandango@example.com'){
                    System.assertEquals(false, l.IsConverted, 'Lead with email fandango@example.com should not be converted.');
                
                } else if(l.Email == 'him-her@example.com'){
                    System.assertEquals(false, l.IsConverted, 'Lead with email fandango@example.com should not be converted.');
            }         
        }
    }
}    
    
