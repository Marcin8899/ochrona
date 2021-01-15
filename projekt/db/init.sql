CREATE DATABASE notes DEFAULT CHARACTER SET utf8 COLLATE utf8_polish_ci;
USE notes;

CREATE TABLE user (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nickname VARCHAR(40) NOT NULL UNIQUE,
    password_hash VARCHAR(256) NOT NULL,
    mail VARCHAR(40) NOT NULL UNIQUE
);

CREATE TABLE note (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    author VARCHAR(40) NOT NULL ,
    name VARCHAR(40) NOT NULL ,
    note VARBINARY (4000) NOT NULL,
    public BOOLEAN,
    encrypted BOOLEAN
);

CREATE TABLE shared (
    id VARCHAR(60) NOT NULL UNIQUE,
    nickname  VARCHAR(40) NOT NULL ,
    author VARCHAR(40) NOT NULL ,
    name VARCHAR(40) NOT NULL ,
    note VARBINARY (4000) NOT NULL,
    public BOOLEAN,
    encrypted BOOLEAN
);
CREATE TABLE last_login(
    ip VARCHAR(60) NOT NULL UNIQUE,
    bad_logins INTEGER NOT NULL
);

CREATE TABLE files(
    author VARCHAR(40) NOT NULL,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE session_data(
    user VARCHAR(40) NOT NULL,
    ip VARCHAR(40) NOT NULL
);


INSERT INTO user(nickname, password_hash, mail) VALUES ("admin","3875034e17855bac03a3cc9e107b1d28a9b44313d381c3335588525b4e70b551","mail@gmail.com");
INSERT INTO user(nickname, password_hash, mail) VALUES ("root","8b4d37bd90dd4f2082d053b763c18c283aae7529809f6d469b514697de334862","mail1@gmail.com");
INSERT INTO user(nickname, password_hash, mail) VALUES ("master","a4b6bbb952f1783dbcb64e198979c151106fcb932532f67325ffe15856afdc61","mail2@gmail.com");
