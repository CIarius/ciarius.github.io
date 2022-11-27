function showModal(filename){

	console.log(filename);

	let request = new XMLHttpRequest();

	request.open("GET", filename);

	request.send(null);

	request.onreadystatechange = function(){

		//document.getElementById("title").innerHTML = filename;

		document.getElementById("code").innerHTML = request.responseText.replaceAll("<","&lt;").replaceAll(">","&gt;");

		document.getElementById("modal-outer").style.display 	= "block";

	}

}

function toggleDisplay(obj){
	// using indexOf here as a workaround for the style.display property being "" initially ?
	obj.nextElementSibling.style.display = ( ["none", ""].indexOf(obj.nextElementSibling.style.display) != -1 ) ? "block" : "none";
	obj.classList.toggle("open");
}