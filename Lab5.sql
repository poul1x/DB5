-- TODO Сделать процедуру get-tree-size - колво узлов удвоенное

CREATE OR REPLACE TABLE nested(
    node_id INT NOT NULL PRIMARY KEY AUTOINC,
    node_name VARCHAR(16) NOT NULL UNIQUE,
    left_num INT NOT NULL,
    right_num INT NOT NULL
);

CREATE OR REPLACE TABLE nodes_of_nested(
    node_name VARCHAR(16) NOT NULL UNIQUE
);

CREATE OR REPLACE TABLE path_in_nested(
    id INT NOT NULL PRIMARY KEY AUTOINC,
    node_name VARCHAR(16) NOT NULL UNIQUE
);

--|--------------------------------------------------------------------------------
--| 1. Вывести список всех терминальных элементов
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE GetNodesWithoutChildren(
) RESULT CURSOR(node_name VARCHAR(16)) 
DECLARE
  VAR c typeof(result);
CODE
  OPEN c FOR
  "SELECT node_name FROM nested 
    WHERE right_num-left_num=1";
  RETURN c;
END;

--|--------------------------------------------------------------------------------
--| 2. Найти корень дерева
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE GetRoot(
) RESULT VARCHAR(16) 
DECLARE
  VAR c typeof(result);
CODE
  EXECUTE "SELECT node_name FROM nested WHERE left_num=1" INTO c;
  RETURN c;
END;

--|--------------------------------------------------------------------------------
--| 3. Определить длину максимального пути (глубину) дерева
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE GetMaxDepth(
) RESULT INT
DECLARE
  VAR m typeof(result);
CODE
  EXECUTE "select MAX(level) FROM GetHierarchyLevels()" INTO m;
  RETURN m;
END;

--|--------------------------------------------------------------------------------
--| 4. Вывести все пути по одному (двум, трем, ...) уровням в дереве
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE GetAllDestinations(
  IN level INT
) RESULT CURSOR(node_id INT, node_name VARCHAR(16))
DECLARE
  VAR c typeof(result);
CODE
  OPEN c FOR
  "select node_id, node_name FROM GetHierarchyLevels()
    WHERE level=?", level;
  RETURN c;
END;

--|--------------------------------------------------------------------------------
--| 5. Суммирование данных узлов по поддереву от заданного корня
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE Summarize(
  IN node_start VARCHAR(16);
) RESULT INT
DECLARE
  VAR s typeof(result);
  VAR node_id INT;
  VAR cnt_ch INT;
CODE
  node_id := NameToId(node_start);
  cnt_ch := CountOfChildren(node_id);
  s := 0;
  
  IF cnt_ch > 0 THEN
  EXECUTE "SELECT CAST SUM(child_node_id) AS INT FROM GetParentChildPairs()
    WHERE parent_node_name=?", node_start INTO s;
  ENDIF;
  
  RETURN s + node_id;
END;

--|--------------------------------------------------------------------------------
--| 6. Вычислить уровень иерархии данного узла
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE GetNodeHierarchyLevel(
  IN node_name VARCHAR(16);
) RESULT INT
DECLARE
  VAR h typeof(result);
CODE
  EXECUTE "SELECT level FROM GetHierarchyLevels()
    WHERE node_name=?", node_name INTO h;
  RETURN h;
END;

--|--------------------------------------------------------------------------------
--| 7. Вычислить уровни всех узлов
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE GetHierarchyLevelsSorted(
  IN node_name VARCHAR(16);
) RESULT CURSOR(node_id INT, node_name VARCHAR(16), level INT)
DECLARE
  VAR c typeof(result);
CODE
  OPEN c FOR
  "SELECT * FROM GetHierarchyLevels() ORDER BY level";
  RETURN c;
END;

--|--------------------------------------------------------------------------------
--| 10. Вывести всех потомков данного элемента
--|--------------------------------------------------------------------------------

--| 10.a. Всех потомков 
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE GetAllChildren(
  IN node_name VARCHAR(16);
) RESULT CURSOR(node_id INT, node_name VARCHAR(16))
DECLARE
  VAR c typeof(result);
