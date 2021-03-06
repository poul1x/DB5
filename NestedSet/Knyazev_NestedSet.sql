CREATE OR REPLACE TABLE nested(
    node_id INT NOT NULL PRIMARY KEY AUTOINC,
    node_name VARCHAR(16) NOT NULL UNIQUE,
    left_num INT NOT NULL,
    right_num INT NOT NULL
);

-- �.14-16
CREATE OR REPLACE TABLE nodes_of_nested(
    node_name VARCHAR(16) NOT NULL UNIQUE
);

-- �.8-9
CREATE OR REPLACE TABLE path_in_nested(
    id INT NOT NULL PRIMARY KEY AUTOINC,
    node_name VARCHAR(16) NOT NULL UNIQUE
);

-- �.19
CREATE OR REPLACE TABLE nested_subtree(
    node_name VARCHAR(16) NOT NULL UNIQUE,
    left_num INT NOT NULL,
    right_num INT NOT NULL
);

-- �.17
CREATE OR REPLACE TABLE children(
    node_name VARCHAR(16) NOT NULL UNIQUE,
    left_num INT NOT NULL,
    right_num INT NOT NULL
);

--|--------------------------------------------------------------------------------
--| 1. ������� ������ ���� ������������ ���������
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
--| 2. ����� ������ ������
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
--| 3. ���������� ����� ������������� ���� (�������) ������
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE GetMaxDepth(
) RESULT INT
DECLARE
  VAR m typeof(result);
CODE
  EXECUTE "SELECT MAX(level) FROM GetHierarchyLevels()" INTO m;
  RETURN m;
END;

--|--------------------------------------------------------------------------------
--| 4. ������� ��� ���� �� ������ (����, ����, ...) ������� � ������
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE GetAllDestinations(
  IN level INT
) RESULT CURSOR(node_id INT, node_name VARCHAR(16))
DECLARE
  VAR c typeof(result);
CODE
  OPEN c FOR
  "SELECT node_id, node_name FROM GetHierarchyLevels()
    WHERE level=?", level;
  RETURN c;
END;

--|--------------------------------------------------------------------------------
--| 5. ������������ ������ ����� �� ��������� �� ��������� �����
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE Summarize(
  IN node_start VARCHAR(16);
) RESULT CURSOR(node_name VARCHAR(16))
DECLARE
  VAR c typeof(result);
  VAR node_id INT;
  VAR cnt_ch INT;
CODE
  OPEN c FOR DIRECT
  "SELECT child_node_name FROM GetParentChildPairs()
    WHERE parent_node_name='"+node_start+"' UNION SELECT '"+node_start+"'";
  RETURN c;
END;

--|--------------------------------------------------------------------------------
--| 6. ��������� ������� �������� ������� ����
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
--| 7. ��������� ������ ���� �����
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

CREATE OR REPLACE PROCEDURE GetPathFromBottomUnsorted(
  IN node_name_bottom VARCHAR(16);
  IN node_name_top VARCHAR(16);
) RESULT CURSOR(node_id INT, node_name VARCHAR(16), left_num INT, right_num INT) 
DECLARE
VAR c typeof(result);
VAR left_num_bottom, left_num_top INT;
VAR right_num_bottom, right_num_top INT;
CODE  
EXECUTE "SELECT left_num, right_num FROM nested WHERE node_name=?", 
  node_name_bottom INTO left_num_bottom, right_num_bottom;
EXECUTE "SELECT left_num, right_num FROM nested WHERE node_name=?", 
  node_name_top INTO left_num_top, right_num_top;
OPEN c FOR
  "SELECT * FROM nested 
  WHERE (left_num<? AND right_num>?) AND (left_num>=? AND right_num<=?)
  UNION SELECT * FROM nested 
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
"SELECT node_name FROM GetPathFromBottomUnsorted(
  '" + node_name_bottom + "','" + node_name_top + "') ORDER BY right_num";
WHILE NOT outofcursor(c) LOOP
  EXECUTE "INSERT INTO path_in_nested(node_name) VALUES(?)", c.node_name;
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
"SELECT node_name FROM GetPathFromBottomUnsorted(
  '" + node_name_bottom + "','" + node_name_top + "') ORDER BY left_num";
