PRAGMA foreign_keys = ON;
DROP TABLE if exists question_likes;
DROP TABLE if exists replies;
DROP TABLE if exists question_follows;
DROP TABLE if exists questions;
DROP TABLE if exists users;

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    fname VARCHAR(255) NOT NULL,
    lname VARCHAR(255) NOT NULL
);

CREATE TABLE questions (
    id INTEGER PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    user_id INTEGER NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE replies (
    id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    reply_id INTEGER, 
    user_id INTEGER NOT NULL,
    body TEXT NOT NULL,

    FOREIGN KEY (question_id) REFERENCES questions(id)
    FOREIGN KEY (reply_id) REFERENCES replies(id)
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_likes (
    id INTEGER PRIMARY KEY,
    likes INTEGER,
    question_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,

    FOREIGN KEY (question_id) REFERENCES questions(id)
    FOREIGN KEY (user_id) REFERENCES users(id)
);

INSERT INTO
    users (fname, lname)
VALUES
    ('Alissa', 'Crane'),
    ('Kevin', 'Brimmerman'),
    ('Guy', 'Fieri');

INSERT INTO
    questions (title, body, user_id)
VALUES
    ('Looking for Flavortown', 'Can anyone show me how to get to Flavortown?', (SELECT id FROM users WHERE fname = 'Guy' AND lname = 'Fieri'));

INSERT INTO
    replies (question_id, reply_id, user_id, body)
VALUES
    (
    (SELECT id FROM questions WHERE title = 'Looking for Flavortown'),
    NULL, (SELECT id FROM users WHERE fname = 'Alissa'), 'Yo dawg I think I saw Flavortown on my way to detroit!');

INSERT INTO 
    question_likes (likes, question_id, user_id)
VALUES
    (420, (SELECT id FROM questions WHERE title = 'Looking for Flavortown'), (SELECT id FROM users WHERE fname = 'Guy'));