CODE
  OPEN c FOR
  "SELECT child_node_id, child_node_name FROM GetParentChildPairs()
    WHERE parent_node_name=?", node_name;
  RETURN c;
END;

--| 10.b. Всех потомков заданного уровня
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE GetAllChildrenAtLevel(
  IN node_name VARCHAR(16);
  IN level INT;
) RESULT CURSOR(node_id INT, node_name VARCHAR(16))
DECLARE
  VAR c typeof(result);
CODE
  OPEN c FOR
  "SELECT child_node_id, child_node_name FROM GetParentChildLevelDiff()
    WHERE parent_node_name=? AND level_diff=?", node_name, level;
  RETURN c;
END;

--| 10.c. Потомков до заданного уровня
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE GetAllChildrenUpToLevel(
  IN node_name VARCHAR(16);
  IN level INT;
) RESULT CURSOR(node_id INT, node_name VARCHAR(16))
DECLARE
  VAR c typeof(result);
CODE
  OPEN c FOR
  "SELECT child_node_id, child_node_name FROM GetParentChildLevelDiff()
    WHERE parent_node_name=? AND level_diff<=?", node_name, level;
  RETURN c;
END;

--| 10.d. Всех терминальных потомков
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE GetAllChildrenLeaves(
  IN node_name VARCHAR(16);
) RESULT CURSOR(node_id INT, node_name VARCHAR(16))
DECLARE
  VAR c typeof(result);
CODE
  OPEN c FOR
  "SELECT node_id, node_name FROM nested WHERE node_id IN 
    (SELECT child_node_id FROM GetParentChildPairs()
    WHERE parent_node_name=?) AND right_num-left_num=1", node_name;
  RETURN c;
END;

--|--------------------------------------------------------------------------------
--| 12. Вывести всех предков данного элемента
--|--------------------------------------------------------------------------------

--| 12.a. Всех предков 
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE GetAllParents(
  IN node_name VARCHAR(16);
) RESULT CURSOR(node_id INT, node_name VARCHAR(16))
DECLARE
  VAR c typeof(result);
CODE
  OPEN c FOR
  "SELECT parent_node_id, parent_node_name FROM GetParentChildPairs()
    WHERE child_node_name=?", node_name;
  RETURN c;
END;

--| 12.b. Всех предков заданного уровня
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE GetAllParentsAtLevel(
  IN node_name VARCHAR(16);
  IN level INT;
) RESULT CURSOR(node_id INT, node_name VARCHAR(16))
DECLARE
  VAR c typeof(result);
CODE
  OPEN c FOR
  "SELECT parent_node_id, parent_node_name FROM GetParentChildLevelDiff()
    WHERE child_node_name=? AND level_diff=?", node_name, level;
  RETURN c;
END;

--| 12.c. Предков до заданного уровня
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE GetAllParentsUpToLevel(
  IN node_name VARCHAR(16);
  IN level INT;
) RESULT CURSOR(node_id INT, node_name VARCHAR(16))
DECLARE
  VAR c typeof(result);
CODE
  OPEN c FOR
  "SELECT parent_node_id, parent_node_name FROM GetParentChildLevelDiff()
    WHERE child_node_name=? AND level_diff<=?", node_name, level;
  RETURN c;
END;

--|--------------------------------------------------------------------------------
--| 14.a-d. Вывести всех общих предков двух и более заданных элементов
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE GetAllCommonParents() 
RESULT CURSOR(node_id INT, node_name VARCHAR(16))
DECLARE
  VAR c typeof(result);
  VAR cnt INT;
CODE
  EXECUTE "SELECT COUNT(*) from nodes_of_nested" into cnt;
  OPEN c FOR
  "SELECT pcp.parent_node_id, pcp.parent_node_name FROM GetParentChildPairs() pcp
  WHERE pcp.child_node_name IN (select node_name FROM nodes_of_nested)
  GROUP BY pcp.parent_node_id, pcp.parent_node_name
  HAVING COUNT(pcp.parent_node_id)=?", cnt;
  RETURN c;
END;

--|--------------------------------------------------------------------------------
--| 15. Вывести всех общих предков двух и более заданных элементов
--|--------------------------------------------------------------------------------

