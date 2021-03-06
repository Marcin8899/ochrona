# -*- coding: utf-8 -*-
from flask import Flask, render_template, request, jsonify, make_response, abort, session, flash, send_file
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, set_access_cookies, unset_jwt_cookies, get_jwt_identity
from datetime import datetime
from Crypto.Cipher import ARC4
import json
import hashlib
import os
import logging
import math
import time
import mysql.connector
from flask_wtf.csrf import CSRFProtect
from const import * 
import uuid
app = Flask(__name__, static_url_path="")
jwt = JWTManager(app)
log = app.logger

#csrf = CSRFProtect(app)

TOKEN_EXPIRES_IN_SECONDS = 300

SECRET_KEY = "LOGIN_JWT_SECRET"
UPLOAD_FOLDER = 'files/'
app.config["JWT_SECRET_KEY"] = os.environ.get(SECRET_KEY)
app.config["RESET_KEY"] = os.environ.get("RESET_KEY")
app.config["JWT_ACCESS_TOKEN_EXPIRES"] = TOKEN_EXPIRES_IN_SECONDS
app.config["JWT_TOKEN_LOCATION"] = 'cookies'
app.config["JWT_COOKIE_CSRF_PROTECT"] = False
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

config = {
        'user': "root",
        'password': "root",
        'host': "db",
        'port': 3306
    }
app.secret_key = os.environ.get(SECRET_KEY)
connection = mysql.connector.connect(**config)
cursor = connection.cursor()

def setup():
    log.setLevel(logging.DEBUG)

@app.route("/", methods=[GET])
def home():
    return render_template("login.html"), 200

@app.route("/register/",  methods=[GET,POST])
def register():
    ip = request.remote_addr
    if(check_ban(ip)):
        return render_template("ban.html")
    if request.method == POST:
        login = request.form["login"]
        password = request.form["password"]
        repeated_password = request.form["re-password"]
        email = request.form["mail"]
        integral = request.form["inte"]
        if( check_field(login) or check_field(password) or check_field(repeated_password) or check_field(email) or check_field(integral) ):
            response = make_response( jsonify( {"message": "Niezezpieczne znaki"} ), 406)
            response.headers["Content-Type"] = "application/json"
            return response 

        if(repeated_password != password):
            return "Hasła są różne", 400

        cursor.execute("USE notes")

        query = ("SELECT * FROM user WHERE nickname = %(login)s")
        cursor.execute(query, {'login' : login})
        data = cursor.fetchall()

        if(len(data) != 0):
            response = make_response( jsonify( {"message": "Błędne dane"} ), 400)
            response.headers["Content-Type"] = "application/json"
            return response

        if(integral != '81'):
            response = make_response( jsonify( {"message": "Błędne dane"} ), 400)
            response.headers["Content-Type"] = "application/json"
            return response

        query = ("SELECT * FROM user WHERE mail = %(email)s")
        cursor.execute(query, {'email' : email})
        data = cursor.fetchall()
        if(len(data) != 0):
            response = make_response( jsonify( {"message": "Błędne dane"} ), 400)
            response.headers["Content-Type"] = "application/json"
            return response

        H = entropy(password)
        log.debug("Entropy: " + str(H))

        if(H<3):
            return "Hasło jest za słabe", 400

        password_hash = hashpass(password)
    
        add_user = ('''INSERT INTO user
            (nickname, password_hash, mail) 
            VALUES (%(login)s, %(password_hash)s, %(email)s)''')

        user_data = {
            'login': login,
            'password_hash': password_hash,
            'email' : email
        }
        cursor.execute(add_user, user_data)
        connection.commit()
        cursor.execute("SELECT * FROM user")
        data = cursor.fetchall()
        return "OK", 201
    else:
        return render_template("registration.html"), 200