WHILE NOT outofcursor(c) LOOP
  EXECUTE "INSERT INTO path_in_nested(node_name) VALUES(?)", c.node_name;
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
  EXECUTE "DELETE FROM nodes_of_nested";
  EXECUTE "INSERT INTO nodes_of_nested(node_name) VALUES(?)", node_name1;
  EXECUTE "INSERT INTO nodes_of_nested(node_name) VALUES(?)", node_name2;
  
  EXECUTE "SELECT MAX(n.left_num) 
  FROM GetAllCommonParents() acp INNER JOIN nested n 
  ON acp.node_id = n.node_id" INTO cp_max_left; 

  EXECUTE "SELECT node_name FROM nested WHERE left_num=?",
    cp_max_left INTO min_common_parent;

  return min_common_parent;
END;

--|--------------------------------------------------------------------------------
--| 9. ������� ���� ����� ����� ������
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE CreatePathInNested(
  IN node_name_FROM VARCHAR(16);
  IN node_name_to VARCHAR(16);
)
DECLARE
VAR left_num_FROM, right_num_FROM INT;
VAR left_num_to , right_num_to INT;
VAR min_common_parent VARCHAR(16);
CODE
EXECUTE "SELECT left_num, right_num FROM nested WHERE node_name=?", 
  node_name_FROM INTO left_num_FROM, right_num_FROM;
EXECUTE "SELECT left_num, right_num FROM nested WHERE node_name=?", 
  node_name_to INTO left_num_to, right_num_to;
IF left_num_FROM=left_num_to AND right_num_FROM=right_num_to THEN
  /* the same node */
  EXECUTE "INSERT INTO path_in_nested(node_name) VALUES(?)", node_name_to;
ELSEIF left_num_FROM > left_num_to AND right_num_FROM < right_num_to THEN
  /* bottom -> top */
  call UpdatePathFromBottom(node_name_FROM, node_name_to);
ELSEIF left_num_FROM < left_num_to AND right_num_FROM > right_num_to THEN
  /* top -> bottom */
  call UpdatePathFromTop(node_name_to, node_name_FROM);
ELSE
  /* bottom -> top -> bottom with sharing one node */
  min_common_parent := FindMinCommonParent(node_name_FROM, node_name_to);
  call UpdatePathFromBottom(node_name_FROM, min_common_parent);
  call UpdatePathFromTop(node_name_to, min_common_parent);
ENDIF;
END;

--|--------------------------------------------------------------------------------
--| 10. ������� ���� �������� ������� ��������
--|--------------------------------------------------------------------------------

--| 10.a. ���� �������� 
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

--| 10.b. ���� �������� ��������� ������
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

--| 10.c. �������� �� ��������� ������
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

--| 10.d. ���� ������������ ��������
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
--| 12. ������� ���� ������� ������� ��������
--|--------------------------------------------------------------------------------

--| 12.a. ���� ������� 
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

--| 12.b. ���� ������� ��������� ������
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

--| 12.c. ������� �� ��������� ������
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
--| 14.a-d. ������� ���� ����� ������� ���� � ����� �������� ���������
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE GetAllCommonParents() 
RESULT CURSOR(node_id INT, node_name VARCHAR(16))
DECLARE
  VAR c typeof(result);
  VAR cnt INT;
CODE
  EXECUTE "SELECT COUNT(*) FROM nodes_of_nested" into cnt;
  OPEN c FOR
  "SELECT pcp.parent_node_id, pcp.parent_node_name FROM GetParentChildPairs() pcp
  WHERE pcp.child_node_name IN (select node_name FROM nodes_of_nested)
  GROUP BY pcp.parent_node_id, pcp.parent_node_name
  HAVING COUNT(pcp.parent_node_id)=?", cnt;
  RETURN c;
END;

--|--------------------------------------------------------------------------------
--| 15. ������� ���� ����� ������� ���� � ����� �������� ���������
--|--------------------------------------------------------------------------------

--| 15.a ������� �����
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

--| 15.b ������� ������
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
  EXECUTE DIRECT "SELECT count(node_id) FROM nested where left_num=1" INTO already_has_root;
  IF already_has_root=1 THEN
    RETURN -1;
  ENDIF;
  EXECUTE "INSERT INTO nested(node_name, left_num, right_num) VALUES(?,1,2)", new_node_name;
  RETURN 1;
END;

--|--------------------------------------------------------------------------------
--| 17. ������� ���� (����)
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

