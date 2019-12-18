--|--------------------------------------------------------------------------------
--| 1. Вывести список всех терминальных элементов
--|--------------------------------------------------------------------------------
-- DELETE FROM nested;
-- call AddLeaf('A');
-- call AddLeaf('B', 'A');
-- call AddLeaf('C', 'A');
-- call AddLeaf('D', 'B');
-- call AddLeaf('E', 'B');
-- call AddLeaf('F', 'A');
-- call AddLeaf('M', 'C');
-- call AddLeaf('N', 'C');
-- 
-- call GetNodesWithoutChildren();

--|--------------------------------------------------------------------------------
--| 2. Найти корень дерева
--|--------------------------------------------------------------------------------
-- DELETE FROM nested;
-- call AddLeaf('A');
-- call AddLeaf('B', 'A');
-- call AddLeaf('C', 'A');
-- 
-- call FindRoot();

--|--------------------------------------------------------------------------------
--| 3. Определить длину максимального пути (глубину) дерева
--|--------------------------------------------------------------------------------
-- DELETE FROM nested;
-- call AddLeaf('A');
-- call AddLeaf('B', 'A');
-- call AddLeaf('C', 'A');
-- call AddLeaf('D', 'B');
-- call AddLeaf('E', 'B');
-- call AddLeaf('F', 'A');
-- call AddLeaf('M', 'C');
-- call AddLeaf('N', 'C');
-- call GetMaxDepth();

--|--------------------------------------------------------------------------------
--| 4. Вывести все пути по одному (двум, трем, ...) уровням в дереве
--|--------------------------------------------------------------------------------
-- DELETE FROM nested;
-- call AddLeaf('A');
-- call AddLeaf('B', 'A');
-- call AddLeaf('C', 'A');
-- call AddLeaf('D', 'B');
-- call AddLeaf('E', 'B');
-- call AddLeaf('F', 'A');
-- call AddLeaf('M', 'C');
-- call AddLeaf('N', 'C');
-- 
-- call GetAllDestinations();

--|--------------------------------------------------------------------------------
--| 5. Суммирование данных узлов по поддереву от заданного корня
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

call Summarize('A');
call Summarize('B');
call Summarize('C');
call Summarize('M');
call GetParentChildPairs();

--|--------------------------------------------------------------------------------
--| 6. Вычислить уровень иерархии данного узла
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

call GetNodeHierarchyLevel('A');
call GetNodeHierarchyLevel('B');
call GetNodeHierarchyLevel('N');
