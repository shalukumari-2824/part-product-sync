/**
 * @description Test class for PartProductSyncScheduler
 * @author Shalu Kumari
 * @date 2025
 */
@IsTest
private class PartProductSyncSchedulerTest {
    
    /**
     * @description Test scheduling the job
     * Expected: Job should be scheduled successfully
     */
    @IsTest
    static void testScheduleJob() {
        Test.startTest();
        String jobId = PartProductSyncScheduler.scheduleDaily();
        Test.stopTest();
        
        // Verify job was scheduled
        System.assertNotEquals(null, jobId, 'Job ID should not be null');
        
        // Verify job exists
        CronTrigger ct = [
            SELECT Id, CronExpression, TimesTriggered, NextFireTime
            FROM CronTrigger 
            WHERE Id = :jobId
        ];
        
        System.assertEquals('0 0 6 * * ?', ct.CronExpression, 
            'Cron expression should be for daily 6 AM');
        System.assertEquals(0, ct.TimesTriggered, 
            'Job should not have been triggered yet');
    }
    
    /**
     * @description Test scheduler execution
     * Expected: Scheduler should execute without errors
     */
    @IsTest
    static void testSchedulerExecution() {
        // Create test data
        SQX_Part__c testPart = new SQX_Part__c(
            Name = 'Test Part',
            Part_Number__c = 'TEST-001',
            Active__c = true
        );
        insert testPart;
        
        Test.startTest();
        PartProductSyncScheduler scheduler = new PartProductSyncScheduler();
        String cronExp = '0 0 6 * * ?';
        String jobId = System.schedule('Test Job', cronExp, scheduler);
        Test.stopTest();
        
        // Verify job was scheduled
        System.assertNotEquals(null, jobId, 'Job should be scheduled');
    }
    
    /**
     * @description Test removing duplicate scheduled jobs
     * Expected: Old jobs should be removed, new job should be created
     */
    @IsTest
    static void testRemoveDuplicateJobs() {
        // Schedule first job
        String jobId1 = PartProductSyncScheduler.scheduleDaily();
        System.assertNotEquals(null, jobId1, 'First job should be scheduled');
        
        Test.startTest();
        // Schedule again (should remove first job)
        String jobId2 = PartProductSyncScheduler.scheduleDaily();
        Test.stopTest();
        
        System.assertNotEquals(null, jobId2, 'Second job should be scheduled');
        
        // Verify only one job exists
        List<CronTrigger> jobs = [
            SELECT Id 
            FROM CronTrigger 
            WHERE CronJobDetail.Name LIKE 'Part Product Sync%'
        ];
        
        System.assertEquals(1, jobs.size(), 
            'Should only have one scheduled job');
    }
}