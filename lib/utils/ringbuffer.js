(function() {
  var Ringbuffer;

  Ringbuffer = (function() {

    function Ringbuffer(size) {
      this.size = size;
      this.items = [];
      this.count = 0;
    }

    Ringbuffer.prototype.add = function(item) {
      var index;
      index = this.count % this.size;
      this.count++;
      item._timestamp = Number(new Date);
      this.items[index] = item;
      return this.buildKey(index, item);
    };

    Ringbuffer.prototype.all = function() {
      return this.items;
    };

    Ringbuffer.prototype.retrieve = function(key) {
      var index, item, ts;
      if (!key.match(/^[0-9]+\-[0-9]+$/)) return null;
      index = Number(key.match(/^[0-9]+/)[0]);
      ts = Number(key.match(/[0-9]+$/)[0]);
      if (index !== void 0 && ts) {
        item = this.items[index];
        if (item && item._timestamp === ts) {
          return item;
        } else {
          return null;
        }
      }
    };

    Ringbuffer.prototype.buildKey = function(index, item) {
      return "" + index + "-" + item._timestamp;
    };

    return Ringbuffer;

  })();

  exports.create = function(size) {
    return new Ringbuffer(size || 1000);
  };

}).call(this);
