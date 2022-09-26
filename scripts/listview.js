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

function drawPage(){

  var rows = document.getElementById("results").getElementsByTagName("tr");

  // ignoring the header row count number of rows visible to client

  var unfiltered = 0;

  for ( var row = 0; row < rows.length; row++ ){
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

function drawPageNavigationButtons(){

  var alpha, omega;

  alpha = ( cur_page_num - 2 > 0 )       ? cur_page_num - 2 : first_page_num;

  omega = ( alpha + 4 <= last_page_num ) ? alpha + 4 : last_page_num;

  alpha = ( alpha < last_page_num - 4 )  ? alpha : last_page_num - 4;

  alpha = ( alpha < first_page_num )     ? first_page_num : alpha;
  
  text = "<input type='button' class='w3-button' onclick='navigate(this.value)' value='|<'/>";

  text = text + "<input type='button' class='w3-button' onclick='navigate(this.value)' value='<'/>";

  for ( var page = alpha; page <= omega; page++ ){
    text = text + "<input class='w3-button' onclick='navigate(this.value)' type='button' value='" + page + "'/>";    
  }  

  text = text + "<input type='button' class='w3-button' onclick='navigate(this.value)' value='>'/>";

  text = text + "<input type='button' class='w3-button' onclick='navigate(this.value)' value='>|'/>";
  
  text = text + "<input id='search' title='search for...' type='search' value='" + criteria + "'/>";
  
  text = text + "<input type='button' class='w3-button fa fa-search' onclick='drawPage()'/>";

  text = text + "<input id='length' min='10' max='100' title='page length...' type='numeric' value='" + page_size + "'/>";
  
  text = text + "<input type='button' class='w3-button fa fa-refresh' onclick='drawPage()'/>";

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