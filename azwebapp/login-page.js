const loginForm = document.getElementById("login-form");
const loginButton = document.getElementById("login-form-submit");
const loginErrorMsg = document.getElementById("login-error-msg-holder");

loginButton.addEventListener("click", (e) => {
    e.preventDefault();
    const username = loginForm.username.value;
    const password = loginForm.password.value;

    if (username === "net_admin" && password === "P@ssw0rd!123") {
		loginErrorMsg.style.opacity = 0;
        window.location.href = "portsecurity.html";
    } else {
        loginErrorMsg.style.opacity = 1;
    }
})