--|--------------------------------------------------------------------------------
--| 17. ������� ����
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE InsertNode(
  IN new_node_name varchar(16);
  IN parent_node_name varchar(16);
)
DECLARE
  VAR parent_node_left, parent_node_right INT;
  VAR new_node_left, new_node_right INT;
CODE
EXECUTE "SELECT left_num, right_num FROM nested 
  WHERE node_name=?", parent_node_name INTO parent_node_left, parent_node_right;

EXECUTE "SELECT MIN(left_num), MAX(right_num)+2 
  FROM children" INTO new_node_left, new_node_right;

EXECUTE "UPDATE nested
  SET left_num=left_num+1, right_num=right_num+1
  WHERE left_num>=? AND right_num<?", new_node_left, new_node_right;

EXECUTE "UPDATE nested SET right_num=right_num+2
  WHERE left_num<=? AND right_num>=?", parent_node_left, parent_node_right;

EXECUTE "UPDATE nested
  SET left_num=left_num+2, right_num=right_num+2
  WHERE left_num+1>=?", new_node_right;

EXECUTE "INSERT INTO nested(node_name, left_num, right_num)
  VALUES(?,?,?)", new_node_name, new_node_left, new_node_right;  
END;

--|--------------------------------------------------------------------------------
--| 18. �������� ���� (����)
--|--------------------------------------------------------------------------------
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
--| 18. �������� ����
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

--|--------------------------------------------------------------------------------
--| 19. ������� ���������
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE InsertTree(
  IN parent_node_name VARCHAR(16);
)
DECLARE
VAR in_left, in_right INT;
VAR in_size, sub_size INT;
CODE  
EXECUTE "SELECT left_num, right_num, right_num-left_num+1 
  FROM nested WHERE node_name=?", parent_node_name INTO in_left, in_right, in_size;

EXECUTE "SELECT right_num-left_num+1 
  FROM nested_subtree WHERE left_num=1" INTO sub_size;

EXECUTE "UPDATE nested SET right_num=right_num+?, left_num=left_num+?
  WHERE left_num>?", sub_size, sub_size, in_right;

EXECUTE "UPDATE nested SET right_num=right_num+? 
  WHERE left_num<=? AND right_num>=?", sub_size, in_left, in_right;

EXECUTE "UPDATE nested SET left_num=left_num+?, right_num=right_num+?
  WHERE left_num>? AND right_num<?", sub_size, sub_size, in_left, in_right;

EXECUTE "UPDATE nested_subtree 
  SET left_num=left_num+?, right_num=right_num+?", in_left, in_left;

EXECUTE "INSERT INTO nested(node_name, left_num, right_num)
 SELECT * FROM nested_subtree";
END;

--|--------------------------------------------------------------------------------
--| 20. �������� ��������� (�������� ���� � ���� ��� ��������)
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE RemoveTree(
  IN node_name VARCHAR(16);
)
DECLARE
VAR drop_left, drop_right, drop_size INT;
CODE  
EXECUTE "SELECT left_num, right_num, right_num-left_num+1 
  FROM nested WHERE node_name=?", node_name into drop_left, drop_right, drop_size;

EXECUTE "DELETE FROM nested 
  WHERE left_num>=? and left_num<=?", drop_left, drop_right;

EXECUTE "UPDATE nested SET left_num=left_num-?, right_num=right_num-?
  WHERE left_num>?", drop_size, drop_size, drop_left;

EXECUTE "UPDATE nested SET right_num=right_num-? 
  WHERE right_num>? AND left_num<?", drop_size, drop_right, drop_left; 
END;

--|--------------------------------------------------------------------------------
--| 21. ����������� ��������� 
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE MoveTree(
  IN node_name_rm VARCHAR(16);
  IN node_name_ins VARCHAR(16);
)
DECLARE
VAR left_num, right_num, delta INT;
CODE  
EXECUTE "SELECT left_num, right_num FROM nested 
  WHERE node_name=?", node_name_rm into left_num, right_num;

EXECUTE "INSERT INTO nested_subtree 
  SELECT node_name, left_num, right_num FROM nested WHERE left_num>=? AND right_num<=?", left_num, right_num;

delta := left_num - 1;
EXECUTE "UPDATE nested_subtree
  SET left_num=left_num-?, right_num=right_num-?", delta, delta;

call RemoveTree(node_name_rm);
call InsertTree(node_name_ins);

END;
