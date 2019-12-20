--|--------------------------------------------------------------------------------
--| 14.a-d. Вывести всех общих предков двух и более заданных элементов
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

--| 1
--|--------------------------------------------------------------------------------
-- DELETE FROM nodes_of_nested;
-- INSERT INTO nodes_of_nested VALUES('D');
-- INSERT INTO nodes_of_nested VALUES('E');
-- INSERT INTO nodes_of_nested VALUES('M');
-- INSERT INTO nodes_of_nested VALUES('L');
-- call GetAllCommonParents();

--| 2
--|--------------------------------------------------------------------------------
-- DELETE FROM nodes_of_nested;
-- INSERT INTO nodes_of_nested VALUES('H');
-- INSERT INTO nodes_of_nested VALUES('I');
-- INSERT INTO nodes_of_nested VALUES('M');
-- call GetAllCommonParents();

--| 3
--|--------------------------------------------------------------------------------
-- DELETE FROM nodes_of_nested;
-- INSERT INTO nodes_of_nested VALUES('P');
-- INSERT INTO nodes_of_nested VALUES('G');
-- call GetAllCommonParents();

--|--------------------------------------------------------------------------------
--| 15 Вывести всех общих предков двух и более заданных элементов
--|--------------------------------------------------------------------------------

--| 15.a Начиная снизу
--|--------------------------------------------------------------------------------

-- DELETE FROM nodes_of_nested;
-- INSERT INTO nodes_of_nested VALUES('H');
-- INSERT INTO nodes_of_nested VALUES('I');
-- INSERT INTO nodes_of_nested VALUES('M');
-- call GetAllCommonParentsFromBottom();
-- 
-- DELETE FROM nodes_of_nested;
-- INSERT INTO nodes_of_nested VALUES('P');
-- INSERT INTO nodes_of_nested VALUES('G');
-- call GetAllCommonParentsFromBottom();

--| 15.b Начиная сверху
--|--------------------------------------------------------------------------------
-- DELETE FROM nodes_of_nested;
-- INSERT INTO nodes_of_nested VALUES('H');
-- INSERT INTO nodes_of_nested VALUES('I');
-- INSERT INTO nodes_of_nested VALUES('M');
-- call GetAllCommonParentsFromTop();
-- 
-- DELETE FROM nodes_of_nested;
-- INSERT INTO nodes_of_nested VALUES('P');
-- INSERT INTO nodes_of_nested VALUES('G');
-- call GetAllCommonParentsFromTop();

--|--------------------------------------------------------------------------------
--| 16. Вывести количество всех общих предков двух и более заданных элементов
--|--------------------------------------------------------------------------------
-- DELETE FROM nodes_of_nested;
-- INSERT INTO nodes_of_nested VALUES('P');
-- INSERT INTO nodes_of_nested VALUES('G');
-- SELECT count(*) FROM GetAllCommonParents();