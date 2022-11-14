var cur_page_num = 1, top_line_num = 1, first_page_num = 1, last_page_num = 1, page_size = 10, criteria = "";

function search(){
  cur_page_num = 1;
  top_line_num = 1;
  drawPage();
}

function navigate(btn){

  switch (btn){

    case "|<":{
      cur_page_num = first_page_num;
      break;
    }

    case "<":{
      cur_page_num = ( cur_page_num == first_page_num ) ? cur_page_num : cur_page_num - 1;
      break;
    }

    case ">":{
      cur_page_num = ( cur_page_num == last_page_num ) ? cur_page_num : cur_page_num + 1;
      break;
    }

    case ">|":{
      cur_page_num = last_page_num;
      break;
    }

    default: {
      cur_page_num = parseInt(btn);
    }

  }

  top_line_num = ( ( cur_page_num - 1 ) * page_size ) + 1;

  drawPage();

}

function initPage(){

	var headers = document.getElementById("results").getElementsByTagName("th");

	for ( var index = 0; index < headers.length; index++ ){

		headers[index].setAttribute('index', index);

		// assign each header an onclick event that toggles the sort order and renders the page accordingly

		headers[index].addEventListener('click', function(e){

			console.log("click!");

			e.target.order = ( e.target.order === "des" ) ? "asc" : "des"; 

			var sorted = false;

			while ( sorted == false ){

				var rows = document.getElementById("results").getElementsByTagName("tr");
	
				sorted = true;

				for ( var row = 1; row < rows.length - 1; row++ ){

					// the comparitors are either numbers, dates, or strings so convert/compare them accordingly

					var cmprtr_a = rows[row].children[e.target.cellIndex].lastChild.innerHTML ? rows[row].children[e.target.cellIndex].lastChild.innerHTML.toLowerCase() : rows[row].children[e.target.cellIndex].innerHTML.toLowerCase();

					if ( cmprtr_a != " " ){
						if ( ! isNaN( Number(cmprtr_a) ) )
							cmprtr_a = Number(cmprtr_a);
						else
							if ( ! isNaN( Date.parse(cmprtr_a) ) )
								cmprtr_a = Date.parse(cmprtr_a)
					}

					var cmprtr_b = rows[row+1].children[e.target.cellIndex].lastChild.innerHTML ? rows[row+1].children[e.target.cellIndex].lastChild.innerHTML.toLowerCase() : rows[row+1].children[e.target.cellIndex].innerHTML.toLowerCase();

					if ( cmprtr_b != " " ){
						if ( ! isNaN( Number(cmprtr_b) ) )
							cmprtr_b = Number(cmprtr_b);
						else
							if ( ! isNaN( Date.parse(cmprtr_b) ) )
								cmprtr_b = Date.parse(cmprtr_b)
					}

					if ( e.target.order == "des" ){

						if ( cmprtr_a < cmprtr_b ){
							sorted = false;
							buffer = rows[row].innerHTML;
							rows[row].innerHTML = rows[row+1].innerHTML;
							rows[row+1].innerHTML = buffer;
						}

					}else{

						if ( cmprtr_a > cmprtr_b ){
							sorted = false;
							buffer = rows[row].innerHTML;
							rows[row].innerHTML = rows[row+1].innerHTML;
							rows[row+1].innerHTML = buffer;
						}

					}

				}

			}

			drawPage();

		});

	}

	drawPage();

}

function drawPage(){

  var rows = document.getElementById("results").getElementsByTagName("tr");

  // ignoring the header row determine number of rows visible to client

  var unfiltered = 0;

  for ( var row = 1; row < rows.length; row++ ){
    if ( isVisible(rows[row]) ){
      unfiltered++;
    }
  }

  if ( document.getElementById("length") ){
    page_size = parseInt(document.getElementById("length").value);
  }

  // handle condition sometimes encountered when paging filtered selection

  if ( unfiltered < page_size ){
    top_line_num = 1;
  }

  last_page_num = Math.ceil( unfiltered / page_size );

  // hide those rows which don't match the search criteria or are not on the current page

  var index = 1;

  for ( var row = 1; row < rows.length; row++ ){ // ignore the header line at rows index 0

    if ( isVisible(rows[row]) ){

      if ( index >= top_line_num && index < ( top_line_num + page_size ) ){
        rows[row].style.display = "";
      }else{
        rows[row].style.display = "none";
      }

      index++;

    }else{
      rows[row].style.display = "none";
    }

  } 
  
  drawPageNavigationButtons();

}

function logout(){
	window.location = "/cgi-bin/logout.pl";	
}

function drawPageNavigationButtons(){

  var alpha, omega;

  alpha = ( cur_page_num - 2 > 0 )       ? cur_page_num - 2 : first_page_num;

  omega = ( alpha + 4 <= last_page_num ) ? alpha + 4 : last_page_num;

  alpha = ( alpha < last_page_num - 4 )  ? alpha : last_page_num - 4;

  alpha = ( alpha < first_page_num )     ? first_page_num : alpha;

  text = "<input onclick='navigate(this.value)' type='button' value='|&lt;'/>";

  text = text + "<input type='button' onclick='navigate(this.value)' value='<'/>";

  for ( var page = alpha; page <= omega; page++ ){
    text = text + "<input onclick='navigate(this.value)' type='button' value='" + page + "'/>";    
  }  

  text = text + "<input type='button' onclick='navigate(this.value)' value='>'/>";

  text = text + "<input type='button' onclick='navigate(this.value)' value='>|'/>";

  text += "<input id='search' placeholder='search for...' title='search for...' type='search' value='" + criteria + "'/>";  

  text += "<button onclick='drawPage()'/><i class='fa fa-search'></i></button>";

  text += "<input id='length' min='10' max='100' step='10' title='page length...' type='number' value='" + page_size + "'/>";

  text += "<button onclick='drawPage()'><i class='fa fa-refresh'></i></button>";

  text += "<button onclick='logout()'><i class='fa fa-sign-out'></i></button>";

  document.getElementById("navigation").innerHTML = text;

}

function isVisible(row){

  // determine if a record(row) is visible based on a cell containing user's 'search criteria
  if ( document.getElementById("search") ){
    criteria = document.getElementById("search").value.toUpperCase();
  }
  
  var cols = row.getElementsByTagName("td");
  var match = false;

  for ( var col = 0; col < cols.length; col++ ){
    text = cols[col].textContent || cols[col].innerText;
    if ( text.toUpperCase().indexOf(criteria) > -1 )
      match = true;
  }

  return match;

}