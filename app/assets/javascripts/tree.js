// http://odyniec.net/articles/turning-lists-into-trees/
window.onload = function () {
  var trees = document.getElementsByClassName("tree");
  for (i = 0; i < trees.length; i++) {
    var tree = trees[i];

    var lists = [ tree ];

    for (var i = 0; i < tree.getElementsByTagName("ul").length; i++)
      lists[lists.length] = tree.getElementsByTagName("ul")[i];

    for (var i = 0; i < lists.length; i++) {
      var item = lists[i].lastChild;

      while (!item.tagName || item.tagName.toLowerCase() != "li")
      item = item.previousSibling;

      item.className += " last";
    }
  }
};
