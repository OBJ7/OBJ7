-- Intended SQL Server assertions; NOT EXECUTED in preparation environment.
-- Run against untouched fixtures. Expected errors may doom caller transaction.
SET XACT_ABORT ON;
BEGIN TRY
 BEGIN TRAN;
 EXEC demo.ApplyIdentityRepair @ExpectedTailChanges=1;
 IF NOT EXISTS(SELECT 1 FROM demo.Tail WHERE TailId='TAIL-001' AND MerchantId='MERCHANT-NEW-001') THROW 51100,'Tail repair failed.',1;
 IF (SELECT COUNT(*) FROM demo.OperatorMerchant)<>2
 OR NOT EXISTS(SELECT 1 FROM demo.OperatorMerchant WHERE OperatorId='OPERATOR-001' AND MerchantId='MERCHANT-NEW-001')
 OR NOT EXISTS(SELECT 1 FROM demo.OperatorMerchant WHERE OperatorId='OPERATOR-001' AND MerchantId='MERCHANT-NEW-002') THROW 51100,'Operator links changed.',1;
 IF NOT EXISTS(SELECT 1 FROM demo.Tail WHERE TailId='TAIL-002' AND MerchantId='MERCHANT-NEW-002') THROW 51100,'Already-correct tail changed.',1;
 IF EXISTS(SELECT 1 FROM demo.ParentRecord WHERE ParentId='PARENT-001') THROW 51100,'Eligible parent retained.',1;
 IF NOT EXISTS(SELECT 1 FROM demo.ParentRecord WHERE ParentId='PARENT-002') THROW 51100,'Referenced parent removed.',1;
 DECLARE @AuditCount int=(SELECT COUNT(*) FROM demo.RepairAudit);
 EXEC demo.ApplyIdentityRepair @ExpectedTailChanges=0;
 IF (SELECT COUNT(*) FROM demo.RepairAudit)<>@AuditCount THROW 51100,'Rerun mutated state.',1;
 ROLLBACK;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
-- Forced failure outside caller transaction checks full rollback.
DECLARE @ExpectedError int=0;
BEGIN TRY EXEC demo.ApplyIdentityRepair @ExpectedTailChanges=1,@ForceFailure=1; END TRY
BEGIN CATCH SET @ExpectedError=ERROR_NUMBER(); END CATCH;
IF @ExpectedError<>51005 THROW 51101,'Expected forced failure.',1;
IF NOT EXISTS(SELECT 1 FROM demo.Tail WHERE TailId='TAIL-001' AND MerchantId='MERCHANT-OLD-001') THROW 51101,'Rollback failed.',1;
IF NOT EXISTS(SELECT 1 FROM demo.ParentRecord WHERE ParentId='PARENT-001') THROW 51101,'Parent rollback failed.',1;
IF EXISTS(SELECT 1 FROM demo.RepairAudit) THROW 51101,'Failed run left audit rows.',1;
-- Each bad mapping fixture is isolated and rolled back.
DECLARE @Cases TABLE(CaseId int,OldId varchar(30),NewId varchar(30));
INSERT @Cases VALUES (1,'MERCHANT-OLD-001','MERCHANT-003'),
 (2,'MERCHANT-003','MISSING'),(3,'MERCHANT-003','MERCHANT-003'),
 (4,'MERCHANT-NEW-001','MERCHANT-OLD-001');
DECLARE @Case int=1,@Old varchar(30),@New varchar(30),@Error int;
WHILE @Case<=4
BEGIN
 SELECT @Old=OldId,@New=NewId FROM @Cases WHERE CaseId=@Case;
 SET @Error=0;
 BEGIN TRAN;
 INSERT demo.MerchantMapping VALUES (@Old,@New);
 BEGIN TRY EXEC demo.ApplyIdentityRepair @ExpectedTailChanges=1; END TRY
 BEGIN CATCH SET @Error=ERROR_NUMBER(); END CATCH;
 IF XACT_STATE()<>0 ROLLBACK;
 IF @Error<>51002 THROW 51102,'Bad mapping was not blocked.',1;
 SET @Case+=1;
END;
PRINT 'Identity assertions completed; this message is evidence only when actually run.';
