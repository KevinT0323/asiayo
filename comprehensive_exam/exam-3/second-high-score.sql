-- 這個語法會先依分數由高至低排序，再略過最高分的記錄，取得第二筆資料，最後透過 JOIN 取得對應班級。
SELECT c.class
FROM score s
JOIN class c ON s.name = c.name
ORDER BY s.score DESC
LIMIT 1 OFFSET 1;