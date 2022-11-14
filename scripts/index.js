function showModal(filename){

	let request = new XMLHttpRequest();

	request.open("GET", filename);

	request.send(null);

	request.onload = function(){
		document.getElementById("code").innerHTML = request.responseText.replaceAll("<","&lt;").replaceAll(">","&gt;");
		document.getElementById("modal").style.display = "block";
	}

}

function toggleDisplay(obj){
	// using indexOf here as a workaround for the style.display property being "" initially ?
	obj.nextElementSibling.style.display = ( ["none", ""].indexOf(obj.nextElementSibling.style.display) != -1 ) ? "block" : "none";
	obj.classList.toggle("open");
}