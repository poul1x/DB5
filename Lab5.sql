-- TODO Сделать процедуру get-tree-size - колво узлов удвоенное

CREATE OR REPLACE TABLE nested(
    node_id INT NOT NULL PRIMARY KEY AUTOINC,
    node_name VARCHAR(16) NOT NULL UNIQUE,
    left_num INT NOT NULL check(left_num > 0),
    right_num INT NOT NULL check (right_num > 0)
);

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
RESULT CURSOR(node_name VARCHAR(16), level INT)
DECLARE
  VAR c_levels typeof(result);
CODE
OPEN c_levels FOR
"SELECT child.node_name, COUNT(parent.node_id) AS level
FROM nested child JOIN nested parent 
  ON child.left_num BETWEEN parent.left_num AND parent.right_num
  GROUP BY child.node_name
  ORDER BY level";
  
RETURN c_levels;
END;

CREATE OR REPLACE PROCEDURE BuildHierarchyLevels() 
CODE
EXECUTE "CREATE OR REPLACE VIEW HierarchyLevels AS
SELECT child.node_id, child.node_name, COUNT(parent.node_id) AS level
FROM nested child JOIN nested parent 
  ON child.left_num BETWEEN parent.left_num AND parent.right_num
  GROUP BY child.node_name, child.node_id";
END;

CREATE OR REPLACE PROCEDURE GetHierarchyLevelsDiff(
) RESULT CURSOR(higher_node_id INT, higher_node_name VARCHAR(16), lower_node_id INT, lower_node_name VARCHAR(16), level_diff INT)
DECLARE
VAR c typeof(result);
CODE
call BuildHierarchyLevels();
open c for
"SELECT HL1.node_id as higher_node_id, HL1.node_name as higher_node_name, 
       HL2.node_id as lower_node_id, HL2.node_name as lower_node_name,
       HL2.level - HL1.level as level_diff
FROM HierarchyLevels HL1 JOIN HierarchyLevels HL2
  ON HL2.level-HL1.level > 0";
return c;
END;

CREATE OR REPLACE PROCEDURE GetParentChildrenPairs(
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
IF length(node_name) = 0 THEN
    open c for
"SELECT parent.node_id as parent_node_id, parent.node_name as parent_node_name, 
       child.node_id as child_node_id, child.node_name as child_node_name
from nested parent join nested child 
  on parent.left_num < child.left_num and child.left_num < parent.right_num";
ELSE
    open c for
"SELECT parent.node_id as parent_node_id, parent.node_name as parent_node_name, 
       child.node_id as child_node_id, child.node_name as child_node_name
from nested parent join nested child 
  on parent.left_num < child.left_num and child.left_num < parent.right_num
WHERE parent.node_name=?", node_name;
  ENDIF;

return c;
END;



call AddLeaf('A');
call AddLeaf('B', 'A');
call AddLeaf('C', 'A');
call AddLeaf('D', 'B');
call AddLeaf('E', 'B');
call AddLeaf('F', 'A');
call AddLeaf('M', 'C');
call AddLeaf('N', 'C');

call BuildHierarchyLevels();
call BuildHierarchyLevelsDiffForAllNodes(2);

CREATE OR REPLACE VIEW ParentChildrenPairs AS
SELECT parent.node_id as parent_node_id, parent.node_name as parent_node_name, 
       child.node_id as child_node_id, child.node_name as child_node_name
from nested parent join nested child 
  on parent.left_num < child.left_num and child.left_num < parent.right_num
WHERE parent.node_name='A';

--select pcp.parent_node_name, pcp.child_node_name from HierarchyLevelsDiff hld INNER JOIN ParentChildrenPairs pcp
--ON hld.higher_node_id = pcp.parent_node_id AND hld.lower_node_id = pcp.child_node_id;
  
-- SELECT * from HierarchyLevelsDiff;

select * from GetHierarchyLevelsDiff();
select * from GetParentChildrenPairs('B');
  