@app.route("/login/",  methods=[GET,POST])
def login():
    ip = request.remote_addr
    if(check_ban(ip)):
        return render_template("ban.html")
    if request.method == POST:
        log.warn("logowanie nastąpi za 2 sekuny")
        time.sleep(2)
        
        login = request.form["login"]
        password = request.form["password"]

        if(login == "admin" or login == "root" or login == "master"):
            log.warn("PRÓBA ZALOGOWANIA NA NIEOZWOLONE KONTA !!!!!!!!!!!!!")
            log.warn("Wykonana z ip: " + str(ip) )

        if( check_field(login)):
            response = make_response( jsonify( {"message": "Wrong username or password"} ), 406)
            response.headers["Content-Type"] = "application/json"
            return response 
        
        cursor.execute("USE notes")

        query = ("SELECT password_hash FROM user WHERE nickname = %(login)s")    
        cursor.execute(query, {'login' : login}) 
        data = cursor.fetchall()
        if(len(data) == 0):
            update_ip(ip, 1)
            response = make_response( jsonify( {"message": "Wrong username or password"} ), 400)
            response.headers["Content-Type"] = "application/json"
            return response

        password_hash = hashpass(password)

        corr_password = data[0][0]
        if(corr_password == password_hash):
            cursor.execute(" INSERT INTO session_data VALUES (%(user)s, %(ip)s)", {'user': login, 'ip': str(ip)})
            connection.commit()
            update_ip(ip, 0)
            access_token = create_access_token(identity = hashlib.sha512(login.encode("utf-8")).hexdigest())
            response = make_response( jsonify( {"message": "OK"} ), 200)
            response.headers["Content-Type"] = "application/json"
            set_access_cookies(response, access_token)
            session['user'] = login
            return response
        else:
            update_ip(ip, 1)
            response = make_response( jsonify( {"message": "Wrong username or password"} ), 400)
            response.headers["Content-Type"] = "application/json"
            return response
    else:
        return render_template("login.html"), 200

@app.route("/logout/",  methods=[GET])
def logout():
    log.debug(check_user())
    user = check_user()
    flask_user = session['user']
    cursor.execute("USE notes")
    cursor.execute("DELETE FROM session_data WHERE user = %(user)s", {'user': flask_user})
    connection.commit()
    response = make_response(render_template("logout.html"))
    unset_jwt_cookies(response)
    session.pop('user', None)
    return response, 200



@app.route("/notes/",  methods=[GET,POST])
@jwt_required
def notes():
    ip = request.remote_addr
    if(check_ban(ip)):
        return render_template("ban.html")
    if(request.method == POST):
        name = request.form["name"]
        note = request.form["note"]
        public = check_mark_on_bool(request.form.get("public"))
        encrypted = check_mark_on_bool(request.form.get("check"))
        password = request.form["password"]
        author = check_user()

        if( check_field(name) or check_field(note) or check_field(password) ):
            return render_template("wrong_data.html")

        if(encrypted):
            H = entropy(password)
            if(H < 3.0):
                return render_template("notes.html", info = "   Hasło jest za słabe")
            note = encrypt_note(note, password)        
        else:
            note = bytes(note, 'utf-8')
        
        add_note = ('''INSERT INTO note
            (author, name, note, public, encrypted) 
            VALUES (%(author)s, %(name)s, %(note)s, %(public)s, %(encrypted)s)''')
        
        note_data = {
            'author': author,
            'name': name,
            'note': note,
            'public': public,
            'encrypted': encrypted
        }

        cursor.execute("USE notes")

        cursor.execute(add_note,note_data)
        connection.commit()
        return render_template("notes.html", info = "   Notatka została utworzona")

    else:
        return render_template("notes.html")

@app.route("/public/",  methods=[GET])
def public():
    ip = request.remote_addr
    if(check_ban(ip)):
        return render_template("ban.html")
    cursor.execute("USE notes")
    cursor.execute(''' SELECT * FROM note
                        WHERE public''')
    data = cursor.fetchall()
    to_send = []
    for row in data:
        if(row[5] == 1):
            info = "Notatka zaszyfrowana"
            note = row[3]
        else:
            info = "Zwykła notatka"
            note =  row[3].decode("utf-8")
        to_send.append({
            'author': row[1],
            'name': row[2],
            'note': note,
            'info' : info
        })
    return render_template("public.html", notes = to_send)

