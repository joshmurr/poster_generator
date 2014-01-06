import processing.pdf.*;
import controlP5.*;

PrintWriter jsonFile, defJSON;
JSONObject json;
ControlP5 cp5;
String textValue = "";
String searchTerm = "";
String previousSearch, previousSearchNonFormat = "";
PImage bgImage;
boolean searched, madepg = false;
String errors = "";
PFont font, helvTitle, helvBody;
PGraphics pg, pdfpg;
int iw = 750;
int ih = 850;
int padding;

void setup() {
  size(500, 300);
  background(0);
  frame.setResizable(true);
  font = createFont("andale mono", 10, false);
  helvTitle = createFont("Helvetica", 55, false);
  helvBody = createFont("Helvetica", 16, false);
  cp5 = new ControlP5(this);

  cp5.addTextfield("search")
    .setPosition(20, 20)
      .setSize(200, 13)
        .setFont(font)
          .setFocus(true)
            .setColor(color(255));
  pdfpg = createGraphics(841, 1189, PDF, "sdgf.pdf");
}

void draw() {
  if (searched) {
    pg = createGraphics(841, 1189);
    frame.setSize(pg.width, pg.height);
    padding = (pg.width-iw)/2;
    image(bgImage, padding, padding);
    //if (madepg) {

    pdfpg.beginDraw();
    pdfpg.image(pg, 0, 0);
    pdfpg.endDraw();
    //}
  }
  fill(255);
  textFont(font);
  text(errors, 20, 80);
}

public void input(String inputval) {
  textValue = inputval;
}

String ammendSearch(String searchTerm_) {
  String searchTerm = searchTerm_;
  String searchTermMod = "";
  String space = "+";
  ArrayList<String> subStrings = new ArrayList<String>();
  int index = 0;

  searchTerm = searchTerm.toLowerCase();
  for (int i=0; i<searchTerm.length(); i++) {
    if (searchTerm.charAt(i) == ' ') {
      subStrings.add(searchTerm.substring(index, i));
      subStrings.add(space);
      index = i+1;
    }
  }

  subStrings.add(searchTerm.substring(index, searchTerm.length()));

  for (int j=0; j<subStrings.size(); j++) {
    searchTermMod += subStrings.get(j);
  }
  return searchTermMod;
}

public void search(String searchTerm_) {
  if (searchTerm_.charAt(0) == ' ') {
    errors = "Incorrect search term";
    return;
  } 
  else {
    errors = "";
    searchTerm = ammendSearch(searchTerm_);
    previousSearchNonFormat = searchTerm;
    JSONObject response;
    String[] imgUrls;
    File fileName = new File(dataPath(searchTerm+".json"));
    if (!fileName.exists()) {
      println(searchTerm + " does not exist");
      println("Making JSON");
      makeJSON(searchTerm);
    }
    json = loadJSONObject(searchTerm+".json");
    try {
      response = json.getJSONObject("responseData");
    } 
    catch(Exception e) {
      response = null;
    }
    if (response == null) {
      errors = "Search yeilded no results, but try again...";
      makeJSON(searchTerm);
      return;
    }
    else {
      JSONArray results = response.getJSONArray("results");
      imgUrls = new String[results.size()];
      for (int i = 0; i < results.size(); i++) {
        JSONObject obj = results.getJSONObject(i); 
        String imgUrl = obj.getString("unescapedUrl");
        imgUrls[i] = imgUrl;
      }
    }
    try {
      loadBG(imgUrls);
    } 
    catch (Exception e) {
      errors = "Image load error";
      loadBG(imgUrls);
    }
    previousSearch = searchTerm;
    searched = true;
    searchTerm = "";
    //dotMatrix();
  }
}

void loadBG(String[] bgImgs_) {
  String[] bgImgs = bgImgs_;
  PImage temp = loadImage(bgImgs[floor(random(bgImgs.length))]);
  if (!(temp.width>0 && temp.height>0)) loadBG(bgImgs);
  bgImage = temp.get((temp.width/2)-(iw/2), (temp.height/2)-(ih/2), iw, ih);
}

void makeJSON(String toSearch) {
  String lines[] = loadStrings("https://ajax.googleapis.com/ajax/services/search/images?v=1.0&q="+toSearch+"&imgsz=xxlarge");
  jsonFile = createWriter("data/"+toSearch+".json");
  for (int l=0; l<lines.length; l++) {
    jsonFile.println(lines[l]);
  }
  jsonFile.flush();
  jsonFile.close();
}

