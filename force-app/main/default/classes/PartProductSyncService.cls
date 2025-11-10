/**
 * @class PartProductSyncService
 * @test class PartProductSyncServiceTest
 * @description Service class to synchronize Parts with Products
 * @author shalu kumari
 * @date 2025
 */
public with sharing class PartProductSyncService {
    
    private PartSelector partSelector;
    private ProductSelector productSelector;
    
    /**
     * @description Constructor with dependency injection for testability
     */
    public PartProductSyncService() {
        this.partSelector = new PartSelector();
        this.productSelector = new ProductSelector();
    }
    
    /**
     * @description Constructor with dependency injection for testing
     * @param partSelector Instance of PartSelector
     * @param productSelector Instance of ProductSelector
     */
    @TestVisible
    private PartProductSyncService(PartSelector partSelector, ProductSelector productSelector) {
        this.partSelector = partSelector;
        this.productSelector = productSelector;
    }
    
    /**
     * @description Main method to execute part-product synchronization
     * @return SyncResult containing success count and errors
     */
    public SyncResult synchronizeParts() {
        SyncResult result = new SyncResult();
        
        try {
            // Verify user has required permissions
            if (!hasRequiredPermissions()) {
                result.addError('User does not have required permissions (System Administrator + CQ Product Admin)');
                return result;
            }
            
            // Get active parts without product reference
            List<SQX_Part__c> partsToSync = partSelector.getActivePartsWithoutProduct();
            
            if (partsToSync.isEmpty()) {
                result.message = 'No parts to synchronize';
                return result;
            }
            
            // Collect part numbers for product lookup
            Set<String> partNumbers = extractPartNumbers(partsToSync);
            
            // Get existing products by product code (part number)
            Map<String, Product2> existingProducts = productSelector.getProductsByProductCodes(partNumbers);
            
            // Separate parts: those with existing products vs those needing new products
            Map<String, SQX_Part__c> partsNeedingNewProducts = new Map<String, SQX_Part__c>();
            List<SQX_Part__c> partsToUpdate = new List<SQX_Part__c>();
            
            for (SQX_Part__c part : partsToSync) {
                if (existingProducts.containsKey(part.Part_Number__c)) {
                    // Product exists, link it
                    part.Product__c = existingProducts.get(part.Part_Number__c).Id;
                    partsToUpdate.add(part);
                } else {
                    // Product doesn't exist, need to create it
                    partsNeedingNewProducts.put(part.Part_Number__c, part);
                }
            }
            
            // Create new products for parts that don't have matching products
            if (!partsNeedingNewProducts.isEmpty()) {
                Map<String, Id> newProductIds = createProducts(partsNeedingNewProducts.values());
                
                // Link parts to newly created products
                for (String partNumber : newProductIds.keySet()) {
                    SQX_Part__c part = partsNeedingNewProducts.get(partNumber);
                    part.Product__c = newProductIds.get(partNumber);
                    partsToUpdate.add(part);
                }
            }
            
            // Update all parts with product references
            if (!partsToUpdate.isEmpty()) {
                Database.SaveResult[] updateResults = Database.update(partsToUpdate, false);
                result.processResults(updateResults, partsToUpdate);
            }
            
        } catch (Exception e) {
            result.addError('Unexpected error: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString());
        }
        
        return result;
    }
    
    /**
     * @description Check if current user has required permissions
     * @return true if user is System Administrator with CQ Product Admin permission set
     */
    private Boolean hasRequiredPermissions() {
        try {
            // Check for System Administrator profile
            User currentUser = [SELECT Id, Profile.Name,(SELECT Id FROM PermissionSetAssignments WHERE PermissionSet.Name = 'CQ_Product_Admin') FROM User
                WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED LIMIT 1];
            
            Boolean isSystemAdmin = currentUser.Profile.Name == 'System Administrator';
            Boolean hasCQProductAdmin = !currentUser.PermissionSetAssignments.isEmpty();
            
            return isSystemAdmin && hasCQProductAdmin;
        } catch (Exception e) {
            System.debug('Error Line CQ:'+e.getLineNumber()+'Message::'+e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Extract part numbers from parts list
     * @param parts List of parts
     * @return Set of part numbers
     */
    private Set<String> extractPartNumbers(List<SQX_Part__c> parts) {
        Set<String> partNumbers = new Set<String>();
        for (SQX_Part__c part : parts) {
            if (String.isNotBlank(part.Part_Number__c)) {
                partNumbers.add(part.Part_Number__c);
            }
        }
        return partNumbers;
    }
    
    /**
     * @description Create new Product2 records from parts
     * @param parts List of parts needing new products
     * @return Map of part number to created product Id
     */
    private Map<String, Id> createProducts(List<SQX_Part__c> parts) {
        Map<String, Id> productIdMap = new Map<String, Id>();
        List<Product2> productsToInsert = new List<Product2>();
        
        for (SQX_Part__c part : parts) {
            Product2 newProduct = new Product2(
                Name = part.Name,
                ProductCode = part.Part_Number__c,
                IsActive = true
            );
            productsToInsert.add(newProduct);
        }
        
        if (!productsToInsert.isEmpty()) {
            Database.SaveResult[] insertResults = Database.insert(productsToInsert, false);
            
            for (Integer i = 0; i < insertResults.size(); i++) {
                if (insertResults[i].isSuccess()) {
                    productIdMap.put(productsToInsert[i].ProductCode, insertResults[i].getId());
                }
            }
        }
        
        return productIdMap;
    }
    
    /**
     * @description Inner class to hold synchronization results
     */
    public class SyncResult {
        public Integer successCount { get; private set; }
        public List<String> errors { get; private set; }
        public String message { get; set; }
        
        public SyncResult() {
            this.successCount = 0;
            this.errors = new List<String>();
            this.message = '';
        }
        
        public void addError(String error) {
            this.errors.add(error);
        }
        
        public void processResults(Database.SaveResult[] results, List<SQX_Part__c> parts) {
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    successCount++;
                } else {
                    String errorMsg = 'Part ' + parts[i].Name + ': ';
                    for (Database.Error err : results[i].getErrors()) {
                        errorMsg += err.getMessage() + '; ';
                    }
                    addError(errorMsg);
                }
            }
        }
        
        public Boolean hasErrors() {
            return !errors.isEmpty();
        }
    }
}