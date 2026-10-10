CREATE OR ALTER PROCEDURE demo.ApplyIdentityRepair
 @ExpectedTailChanges int,
 @ForceFailure bit=0 -- test fixture only: fail after mutations but before commit
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @ExpectedTailChanges IS NULL OR @ExpectedTailChanges<0
   THROW 51001, 'Expected non-negative tail change count required.', 1;
 DECLARE @RunId uniqueidentifier=NEWID(), @OwnTransaction bit=IIF(@@TRANCOUNT=0,1,0);
 BEGIN TRY
   IF @OwnTransaction=1 BEGIN TRAN; ELSE SAVE TRAN IdentityRepair;
   -- Small demonstration: serializable table/range locks prevent stale previews
   -- and concurrent dependency inserts. Coarse locking is deliberate here.
   DECLARE @LockCount bigint;
   SELECT @LockCount=COUNT_BIG(*) FROM demo.MerchantMapping WITH (UPDLOCK,HOLDLOCK);
   SELECT @LockCount=COUNT_BIG(*) FROM demo.Merchant WITH (UPDLOCK,HOLDLOCK);
   SELECT @LockCount=COUNT_BIG(*) FROM demo.Tail WITH (UPDLOCK,HOLDLOCK);
   SELECT @LockCount=COUNT_BIG(*) FROM demo.OperatorMerchant WITH (UPDLOCK,HOLDLOCK);
   SELECT @LockCount=COUNT_BIG(*) FROM demo.ParentRecord WITH (UPDLOCK,HOLDLOCK);
   SELECT @LockCount=COUNT_BIG(*) FROM demo.ParentDependency WITH (UPDLOCK,HOLDLOCK);
   SELECT * INTO #Plan FROM demo.RepairPlan;
   IF EXISTS (SELECT 1 FROM #Plan WHERE PlanStatus NOT IN ('ready','already_correct_or_no_old_tail','no_tail'))
     THROW 51002, 'Mapping validation blocked repair; inspect preview.', 1;
   IF (SELECT COUNT(*) FROM #Plan WHERE PlanStatus='ready')<>@ExpectedTailChanges
     THROW 51003, 'Change count differs from expectation; re-preview.', 1;
   UPDATE T SET MerchantId=P.NewMerchantId
   OUTPUT @RunId,'tail',deleted.TailId,deleted.MerchantId,inserted.MerchantId
     INTO demo.RepairAudit(RunId,EntityType,EntityId,BeforeMerchantId,AfterMerchantId)
   FROM demo.Tail T JOIN #Plan P ON T.TailId=P.TailId AND T.MerchantId=P.OldMerchantId
   WHERE P.PlanStatus='ready';
   IF @@ROWCOUNT<>@ExpectedTailChanges
     THROW 51004, 'Unexpected mutation count.', 1;
   DELETE P
   OUTPUT @RunId,'parent',deleted.ParentId,deleted.MerchantId,NULL
     INTO demo.RepairAudit(RunId,EntityType,EntityId,BeforeMerchantId,AfterMerchantId)
   FROM demo.ParentRecord P
   WHERE P.IsRedundant=1
     AND EXISTS (SELECT 1 FROM #Plan M WHERE M.OldMerchantId=P.MerchantId)
     AND NOT EXISTS (SELECT 1 FROM demo.Tail T WHERE T.MerchantId=P.MerchantId)
     AND NOT EXISTS (SELECT 1 FROM demo.OperatorMerchant O WHERE O.MerchantId=P.MerchantId)
     AND NOT EXISTS (SELECT 1 FROM demo.ParentDependency D WHERE D.ParentId=P.ParentId);
   IF @ForceFailure=1 THROW 51005, 'Forced failure: all changes must roll back.', 1;
   IF @OwnTransaction=1 COMMIT;
   SELECT * FROM demo.RepairAudit WHERE RunId=@RunId ORDER BY AuditId;
   SELECT P.ParentId,'blocked_cleanup' AS CleanupStatus FROM demo.ParentRecord P
    WHERE P.IsRedundant=1 AND EXISTS(SELECT 1 FROM #Plan M WHERE M.OldMerchantId=P.MerchantId);
 END TRY
 BEGIN CATCH
   IF @OwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK;
   ELSE IF @OwnTransaction=0 AND XACT_STATE()=1 ROLLBACK TRAN IdentityRepair;
   -- A doomed caller transaction cannot roll back to a savepoint; caller must roll back.
   THROW;
 END CATCH
END;
GO
