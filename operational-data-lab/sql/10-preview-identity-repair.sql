-- Read-only preview. Apply must recheck; preview is not a lock or approval.
SELECT OldMerchantId, NewMerchantId, MappingRows, TailId, PlanStatus
FROM demo.RepairPlan ORDER BY OldMerchantId;
SELECT P.ParentId, P.MerchantId,
 CASE WHEN P.IsRedundant=0 THEN 'retain_not_redundant'
 WHEN EXISTS (SELECT 1 FROM demo.ParentDependency D WHERE D.ParentId=P.ParentId) THEN 'blocked_parent_dependency'
 WHEN EXISTS (SELECT 1 FROM demo.OperatorMerchant O WHERE O.MerchantId=P.MerchantId) THEN 'blocked_operator_link'
 WHEN EXISTS (SELECT 1 FROM demo.RepairPlan M WHERE M.OldMerchantId=P.MerchantId AND M.PlanStatus='ready') THEN 'cleanup_after_repair_if_revalidated'
 ELSE 'retain_or_recheck' END AS CleanupPreview
FROM demo.ParentRecord P ORDER BY P.ParentId;