@app.route("/my/",  methods=[GET])
@jwt_required
def my_notes():
    ip = request.remote_addr
    if(check_ban(ip)):
        return render_template("ban.html")
    login = check_user()
    cursor.execute("USE notes")
    sql = (''' SELECT * FROM note
                        WHERE author = %(nickname)s ''')
    cursor.execute(sql, {'nickname': login})
    data = cursor.fetchall()

    to_send = []
    for row in data:
        to_send.append({
            'id': row[0],
            'name': row[2],
        })
    return render_template("my.html", notes = to_send)

@app.route("/my/<int:note_id>/",  methods=[GET])
@jwt_required
def one_note(note_id):
    ip = request.remote_addr
    if(check_ban(ip)):
        return render_template("ban.html")
    login = check_user()
    cursor.execute("USE notes")
    sql = (''' SELECT * FROM note
            WHERE author = %(nickname)s  
            AND id = %(note_id)s''')
    cursor.execute(sql, {'nickname': login, 'note_id': note_id})
    data = cursor.fetchall()
    if(len(data) == 0):
        return render_template("logout.html")
    data = data[0]
    if(data[5] == 1):
        info = "Notatka zaszyfrowana"
        note = data[3]
    else:
        info = "Zwykła notatka"
        note =  data[3].decode("utf-8")
    to_send =({
        'id': data[0],
        'author': data[1],
        'name': data[2],
        'note': note,
        'info' : info,
    })
    return render_template("note.html", note = to_send)

@app.route("/share/", methods=[POST])
@jwt_required
def share():
    ip = request.remote_addr
    if(check_ban(ip)):
        return render_template("ban.html")
    login = check_user()
    user = request.form["user"]
    note_id = request.form["note_id"]

    if( check_field(user) or check_field(note_id)):
        response = make_response( jsonify( {"message": "Niezezpieczne znaki"} ), 406)
        response.headers["Content-Type"] = "application/json"
        return response 
    sql = (''' SELECT * FROM note
            WHERE author = %(nickname)s   
            AND id = %(note_id)s''')
    data = {
        'nickname': login,
        'note_id': note_id,
    }

    cursor.execute("USE notes")
    cursor.execute(sql,data)
    data = cursor.fetchall()
    if(len(data) == 0):
        return "BAD", 400
    data = data[0]

    cursor.execute("SELECT * FROM shared WHERE id = %(id)s",{'id': user + note_id})
    exists = cursor.fetchall()

    if(len(exists) != 0):
        return "BAD", 400

    add_note = ('''INSERT INTO shared
            (id, nickname, author, name, note, public, encrypted) 
            VALUES (%(id)s, %(nickname)s, %(author)s, %(name)s, %(note)s, %(public)s, %(encrypted)s)''')
        
    note_data = {
        'id': user + note_id,
        'nickname': user,
        'author': login,
        'name': data[2],
        'note': data[3],
        'public': data[4],
        'encrypted': data[5]
    }

    cursor.execute(add_note,note_data)
    connection.commit()
    return "OK", 200

@app.route("/shared/",  methods=[GET])
@jwt_required
def shared_notes():
    ip = request.remote_addr
    if(check_ban(ip)):
        return render_template("ban.html")
    login = check_user()
    cursor.execute("USE notes")
    sql = (''' SELECT * FROM shared
                        WHERE nickname = %(nickname)s ''')
    cursor.execute(sql, {'nickname': login})
    data = cursor.fetchall()

    to_send = []
    for row in data:
        if(row[6] == 1):
            info = "Notatka zaszyfrowana"
            note = row[4]
        else:
            info = "Zwykła notatka"
            note =  row[4].decode("utf-8")
        to_send.append({
            'author': row[2],
            'name': row[3],
            'note': note,
            'info' : info
        })
    return render_template("shared.html", notes = to_send)

