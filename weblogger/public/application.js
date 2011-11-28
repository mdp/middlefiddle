var MiddleFiddle = {};
MiddleFiddle.views = {};
MiddleFiddle.main = function (){
  if(window.location.hash.length > 1) {
    MiddleFiddle.views.request(window.location.hash.match(/\#(.+)/)[1]);
  } else {
    MiddleFiddle.views.index();
  }
};

MiddleFiddle.views.index = function() {
  var socket = io.connect('http://localhost');
  socket.on('request', function (data) {
    console.log(data);
    var requestData = data['request'];
    var status = Number(requestData['status']);
    requestData['statusClass'] = function(){
      console.log("statusClass");
      if (status >= 500) {
        return 'five_hundred';
      } else if (status >= 400) {
        return 'four_hundred';
      } else if (status >= 300) {
        return 'three_hundred';
      } else if (status >= 200) {
        return 'two_hundred';
      } else {
        return 'two_hundred';
      }
    };
    var template = $("#requestIndexTemplate").html();
    req = $.mustache(template, requestData);
    $('ul#requests').append(req);
    window.scrollTo(0, document.body.scrollHeight);
  });
  $('ul#requests li').live('click', function(){
    window.open('#' + $(this).data('id'));
  });
};

MiddleFiddle.views.request = function (key) {
  $.getJSON('/' + key, function(data) {
    var template = $("#requestShowTemplate").html();
    req = $.mustache(template, data);
    $('body').append(req);
  });
}

MiddleFiddle.main();