--| 15.a Начиная снизу
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE GetAllCommonParentsFromBottom() 
RESULT CURSOR(node_id INT, node_name VARCHAR(16))
DECLARE
  VAR c typeof(result);
CODE
  OPEN c FOR
  "SELECT n.node_id, n.node_name 
  FROM GetAllCommonParents() acp INNER JOIN nested n
  ON acp.node_id = n.node_id
  ORDER BY n.right_num";
  RETURN c;
END;

--| 15.b Начиная сверху
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE GetAllCommonParentsFromTop() 
RESULT CURSOR(node_id INT, node_name VARCHAR(16))
DECLARE
  VAR c typeof(result);
CODE
  OPEN c FOR
  "SELECT n.node_id, n.node_name 
  FROM GetAllCommonParents() acp INNER JOIN nested n
  ON acp.node_id = n.node_id
  ORDER BY n.left_num";
  RETURN c;
END;

CREATE OR REPLACE PROCEDURE NameToId(
  IN node_name VARCHAR(16);
) result INT 
DECLARE
  VAR node_id INT;
CODE 
  EXECUTE "SELECT node_id FROM nested WHERE node_name=?", node_name INTO node_id;
  RETURN node_id;
END;

CREATE OR REPLACE PROCEDURE CountOfChildren(
  IN node_id INT;
) RESULT INT 
DECLARE
  VAR left_num, right_num, diff INT;
CODE 
  EXECUTE "SELECT left_num, right_num FROM nested WHERE node_id=?",
    node_id INTO left_num, right_num;
  
  IF left_num=NULL OR right_num=NULL THEN
    RETURN -1;
  ENDIF;
  
  RETURN (right_num - left_num + 1) / 2 - 1;
END;

CREATE OR REPLACE PROCEDURE AddRoot(
  IN new_node_name VARCHAR(16);
) RESULT INT
DECLARE
  VAR already_has_root INT;
CODE 
  EXECUTE DIRECT "SELECT count(node_id) from nested where left_num=1" INTO already_has_root;
  IF already_has_root=1 THEN
    RETURN -1;
  ENDIF;
  EXECUTE "INSERT INTO nested(node_name, left_num, right_num) VALUES(?,1,2)", new_node_name;
  RETURN 1;
END;

--|--------------------------------------------------------------------------------
--| 17. Вставка узла
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE AddLeaf(
  IN new_node_name varchar(16);
  IN parent_node_name varchar(16) DEFAULT "";
) RESULT INT
DECLARE
  VAR parent_node_id INT;
  VAR parent_right_num INT;
CODE
  IF length(parent_node_name) = 0 THEN
    return AddRoot(new_node_name);
  ENDIF;

  parent_node_id := NameToId(parent_node_name);
  EXECUTE "SELECT right_num FROM nested WHERE node_id=?", parent_node_id INTO parent_right_num;
  EXECUTE "UPDATE nested SET left_num=left_num+2 WHERE left_num>?", parent_right_num;
  EXECUTE "UPDATE nested SET right_num=right_num+2 WHERE right_num>=?", parent_right_num;
  
  EXECUTE "INSERT INTO nested(node_name, left_num, right_num) VALUES(?,?,?)", 
    new_node_name, parent_right_num, parent_right_num + 1;

  RETURN parent_right_num;

END;

CREATE OR REPLACE PROCEDURE RemoveLeaf(
  IN node_name varchar(16);
) RESULT INT
DECLARE
  VAR node_id, right_num INT;
CODE
  node_id := NameToId(node_name);
  EXECUTE "SELECT right_num FROM nested WHERE node_id=?", node_id INTO right_num;
  EXECUTE "UPDATE nested SET left_num=left_num-2 WHERE left_num>?", right_num - 1;
  EXECUTE "UPDATE nested SET right_num=right_num-2 WHERE right_num>?", right_num;
  EXECUTE "DELETE FROM nested WHERE node_id=?", node_id;
  RETURN node_id;
END;


--|--------------------------------------------------------------------------------
--| 18. Удаление узла
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE RemoveNode(
  IN node_name varchar(16);
) RESULT INT
DECLARE
  VAR left_num, right_num, node_id INT;
