require 'sqlite3'
require 'singleton'

class QuestionsDataBase < SQLite3::Database
    include Singleton 

    def initialize 
        super('questions.db')
        self.type_translation = true 
        self.results_as_hash = true 
    end 
end 

class User 
    attr_accessor :fname, :lname
    def self.all
        data = QuestionsDataBase.instance.execute("SELECT * FROM users")
        data.map { |datum| User.new(datum) }
    end 

    def initialize(options)
        @id = options['id']
        @fname = options['fname']
        @lname = options['lname']
    end 

    def followed_questions 
        QuestionFollows.followed_questions_for_user_id(@id)
    end

    def self.find_by_name(fname, lname)
        name = QuestionsDataBase.instance.execute(<<-SQL, fname, lname)
            SELECT
                * 
            FROM
                users 
            WHERE 
                fname = ? AND lname = ?
        SQL
        User.new(*name)
    end 

    def liked_questions 
        Like.liked_questions_for_user_id(@id)
    end 

    def self.find_by_id(id)
        user = QuestionsDataBase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                users
            WHERE
                id = ?
        SQL
        User.new(*user)
    end 

    def create
        raise "#{self} already in database" if @id
        QuestionsDataBase.instance.execute(<<-SQL, @fname, @lname)
            INSERT INTO
                users (fname, lname)
            VALUES
                (?, ?)
        SQL
        @id = QuestionsDataBase.instance.last_insert_row_id
    end

    def update
        raise "#{self} not in database" unless @id
        QuestionsDataBase.instance.execute(<<-SQL, @fname, @lname, @id)
            UPDATE
                users
            SET
                fname = ?, lname = ?
            WHERE
                id = ?
        SQL
    end

    def authored_questions
        Question.find_by_author_id(@id)
    end 

    def authored_replies
        Reply.find_by_user_id(@id)
    end 
end

class Question
    attr_accessor :title, :body
    def self.all
        data = QuestionsDataBase.instance.execute("SELECT * FROM questions")
        data.map { |datum| Question.new(datum) }
    end 

    def initialize(options)
        @id = options['id']
        @title = options['title']
        @body = options['body']
        @user_id = options['user_id']
    end 

    def author 
        User.find_by_id(@user_id)
    end

    def replies 
        Reply.find_by_question_id(@id)
    end 

    def followers
        QuestionFollows.followers_for_question_id(@id)
    end 

    def likers 
        Like.likers_for_question_id(@id)
    end 

    def num_likes
        Like.num_likes_for_question_id(@id)
    end 

    def self.most_followed(n)
        QuestionFollows.most_followed_questions(n)
    end

    def self.find_by_author_id(user_id)
        question = QuestionsDataBase.instance.execute(<<-SQL, user_id)
            SELECT
                *
            FROM
                questions
            WHERE
                user_id = ?
        SQL
        question.map { |item| Question.new(item) }
    end 

    def self.find_by_id(id)
        question = QuestionsDataBase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                questions
            WHERE
                id = ?
        SQL
        Question.new(question.first)
    end

    def create
        raise "#{self} already in database" if @id
        QuestionsDataBase.instance.execute(<<-SQL, @title, @body, @user_id)
            INSERT INTO
                questions (title, body, user_id)
            VALUES
                (?, ?, ?)
        SQL
        @id = QuestionsDataBase.instance.last_insert_row_id
    end

    def update
        raise "#{self} not in database" unless @id
        QuestionsDataBase.instance.execute(<<-SQL, @title, @body, @user_id, @id)
            UPDATE
                questions
            SET
                title = ?, body = ?, user_id = ?
            WHERE
                id = ?
        SQL
    end
    
    def self.most_liked(n)
        Like.most_liked_questions(n)
    end
end

class QuestionFollows

    def self.all
        data = QuestionsDataBase.instance.execute("SELECT * FROM question_follows")
        data.map { |datum| QuestionFollows.new(datum) }
    end 

    def initialize(options)
        @id = options['id']
        @question_id = options['question_id']
        @user_id = options['user_id']
    end

    def self.followers_for_question_id(question_id)
        users = QuestionsDataBase.instance.execute(<<-SQL, question_id)
            SELECT
                *
            FROM
                question_follows
            JOIN
                users ON users.id = question_follows.user_id
            WHERE
                question_id = ?
        SQL
        users.map { |user| User.new(user) }
    end

    def self.followed_questions_for_user_id(user_id)
        questions = QuestionsDataBase.instance.execute(<<-SQL, user_id)
            SELECT
                *
            FROM
                question_follows
            JOIN 
                users ON users.id = question_follows.user_id
            JOIN
                questions ON questions.id = question_follows.question_id
            WHERE
                question_follows.user_id = ?
        SQL
        questions.map { |quest| Question.new(quest) }
        # Question.new(*questions)
    end

    def create
        raise "#{self} already in database" if @id
        QuestionsDataBase.instance.execute(<<-SQL, @question_id, @user_id)
            INSERT INTO
                question_follows (question_id, user_id)
            VALUES
                (?, ?)
        SQL
        @id = QuestionsDataBase.instance.last_insert_row_id
    end

    def self.most_followed_questions(n)
        questions = QuestionsDataBase.instance.execute(<<-SQL, n)
            SELECT
                questions.title, COUNT(question_follows.user_id) AS total_followers
            FROM
                question_follows
            JOIN
                questions ON questions.id = question_follows.question_id
            GROUP BY
                question_id
            ORDER BY
                COUNT(question_follows.user_id) DESC
            LIMIT
                ?
        SQL
    end

    def self.find_by_id(id)
        question_follows = QuestionsDataBase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                question_follows
            WHERE
                id = ?
        SQL
        QuestionFollows.new(*question_follows)
    end