@app.route("/decrypt/<int:note_id>/",  methods=[POST])
@jwt_required
def decrypt(note_id):
    ip = request.remote_addr
    if(check_ban(ip)):
        return render_template("ban.html")
    password = request.form["password"]
    #TODO 

    login = check_user()
    cursor.execute("USE notes")
    sql = (''' SELECT * FROM note
            WHERE author = %(nickname)s  
            AND id = %(note_id)s''')
    cursor.execute(sql, {'nickname': login, 'note_id': note_id})
    data = cursor.fetchall()
    if(len(data) == 0):
        return render_template("logout.html")
    data = data[0]
    if(data[5] == 1):
        info = "Notatka zaszyfrowana"
        note = data[3]
    else:
        info = "Zwykła notatka"
        note =  data[3].decode("utf-8")
    to_send =({
        'id': data[0],
        'author': data[1],
        'name': data[2],
        'note': decrypt_note(note,password),
        'info' : info,
    })
    return render_template("note.html", note = to_send)

@app.route("/files/", methods = [POST,GET])
@jwt_required
def files():
    ip = request.remote_addr
    if(check_ban(ip)):
        return render_template("ban.html")
    cursor.execute("USE notes")
    sql = ('''SELECT * FROM files 
        WHERE author = %(author)s''')
    data = {
        'author': check_user()
    }
    cursor.execute(sql,data)
    my_files = cursor.fetchall()
    if request.method == 'POST':
        if 'file' not in request.files:
            return render_template("files.html", info = "  Brak pliku", my_files = my_files)
        file = request.files['file']
        if file.filename == '':
            return render_template("files.html", info = "  Brak pliku", my_files = my_files )
        extension = file.filename.rsplit('.', 1)[1].lower()
        filename = uuid.uuid4().hex + "." + extension
        file.save(os.path.join(app.config['UPLOAD_FOLDER'], file.filename))
        
        sql = ('''SELECT * FROM files 
        WHERE name = %(name)s''')
        data = {
            'name': file.filename
        }
        cursor.execute(sql, data)
        data_sql = cursor.fetchall()
        if(len(data_sql) != 0):
            return render_template("files.html", info = "  Ten plik już został dodany", my_files = my_files)
        
        data = {
            'author': check_user(),
            'name': file.filename
        }
        sql = (''' INSERT INTO files VALUES
        (%(author)s, %(name)s )''')

        cursor.execute(sql, data)
        connection.commit()
        return render_template("files.html", my_files = my_files)
    else:
        return render_template("files.html", my_files = my_files)

@app.route("/files/<string:name>/", methods = [GET])
@jwt_required
def download_file(name):
    ip = request.remote_addr
    if(check_ban(ip)):
        return render_template("ban.html")

    sql = ('''SELECT * FROM files 
        WHERE author = %(author)s AND name = %(name)s''')
    data = {
        'author': check_user(),
        'name': name
    }
    cursor.execute(sql, data)
    data = cursor.fetchall()
    if(len(data) == 0):
        return render_template("files.html", info = " Nie można pobrać tego pliku")
    filepath = app.config['UPLOAD_FOLDER'] + name
    return send_file(filepath, as_attachment=True)

@app.route("/reset/", methods = [GET,POST])
def reset():
    ip = request.remote_addr
    if(check_ban(ip)):
        return render_template("ban.html")
    if request.method == POST:

        corr_pass = "mail123"
        login = request.form["login"]
        password = request.form["password"]
        code = request.form["code"]

        if( check_field(code) or check_field(login) or check_field(password) ):
            return render_template("wrong_data.html")

        cursor.execute("USE notes")
        cursor.execute(" SELECT * FROM user WHERE nickname = %(username)s",{'username': login})
        data = cursor.fetchall()
        if(len(data) == 0):
            return render_template("reset.html", info = " Błędna nazwa użytkownika" )

        if(entropy(password) < 3):
            return render_template("reset.html", info = " Nowe hasło jest za słabe" )

        if(corr_pass == code):
            password = hashpass(password)
            cursor.execute(" UPDATE user SET password_hash=%(password)s WHERE nickname = %(username)s",{'username': login, 'password':password})
            connection.commit()
            return render_template("reset.html", info = " Hasło zmienione" )
        else:
            return render_template("reset.html", info = " Błędny kod" )
    else:
        return render_template("reset.html")