CODE
  node_id := NameToId(node_name);
  IF CountOfChildren(node_id) = 0 THEN
    return RemoveLeaf(node_name);
  ENDIF;
  EXECUTE "SELECT left_num, right_num FROM nested WHERE node_id=?", node_id INTO left_num, right_num;
  EXECUTE "DELETE FROM nested WHERE node_id=?", node_id;
  
  EXECUTE "UPDATE nested SET left_num=left_num-1, right_num=right_num-1 
              WHERE left_num>? AND right_num<?", left_num, right_num;
  
  EXECUTE "UPDATE nested SET left_num=left_num-2 WHERE left_num>?", right_num;
  EXECUTE "UPDATE nested SET right_num=right_num-2 WHERE right_num>?", right_num;
  RETURN node_id;
END;

CREATE OR REPLACE PROCEDURE GetHierarchyLevels() 
RESULT CURSOR(node_id INT, node_name VARCHAR(16), level INT)
DECLARE
  VAR c_levels typeof(result);
CODE
OPEN c_levels FOR
"SELECT child.node_id, child.node_name, COUNT(parent.node_id) AS level
FROM nested child JOIN nested parent 
  ON child.left_num BETWEEN parent.left_num AND parent.right_num
  GROUP BY child.node_name, child.node_id
  ORDER BY level";
  
RETURN c_levels;
END;

CREATE OR REPLACE PROCEDURE GetParentChildPairs(
  IN node_name VARCHAR(16) DEFAULT "";
) RESULT CURSOR(
  parent_node_id INT, 
  parent_node_name VARCHAR(16), 
  child_node_id INT, 
  child_node_name VARCHAR(16)
) 
DECLARE
VAR c typeof(result);
CODE
OPEN c FOR
"SELECT parent.node_id AS parent_node_id, parent.node_name AS parent_node_name, 
        child.node_id AS child_node_id, child.node_name AS child_node_name
FROM nested parent JOIN nested child 
  ON parent.left_num < child.left_num AND child.left_num < parent.right_num";
return c;
END;

CREATE OR REPLACE PROCEDURE GetHierarchyLevelsDiff(
) RESULT CURSOR(higher_node_id INT, higher_node_name VARCHAR(16), lower_node_id INT, lower_node_name VARCHAR(16), level_diff INT)
DECLARE
VAR c typeof(result);
CODE  
OPEN c FOR
"SELECT HL1.node_id AS higher_node_id, HL1.node_name AS higher_node_name, 
        HL2.node_id AS lower_node_id, HL2.node_name AS lower_node_name, 
        HL2.level - HL1.level AS level_diff 
FROM GetHierarchyLevels() AS HL1 
  JOIN GetHierarchyLevels() AS HL2 
    ON HL2.level - HL1.level > 0";
return c;
END;

CREATE OR REPLACE PROCEDURE GetParentChildLevelDiff(
) RESULT CURSOR(parent_node_id INT, parent_node_name VARCHAR(16), child_node_id INT, child_node_name VARCHAR(16), level_diff INT)
DECLARE
VAR c typeof(result);
CODE  
OPEN c FOR
"SELECT pcp.parent_node_id, pcp.parent_node_name, 
        pcp.child_node_id, pcp.child_node_name, level_diff
FROM GetHierarchyLevelsDiff() hld
  INNER JOIN GetParentChildPairs() pcp
    ON hld.higher_node_id=pcp.parent_node_id 
       AND hld.lower_node_id=pcp.child_node_id";
return c;
END;

CREATE OR REPLACE PROCEDURE GetPathFromBottomUnsorted(
  IN node_name_bottom VARCHAR(16);
  IN node_name_top VARCHAR(16);
) RESULT CURSOR(node_id INT, node_name VARCHAR(16), left_num INT, right_num INT) 
DECLARE
VAR c typeof(result);
VAR left_num_bottom, left_num_top INT;
VAR right_num_bottom, right_num_top INT;
CODE  
EXECUTE "select left_num, right_num from nested where node_name=?", 
  node_name_bottom into left_num_bottom, right_num_bottom;
EXECUTE "select left_num, right_num from nested where node_name=?", 
  node_name_top into left_num_top, right_num_top;
