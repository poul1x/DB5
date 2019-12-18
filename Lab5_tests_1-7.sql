--|--------------------------------------------------------------------------------
--| 1. ������� ������ ���� ������������ ���������
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
--| 2. ����� ������ ������
--|--------------------------------------------------------------------------------
-- DELETE FROM nested;
-- call AddLeaf('A');
-- call AddLeaf('B', 'A');
-- call AddLeaf('C', 'A');
-- 
-- call FindRoot();

--|--------------------------------------------------------------------------------
--| 3. ���������� ����� ������������� ���� (�������) ������
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
--| 4. ������� ��� ���� �� ������ (����, ����, ...) ������� � ������
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
--| 5. ������������ ������ ����� �� ��������� �� ��������� �����
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
--| 6. ��������� ������� �������� ������� ����
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
