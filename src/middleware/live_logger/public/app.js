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
      App.rememberScrollPosition();
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
      App.setScrollPosition();
      $("#detail-view").hide();
    }
  });

  // Request Model
  // ----------
  window.Request = Backbone.Model.extend({

    statusClass: function(){
      var status = this.attributes.status;
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
    }

  });

  window.Requests = Backbone.Collection.extend({
    model: Request,
    url: function() {
      return '/all'
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
      this.Requests = new Requests;
      window.socket.on('request', function (data) {
        self.Requests.add(data['request'])
      });
      this.Requests.bind('add', function(model){
        var view = new RequestView({model: model});
        $("ul#requests").append(view.render().el);
        if (window.scrollWithIt == true) {
          window.scrollTo(0, document.body.scrollHeight);
        }
      });
      this.Requests.bind('reset', function(models){
        _.each(models.models, function(model){
          var view = new RequestView({model: model});
          $("ul#requests").append(view.render().el);
        });
        window.scrollTo(0, document.body.scrollHeight);
      });
      this.Requests.fetch();
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

    rememberScrollPosition: function(){
      if (window.scrollWithIt === true) {
        this.disableScrolling();
        this.lastScrollPosition = -1;
      } else {
        this.lastScrollPosition = window.pageYOffset;
      }
    },

    setScrollPosition: function(){
      if (this.lastScrollPosition >= 0) {
        window.scrollTo(0, this.lastScrollPosition);
      } else {
        this.enableScrolling();
      }
    },

    scrollEvent: function(){
      if (window.pageYOffset < this.lastScrollPosition){
        this.disableScrolling();
      }
      if (window.scrollWithIt === true) {
        this.lastScrollPosition = window.pageYOffset;
      }
    },

    toggleScrolling: function() {
      if (window.scrollWithIt == true) {
        this.disableScrolling();
      } else {
        this.enableScrolling();
      }
    }

  });

  window.socket = io.connect('/');
  window.App = new AppView;
  window.Controller = new Router;
  Backbone.history.start();

  $('#scroll-btn').click(function() {
    App.toggleScrolling();
  });
});
