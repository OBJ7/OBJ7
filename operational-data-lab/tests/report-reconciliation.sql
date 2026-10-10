-- Procedure-output assertions intended for SQL Server. NOT EXECUTED here.
SET XACT_ABORT ON;
BEGIN TRY
 BEGIN TRAN;
 CREATE TABLE #Summary(SourceName char(1),ReportStatus varchar(30),DistinctEvents int,DuplicateRows int,UnknownChannelEvents int);
 CREATE TABLE #Reasons(EventId varchar(30),Reason varchar(30));
 INSERT #Summary EXEC demo.ReconcileReports '20261009','2026-10-09T15:00:00','summary';
 IF (SELECT COUNT(*) FROM #Summary)<>2 THROW 51110,'Summary source count differs.',1;
 IF NOT EXISTS(SELECT 1 FROM #Summary WHERE SourceName='A' AND DistinctEvents=2 AND DuplicateRows=1 AND UnknownChannelEvents=1) THROW 51110,'A cutoff summary differs.',1;
 IF NOT EXISTS(SELECT 1 FROM #Summary WHERE SourceName='B' AND DistinctEvents=3 AND DuplicateRows=0 AND UnknownChannelEvents=1) THROW 51110,'B cutoff summary differs.',1;
 INSERT #Reasons EXEC demo.ReconcileReports '20261009','2026-10-09T15:00:00','reasons';
 IF (SELECT COUNT(*) FROM #Reasons)<>3 THROW 51110,'Event set differs.',1;
 IF NOT EXISTS(SELECT 1 FROM #Reasons WHERE EventId='EVENT-002' AND Reason='late_in_A') THROW 51110,'Late arrival unexplained.',1;
 IF (SELECT COUNT(*) FROM #Reasons WHERE Reason='equal')<>2 THROW 51110,'Comparable records differ.',1;
 TRUNCATE TABLE #Summary;
 INSERT #Summary EXEC demo.ReconcileReports '20261009','2026-10-10T00:00:00','summary';
 IF EXISTS(SELECT 1 FROM #Summary WHERE DistinctEvents<>3) THROW 51110,'Midnight boundary or full-day equality failed.',1;
 -- Zero and absent feed are distinct outputs.
 TRUNCATE TABLE #Summary;
 INSERT #Summary EXEC demo.ReconcileReports '20261008','2026-10-09T15:00:00','summary';
 IF EXISTS(SELECT 1 FROM #Summary WHERE DistinctEvents<>0 OR ReportStatus<>'available') THROW 51110,'Confirmed zero differs.',1;
 UPDATE demo.FeedState SET IsAvailable=0 WHERE SourceName='A';
 TRUNCATE TABLE #Summary;
 INSERT #Summary EXEC demo.ReconcileReports '20261009','2026-10-09T15:00:00','summary';
 IF NOT EXISTS(SELECT 1 FROM #Summary WHERE SourceName='A' AND DistinctEvents IS NULL AND ReportStatus='unavailable_or_incomplete') THROW 51110,'Unavailable was counted as zero.',1;
 UPDATE demo.FeedState SET IsAvailable=1 WHERE SourceName='A';
 -- Add a genuinely missing ID and a contradictory duplicate.
 INSERT demo.EventFeed(SourceName,EventId,OccurredAt,IngestedAt,Region,Channel)
 VALUES ('B','EVENT-MISSING','2026-10-09T01:00:00','2026-10-09T02:00:00','REGION-1','Retail');
 TRUNCATE TABLE #Reasons;
 INSERT #Reasons EXEC demo.ReconcileReports '20261009','2026-10-09T15:00:00','reasons';
 IF NOT EXISTS(SELECT 1 FROM #Reasons WHERE EventId='EVENT-MISSING' AND Reason='not_observed_in_A') THROW 51110,'Missing record not separated from lateness.',1;
 INSERT demo.EventFeed(SourceName,EventId,OccurredAt,IngestedAt,Region,Channel)
 VALUES ('A','EVENT-001','2026-10-09T00:00:00','2026-10-09T00:03:00','REGION-1','Freelance');
 TRUNCATE TABLE #Summary;
 INSERT #Summary EXEC demo.ReconcileReports '20261009','2026-10-09T15:00:00','summary';
 IF NOT EXISTS(SELECT 1 FROM #Summary WHERE ReportStatus='conflicting_payloads' AND DistinctEvents IS NULL) THROW 51110,'Conflict silently collapsed.',1;
 ROLLBACK;
 PRINT 'Reporting assertions completed; evidence only after actual execution.';
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
