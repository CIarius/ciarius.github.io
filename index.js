function showModal(filename){

	let request = new XMLHttpRequest();

	request.open("GET", filename);

	request.onload = function(){
		document.getElementById("code").innerHTML = request.responseText;
		document.getElementById("modal").style.display = "block";
	}

}