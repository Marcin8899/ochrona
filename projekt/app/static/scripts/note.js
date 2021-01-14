document.addEventListener('DOMContentLoaded', function (event) {

    const POST = "POST";
    const URL = "https://localhost:8080/";


    let shareForm = document.getElementById("share-form");
    shareForm.addEventListener("submit",  function (event) {
        event.preventDefault();
        var user = document.getElementById("user").value;
        var note_id = window.location.pathname;
        note_id = note_id.replace('/my/', '');
        note_id = note_id.replace('/', '');
        var formData = new FormData();
        formData.set("user", user);
        formData.set("note_id", note_id);
        submitShare(formData);
            
    });


    function submitShare(formData) {
        let registerUrl = URL + "share/";

        let registerParams = {
            method: POST,
            body: formData,
            redirect: "follow"
        };

        fetch(registerUrl, registerParams)
                .then(response => getResponseData(response))
                .catch(err => {
                    console.log("Caught error: " + err);
                });
    }

    function getResponseData(response) {
        let status = response.status;
        console.log(response)
        if (status === 200) {
            console.log("OK");
            window.location.replace(URL + "my/");
        } else {
            window.location.replace(URL + "logout/");
            console.log(response)
        }
    }


    let passwordForm = document.getElementById("decrypt-form");
    passwordForm.addEventListener("submit",  function (event) {
        event.preventDefault();
        var password = document.getElementById("password").value;
        var note_id = window.location.pathname;
        note_id = note_id.replace('/my/', '');
        note_id = note_id.replace('/', '');
        var formData = new FormData();
        formData.set("password", password);
        submitDecrypt(formData,note_id);
            
    });


    function submitDecrypt(formData,note_id) {
        let registerUrl = URL + "decrypt/" + note_id + "/";
        console.log(registerUrl)
        let registerParams = {
            method: POST,
            body: formData,
            redirect: "follow"
        };

        fetch(registerUrl, registerParams)
                .then(response => console.log(response))
                .catch(err => {
                    console.log("Caught error: " + err);
                });
    }
});