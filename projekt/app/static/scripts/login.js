document.addEventListener('DOMContentLoaded', function (event) {

    const POST = "POST";
    const URL = "https://localhost:8080/";


    let loginForm = document.getElementById("registration-form");
    loginForm.addEventListener("submit",  function (event) {
        event.preventDefault();
        var login = document.getElementById("login").value;
        var password = document.getElementById("password").value;
        var formData = new FormData();
        formData.set("login", login);
        formData.set("password", password);
        submitRegisterForm(formData);
            
    });


    function submitRegisterForm(formData) {
        let registerUrl = URL + "login/";

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
        if (status === 200) {
            console.log("OK");
            window.location.replace(URL + "my/");
        } else if(status=== 400){
            window.location.replace(URL + "wrong-password/");
        } else{
            window.location.replace(URL + "wrong-data/");
        }
    }


});