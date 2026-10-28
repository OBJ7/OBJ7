/* Redacted adaptation of a real working reporting revision.
   Public names, dates and records are replacements, not production data.
   No commercial thresholds, mail configuration or internal objects included.
   SQL Server 2012+; native execution of this adaptation NOT YET VERIFIED.
   The query changes no persistent data. See daily-transitions.md. */
SET NOCOUNT ON;

DECLARE @DailyState TABLE (
    snapshot_date date NOT NULL,
    entity_id varchar(20) NOT NULL,
    is_active bit NOT NULL
);

INSERT @DailyState (snapshot_date, entity_id, is_active) VALUES
('20000101', 'E-A', 1), ('20000101', 'E-B', 1),
('20000101', 'E-C', 1), ('20000101', 'E-D', 0),
('20000102', 'E-A', 0), ('20000102', 'E-B', 1),
('20000102', 'E-B', 1), ('20000102', 'E-D', 1);

DECLARE @ReportDate date, @PriorDate date;
SELECT @ReportDate = MAX(snapshot_date) FROM @DailyState;
IF @ReportDate IS NULL
    THROW 51001, 'No current snapshot is available.', 1;
SET @PriorDate = DATEADD(day, -1, @ReportDate);

IF NOT EXISTS (SELECT 1 FROM @DailyState WHERE snapshot_date = @PriorDate)
    THROW 51002, 'Prior calendar date is unavailable; do not report a zero.', 1;

IF EXISTS (
    SELECT 1 FROM @DailyState
    WHERE snapshot_date IN (@ReportDate, @PriorDate)
    GROUP BY snapshot_date, entity_id
    HAVING MIN(CONVERT(int, is_active)) <> MAX(CONVERT(int, is_active))
)
    THROW 51003, 'Conflicting entity/date states require investigation.', 1;

DECLARE @Transitions TABLE (
    entity_id varchar(20) NOT NULL PRIMARY KEY,
    classification varchar(30) NOT NULL
);

;WITH daily AS (
    SELECT snapshot_date, entity_id, MAX(CONVERT(int, is_active)) AS is_active
    FROM @DailyState
    WHERE snapshot_date IN (@ReportDate, @PriorDate)
    GROUP BY snapshot_date, entity_id
)
INSERT @Transitions (entity_id, classification)
SELECT prior.entity_id,
       CASE WHEN current_day.entity_id IS NULL THEN 'MISSING_CURRENT'
            WHEN current_day.is_active = 0 THEN 'NEWLY_INACTIVE'
            ELSE 'STILL_ACTIVE' END
FROM daily AS prior
LEFT JOIN daily AS current_day
  ON current_day.snapshot_date = @ReportDate
 AND current_day.entity_id = prior.entity_id
WHERE prior.snapshot_date = @PriorDate AND prior.is_active = 1;

SELECT @ReportDate AS report_date, @PriorDate AS prior_date,
       entity_id, classification
FROM @Transitions ORDER BY entity_id;

SELECT SUM(CASE WHEN classification = 'NEWLY_INACTIVE' THEN 1 ELSE 0 END)
           AS newly_inactive,
       SUM(CASE WHEN classification = 'MISSING_CURRENT' THEN 1 ELSE 0 END)
           AS missing_current_exceptions
FROM @Transitions;
