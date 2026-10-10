-- New fictional demonstration. Run only in a fresh disposable database.
IF DB_NAME() IN ('master','model','msdb','tempdb')
    THROW 51000, 'Use a dedicated disposable database.', 1;
IF SCHEMA_ID('demo') IS NOT NULL
    THROW 51000, 'demo schema already exists; refusing to overwrite.', 1;
GO
CREATE SCHEMA demo;
GO
CREATE TABLE demo.Merchant (MerchantId varchar(30) NOT NULL PRIMARY KEY);
CREATE TABLE demo.Tail (
    TailId varchar(30) NOT NULL PRIMARY KEY,
    MerchantId varchar(30) NOT NULL UNIQUE REFERENCES demo.Merchant(MerchantId)
);
CREATE TABLE demo.Operator (OperatorId varchar(30) NOT NULL PRIMARY KEY);
CREATE TABLE demo.OperatorMerchant (
    OperatorId varchar(30) NOT NULL REFERENCES demo.Operator(OperatorId),
    MerchantId varchar(30) NOT NULL REFERENCES demo.Merchant(MerchantId),
    PRIMARY KEY (OperatorId, MerchantId)
);
-- Raw staging mappings deliberately allow duplicates, bad destinations and conflicts.
CREATE TABLE demo.MerchantMapping (
    MappingRowId int IDENTITY PRIMARY KEY,
    OldMerchantId varchar(30) NOT NULL,
    NewMerchantId varchar(30) NOT NULL
);
-- ParentRecord is a fictional obsolete directory entry, not the merchant itself.
CREATE TABLE demo.ParentRecord (
    ParentId varchar(30) NOT NULL PRIMARY KEY,
    MerchantId varchar(30) NOT NULL REFERENCES demo.Merchant(MerchantId),
    IsRedundant bit NOT NULL
);
CREATE TABLE demo.ParentDependency (
    DependencyId varchar(30) NOT NULL PRIMARY KEY,
    ParentId varchar(30) NOT NULL REFERENCES demo.ParentRecord(ParentId)
);
CREATE TABLE demo.RepairAudit (
    AuditId bigint IDENTITY PRIMARY KEY,
    RunId uniqueidentifier NOT NULL,
    EntityType varchar(20) NOT NULL,
    EntityId varchar(30) NOT NULL,
    BeforeMerchantId varchar(30) NOT NULL,
    AfterMerchantId varchar(30) NULL,
    ChangedAt datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE TABLE demo.FeedState (
    SourceName char(1) NOT NULL PRIMARY KEY CHECK (SourceName IN ('A','B')),
    IsAvailable bit NOT NULL,
    CoverageThrough datetime2(0) NOT NULL
);
CREATE TABLE demo.EventFeed (
    FeedRowId int IDENTITY PRIMARY KEY,
    SourceName char(1) NOT NULL REFERENCES demo.FeedState(SourceName),
    EventId varchar(30) NOT NULL,
    OccurredAt datetime2(0) NOT NULL,
    IngestedAt datetime2(0) NOT NULL,
    Region varchar(30) NULL,
    Channel varchar(30) NULL,
    CHECK (IngestedAt >= OccurredAt)
);
GO
-- Global validation: reject all mappings if any raw input is unsupported.
CREATE VIEW demo.RepairPlan AS
WITH M AS (
    SELECT OldMerchantId, MIN(NewMerchantId) AS NewMerchantId,
           COUNT(DISTINCT NewMerchantId) AS DestinationCount,
           COUNT(*) AS MappingRows
    FROM demo.MerchantMapping GROUP BY OldMerchantId
)
SELECT M.*, T.TailId,
    CASE
      WHEN DestinationCount <> 1 THEN 'conflicting_mapping'
      WHEN M.OldMerchantId = M.NewMerchantId THEN 'self_mapping'
      WHEN O.MerchantId IS NULL THEN 'missing_origin'
      WHEN N.MerchantId IS NULL THEN 'missing_destination'
      WHEN EXISTS (SELECT 1 FROM demo.MerchantMapping X WHERE X.OldMerchantId=M.NewMerchantId)
        THEN 'unsupported_chain_or_cycle'
      WHEN EXISTS (SELECT 1 FROM M X WHERE X.NewMerchantId=M.NewMerchantId AND X.OldMerchantId<>M.OldMerchantId)
        THEN 'multiple_origins_same_destination'
      WHEN T.TailId IS NOT NULL AND EXISTS (SELECT 1 FROM demo.Tail X WHERE X.MerchantId=M.NewMerchantId)
        THEN 'destination_has_tail'
      WHEN T.TailId IS NOT NULL THEN 'ready'
      WHEN EXISTS (SELECT 1 FROM demo.Tail X WHERE X.MerchantId=M.NewMerchantId)
        THEN 'already_correct_or_no_old_tail'
      ELSE 'no_tail'
    END AS PlanStatus
FROM M
LEFT JOIN demo.Merchant O ON O.MerchantId=M.OldMerchantId
LEFT JOIN demo.Merchant N ON N.MerchantId=M.NewMerchantId
LEFT JOIN demo.Tail T ON T.MerchantId=M.OldMerchantId;
GO
