WITH dept AS (
SELECT a.db_key dept1
      ,b.db_key dept2
      ,c.db_key dept3
      ,d.db_key dept4
      ,f.db_key dept5
  FROM dw_fi_dept a
  LEFT JOIN dw_fi_dept b ON b.parent_key = a.db_key
  LEFT JOIN dw_fi_dept c ON c.parent_key = b.db_key
  LEFT JOIN dw_fi_dept d ON d.parent_key = c.db_key
  LEFT JOIN dw_fi_dept f ON f.parent_key = d.db_key)
 ,dept1 AS (--用户的利润中心：用来排除内部交易
   SELECT dept1 dept  FROM dept a WHERE a.dept1 ='RA00'
   UNION  
   SELECT dept2  FROM dept a WHERE a.dept1 ='RA00'--用户对应的利润中心
   UNION           
   SELECT dept3  FROM dept a WHERE a.dept1='RA00'
   UNION 
   SELECT dept4  FROM dept a WHERE a.dept1='RA00'       
   UNION 
   SELECT dept5  FROM dept a WHERE a.dept1 ='RA00')
   
  ,dept2 AS (--参数的利润中心：用来排除底层数据
   SELECT dept1 dept  FROM dept a WHERE a.dept1 ='RA00'--利润中心参数
   UNION  
   SELECT dept2  FROM dept a WHERE a.dept1 ='RA00'
   UNION           
   SELECT dept3  FROM dept a WHERE a.dept1='RA00'
   UNION 
   SELECT dept4  FROM dept a WHERE a.dept1='RA00'       
   UNION 
   SELECT dept5  FROM dept a WHERE a.dept1 ='RA00') 


 SELECT b.zc_index --自动编号
        ,b.racct
        ,SUM(dmbtr) dmbtr
        ,SUM(dmbtr_year) dmbtr_year
    FROM (
    SELECT c.zc_index --自动编号
                ,a.racct --科目
                ,SUM(CASE
                       WHEN b.zc_hs = 'S' THEN
                        a.dmbtr
                       WHEN b.zc_hs = 'H' THEN
                        -a.dmbtr
                     END) AS dmbtr --按本位币计的金额 
                ,0 AS dmbtr_year
            FROM (SELECT *
                    FROM dw_fi_list_items b
                   WHERE b.zc_index='00008'               
                  ) b 
            JOIN dw_fi_subject c
              ON c.zc_index = b.zc_index
            JOIN (SELECT *
                        FROM dw_fi_account_balance a
                       WHERE a.gjahr = '2019' --年
                         AND a.poper= '004'
                         AND trim(leading '0'FROM a.prctr) IN  
                         (SELECT dept FROM dept2 a )
                         AND NOT EXISTS
                       (SELECT *
                                FROM dw_fi_account_balance b
                               WHERE b.racct LIKE 'A%'
                                 AND trim(leading '0'FROM b.SPRCTR) IN
                                     (SELECT dept FROM dept1 a)
                                 AND a.racct = b.racct 
                                 AND a.sprctr=b.sprctr 
                                 AND a.gjahr=b.gjahr 
                                 AND a.poper=b.poper 
                                 AND a.prctr=b.prctr)) a 
              ON a.racct BETWEEN c.from_racct AND c.to_racct
           WHERE 1 = 1
           GROUP BY c.zc_index --自动编号
                ,a.racct
          UNION ALL
          SELECT c.zc_index --自动编号
                ,a.racct
                ,0 AS dmbtr --按本位币计的金额 
                ,SUM(CASE
                       WHEN b.zc_hs = 'S' THEN
                        a.dmbtr
                       WHEN b.zc_hs = 'H' THEN
                        -a.dmbtr
                     END) AS dmbtr_year
            FROM (SELECT *
                    FROM dw_fi_list_items b
                   WHERE b.zc_index='00008'
                 
                  ) b 
            JOIN dw_fi_subject c
              ON c.zc_index = b.zc_index
            JOIN (SELECT *
                        FROM dw_fi_account_balance a
                       WHERE a.gjahr = '2019' --年
                         AND a.poper<= '005'
                         AND trim(leading '0'FROM a.prctr) IN 
                          (SELECT dept  FROM dept2 a)
                         AND NOT EXISTS
                       (SELECT *
                                FROM dw_fi_account_balance b
                               WHERE b.racct LIKE 'A%'
                                 AND trim(leading '0'FROM b.SPRCTR) IN
                                     (SELECT dept FROM dept1 a)
                                 AND a.racct = b.racct 
                                 AND a.sprctr=b.sprctr 
                                 AND a.gjahr=b.gjahr 
                                 AND a.poper=b.poper 
                                 AND a.prctr=b.prctr)) a 
              ON a.racct BETWEEN c.from_racct AND c.to_racct
           WHERE 1 = 1
           GROUP BY c.zc_index --自动编号
                ,a.racct
          ) b --借方正数或者贷方正数
    GROUP BY b.zc_index --自动编号
             ,b.racct
                   