OPEN c FOR
  "select * from nested 
  WHERE (left_num<? AND right_num>?) AND (left_num>=? AND right_num<=?)
  union select * from nested 
  WHERE left_num=? AND right_num=?", 
  left_num_bottom, right_num_bottom, left_num_top, 
  right_num_top, left_num_bottom, right_num_bottom;
RETURN c;
END;

CREATE OR REPLACE PROCEDURE UpdatePathFromBottom(
  IN node_name_bottom VARCHAR(16);
  IN node_name_top VARCHAR(16);
) 
DECLARE
VAR c CURSOR(node_name VARCHAR(16));
CODE  
OPEN c FOR DIRECT
"select node_name from GetPathFromBottomUnsorted(
  '" + node_name_bottom + "','" + node_name_top + "') ORDER BY right_num";
WHILE NOT outofcursor(c) LOOP
  EXECUTE "insert into path_in_nested(node_name) values(?)", c.node_name;
  fetch c;
ENDLOOP;
END;

CREATE OR REPLACE PROCEDURE UpdatePathFromTop(
  IN node_name_bottom VARCHAR(16);
  IN node_name_top VARCHAR(16);
)
DECLARE
VAR c CURSOR(node_name VARCHAR(16));
CODE  
OPEN c FOR DIRECT
"select node_name from GetPathFromBottomUnsorted(
  '" + node_name_bottom + "','" + node_name_top + "') ORDER BY left_num";
WHILE NOT outofcursor(c) LOOP
  EXECUTE "insert into path_in_nested(node_name) values(?)", c.node_name;
  fetch c;
ENDLOOP;
END;

CREATE OR REPLACE PROCEDURE FindMinCommonParent(
  IN node_name1 VARCHAR(16);
  IN node_name2 VARCHAR(16);
) RESULT VARCHAR(16)
DECLARE
  VAR c CURSOR(node_id INT, node_name VARCHAR(16));
  VAR cp_max_left INT;
  VAR min_common_parent VARCHAR(16);
CODE
  EXECUTE "delete from nodes_of_nested";
  EXECUTE "insert into nodes_of_nested(node_name) values(?)", node_name1;
  EXECUTE "insert into nodes_of_nested(node_name) values(?)", node_name2;
  
  EXECUTE "select MAX(n.left_num) 
  FROM GetAllCommonParents() acp inner join nested n 
  on acp.node_id = n.node_id" into cp_max_left; 

  EXECUTE "select node_name from nested WHERE left_num=?",
    cp_max_left into min_common_parent;

  return min_common_parent;
END;

CREATE OR REPLACE PROCEDURE CreatePathInNested(
  IN node_name_from VARCHAR(16);
  IN node_name_to VARCHAR(16);
)
DECLARE
VAR left_num_from, right_num_from INT;
VAR left_num_to , right_num_to INT;
VAR min_common_parent VARCHAR(16);
CODE
EXECUTE "select left_num, right_num from nested where node_name=?", 
  node_name_from into left_num_from, right_num_from;
EXECUTE "select left_num, right_num from nested where node_name=?", 
  node_name_to into left_num_to, right_num_to;
IF left_num_from=left_num_to AND right_num_from=right_num_to THEN
  EXECUTE "insert into path_in_nested(node_name) values(?)", node_name_to;
ELSEIF left_num_from > left_num_to AND right_num_from < right_num_to THEN
  /* bottom -> top */
  call UpdatePathFromBottom(node_name_from, node_name_to);
ELSEIF left_num_from < left_num_to AND right_num_from > right_num_to THEN
  /* top -> bottom */
  call UpdatePathFromTop(node_name_to, node_name_from);
ELSE
  /* bottom -> top -> bottom with sharing one node */
  min_common_parent := FindMinCommonParent(node_name_from, node_name_to);
  call UpdatePathFromBottom(node_name_from, min_common_parent);
  call UpdatePathFromTop(node_name_to, min_common_parent);
ENDIF;
END;


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

delete from path_in_nested;
-- call UpdatePathFromBottom('B', 'A');
-- call UpdatePathFromTop('G', 'B');

-- call FindMinCommonParent('B', 'A');
call CreatePathInNested('F', 'P');
select * from path_in_nested order by id;