String getDefinition() {
  println("Searching for Definition");
  String thisSearch = previousSearch.toLowerCase();
  String[] lines;
  JSONObject def, primaries2, entries2, terms2;
  JSONArray primaries, entries, terms;
  int count = 0;
  for (int i=0; i<thisSearch.length(); i++) {
    if (thisSearch.charAt(i) == ' ') count++;
  }
  thisSearch = makeSearchforDef(previousSearch, count);
  println("THIS SEARCH: " + thisSearch);
  lines = loadStrings("http://www.google.com/dictionary/json?callback=a&sl=en&tl=en&q="+thisSearch);
  defJSON = createWriter("data/"+thisSearch+"DEF.json");
  String temp = lines[0].substring(2, (lines[0].length()-10));
  String temp2 = "";
  for (int i=0; i<temp.length(); i++) {
    if (!(temp.charAt(i) == '\\')) {
      temp2 += str(temp.charAt(i));
    }
  }
  defJSON.println(temp2);
  defJSON.flush();
  defJSON.close();
  def = loadJSONObject(thisSearch+"DEF.json");
  try {
    primaries = def.getJSONArray("primaries");
  } 
  catch(Exception e) {
    println(e);
    primaries = null;
  }
  if (primaries == null) {
    errors = "Can't get definition. Not sure why.";
    String willDo = "";
    return willDo;
  } 
  primaries2 = primaries.getJSONObject(0);
  entries = primaries2.getJSONArray("entries");
  try {
    entries2 = entries.getJSONObject(1);
  } 
  catch(Exception e) {
    entries2 = entries.getJSONObject(0);
  }
  terms = entries2.getJSONArray("terms");
  terms2 = terms.getJSONObject(0);
  String gotDef = terms2.getString("text");
  println(gotDef);
  String reformatDef = "";
  int c = 0;
  for (int k=0; k<gotDef.length(); k++) {
    if (gotDef.charAt(k) == 'x' && Character.isDigit(gotDef.charAt(k+1))) c++;
  }
  if (c > 0) {
    for (int n=0; n<c; n++) {
      for (int j=0; j<gotDef.length(); j++) {
        int index = 0;
        if (gotDef.charAt(j) == 'x' && Character.isDigit(gotDef.charAt(j+1))) {
          index = j;
          reformatDef += gotDef.substring(0, index);
          reformatDef += gotDef.substring(index+3);
          index += 2;
        }
      }
    }
  }
  else {
    reformatDef = gotDef;
  }
  reformatDef += ".";
  return reformatDef;
}


void mousePressed() {
  dotMatrix();
}

void dotMatrix() {
  madepg = false;
  println("Treating for " + previousSearch);
  int p = 10;
  int rr = (random(1) < 0.5) ? 0 : 255;
  int rg = (random(1) < 0.5) ? 0 : 255;
  int rb = (random(1) < 0.5) ? 0 : 255;
  bgImage.loadPixels();
  pg.beginDraw();
  pg.noStroke();
  pg.fill(rr, rg, rb);
  pg.rect(0, 0, pg.width, pg.height);
  if (rr == rg && rg == rb) {
    if (rr == 0) pg.fill(255);
    else pg.fill(0);
  } 
  else {
    int f = (random(1) < 0.5) ? 0 : 255;
    pg.fill(f);
  }
  pg.translate(padding, padding);
  for (int j=0; j<bgImage.width; j+=(p-2)) {
    for (int k=0; k<bgImage.height; k+=(p-2)) {
      int loc = j+k*bgImage.width;
      float r = (brightness(bgImage.pixels[loc])/255.0)*p;
      pg.ellipse(j+p/2, k+p/2, r, r);
    }
  }
  int count = 0;
  for (int i=0; i<previousSearch.length(); i++) {
    if (previousSearch.charAt(i) == '+') count++;
  }
  previousSearch = remakeSearch(previousSearch, count);
  pg.textFont(helvTitle);
  pg.text(previousSearch, 0, ih+padding*2);
  pg.textFont(helvBody);
  pg.textAlign(LEFT);
  pg.text(getDefinition(), pg.width/2, ih+padding+padding/4, (iw/2)-padding, iw/2);
  pg.endDraw();
  pg.save("NewNew/"+previousSearch+".png");
  searched = false;
  madepg = true;
}

String makeSearchforDef(String search, int rounds) {
  String current = search;
  String remadeSearch = "";
  if (rounds == 0) {
    remadeSearch = current.toLowerCase();
  } 
  else {
    for (int i=0; i<rounds; i++) {
      remadeSearch += current.substring(0, current.indexOf(' '));
      remadeSearch += "%20";
      remadeSearch += current.substring(current.indexOf(' ')+1, current.length());
    }
  }
  return remadeSearch;
}

String remakeSearch(String search, int rounds) {
  String current = search;
  String remadeSearch = "";
  if (rounds == 0) {
    remadeSearch += str(current.charAt(0)).toUpperCase();
    remadeSearch += current.substring(1);
  } 
  else {
    for (int i=0; i<rounds; i++) {
      remadeSearch += str(current.charAt(0)).toUpperCase();
      remadeSearch += current.substring(1, current.indexOf('+'));
      remadeSearch += " ";
      remadeSearch += str(current.charAt(current.indexOf('+')+1)).toUpperCase();
      remadeSearch += current.substring(current.indexOf('+')+2, current.length());
    }
  }
  return remadeSearch;
}

