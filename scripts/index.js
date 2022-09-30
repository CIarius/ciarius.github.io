function showModal(filename){

	let request = new XMLHttpRequest();

	request.open("GET", filename);

	request.send(null);

	request.onload = function(){
		document.getElementById("code").innerHTML = request.responseText.replaceAll("<","&lt;").replaceAll(">","&gt;");
		console.log(request.responseType);
		document.getElementById("modal").style.display = "block";
	}

}
