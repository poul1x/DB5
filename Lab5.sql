CREATE OR REPLACE TABLE nested(
    node_id INT NOT NULL PRIMARY KEY AUTOINC,
    node_name VARCHAR(16) NOT NULL UNIQUE,
    left_num INT NOT NULL check(left_num > 0),
    right_num INT NOT NULL check (right_num > 0),
    check(left_num < right_num)
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
  EXECUTE "UPDATE nested SET left_num=left_num+2 WHERE left_num>=?", parent_right_num + 1;
  EXECUTE "UPDATE nested SET right_num=right_num+2 WHERE right_num>=?", parent_right_num;
  
  EXECUTE "INSERT INTO nested(node_name, left_num, right_num) VALUES(?,?,?)", 
    new_node_name, parent_right_num, parent_right_num + 1;

  RETURN parent_node_id;

END;

CREATE OR REPLACE PROCEDURE RemoveLeaf(
  IN node_name varchar(16);
) RESULT INT
DECLARE
  VAR node_id, right_num INT;
CODE

  node_id := NameToId(node_name);
  IF CountOfChildren(node_id) <> 0 THEN
    return -1;
  ENDIF;

  EXECUTE "SELECT right_num FROM nested WHERE node_id=?", node_id INTO right_num;
  EXECUTE "UPDATE nested SET left_num=left_num-2 WHERE left_num>?", right_num - 1;
  EXECUTE "UPDATE nested SET right_num=right_num-2 WHERE right_num>?", right_num;
  EXECUTE "DELETE FROM nested WHERE node_id=?", node_id;
  RETURN node_id;
END;