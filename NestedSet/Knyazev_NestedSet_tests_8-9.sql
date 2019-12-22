--|--------------------------------------------------------------------------------
--| 9. ¬ывести путь между двум€ узлами
--|--------------------------------------------------------------------------------
DELETE FROM nested;
call AddLeaf('A');
call AddLeaf('B', 'A');
call AddLeaf('C', 'A');
call AddLeaf('D', 'B');
call AddLeaf('E', 'B');
call AddLeaf('F', 'A');
call AddLeaf('M', 'C');
call AddLeaf('N', 'C');
call AddLeaf('L', 'C');
call AddLeaf('P', 'D');
call AddLeaf('G', 'D');
call AddLeaf('H', 'N');
call AddLeaf('I', 'N');

-- DELETE FROM path_in_nested;
-- call CreatePathInNested('P', 'A');
-- SELECT * FROM path_in_nested ORDER BY id;
-- 
-- DELETE FROM path_in_nested;
-- call CreatePathInNested('I', 'A');
-- SELECT * FROM path_in_nested ORDER BY id;
-- 
-- DELETE FROM path_in_nested;
-- call CreatePathInNested('M', 'D');
-- SELECT * FROM path_in_nested ORDER BY id;
-- 
-- DELETE FROM path_in_nested;
-- call CreatePathInNested('F', 'F');
-- SELECT * FROM path_in_nested ORDER BY id;

--|--------------------------------------------------------------------------------
--| 8. ¬ычислить разность уровней двух заданных узлов
--|--------------------------------------------------------------------------------
-- DELETE FROM path_in_nested;
-- call CreatePathInNested('P', 'A');
-- SELECT count(*)-1 as Diff FROM path_in_nested;
-- 
-- DELETE FROM path_in_nested;
-- call CreatePathInNested('I', 'A');
-- SELECT count(*)-1 AS Diff FROM path_in_nested;
--
-- DELETE FROM path_in_nested;
-- call CreatePathInNested('M', 'D');
-- SELECT count(*)-1 AS Diff FROM path_in_nested;
-- 
-- DELETE FROM path_in_nested;
-- call CreatePathInNested('F', 'F');
-- SELECT count(*)-1 AS Diff FROM path_in_nested;