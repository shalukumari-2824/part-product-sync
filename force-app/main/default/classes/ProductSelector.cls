/**
 * @description Selector class for Product2 object queries
 * @author shalu kumari
 * @date 2025
 */
public with sharing class ProductSelector {
    
    /**
     * @description Get products by product codes
     * @param productCodes Set of product codes to query
     * @return Map of product code to Product2 record
     */
    public Map<String, Product2> getProductsByProductCodes(Set<String> productCodes) {
        Map<String, Product2> productMap = new Map<String, Product2>();
        
        List<Product2> products = [
            SELECT Id, Name, ProductCode, IsActive
            FROM Product2
            WHERE ProductCode IN :productCodes
            WITH SECURITY_ENFORCED
        ];
        
        for (Product2 prod : products) {
            if (String.isNotBlank(prod.ProductCode)) {
                productMap.put(prod.ProductCode, prod);
            }
        }
        
        return productMap;
    }
}