@app.route("/wrong-password/", methods = [GET])
def wrong_password():
    return render_template("wrong_password.html")

@app.route("/wrong-data/", methods = [GET])
def wrong_data():
    return render_template("wrong_data.html")

def entropy(password):
    counter = {}
    for i in password:
        if i in counter:
            counter[i] += 1
        else:
            counter[i] = 1
    H = 0
    for i in counter.keys():
        p_i = counter[i]/len(password)
        H -= p_i * math.log2(p_i)
    return H

def hashpass(password):
    m = hashlib.sha256()
    for i in range(10):
        m.update(bytes(password,'utf-8'))
    return m.hexdigest()

def encrypt_note(note, password):
    password = bytes(password, 'utf-8')
    cipher = ARC4.new(password)
    encrypted = cipher.encrypt(bytes(note, 'utf-8'))
    return encrypted

def decrypt_note(note, password):
    password = bytes(password, 'utf-8')
    cipher = ARC4.new(password)
    encrypted = cipher.decrypt(bytes(note))
    try:
        return encrypted.decode("utf-8") 
    except:
        return str(encrypted)

def update_ip(ip, to_add):
    cursor.execute("USE notes")
    cursor.execute("SELECT * from last_login WHERE ip = %(ip)s",{'ip':ip})
    data = cursor.fetchall()

    if(len(data) == 0):
        cursor.execute("INSERT INTO last_login VALUES (%(ip)s, %(bad_logins)s)", {'ip':ip, 'bad_logins': to_add})
        connection.commit()
    else:
        sql = ''' UPDATE last_login
                    SET bad_logins = %(bad_logins)s
                    WHERE ip = %(ip)s '''
        if(to_add == 0):
            bad_logins = 0
        else:
            bad_logins = data[0][1]
            bad_logins = bad_logins + 1
            if(bad_logins == 10):
                log.error("Ip zbanowane")
        cursor.execute(sql,{'bad_logins': bad_logins,'ip': ip})
        connection.commit()

def check_mark_on_bool(check):
    if(check == "on"):
        return True
    else:
        return False

def check_field(field):
    for char in field:
        if(char == "(" or char == ")" or char == "<" or char == ">"):
            return True
    return False


def check_user():

    cursor.execute("USE notes")
    
    jwt_user = get_jwt_identity()
    flask_user = session['user']
    cursor.execute(" SELECT * FROM session_data WHERE user=%(user)s", {'user': flask_user })
    data = cursor.fetchall()
    flask_user_hash = hashlib.sha512(flask_user.encode("utf-8")).hexdigest()

    if(jwt_user == flask_user_hash or len(data) != 0):
        return flask_user
    else:
        abort(401)

def check_ban(ip):
    cursor.execute("USE notes")
    cursor.execute("SELECT * from last_login WHERE ip = %(ip)s",{'ip':ip})
    data = cursor.fetchall()
    if(len(data) != 0):
        bad_logins = data[0][1]
        if(bad_logins == 10):
            return True
        else:
            return False
    else:
        return False

@app.errorhandler(400)
def wrong_data(error):
    return render_template("errors/400.html", error=error)

@app.errorhandler(401)
def page_unauthorized(error):
    return render_template("errors/401.html", error=error)

@app.errorhandler(403)
def page_forbidden(error):
    return render_template("errors/403.html", error=error)

@app.errorhandler(404)
def page_not_found(error):
    return render_template("errors/404.html", error=error)

@app.errorhandler(500)
def server_error(error):
    return render_template("errors/500.html", error=error)

@jwt.expired_token_loader
def my_expired_token_callback(expired_token):
    session.pop('user', None)
    return render_template('errors/401.html', error = "Żeton stracił ważność")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=True)
