/**
 * Schedular Class PartProductSyncScheduler
 * Test class PartProductSyncSchedulerTest
 * @description Scheduler class to run Part-Product sync daily at 6 AM GMT
 * @author shalu Kumari
 * @date 2025
 */
public class PartProductSyncScheduler implements Schedulable {
    
    /**
     * @description This is used to execute method 
     * @param sc SchedulableContext
     */
    public void execute(SchedulableContext sc) {
        PartProductSyncService service = new PartProductSyncService();
        PartProductSyncService.SyncResult result = service.synchronizeParts();
        
        // Log results
        if (result.hasErrors()) {
            System.debug(LoggingLevel.ERROR, 'Part-Product Sync completed with errors: ' + result.errors);
        } else {
            System.debug(LoggingLevel.INFO, 'Part-Product Sync completed successfully. Records synced: ' + result.successCount);
        }
    }
    
    /**
     * @description Schedule the job to run daily at 6 AM GMT
     * @return Scheduled job Id
     */
    public static String scheduleDaily() {
        String cronExp = '0 0 6 * * ?'; // Daily at 6 AM
        String jobName = 'Part Product Sync - Daily 6 AM GMT';
        
        // Remove existing jobs with same name to avoid duplicates
        List<CronTrigger> existingJobs = [
            SELECT Id 
            FROM CronTrigger 
            WHERE CronJobDetail.Name = :jobName
        ];
        
        for (CronTrigger ct : existingJobs) {
            System.abortJob(ct.Id);
        }
        
        return System.schedule(jobName, cronExp, new PartProductSyncScheduler());
    }
}