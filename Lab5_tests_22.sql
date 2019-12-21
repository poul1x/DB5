--|--------------------------------------------------------------------------------
--| 22. Конвертация из данного представления в модель "предок-потомок"
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

CREATE OR REPLACE TABLE nodes_list(node_id INT PRIMARY KEY, node_name VARCHAR(16)) AS
SELECT node_id, node_name FROM nested;
CREATE OR REPLACE TABLE nodes_path(node_id_from INT, node_id_to INT) AS
SELECT child_node_id, parent_node_id From GetParentChildPairs();

SELECT * FROM nodes_list 
INNER JOIN nodes_path 
ON node_id=node_id_to;
