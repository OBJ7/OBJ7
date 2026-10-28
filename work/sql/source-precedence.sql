/* Redacted adaptation of a real working hierarchy correction.
   Names and fixtures are replacements, not production data.
   Read-only proposed result: no procedure patching or source deletion.
   SQL Server 2012+; native execution of this adaptation NOT YET VERIFIED. */
SET NOCOUNT ON;

DECLARE @SourceRows TABLE (
    source_row_key int NOT NULL,
    entity_id varchar(20) NOT NULL,
    source_kind varchar(20) NOT NULL,
    is_active bit NOT NULL,
    changed_at datetime2(0) NOT NULL
);

INSERT @SourceRows VALUES
(1, ' E-A ', 'SPECIALIST', 1, '20000101'),
(2, 'E-A', 'GENERAL', 1, '20000103'),
(3, 'E-B', 'GENERAL', 1, '20000102'),
(4, 'E-B', 'GENERAL', 1, '20000102'),
(5, 'E-C', 'GENERAL', 1, '20000101'),
(6, 'E-C', 'GENERAL', 0, '20000103'),
(7, ' ', 'GENERAL', 1, '20000102');

IF EXISTS (
    SELECT 1 FROM @SourceRows
    GROUP BY source_row_key HAVING COUNT(*) > 1
)
    THROW 51011, 'The final tie-break key must be unique.', 1;

-- Keep invalid business identifiers visible; do not silently discard them.
SELECT source_row_key, 'MISSING_ENTITY_ID' AS exception
FROM @SourceRows
WHERE NULLIF(LTRIM(RTRIM(entity_id)), '') IS NULL;

;WITH normalized AS (
    SELECT source_row_key, NULLIF(LTRIM(RTRIM(entity_id)), '') AS entity_id,
           source_kind, is_active, changed_at
    FROM @SourceRows
), candidates AS (
    SELECT * FROM normalized
    WHERE entity_id IS NOT NULL AND source_kind = 'SPECIALIST'
    UNION ALL
    SELECT general_row.* FROM normalized AS general_row
    WHERE general_row.entity_id IS NOT NULL
      AND general_row.source_kind = 'GENERAL'
      AND NOT EXISTS (
          SELECT 1 FROM normalized AS specialist
          WHERE specialist.entity_id = general_row.entity_id
            AND specialist.source_kind = 'SPECIALIST'
      )
), ranked AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY entity_id
        ORDER BY CASE WHEN source_kind = 'SPECIALIST' THEN 0 ELSE 1 END,
                 CASE WHEN is_active = 1 THEN 0 ELSE 1 END,
                 changed_at DESC, source_row_key
    ) AS selection_rank
    FROM candidates
)
SELECT entity_id, source_row_key, source_kind, is_active, changed_at
FROM ranked WHERE selection_rank = 1 ORDER BY entity_id;
