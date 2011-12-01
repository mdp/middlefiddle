// Load the application once the DOM is ready, using `jQuery.ready`:
$(function(){

  // Router
  window.Router = Backbone.Router.extend({
    routes: {
      "request/:id": "showRequest",
      "": "index",
      "/": "index"
    },

    showRequest: function(id){
      var reqDetails = new RequestDetail({id: id});
      reqDetails.fetch({
        success: function(model){
          var view = new RequestDetailView({model: model});
          view.render();
        }
      });
      $("#list-view").hide();
    },

    index: function(){
      $("#list-view").show();
      App.enableScrolling();
      $("#detail-view").hide();
    }
  });

  // Request Model
  // ----------
  window.Request = Backbone.Model.extend({

    statusClass: function(){
      if (this.status >= 500) {
        return 'five_hundred';
      } else if (this.status >= 400) {
        return 'four_hundred';
      } else if (this.status >= 300) {
        return 'three_hundred';
      } else if (this.status >= 200) {
        return 'two_hundred';
      } else {
        return 'two_hundred';
      }
    }

  });

  window.RequestDetail = Backbone.Model.extend({
    url: function(){
      return "/" + this.id;
    }

  });

  // The DOM element for an individual request...
  window.RequestView = Backbone.View.extend({
    tagName: 'li',

    // Cache the template function for a single item.
    template: $("#request-item").html(),

    container: $('#list-view'),

    events: {
      "click": "openRequestDetail"
    },

    openRequestDetail: function(){ Controller.navigate("request/" + this.model.id, true) },

    // Render the Request
    render: function() {
      var req = $.mustache(this.template, this.model.attributes);
      $(this.el).attr('class', this.model.get('method') + ' ' + this.model.statusClass());
      $(this.el).html(req);
      return this;
    }

  });

  window.RequestDetailView = Backbone.View.extend({
    // Cache the template function for a single item.
    template: $("#requestDetailTemplate").html(),

    container: $('#detail-view'),

    events: {
      "click": "closeRequestDetail"
    },

    closeRequestDetail: function(){ Controller.navigate("/", true) },

    // Render the Request
    render: function() {
      var reqDetail = $.mustache(this.template, this.model.toJSON());
      this.container.show();
      this.container.html(reqDetail);
      App.disableScrolling();
      return this;
    }
  });

  window.ScrollButtonView = Backbone.View.extend({
    className: 'scroll-btn',
    render: function(){
      $(this.el).html(req);
    }
  });

  // The Application
  // ---------------

  window.AppView = Backbone.View.extend({

    initialize: function() {
      var self = this;
      window.socket.on('request', function (data) {
        self.addRequest(data);
      });
    },

    addRequest: function(data) {
      var model = new Request(data['request']);
      var view = new RequestView({model: model});
      $("ul#requests").append(view.render().el);
      if (window.scrollWithIt == true) {
        window.scrollTo(0, document.body.scrollHeight);
      }
    },

    disableScrolling: function(){
      window.scrollWithIt = false;
      $('#scroll-btn').attr('class', '');
    },

    enableScrolling: function(){
      window.scrollWithIt = true;
      $('#scroll-btn').attr('class', 'active');
      window.scrollTo(0, document.body.scrollHeight);
    },

    toggleScrolling: function() {
      if (window.scrollWithIt == true) {
        this.disableScrolling();
      } else {
        this.enableScrolling();
      }
    }

  });

  window.socket = io.connect('http://localhost');
  window.App = new AppView;
  window.Controller = new Router;
  Backbone.history.start();

  $('#scroll-btn').click(function() {
    App.toggleScrolling();
  });

});
