CREATE OR ALTER PROCEDURE demo.ReconcileReports
 @ReportingDate date, @Cutoff datetime2(0),
 @ResultSet varchar(12)='all' -- summary / reasons / all for reproducible assertions
AS
BEGIN
 SET NOCOUNT ON;
 IF @ResultSet NOT IN ('summary','reasons','all') THROW 51011, 'Invalid result selection.', 1;
 IF @ReportingDate IS NULL OR @Cutoff IS NULL
   THROW 51010, 'Explicit date and cutoff required.', 1;
 DECLARE @Start datetime2(0)=CAST(@ReportingDate AS datetime2(0)),
         @End datetime2(0)=DATEADD(day,1,CAST(@ReportingDate AS datetime2(0)));
 -- Missing/incomplete source is not confirmed zero. Stop comparable totals.
 IF (SELECT COUNT(*) FROM demo.FeedState WHERE IsAvailable=1 AND CoverageThrough>=@Cutoff)<>2
 BEGIN
   SELECT S.SourceName, 'unavailable_or_incomplete' AS ReportStatus,
     CAST(NULL AS int) AS DistinctEvents, CAST(NULL AS int) AS DuplicateRows,
     CAST(NULL AS int) AS UnknownChannelEvents
   FROM (VALUES('A'),('B')) S(SourceName)
   LEFT JOIN demo.FeedState F ON F.SourceName=S.SourceName
   WHERE F.SourceName IS NULL OR F.IsAvailable=0 OR F.CoverageThrough<@Cutoff;
   RETURN;
 END;
 -- Repeated event IDs can have contradictory payloads; do not pick one silently.
 SELECT SourceName,EventId,MIN(OccurredAt) AS OccurredAt,
   MIN(IngestedAt) AS FirstIngestedAt,COUNT(*) AS AvailableRows,
   CASE WHEN COUNT(DISTINCT OccurredAt)>1
     OR COUNT(DISTINCT COALESCE(Region,'UNKNOWN'))>1
     OR COUNT(DISTINCT COALESCE(Channel,'UNKNOWN'))>1 THEN 1 ELSE 0 END AS PayloadConflict,
   CASE WHEN COUNT(DISTINCT COALESCE(Region,'UNKNOWN'))>1 THEN 'AMBIGUOUS'
     ELSE MIN(COALESCE(Region,'UNKNOWN')) END AS Region,
   CASE WHEN COUNT(DISTINCT COALESCE(Channel,'UNKNOWN'))>1 THEN 'AMBIGUOUS'
     ELSE MIN(COALESCE(Channel,'UNKNOWN')) END AS Channel
 INTO #Events FROM demo.EventFeed
 WHERE IngestedAt<=@Cutoff GROUP BY SourceName,EventId;
 -- Filter after global identity comparison, so cross-day conflicts are visible.
 IF EXISTS (SELECT 1 FROM #Events WHERE PayloadConflict=1)
 BEGIN
   SELECT DISTINCT SourceName, 'conflicting_payloads' AS ReportStatus,
     CAST(NULL AS int) AS DistinctEvents,CAST(NULL AS int) AS DuplicateRows,
     CAST(NULL AS int) AS UnknownChannelEvents
   FROM #Events WHERE PayloadConflict=1;
   RETURN;
 END;
 DELETE FROM #Events WHERE OccurredAt<@Start OR OccurredAt>=@End;
 SELECT S.SourceName,CAST('available' AS varchar(30)) AS ReportStatus,COUNT(E.EventId) AS DistinctEvents,
   COALESCE(SUM(E.AvailableRows-1),0) AS DuplicateRows,
   COALESCE(SUM(CASE WHEN E.Channel NOT IN ('Retail','Freelance') THEN 1 ELSE 0 END),0) AS UnknownChannelEvents
 INTO #Summary
 FROM (VALUES('A'),('B')) S(SourceName)
 LEFT JOIN #Events E ON E.SourceName=S.SourceName GROUP BY S.SourceName;
 IF @ResultSet IN ('summary','all') SELECT * FROM #Summary ORDER BY SourceName;
 IF @ResultSet='summary' RETURN;
 IF @ResultSet='all' SELECT SourceName,Region,Channel,COUNT(*) AS DistinctEvents
 FROM #Events GROUP BY SourceName,Region,Channel;
 SELECT COALESCE(A.EventId,B.EventId) AS EventId,
   CASE WHEN A.EventId IS NULL THEN
      CASE WHEN EXISTS (SELECT 1 FROM demo.EventFeed F WHERE F.SourceName='A' AND F.EventId=B.EventId AND F.IngestedAt>@Cutoff)
        THEN 'late_in_A' ELSE 'not_observed_in_A' END
    WHEN B.EventId IS NULL THEN
      CASE WHEN EXISTS (SELECT 1 FROM demo.EventFeed F WHERE F.SourceName='B' AND F.EventId=A.EventId AND F.IngestedAt>@Cutoff)
        THEN 'late_in_B' ELSE 'not_observed_in_B' END
    WHEN A.OccurredAt<>B.OccurredAt OR A.Region<>B.Region OR A.Channel<>B.Channel THEN 'payload_mismatch'
    ELSE 'equal' END AS Reason
 FROM (SELECT * FROM #Events WHERE SourceName='A') A
 FULL JOIN (SELECT * FROM #Events WHERE SourceName='B') B ON A.EventId=B.EventId
 ORDER BY COALESCE(A.EventId,B.EventId);
END;
GO
