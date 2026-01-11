-- ==============================
-- DATABASE: Social Network Mini Project
-- TOPIC: VIEW & INDEX (MySQL)
-- ==============================

DROP DATABASE IF EXISTS social_network;
CREATE DATABASE social_network;
USE social_network;

-- ==============================
-- 1. TABLE: users
-- ==============================
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ==============================
-- 2. TABLE: posts
-- ==============================
CREATE TABLE posts (
    post_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    content TEXT,
    privacy ENUM('PUBLIC', 'FRIEND', 'PRIVATE') DEFAULT 'PUBLIC',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- ==============================
-- 3. TABLE: comments
-- ==============================
CREATE TABLE comments (
    comment_id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(post_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- ==============================
-- 4. TABLE: likes
-- ==============================
CREATE TABLE likes (
    like_id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(post_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- ==============================
-- INSERT SAMPLE DATA
-- ==============================

-- Users
INSERT INTO users (username, email, phone) VALUES
('alice', 'alice@gmail.com', '0901111111'),
('bob', 'bob@gmail.com', '0902222222'),
('charlie', 'charlie@gmail.com', '0903333333'),
('david', 'david@gmail.com', '0904444444');

-- Posts
INSERT INTO posts (user_id, content, privacy, created_at) VALUES
(1, 'Hello world from Alice', 'PUBLIC', '2024-01-10'),
(2, 'Bob private post', 'PRIVATE', '2024-02-01'),
(3, 'Charlie public sharing', 'PUBLIC', '2024-03-05'),
(1, 'Alice friend-only post', 'FRIEND', '2024-03-20'),
(4, 'David public post', 'PUBLIC', '2024-04-01');

-- Comments
INSERT INTO comments (post_id, user_id, content) VALUES
(1, 2, 'Nice post!'),
(1, 3, 'Welcome Alice'),
(3, 1, 'Good content'),
(5, 2, 'Great post David');

-- Likes
INSERT INTO likes (post_id, user_id) VALUES
(1, 2),
(1, 3),
(3, 1),
(3, 2),
(5, 1),
(5, 3);

-- ==============================
-- END OF FILE
-- ============================

-- Câu 1. View hồ sơ người dùng công khai

create view view_user
as
select username, email, created_at from users;

select * from view_user;

-- Câu 2. View News Feed bài viết công khai
create view view_user_post
as
select u.username, p.content, p.created_at,count(l.like_id) from posts p
inner join users u on p.user_id = u.user_id
left join likes l on p.post_id = l.post_id
where p.privacy = 'PUBLIC'
group by  p.post_id, u.username, p.content, p.created_at;


select * from view_user_post;



-- Câu 3. View có CHECK OPTION


create or replace view  view_user_post
as
select p.user_id, p.post_id, p.content,privacy, p.created_at from posts p
where p.privacy = 'PUBLIC'
with check option;

-- thêm được do đúng điều kiện
insert into view_user_post (user_id, content, privacy, created_at) 
values (1,'tôi tên là hung','PUBLIC','2024-01-10 00:00:00');


insert into view_user_post (user_id, content, privacy, created_at) 
values (2,'tôi tên là hung dep zai','FRIEND','2024-01-10 00:00:00');
-- Error Code: 1369. CHECK OPTION failed 'social_network.view_user_post'
-- do with check option nên không thể thêm vào bài viết khác với privacy = 'PUBLIC'
select * from posts;


-- Câu 4. Phân tích truy vấn News Feed 

explain analyze
SELECT * 

FROM posts

WHERE privacy = 'PUBLIC'

ORDER BY created_at DESC;


explain analyze
select * from view_user_post;


-- -> Sort: posts.created_at DESC  (cost=1.05 rows=8) (actual time=0.0763..0.0771 rows=5 loops=1)
-- -> Filter: (posts.privacy = 'PUBLIC')  (cost=1.05 rows=8) (actual time=0.0339..0.0459 rows=5 loops=1)
-- -> Table scan on posts  (cost=1.05 rows=8) (a...


-- '-> Filter: (p.privacy = \'PUBLIC\')  (cost=1.05 rows=2.67) (actual time=0.022..0.0354 rows=5 loops=1)\n    -> Table scan on p  (cost=1.05 rows=8) (actual time=0.018..0.0287 rows=8 loops=1)\n'


--   -> Table scan on p  (cost=1.05 rows=8) (actual time=0.0586..0.0728 rows=8 loops=1)\n'

-- sử dụng câu lệnh select với điều kiện where : (cost=1.05 rows=8) (actual time=0.0763..0.0771 rows=5 loops=1)
-- Sử dụng view : (cost=1.05 rows=2.67) (actual time=0.0634..0.0791 rows=5 loops=1)

-- Ta có thể thấy giá cost thì tương đương nhưng thời gian thấp hơn 0.02 so với lọc với điều kiện where


-- Câu 5. Tạo INDEX tối ưu

drop index id_post on posts;
create index id_post on posts(post_id);

explain analyze
select * from posts
where post_id = 5;

-- -> Rows fetched before execution  (cost=0..0 rows=1) (actual time=500e-6..600e-6 rows=1 loops=1)
-- -> Rows fetched before execution  (cost=0..0 rows=1) (actual time=200e-6..300e-6 rows=1 loops=1)
 -- kết quả trước khi có index là 500e nhưng sau khi tạo index thì sau khi truy vấn actual chỉ còn 200e


--  Câu 6. Phân tích hạn chế của INDEX


-- Khi nào không nên tạo index?
-- khi có số lượng bản ghi nhỏ không nhất thiết cần tạo index
 
-- Vì sao không nên index cột nội dung bài viết?
-- do nọi dung bài viết đều khác nhau và nếu có muốn đặt index cho bài viết thì có thể đặt cho id bài viết
 
-- Index ảnh hưởng thế nào đến thao tác INSERT / UPDATE?
-- insert chậm hơn do phải cập nhật lại index
-- update Chậm hơn nếu update cột nằm trong index hoặc cần kiểm tra lại index
-- delete hậm hơn vì cần xóa trong index



