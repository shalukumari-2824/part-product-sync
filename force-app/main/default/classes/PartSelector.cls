/**
 * @description Selector class for Part object queries (Separation of Concerns)
 * @author shalu kumari
 * @date 2025
 */
public with sharing class PartSelector {
    
    /**
     * @description Get active parts without product reference
     * @return List of parts that need product assignment
     */
    public List<SQX_Part__c> getActivePartsWithoutProduct() {
        return [
            SELECT Id, Name, Part_Number__c, Active__c, Product__c
            FROM SQX_Part__c
            WHERE Active__c = true 
            AND Product__c = null
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate
        ];
    }
    
    /**
     * @description Get parts by part numbers
     * @param partNumbers Set of part numbers to query
     * @return List of matching parts
     */
    public List<SQX_Part__c> getPartsByPartNumbers(Set<String> partNumbers) {
        return [
            SELECT Id, Name, Part_Number__c, Active__c, Product__c
            FROM SQX_Part__c
            WHERE Part_Number__c IN :partNumbers
            WITH SECURITY_ENFORCED
        ];
    }
}