end

class Reply

    attr_accessor :body
    def self.all
        data = QuestionsDataBase.instance.execute("SELECT * FROM replies")
        data.map { |datum| Reply.new(datum) }
    end 

    def initialize(options)
        @id = options['id']
        @question_id = options['question_id']
        @body = options['body']
        @user_id = options['user_id']
        @reply_id = options['reply_id']
    end 

    def author 
        User.find_by_id(@user_id)
    end

    def question 
        Question.find_by_id(@question_id)
    end 

    def parent_reply
        Reply.find_by_reply_id(@reply_id) unless @reply_id == nil
    end

    def child_replies
        Reply.find_replys_by_id(@id)
    end

    def self.find_replys_by_id(id)
        reply = QuestionsDataBase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                replies
            WHERE
                reply_id = ?
        SQL
        Reply.new(reply.first)
    end

    def self.find_by_reply_id(reply_id)
        reply = QuestionsDataBase.instance.execute(<<-SQL, reply_id)
            SELECT
                *
            FROM
                replies
            WHERE
                reply_id = ?
        SQL
        Reply.new(reply.first)
    end

    def self.find_by_user_id(user_id)
        reply = QuestionsDataBase.instance.execute(<<-SQL, user_id)
            SELECT
                *
            FROM
                replies
            WHERE
                user_id = ?
        SQL
        reply.map { |rep| Reply.new(rep) }
    end 

    def self.find_by_question_id(question_id)
        reply = QuestionsDataBase.instance.execute(<<-SQL, question_id)
            SELECT
                *
            FROM
                replies
            WHERE
                question_id = ?
        SQL
        reply.map { |rep| Reply.new(rep) }
    end

    def create
        raise "#{self} already in database" if @id
        QuestionsDataBase.instance.execute(<<-SQL, @question_id, @body, @user_id, @reply_id)
            INSERT INTO
                replies (question_id, body, user_id, reply_id)
            VALUES
                (?, ?, ?, ?)
        SQL
        @id = QuestionsDataBase.instance.last_insert_row_id
    end

    def update
        raise "#{self} not in database" unless @id
        QuestionsDataBase.instance.execute(<<-SQL, @question_id, @body, @user_id, @reply_id, @id)
            UPDATE
                replies
            SET
                question_id = ?, body = ?, user_id = ?, reply_id = ?
            WHERE
                id = ?
        SQL
    end 
end

class Like
    attr_accessor :likes

    def self.all
        data = QuestionsDataBase.instance.execute("SELECT * FROM question_likes")
        data.map { |datum| Like.new(datum) }
    end 

    def initialize(options)
        @id = options['id']
        @question_id = options['question_id']
        @user_id = options['user_id']
        @likes = options['likes']
    end 

    def self.most_liked_questions(n)
        likes = QuestionsDataBase.instance.execute(<<-SQL, n)
            SELECT
                questions.title, SUM(likes) AS total_likes
            FROM
                question_likes
            JOIN
                questions ON questions.id = question_likes.question_id
            GROUP BY
                question_id
            ORDER BY
                SUM(likes) DESC
            LIMIT
                ?
        SQL
    end 

    def self.find_by_id(id)
        like = QuestionsDataBase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                question_likes 
            WHERE
                id = ?
        SQL
        Like.new(*like)
    end 

    def self.likers_for_question_id(question_id)
        QuestionsDataBase.instance.execute(<<-SQL, question_id)
            SELECT
                fname, lname
            FROM 
                question_likes
            JOIN
                users ON users.id = question_likes.user_id 
            WHERE
                question_id = ?
        SQL
    end

    def self.num_likes_for_question_id(question_id)
        QuestionsDataBase.instance.execute(<<-SQL, question_id)
            SELECT
                SUM(likes)
            FROM 
                question_likes
            WHERE
                question_id = ?
        SQL
    end

    def self.liked_questions_for_user_id(user_id)
        QuestionsDataBase.instance.execute(<<-SQL, user_id)
            SELECT
                title
            FROM 
                question_likes
            JOIN 
                questions ON questions.id = question_likes.question_id
            WHERE
                question_likes.user_id = ?
        SQL
    end

    def create
        raise "#{self} already in database" if @id
        QuestionsDataBase.instance.execute(<<-SQL, @question_id, @likes, @user_id)
            INSERT INTO
                question_likes (question_id, likes, user_id)
            VALUES
                (?, ?, ?)
        SQL
        @id = QuestionsDataBase.instance.last_insert_row_id
    end

    def update
        raise "#{self} not in database" unless @id
        QuestionsDataBase.instance.execute(<<-SQL, @question_id, @likes, @user_id, @id)
            UPDATE
                question_likes
            SET
                question_id = ?, likes = ?, user_id = = ?
            WHERE
                id = ?
        SQL
    end 
end