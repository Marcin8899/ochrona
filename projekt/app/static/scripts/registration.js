document.addEventListener('DOMContentLoaded', function (event) {

    const GET = "GET";
    const POST = "POST";
    const URL = "https://localhost:8080/";

    const LOGIN_FIELD_ID = "login";
    const MAIL_FIELD_ID = "mail";
    const PASSWORD_FIELD_ID = "password";
    const REP_PASSWORD_FIELD_ID = "re-password";

    var HTTP_STATUS = {OK: 200, CREATED: 201, NOT_FOUND: 404};

    let registrationForm = document.getElementById("registration-form");
        registrationForm.addEventListener("submit",  function (event) {
        event.preventDefault();
        var login = document.getElementById("login").value;
        var password = document.getElementById("password").value;
        var repeatedPassword = document.getElementById("re-password").value;
        var mail = document.getElementById("mail").value;

        var toSend = true;
        removeWarning("loginWarning");
        removeWarning("passwordWarning");
        removeWarning("repeatedPasswordWarning");
        removeWarning("mailWarning");

        if(! loginValidate(login)){
            toSend = false;
        }
        console.log(toSend)
        if(! passwordValidate(password)){
            toSend = false;
        }
        console.log(toSend)
        if(! mailValidate(mail)){
            toSend = false;
        }
        console.log(toSend)
        if(! repeatedPasswordValidate(repeatedPassword, password)){
            toSend = false;
        }
        console.log(toSend)
        if(toSend) {
            var formData = new FormData();
            formData.set("login", login);
            formData.set("mail", mail);
            formData.set("password", password);
            formData.set("re-password", repeatedPassword);
            
            submitRegisterForm(formData);
            
        }
    });

    function repeatedPasswordValidate(repeatedPassword,password) {
        if(password != repeatedPassword) {
            let warningElem = prepareWarning("repeatedPasswordWarning", "Powtórzone hasło jest inne.");
            appendAfterElem(REP_PASSWORD_FIELD_ID, warningElem);
            return false;
        }
        return true;
    }

    function passwordValidate(password) {
         if (password.length < 8){
            let warningElem = prepareWarning("passwordWarning", "Za krótkie hasło.");
            appendAfterElem(PASSWORD_FIELD_ID, warningElem);
            return false; 
        }
         if (!(/^[a-zA-Z0-9\!\@\#\$\%\^\&\*]+$/.test(password))){
            let warningElem = prepareWarning("passwordWarning", "Dozwolone są litery liczby oraz !@#$%&*");
            appendAfterElem(PASSWORD_FIELD_ID, warningElem);
            return false; 
        }
         if(!(/[A-Z]+/.test(password))){
            let warningElem = prepareWarning("passwordWarning", "Hasło musi zawierać jedną wielką literę");
            appendAfterElem(PASSWORD_FIELD_ID, warningElem);
            return false; 
        }
         if(!(/[a-z]+/.test(password))){
            let warningElem = prepareWarning("passwordWarning","Hasło musi zawierać jedną małą literę");
            appendAfterElem(PASSWORD_FIELD_ID, warningElem);
            return false; 
        }
         if(!(/[0-9]+/.test(password))){
            let warningElem = prepareWarning("passwordWarning", "Hasło musi zawierać jedną cyfrę");
            appendAfterElem(PASSWORD_FIELD_ID, warningElem);
            return false; 
        }
         if(!(/[\!\@\#\$\%\^\&\*]+/.test(password))){
            let warningElem = prepareWarning("passwordWarning", "Hasło musi zawierać znak specjalny: !@#$%^&*.");
            appendAfterElem(PASSWORD_FIELD_ID, warningElem);
            return false; 
        }
        return true;
    }

    function loginValidate(login) {
        if(login.length < 5){
            let warningElem = prepareWarning("loginWarning", "Login musi mieć przynajmniej 5 znaków.");
            appendAfterElem(LOGIN_FIELD_ID, warningElem);
            return false;
        }
         if(!(/^[a-zA-Z0-9]+$/.test(login))){
            let warningElem = prepareWarning("loginWarning", "Login może składać się tylko z liter i cyfr.");
            appendAfterElem(LOGIN_FIELD_ID, warningElem);
            return false;
        }
        return true;
    }
    
    function mailValidate(mail) {

        return true;
    }

    function submitRegisterForm(formData) {
        let registerUrl = URL + "register/";

        let registerParams = {
            method: POST,
            body: formData,
            redirect: "follow"
        };

        fetch(registerUrl, registerParams)
                .then(response => getRegisterResponseData(response))
                .catch(err => {
                    console.log("Caught error: " + err);
                });
    }

    function getRegisterResponseData(response) {
        let status = response.status;
        console.log(response)
        if (status === 201) {
            console.log("OK");
            id = "button-reg-form";
            let correctElem = prepareWarning("correct", " Zarejestrowano!");
            appendAfterElem(id, correctElem);
        } else if (status === 406) {
            window.location.replace(URL + "wrong-data/");
        }
        else{
            alert("Błędne dane")
        }
    }

    function removeWarning(warningElemId) {
        let warningElem = document.getElementById(warningElemId);

        if (warningElem !== null) {
            warningElem.remove();
        }
    }

    function prepareWarning(newElemId, message) {
        let warningField = document.getElementById(newElemId);

        if (warningField === null) {
            let textMessage = document.createTextNode(message);
            warningField = document.createElement('span');

            warningField.setAttribute("id", newElemId);
            warningField.className = "warning-field";
            warningField.appendChild(textMessage);
        }
        return warningField;
    }

    function appendAfterElem(currentElemId, newElem) {
        let currentElem = document.getElementById(currentElemId);
        currentElem.insertAdjacentElement('afterend', newElem);
    }

});