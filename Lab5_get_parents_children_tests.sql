--|--------------------------------------------------------------------------------
--| AddLeaf tests
--|--------------------------------------------------------------------------------

--| 1 
--|--------------------------------------------------------------------------------
-- DELETE FROM nested;
-- call AddLeaf('A');
-- call AddLeaf('B', 'A');
-- call AddLeaf('C', 'B');
-- call AddLeaf('D', 'C');
-- call AddLeaf('E', 'D');
-- call AddLeaf('F', 'E');

--| 2 
--|--------------------------------------------------------------------------------
-- DELETE FROM nested;
-- call AddLeaf('A');
-- call AddLeaf('B', 'A');
-- call AddLeaf('C', 'B');
-- call AddLeaf('D', 'C');
-- call AddLeaf('E', 'D');
-- call AddLeaf('F', 'E');
-- call AddLeaf('G', 'F');
-- call AddLeaf('H', 'E');
-- call AddLeaf('J', 'D');

--| 3 
--|--------------------------------------------------------------------------------
-- DELETE FROM nested;
-- call AddLeaf('A');
-- call AddLeaf('B', 'A');
-- call AddLeaf('C', 'B');
-- call AddLeaf('D', 'C');
-- call AddLeaf('E', 'D');
-- call AddLeaf('F', 'E');
-- call AddLeaf('G', 'F');
-- call AddLeaf('H', 'E');
-- call AddLeaf('J', 'D');
-- call AddLeaf('K', 'J');
-- call AddLeaf('L', 'J');
-- call AddLeaf('M', 'J');

--|--------------------------------------------------------------------------------
--| RemoveLeaf tests
--|--------------------------------------------------------------------------------

--| 1 
--|--------------------------------------------------------------------------------
-- DELETE FROM nested;
-- call AddLeaf('A');
-- call AddLeaf('B', 'A');
-- call AddLeaf('C', 'A');
-- call RemoveLeaf('A'); -- fails
-- call RemoveLeaf('C');

--| 2
--|--------------------------------------------------------------------------------
-- DELETE FROM nested;
-- call AddLeaf('A');
-- call AddLeaf('B', 'A');
-- call AddLeaf('C', 'A');
-- call RemoveLeaf('C');
-- call RemoveLeaf('B');
-- call RemoveLeaf('A');

--| 3 
--|--------------------------------------------------------------------------------
-- DELETE FROM nested;
-- call AddLeaf('A');
-- call AddLeaf('B', 'A');
-- call AddLeaf('C', 'B');
-- call AddLeaf('D', 'C');
-- call AddLeaf('E', 'D');
-- call AddLeaf('F', 'E');
-- call AddLeaf('G', 'F');
-- call AddLeaf('H', 'E');
-- call AddLeaf('J', 'D');
-- call AddLeaf('K', 'J');
-- call AddLeaf('L', 'J');
-- call AddLeaf('M', 'J');
-- call RemoveLeaf('G');
-- call RemoveLeaf('L');
-- call RemoveLeaf('M');

--|--------------------------------------------------------------------------------
--| RemoveLeaf tests
--|--------------------------------------------------------------------------------

--| 1 
--|--------------------------------------------------------------------------------
-- DELETE FROM nested;
-- call AddLeaf('A');
-- call AddLeaf('B', 'A');
-- call AddLeaf('C', 'A');
-- call AddLeaf('D', 'B');
-- call AddLeaf('E', 'B');
-- call AddLeaf('F', 'C');
-- call AddLeaf('K', 'C');
-- call RemoveNode('B');

--| 2 
--|--------------------------------------------------------------------------------
-- DELETE FROM nested;
-- call AddLeaf('A');
-- call AddLeaf('B', 'A');
-- call AddLeaf('C', 'A');
-- call AddLeaf('D', 'B');
-- call AddLeaf('E', 'B');
-- call AddLeaf('F', 'C');
-- call AddLeaf('K', 'C');
-- call RemoveNode('C');

--| 3 
--|--------------------------------------------------------------------------------
DELETE FROM nested;
call AddLeaf('A');
call AddLeaf('B', 'A');
call AddLeaf('C', 'A');
call AddLeaf('D', 'B');
call AddLeaf('E', 'B');
call AddLeaf('M', 'D');
call AddLeaf('N', 'D');
call AddLeaf('F', 'C');
call AddLeaf('K', 'C');
call RemoveNode('B');